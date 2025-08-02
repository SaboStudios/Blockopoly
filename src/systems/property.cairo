use blockopoly::model::game_model::{
    Game, GameBalance, GameCounter, GameStatus, GameTrait, GameType, IGameBalance,
};
use blockopoly::model::property_model::{
    IdToProperty, Property, PropertyToId, PropertyTrait, PropertyType, TradeCounter, TradeOffer,
    TradeOfferDetails, TradeStatus,
};
use blockopoly::model::player_model::{AddressToUsername, IsRegistered, Player, PlayerTrait, UsernameToAddress};
use starknet::ContractAddress;
// define the interface
#[starknet::interface]
pub trait IProperty<T> {
    fn buy_property(ref self: T, property_id: u8, game_id: u256) -> bool;
    fn mortgage_property(ref self: T, property_id: u8, game_id: u256) -> bool;
    fn unmortgage_property(ref self: T, property_id: u8, game_id: u256) -> bool;
    fn pay_rent(ref self: T, property_id: u8, game_id: u256) -> bool;
    fn buy_house_or_hotel(ref self: T, property_id: u8, game_id: u256) -> bool;
    fn finish_turn(ref self: T, game_id: u256) -> Game;
    fn sell_house_or_hotel(ref self: T, property_id: u8, game_id: u256) -> bool;
    
}

// dojo decorator
#[dojo::contract]
pub mod property {
    use blockopoly::model::game_player_model::{GamePlayer, GamePlayerTrait, PlayerSymbol};
    use dojo::event::EventStorage;
    use dojo::model::ModelStorage;
    use starknet::{
        ContractAddress, contract_address_const, get_block_timestamp, get_caller_address,
        get_contract_address,
    };
    use super::{
        Game, GameBalance, GameCounter, GameStatus, GameTrait, GameType, IGameBalance, IProperty,
        IdToProperty, Player, Property, PropertyToId, PropertyTrait, PropertyType, TradeCounter,
        TradeOffer, TradeOfferDetails, TradeStatus,
    };

    #[derive(Copy, Drop, Serde)]
    #[dojo::event]
    pub struct PlayerCreated {
        #[key]
        pub username: felt252,
        #[key]
        pub player: ContractAddress,
        pub timestamp: u64,
    }

    #[abi(embed_v0)]
    impl PropertysImpl of IProperty<ContractState> {
        fn buy_property(ref self: ContractState, property_id: u8, game_id: u256) -> bool {
            // get the world
            let mut world = self.world_default();
            // get the game and check it is ongoing
            let mut found_game: Game = world.read_model(game_id);
            assert!(found_game.status == GameStatus::Ongoing, "game has not started yet ");

            let caller = get_caller_address();
            // Load the property
            let mut property: Property = world.read_model((property_id, game_id));
            let mut player: GamePlayer = world.read_model((caller, property_id));
            let mut owner: GamePlayer = world.read_model((property.owner, game_id));

            assert(player.position == property.id, 'wrong property');
            assert(player.game_id == owner.game_id, 'Not in the same game');
            assert(player.balance >= property.cost_of_property, 'insufficient funds');

            // Transfer funds
            player.balance -= property.cost_of_property;
            owner.balance += property.cost_of_property;

            // Transfer ownership
            property.owner = caller;
            property.for_sale = false;
            player.properties_owned.append(property.id);

            // Increment section or special counters
            if property.property_type == PropertyType::RailRoad {
                player.no_of_railways += 1;
            }
            if property.property_type == PropertyType::Utility {
                player.no_of_utilities += 1;
            }
            match property.group_id {
                0 => {},
                1 => player.no_section1 += 1,
                2 => player.no_section2 += 1,
                3 => player.no_section3 += 1,
                4 => player.no_section4 += 1,
                5 => player.no_section5 += 1,
                6 => player.no_section6 += 1,
                7 => player.no_section7 += 1,
                8 => player.no_section8 += 1,
                _ => {},
            }

            // Finish turn
            found_game = self.finish_turn(found_game.id);

            // Persist changes
            world.write_model(@found_game);
            world.write_model(@player);
            world.write_model(@owner);
            world.write_model(@property);

            true
        }

        fn mortgage_property(ref self: ContractState, property_id: u8, game_id: u256) -> bool {
            let mut world = self.world_default();

            // Check the game is ongoing
            let mut game: Game = world.read_model(game_id);
            assert(game.status == GameStatus::Ongoing, 'Game has not started yet');
            // Load property and owner
            let mut property: Property = world.read_model((property_id, game_id));
            assert(property.id == property_id, 'Property not found');
            let caller = get_caller_address();
            let mut owner: GamePlayer = world.read_model((property.owner, game_id));

            // Ensure caller owns property and it is not already mortgaged
            assert(property.owner == caller, 'Not your property');
            assert(!property.is_mortgaged, 'Property already mortgaged');

            // Mortgage: give owner half the cost
            let amount: u256 = property.cost_of_property / 2;
            owner.balance += amount;

            // Mark property as mortgaged
            property.mortgage(caller);

            // Persist changes
            world.write_model(@owner);
            world.write_model(@property);

            true
        }


        fn unmortgage_property(ref self: ContractState, property_id: u8, game_id: u256) -> bool {
            let mut world = self.world_default();
            let caller = get_caller_address();

            // Load game and ensure it's ongoing
            let game: Game = world.read_model(game_id);
            assert(game.status == GameStatus::Ongoing, 'Game has not started yet');

            // Load property
            let mut property: Property = world.read_model((property_id, game_id));
            assert(property.id == property_id, 'Property not found');

            // Load owner
            let mut owner: GamePlayer = world.read_model((property.owner, game_id));
            

            // Assertions
            assert(property.owner == caller, 'Only the owner can unmortgage');
            assert(property.is_mortgaged, 'Property is not mortgaged');

            // Compute repayment (mortgage + interest)
            let mortgage_amount: u256 = property.cost_of_property / 2;
            let interest: u256 = mortgage_amount * 10 / 100; // 10%
            let repay_amount: u256 = mortgage_amount + interest;

            assert(owner.balance >= repay_amount, 'Insufficient unmortgage');

            // Pay the mortgage
            owner.balance -= repay_amount;

            // Lift the mortgage flag
            property.lift_mortgage(caller);

            // Persist changes
            world.write_model(@owner);
            world.write_model(@property);

            true
        }


        fn pay_rent(ref self: ContractState,  property_id: u8, game_id: u256) -> bool {
            let mut world = self.world_default();
            let caller = get_caller_address();

               // Load property
            let mut property: Property = world.read_model((property_id, game_id));
            assert(property.id == property_id, 'Property not found');

            let mut player: GamePlayer = world.read_model((caller, game_id));
            let mut owner: GamePlayer = world.read_model((property.owner, game_id));

            // Validate game
            let mut game: Game = world.read_model(game_id);
            assert(game.status == GameStatus::Ongoing, 'Game not started');

            // Basic checks
            let zero_address: ContractAddress = contract_address_const::<0>();
            assert(property.owner != zero_address, 'Property unowned');
            assert(property.owner != caller, 'Cannot pay rent to yourself');
            assert(player.position == property.id, 'Not on property');
            assert(!property.is_mortgaged, 'No rent on mortgaged');

            // Get dynamic counts
            let railroads = self.count_owner_railroads(property.owner, property.game_id);
            let utilities = self.count_owner_utilities(property.owner, property.game_id);

            // Calculate rent
            let rent_amount = property
                .get_rent_amount(railroads, utilities, player.dice_rolled.into());

            assert(player.balance >= rent_amount, 'Insufficient funds');

            // Transfer rent
            player.balance -= rent_amount;
            owner.balance += rent_amount;

            // Finish turn and persist
            game = self.finish_turn(game.id);

            world.write_model(@game);
            world.write_model(@player);
            world.write_model(@owner);
            world.write_model(@property);

            true
        }


        fn buy_house_or_hotel(ref self: ContractState, property_id: u8, game_id: u256) -> bool {
            let mut world = self.world_default();
            let caller = get_caller_address();
            let mut player: GamePlayer = world.read_model((caller, game_id));
            let mut property: Property = world.read_model((property_id, game_id));

            assert(property.owner == caller, 'Only the owner can develop');
            assert(!property.is_mortgaged, 'Property is mortgaged');
            assert(property.development < 5, 'Maximum development reached');

            // ✅ Check owns full set
            let owns_entire_group = match property.group_id {
                0 => false,
                1 => player.no_section1 == 2,
                2 => player.no_section2 == 3,
                3 => player.no_section3 == 3,
                4 => player.no_section4 == 3,
                5 => player.no_section5 == 3,
                6 => player.no_section6 == 3,
                7 => player.no_section7 == 3,
                8 => player.no_section8 == 2,
                _ => false,
            };
            assert!(owns_entire_group, "Must own all properties in the group to build");

            // ✅ Enforce even building
            let group_properties: Array<Property> = self
                .get_properties_by_group(property.group_id, property.game_id);

            let mut i = 0;
            while i < group_properties.len() {
                let prop = group_properties[i];
                if *prop.id != property.id {
                    assert!(
                        *prop.development >= property.development,
                        "Must build evenly: other properties are under-developed",
                    );
                }
                i += 1;
            };

            // ✅ Passed checks, build
            let cost: u256 = property.cost_of_house;
            assert(player.balance >= cost, 'Insufficient balance');

            player.balance -= cost;
            property.development += 1;

            if property.development < 5 {
                player.total_houses_owned += 1;
            } else {
                player.total_hotels_owned += 1;
            }

            world.write_model(@property);
            world.write_model(@player);

            true
        }

        fn sell_house_or_hotel(ref self: ContractState, property_id: u8, game_id: u256) -> bool {
            let mut world = self.world_default();
            let caller = get_caller_address();
            let mut property: Property = world.read_model((property_id, game_id));
            let contract_address = get_contract_address();

            assert(property.owner == caller, 'Only the owner ');
            assert(property.development > 0, 'No houses to sell');

            let refund: u256 = property.cost_of_house / 2;

            // self.transfer_from(contract_address, caller, game_id, refund);

            property.development -= 1;

            world.write_model(@property);

            true
        }

        fn finish_turn(ref self: ContractState, game_id: u256) -> Game {
            let mut world = self.world_default();
            let caller = get_caller_address();
            let mut index = 0;
            let mut current_index = 0;
            let mut game: Game = world.read_model(game_id);
            let players_len = game.game_players.len();

            while index < players_len {
                let player = game.game_players.at(index);
                if *player == caller {
                    current_index = index;
                    break;
                }
                index += 1;
            };

            let next_index = (current_index + 1) % players_len;
            game.next_player = *game.game_players.at(next_index);

            world.write_model(@game);
            game
        }
       
    }

    #[generate_trait]
    impl InternalImpl of InternalTrait {
        /// Use the default namespace "dojo_starter". This function is handy since the ByteArray
        /// can't be const.
        fn world_default(self: @ContractState) -> dojo::world::WorldStorage {
            self.world(@"blockopoly")
        }

               fn create_trade_id(ref self: ContractState) -> u256 {
            let mut world = self.world_default();
            let mut trade_counter: TradeCounter = world.read_model('v0');
            let new_val = trade_counter.current_val + 1;
            trade_counter.current_val = new_val;
            world.write_model(@trade_counter);
            new_val
        }


        fn get_properties_by_group(
            ref self: ContractState, group_id: u8, game_id: u256,
        ) -> Array<Property> {
            let mut world = self.world_default();
            let mut group_properties: Array<Property> = array![];

            let mut i = 0; // defaults to felt252
            while i < 41_u32 {
                let prop: Property = world.read_model((i, game_id));
                if prop.group_id == group_id {
                    group_properties.append(prop);
                }
                i += 1;
            };

            group_properties
        }

        fn count_owner_railroads(
            ref self: ContractState, owner: ContractAddress, game_id: u256,
        ) -> u8 {
            let mut count = 0;
            let mut i = 1;
            while i < 41_u32 {
                let prop: Property = self.world_default().read_model((i, game_id));
                if prop.owner == owner && prop.property_type == PropertyType::RailRoad {
                    count += 1;
                }
                i += 1;
            };
            count
        }

        // Count how many utilities the owner has
        fn count_owner_utilities(
            ref self: ContractState, owner: ContractAddress, game_id: u256,
        ) -> u8 {
            let mut count = 0;
            let mut i = 1;
            while i < 41_u32 {
                let prop: Property = self.world_default().read_model((i, game_id));
                if prop.owner == owner && prop.property_type == PropertyType::Utility {
                    count += 1;
                }
                i += 1;
            };
            count
        }
    }
}

