// dojo decorator
#[dojo::contract]
pub mod actions {
    use dojo_starter::interfaces::IActions::IActions;
    use dojo_starter::model::property_model::{
        Property, PropertyType, PropertyTrait, PropertyToId, IdToProperty,
    };
    use dojo_starter::model::utility_model::{Utility, UtilityTrait, UtilityToId, IdToUtility};
    use dojo_starter::model::rail_road_model::{RailRoad, RailRoadTrait, RailRoadToId, IdToRailRoad};
    use dojo_starter::model::game_model::{
        GameType, Game, GameBalance, GameTrait, GameCounter, GameStatus, IGameBalance,
    };
    use dojo_starter::model::player_model::{
        Player, UsernameToAddress, AddressToUsername, PlayerTrait, IsRegistered,
    };
    use dojo_starter::model::game_player_model::{GamePlayer, PlayerSymbol, GamePlayerTrait};
    use dojo_starter::model::chance_model::{Chance, ChanceTrait};
    use dojo_starter::model::community_chest_model::{CommunityChest, CommunityChestTrait};
    use dojo_starter::model::jail_model::{Jail};
    use dojo_starter::model::go_free_parking_model::{Go};
    use dojo_starter::model::tax_model::{Tax};
    use starknet::{
        ContractAddress, get_caller_address, get_block_timestamp, contract_address_const,
        get_contract_address,
    };

    use dojo::model::{ModelStorage};
    use dojo::event::EventStorage;
    use origami_random::dice::{Dice, DiceTrait};


    #[derive(Copy, Drop, Serde)]
    #[dojo::event]
    pub struct GameCreated {
        #[key]
        pub game_id: u256,
        pub timestamp: u64,
    }

    #[derive(Copy, Drop, Serde)]
    #[dojo::event]
    pub struct PlayerCreated {
        #[key]
        pub username: felt252,
        #[key]
        pub player: ContractAddress,
        pub timestamp: u64,
    }

    #[derive(Copy, Drop, Serde)]
    #[dojo::event]
    pub struct GameStarted {
        #[key]
        pub game_id: u256,
        pub timestamp: u64,
    }

    #[derive(Copy, Drop, Serde)]
    #[dojo::event]
    pub struct PlayerJoined {
        #[key]
        pub game_id: u256,
        #[key]
        pub username: felt252,
        pub timestamp: u64,
    }


    #[abi(embed_v0)]
    impl ActionsImpl of IActions<ContractState> {
        fn is_registered(self: @ContractState, address: ContractAddress) -> bool {
            let world = self.world_default();
            let is_registered: IsRegistered = world.read_model(address);
            is_registered.is_registered
        }

        fn roll_dice(ref self: ContractState) -> (u8, u8) {
            let seed = get_block_timestamp();

            let mut dice1 = DiceTrait::new(6, seed.try_into().unwrap());
            let mut dice2 = DiceTrait::new(6, (seed + 1).try_into().unwrap());

            let dice1_roll = dice1.roll();
            let dice2_roll = dice2.roll();

            (dice1_roll, dice2_roll)
        }

        fn get_username_from_address(self: @ContractState, address: ContractAddress) -> felt252 {
            let world = self.world_default();

            let address_map: AddressToUsername = world.read_model(address);

            address_map.username
        }

        fn register_new_player(ref self: ContractState, username: felt252) {
            let mut world = self.world_default();

            let caller: ContractAddress = get_caller_address();

            let zero_address: ContractAddress = contract_address_const::<0x0>();

            let timestamp = get_block_timestamp();

            // Validate username
            assert(username != 0, 'USERNAME CANNOT BE ZERO');

            // Check if the player already exists (ensure username is unique)
            let existing_player: UsernameToAddress = world.read_model(username);
            assert(existing_player.address == zero_address, 'USERNAME ALREADY TAKEN');

            // Ensure player cannot update username by calling this function
            let existing_username = self.get_username_from_address(caller);

            assert(existing_username == 0, 'USERNAME ALREADY CREATED');

            let new_player: Player = PlayerTrait::new(username, caller, timestamp);
            let username_to_address: UsernameToAddress = UsernameToAddress {
                username, address: caller,
            };
            let address_to_username: AddressToUsername = AddressToUsername {
                address: caller, username,
            };
            let mut is_registered: IsRegistered = world.read_model(caller);
            is_registered.is_registered = true;

            world.write_model(@is_registered);
            world.write_model(@new_player);
            world.write_model(@username_to_address);
            world.write_model(@address_to_username);
            world
                .emit_event(
                    @PlayerCreated { username, player: caller, timestamp: get_block_timestamp() },
                );
        }

        fn get_tax(self: @ContractState, id: u8, game_id: u256) -> Tax {
            let world = self.world_default();
            let tax: Tax = world.read_model((id, game_id));
            tax
        }

        fn get_go(self: @ContractState, id: u8, game_id: u256) -> Go {
            let world = self.world_default();
            let go: Go = world.read_model((id, game_id));
            go
        }

        fn get_chance(self: @ContractState, id: u8, game_id: u256) -> Chance {
            let world = self.world_default();
            let chance: Chance = world.read_model((id, game_id));
            chance
        }

        fn get_community_chest(self: @ContractState, id: u8, game_id: u256) -> CommunityChest {
            let world = self.world_default();
            let community_chest: CommunityChest = world.read_model((id, game_id));
            community_chest
        }

        fn get_property(self: @ContractState, id: u8, game_id: u256) -> Property {
            let world = self.world_default();
            let property: Property = world.read_model((id, game_id));
            property
        }

        fn get_utility(self: @ContractState, id: u8, game_id: u256) -> Utility {
            let world = self.world_default();
            let utility: Utility = world.read_model((id, game_id));
            utility
        }

        fn get_railroad(self: @ContractState, id: u8, game_id: u256) -> RailRoad {
            let world = self.world_default();
            let railroad: RailRoad = world.read_model((id, game_id));
            railroad
        }

        fn get_jail(self: @ContractState, id: u8, game_id: u256) -> Jail {
            let world = self.world_default();
            let jail: Jail = world.read_model((id, game_id));
            jail
        }

        fn start_game(ref self: ContractState, game_id: u256) -> bool {
            let mut world = self.world_default();
            let mut game: Game = world.read_model(game_id);

            game.status = GameStatus::Ongoing;
            game.next_player = get_caller_address();

            let len = game.game_players.len();
            let mut i = 0;
            while i < len {
                self.mint(*game.game_players[i], 1, 1500);
                i += 1;
            };
            world.write_model(@game);
            true
        }

        // to stay and call models
        fn create_new_game(
            ref self: ContractState,
            game_type: GameType,
            player_symbol: PlayerSymbol,
            number_of_players: u8,
        ) -> u256 {
            // Get default world
            let mut world = self.world_default();

            assert(number_of_players >= 2 && number_of_players <= 8, 'invalid no of players');

            // Get the account address of the caller
            let caller_address = get_caller_address();

            let caller_username = self.get_username_from_address(caller_address);
            assert(caller_username != 0, 'PLAYER NOT REGISTERED');

            let game_id = self.create_new_game_id();
            let mut player: GamePlayer = world.read_model((caller_address, game_id));
            let timestamp = get_block_timestamp();

            // Initialize player symbols
            let (
                player_hat,
                player_car,
                player_dog,
                player_thimble,
                player_iron,
                player_battleship,
                player_boot,
                player_wheelbarrow,
            ) =
                match player_symbol {
                PlayerSymbol::Hat => (caller_username, 0, 0, 0, 0, 0, 0, 0),
                PlayerSymbol::Car => (0, caller_username, 0, 0, 0, 0, 0, 0),
                PlayerSymbol::Dog => (0, 0, caller_username, 0, 0, 0, 0, 0),
                PlayerSymbol::Thimble => (0, 0, 0, caller_username, 0, 0, 0, 0),
                PlayerSymbol::Iron => (0, 0, 0, 0, caller_username, 0, 0, 0),
                PlayerSymbol::Battleship => (0, 0, 0, 0, 0, caller_username, 0, 0),
                PlayerSymbol::Boot => (0, 0, 0, 0, 0, 0, caller_username, 0),
                PlayerSymbol::Wheelbarrow => (0, 0, 0, 0, 0, 0, 0, caller_username),
            };

            let mut game_player = ArrayTrait::new();
            game_player.append(caller_address);

            let chance = self.generate_chance_deck();
            let community = self.generate_community_chest_deck();

            // Create a new game
            let mut new_game: Game = GameTrait::new(
                game_id,
                caller_username,
                game_type,
                player_hat,
                player_car,
                player_dog,
                player_thimble,
                player_iron,
                player_battleship,
                player_boot,
                player_wheelbarrow,
                number_of_players,
                game_player,
                chance,
                community,
            );
            // Generate tiles
            self.generate_board_tiles(game_id);
            // Set visibility based on game mode
            let mut emitted_game_id = game_id;

            if (game_type == GameType::PrivateGame) {
                emitted_game_id = 0;
            }

            new_game.players_joined += 1;

            // Save game to storage
            world.write_model(@new_game);

            world.emit_event(@GameCreated { game_id: emitted_game_id, timestamp });

            game_id
        }

        /// Allows a registered player to join a pending game by selecting a symbol.
        /// Automatically starts the game once the required number of players have joined.
        fn join_game(ref self: ContractState, player_symbol: PlayerSymbol, game_id: u256) {
            // Load world state
            let mut world = self.world_default();

            // Retrieve game from storage
            let mut game: Game = world.read_model(game_id);

            // Ensure the game has been initialized
            assert(game.is_initialised, 'GAME NOT INITIALISED');

            // Ensure the game still has room for new players
            assert(game.players_joined < game.number_of_players, 'ROOM FILLED');

            // Ensure the game is in the Pending state
            assert(game.status == GameStatus::Pending, 'GAME NOT PENDING');

            // Get the caller's address and corresponding username
            let caller_address = get_caller_address();
            let caller_username = self.get_username_from_address(caller_address);

            // Ensure the caller is a registered player
            assert(caller_username != 0, 'PLAYER NOT REGISTERED');

            // Ensure the player hasn't already joined under a different symbol
            self.assert_player_not_already_joined(game.clone(), caller_username);

            // Attempt to join the game with the selected symbol
            self.try_join_symbol(game.clone(), player_symbol, caller_username, game_id);

            // Emit event for player joining
            world
                .emit_event(
                    @PlayerJoined {
                        game_id, username: caller_username, timestamp: get_block_timestamp(),
                    },
                );

            // Recount players and update the joined count
            game.players_joined = self.count_joined_players(game.clone());
            game.game_players.append(get_caller_address());

            // Start the game if all players have joined
            if game.players_joined == game.number_of_players {
                game.status = GameStatus::Ongoing;
                world.emit_event(@GameStarted { game_id, timestamp: get_block_timestamp() });
            }

            // Persist the updated game state
            world.write_model(@game);
        }


        fn sell_property(ref self: ContractState, property_id: u8, game_id: u256) -> bool {
            let mut world = self.world_default();
            let caller = get_caller_address();
            let mut property: Property = world.read_model((property_id, game_id));

            assert(property.owner == caller, 'Can only sell your property');

            property.for_sale = true;
            world.write_model(@property);

            true
        }


        fn mortgage_property(ref self: ContractState, mut property: Property) -> bool {
            let mut world = self.world_default();

            // Check the game is ongoing
            let mut game: Game = world.read_model(property.game_id);
            assert(game.status == GameStatus::Ongoing, 'Game has not started yet');

            let caller = get_caller_address();
            let mut owner: GamePlayer = world.read_model((property.owner, property.game_id));

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


        fn unmortgage_property(ref self: ContractState, mut property: Property) -> bool {
            let mut world = self.world_default();
            let caller = get_caller_address();

            // Load game and ensure it's ongoing
            let game: Game = world.read_model(property.game_id);
            assert(game.status == GameStatus::Ongoing, 'Game has not started yet');

            // Load owner
            let mut owner: GamePlayer = world.read_model((property.owner, property.game_id));

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


        fn pay_rent(ref self: ContractState, mut property: Property) -> bool {
            let mut world = self.world_default();
            let caller = get_caller_address();

            let mut player: GamePlayer = world.read_model((caller, property.game_id));
            let mut owner: GamePlayer = world.read_model((property.owner, property.game_id));

            // Validate game
            let mut game: Game = world.read_model(property.game_id);
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
            game = self.finish_turn(game);

            world.write_model(@game);
            world.write_model(@player);
            world.write_model(@owner);
            world.write_model(@property);

            true
        }


        fn move_player(ref self: ContractState, game_id: u256, steps: u8) -> u8 {
            let mut world = self.world_default();
            let caller = get_caller_address();
            let mut game_player: GamePlayer = world.read_model((caller, game_id));
            let mut game: Game = world.read_model(game_id);

            assert(game.next_player == caller, 'Not your turn');
            assert(game.status == GameStatus::Ongoing, 'Game is not ongoing');

            // Move player
            game_player = GamePlayerTrait::move(game_player, steps);

            game_player.dice_rolled = steps;

            if game_player.position > 40 {
                game_player.position = ((game_player.position - 1) % 40) + 1;
                game_player.balance += 200;
            }

            let mut property = self.get_property(game_player.position, game_id);
            property = self.handle_property_landing(game_player.clone(), property.clone());

            // Update state
            world.write_model(@game_player);
            world.write_model(@game);

            game_player.position
        }

        fn buy_property(ref self: ContractState, mut property: Property) -> bool {
            // get the world
            let mut world = self.world_default();
            // get the game and check it is ongoing
            let mut found_game: Game = world.read_model(property.game_id);
            assert!(found_game.status == GameStatus::Ongoing, "game has not started yet ");

            let caller = get_caller_address();

            let mut player: GamePlayer = world.read_model((caller, property.game_id));
            let mut owner: GamePlayer = world.read_model((property.owner, property.game_id));

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
            found_game = self.finish_turn(found_game);

            // Persist changes
            world.write_model(@found_game);
            world.write_model(@player);
            world.write_model(@owner);
            world.write_model(@property);

            true
        }


        fn buy_house_or_hotel(ref self: ContractState, mut property: Property) -> bool {
            let mut world = self.world_default();
            let caller = get_caller_address();
            let mut player: GamePlayer = world.read_model((caller, property.game_id));

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


        // fn offer_trade(
        //     ref self: ContractState,
        //     game_id: u256,
        //     to: ContractAddress,
        //     offered_property_ids: Array<u8>,
        //     requested_property_ids: Array<u8>,
        //     cash_offer: u256,
        //     cash_request: u256,
        // ) {
        //     let mut world = self.world_default();
        //     let caller = get_caller_address();

        //     // Validate trade parameters
        //     assert(offered_property_ids.len() > 0 || cash_offer > 0, 'No properties or cash
        //     offered');
        //     assert(requested_property_ids.len() > 0 || cash_request > 0, 'No properties or cash
        //     requested');

        //     // Ensure the recipient is a valid player in the game
        //     let recipient_username = self.get_username_from_address(to);
        //     assert(recipient_username != 0, 'Recipient not registered');

        //     // Create and store the trade offer
        //     let trade_id = world.get_next_trade_id();
        //     let trade_offer = TradeOffer {
        //         trade_id,
        //         from: caller,
        //         to,
        //         offered_property_ids,
        //         requested_property_ids,
        //         cash_offer,
        //         cash_request,
        //         status: TradeStatus::Pending,
        //     };

        fn sell_house_or_hotel(ref self: ContractState, property_id: u8, game_id: u256) -> bool {
            let mut world = self.world_default();
            let caller = get_caller_address();
            let mut property: Property = world.read_model((property_id, game_id));
            let contract_address = get_contract_address();

            assert(property.owner == caller, 'Only the owner ');
            assert(property.development > 0, 'No houses to sell');

            let refund: u256 = property.cost_of_house / 2;

            // self.transfer_from(contract_address, caller, game_id, refund);/

            property.development -= 1;

            world.write_model(@property);

            true
        }


        fn retrieve_game(self: @ContractState, game_id: u256) -> Game {
            // Get default world
            let mut world = self.world_default();
            //get the game state
            let game: Game = world.read_model(game_id);
            game
        }

        fn transfer_from(
            ref self: ContractState, mut from: GamePlayer, mut to: GamePlayer, amount: u256,
        ) -> Array<GamePlayer> {
            let mut world = self.world_default();

            assert(from.game_id == to.game_id, 'Not in the same game');
            assert(from.balance >= amount, 'insufficient funds');

            from.balance -= amount;
            to.balance += amount;

            let mut game_players: Array<GamePlayer> = array![];
            game_players.append(from);
            game_players.append(to);

            game_players
        }


        fn mint(ref self: ContractState, recepient: ContractAddress, game_id: u256, amount: u256) {
            let mut world = self.world_default();
            let mut player: GamePlayer = world.read_model((recepient, game_id));
            player.balance += amount;
            world.write_model(@player);
        }


        fn get_players_balance(
            self: @ContractState, player: ContractAddress, game_id: u256,
        ) -> u256 {
            let world = self.world_default();

            let players_balance: GameBalance = world.read_model((player, game_id));
            players_balance.balance
        }

        fn retrieve_player(self: @ContractState, addr: ContractAddress) -> Player {
            // Get default world
            let mut world = self.world_default();
            let player: Player = world.read_model(addr);

            player
        }

        fn retrieve_game_player(
            self: @ContractState, addr: ContractAddress, game_id: u256,
        ) -> GamePlayer {
            // Get default world
            let mut world = self.world_default();
            let player: GamePlayer = world.read_model((addr, game_id));

            player
        }

        fn is_game_started(self: @ContractState, game_id: u256) -> u8 {
            let mut world = self.world_default();
            let mut game: Game = world.read_model(game_id);
            let mut stat: u8 = 10;
            if (game.status == GameStatus::Ongoing) {
                stat = 1
            };
            if (game.status == GameStatus::Ended) {
                stat = 0
            };

            if (game.status == GameStatus::Pending) {
                stat = 2
            };
            stat
        }

        fn finish_turn(ref self: ContractState, mut game: Game) -> Game {
            let mut world = self.world_default();
            let caller = get_caller_address();
            let mut index = 0;
            let mut current_index = 0;
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

        fn generate_chance_deck(ref self: ContractState) -> Array<ByteArray> {
            let mut deck: Array<ByteArray> = array![];

            deck.append("Advance to Go (Collect $200)");
            deck.append("Advance to Illinois Avenue - If you pass Go, collect $200");
            deck.append("Advance to St. Charles Place - If you pass Go, collect $200");
            deck.append("Advance token to nearest Utility. Pay 10x dice.");
            deck.append("Advance token to nearest Railroad. Pay 2x rent.");
            deck.append("Bank pays you dividend of $50");
            deck.append("Get out of Jail Free");
            deck.append("Go Back 3 Spaces");
            deck.append("Go to Jail dirctly do not pass Go do not collect $200");
            deck.append("Make general repairs - $25 house, $100 hotel");
            deck.append("Pay poor tax of $15");
            deck.append("Take a trip to Reading Railroad");
            deck.append("Take a walk on the Boardwalk");
            deck.append("Speeding fine $200");
            deck.append("Building loan matures - collect $150");

            // self.shuffle_array(deck);

            deck
        }

        // Count how many railroads the owner has
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


        fn generate_chance_indices(ref self: ContractState) -> Array<u32> {
            let mut indices: Array<u32> = array![];
            let cards = self.generate_chance_deck();
            let n = cards.len();
            let mut i = 0;
            while i < n {
                indices.append(i);
                i += 1;
            };
            indices
        }

        fn handle_chance(ref self: ContractState, game_id: u256, random_index: u32) -> ByteArray {
            let mut world = self.world_default();
            let mut game: Game = world.read_model(game_id);

            let len = game.chance.len();
            if len == 0 {
                game.chance = self.generate_chance_deck(); // returns Array<ByteArray>
                world.write_model(@game);
            }
            let draw_index = (random_index % (len));

            // Directly get the card ByteArray from game.chance (no further indexing needed)
            let card = game.chance[draw_index].clone();

            // Build a new deck without the drawn card
            let mut new_deck = array![];
            let mut i = 0;
            while i < len {
                if i != draw_index {
                    new_deck.append(game.chance[i].clone());
                }
                i += 1;
            };
            game.chance = new_deck.clone();

            world.write_model(@game);

            card
        }


        fn handle_community_chest(
            ref self: ContractState, game_id: u256, random_index: u32,
        ) -> ByteArray {
            let mut world = self.world_default();
            let mut game: Game = world.read_model(game_id);

            let len = game.community.len();
            if len == 0 {
                game.community = self.generate_community_chest_deck(); // Array<ByteArray>
                world.write_model(@game);
            }

            let draw_index = (random_index % (len));

            // Get the card directly from the community deck
            let card = game.community[draw_index].clone();

            // Build a new deck without the drawn card
            let mut new_deck = array![];
            let mut i = 0;
            while i < len {
                if i != draw_index {
                    new_deck.append(game.community[i].clone());
                }
                i += 1;
            };
            game.community = new_deck;

            world.write_model(@game);

            card
        }


        fn find_nearest(ref self: ContractState, player_pos: u8, utilities: Array<u8>) -> u8 {
            let board_size: u8 = 40;

            let mut nearest_pos: u8 = *utilities[0];
            let mut smallest_distance = if *utilities[0] >= player_pos {
                *utilities[0] - player_pos
            } else {
                board_size - (player_pos - *utilities[0])
            };

            let len = utilities.len();
            let mut i = 1;
            while i < len {
                let utility_pos = *utilities[i];
                let distance = if utility_pos >= player_pos {
                    utility_pos - player_pos
                } else {
                    board_size - (player_pos - utility_pos)
                };

                if distance < smallest_distance {
                    smallest_distance = distance;
                    nearest_pos = utility_pos;
                }
                i += 1;
            };

            nearest_pos
        }


        fn process_chance_card(
            ref self: ContractState, mut game: Game, mut player: GamePlayer, card: ByteArray,
        ) -> (Game, GamePlayer) {
            // We'll decode by matching text.
            // NOTE: If you have enums or ids for cards, it's cleaner. With ByteArray, compare
            // strings.

            if card == "Advance to Go (Collect $200)" {
                player.position = 1;
                player.balance += 200;
            } else if card == "Advance to Illinois Avenue - If you pass Go, collect $200" {
                if player.position > 24 { // suppose Illinois is tile 24
                    player.balance += 200;
                }
                player.position = 24;
            } else if card == "Advance to St. Charles Place - If you pass Go, collect $200" {
                if player.position > 11 {
                    player.balance += 200;
                }
                player.position = 11;
            } else if card == "Advance token to nearest Utility. Pay 10x dice." {
                let mut pos: Array<u8> = array![];
                pos.append(12);
                pos.append(28);
                let utility_pos = self.find_nearest(player.position, pos);
                player.position = utility_pos;
                let rent: u256 = 10 * player.dice_rolled.into();
                player.balance -= rent;
            } else if card == "Advance token to nearest Railroad. Pay 2x rent." {
                let mut pos: Array<u8> = array![];
                pos.append(5);
                pos.append(15);
                pos.append(25);
                pos.append(35);
                let rail_pos = self.find_nearest(player.position, pos);
                player.position = rail_pos;
                let rail = self.get_property(rail_pos, game.clone().id);
                self.pay_rent(rail);
                self.pay_rent(rail);
            } else if card == "Bank pays you dividend of $50" {
                player.balance += 50;
            } else if card == "Get out of Jail Free" {
                player.chance_jail_card = true;
            } else if card == "Go Back 3 Spaces" {
                if player.position < 4 {
                    player.position = 40 - (4 - player.position);
                } else {
                    player.position -= 3;
                }
            } else if card == "Go to Jail" {
                player.position = 11; // suppose jail is tile 11
                player.jailed = true;
            } else if card == "Make general repairs - $25 house, $100 hotel" {
                let houses = player.total_houses_owned;
                let hotels = player.total_hotels_owned;
                let cost = (25 * houses) + (100 * hotels);
                player.balance -= cost.into();
            } else if card == "Pay poor tax of $15" {
                player.balance -= 15;
            } else if card == "Take a trip to Reading Railroad" {
                if player.position > 6 {
                    player.balance += 200;
                }
                player.position = 6; // reading railroad
            } else if card == "Take a walk on the Boardwalk" {
                player.position = 39;
            } else if card == "Speeding fine $200" {
                player.balance -= 200;
            } else if card == "Building loan matures - collect $150" {
                player.balance += 150;
            }

            (game, player)
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


        fn process_community_chest_card(
            ref self: ContractState, mut game: Game, mut player: GamePlayer, card: ByteArray,
        ) -> (Game, GamePlayer) {
            let mut world = self.world_default();
            if card == "Advance to Go (Collect $200)" {
                player.position = 1;
                player.balance += 200;
            } else if card == "Bank error in your favor - Collect $200" {
                player.balance += 200;
            } else if card == "Doctor fee - Pay $50" {
                player.balance -= 50;
            } else if card == "From sale of stock - collect $50" {
                player.balance += 50;
            } else if card == "Get Out of Jail Free" {
                player.comm_free_card = true;
            } else if card == "Go to Jail" {
                player.position = 11; // jail position
                player.jailed = true;
            } else if card == "Grand Opera Night - collect $50 from every player" {
                let mut i = 0;
                while i < game.game_players.len() {
                    let addr = *game.game_players[i];
                    if addr != player.address {
                        let mut other_player: GamePlayer = self.retrieve_game_player(addr, game.id);
                        other_player.balance -= 50;
                        player.balance += 50;
                        world.write_model(@other_player);
                    }
                    i += 1;
                }
            } else if card == "Holiday Fund matures - Receive $100" {
                player.balance += 100;
            } else if card == "Income tax refund - Collect $20" {
                player.balance += 20;
            } else if card == "Life insurance matures - Collect $100" {
                player.balance += 100;
            } else if card == "Pay hospital fees of $100" {
                player.balance -= 100;
            } else if card == "Pay school fees of $150" {
                player.balance -= 150;
            } else if card == "Receive $25 consultancy fee" {
                player.balance += 25;
            } else if card == "Street repairs - $40 per house, $115 per hotel" {
                let houses = player.total_houses_owned;
                let hotels = player.total_hotels_owned;
                let cost = (40 * houses) + (115 * hotels);
                player.balance -= cost.into();
            } else if card == "Won second prize in beauty contest - Collect $10" {
                player.balance += 10;
            } else if card == "You inherit $100" {
                player.balance += 100;
            }

            (game, player)
        }

        fn generate_community_chest_deck(ref self: ContractState) -> Array<ByteArray> {
            let mut deck: Array<ByteArray> = array![];

            deck.append("Advance to Go (Collect $200)");
            deck.append("Bank error in your favor - Collect $200");
            deck.append("Doctor fee - Pay $50");
            deck.append("From sale of stock - collect $50");
            deck.append("Get Out of Jail Free");
            deck.append("Go to Jail");
            deck.append("Grand Opera Night - collect $50 from every player");
            deck.append("Holiday Fund matures - Receive $100");
            deck.append("Income tax refund - Collect $20");
            deck.append("Life insurance matures - Collect $100");
            deck.append("Pay hospital fees of $100");
            deck.append("Pay school fees of $150");
            deck.append("Receive $25 consultancy fee");
            deck.append("Street repairs - $40 per house, $115 per hotel");
            deck.append("Won second prize in beauty contest - Collect $10");
            deck.append("You inherit $100");

            // self.shuffle_array(deck);

            deck
        }


        fn generate_board_tiles(ref self: ContractState, game_id: u256) {
            let mut world = self.world_default();
            let contract_address = get_contract_address();
            let bank: GamePlayer = world.read_model((contract_address, game_id));

            self
                .generate_properties(
                    1,
                    game_id,
                    'Go',
                    0,
                    PropertyType::Go,
                    0,
                    0,
                    0,
                    0,
                    0,
                    0,
                    0,
                    false,
                    0,
                    bank.address,
                );
            self
                .generate_properties(
                    2,
                    game_id,
                    'Axone Avenue',
                    60,
                    PropertyType::Property,
                    2,
                    10,
                    30,
                    90,
                    160,
                    250,
                    50,
                    false,
                    1,
                    bank.address,
                );
            self
                .generate_properties(
                    3,
                    game_id,
                    'Community Chest',
                    0,
                    PropertyType::CommunityChest,
                    0,
                    0,
                    0,
                    0,
                    0,
                    0,
                    0,
                    false,
                    0,
                    bank.address,
                );
            self
                .generate_properties(
                    4,
                    game_id,
                    'Onlydust Avenue',
                    60,
                    PropertyType::Property,
                    4,
                    20,
                    60,
                    180,
                    320,
                    450,
                    50,
                    false,
                    1,
                    bank.address,
                );
            self
                .generate_properties(
                    5,
                    game_id,
                    'IPFS Railroad',
                    200,
                    PropertyType::RailRoad,
                    25,
                    50,
                    100,
                    200,
                    400,
                    0,
                    0,
                    false,
                    0,
                    bank.address,
                );
            self
                .generate_properties(
                    6,
                    game_id,
                    'ZkSync Lane',
                    100,
                    PropertyType::Property,
                    6,
                    30,
                    90,
                    270,
                    400,
                    550,
                    50,
                    false,
                    2,
                    bank.address,
                );
            self
                .generate_properties(
                    7,
                    game_id,
                    'Chance',
                    0,
                    PropertyType::Chance,
                    0,
                    0,
                    0,
                    0,
                    0,
                    0,
                    0,
                    false,
                    0,
                    bank.address,
                );
            self
                .generate_properties(
                    8,
                    game_id,
                    'Starknet Lane',
                    100,
                    PropertyType::Property,
                    6,
                    30,
                    90,
                    270,
                    400,
                    550,
                    50,
                    false,
                    2,
                    bank.address,
                );
            self
                .generate_properties(
                    9,
                    game_id,
                    'Linea Lane',
                    120,
                    PropertyType::Property,
                    8,
                    40,
                    100,
                    300,
                    450,
                    600,
                    50,
                    false,
                    2,
                    bank.address,
                );
            self
                .generate_properties(
                    10,
                    game_id,
                    'Visiting Jail',
                    0,
                    PropertyType::VisitingJail,
                    0,
                    0,
                    0,
                    0,
                    0,
                    0,
                    0,
                    false,
                    0,
                    bank.address,
                );

            self
                .generate_properties(
                    11,
                    game_id,
                    'Arbitrium Avenue',
                    140,
                    PropertyType::Property,
                    10,
                    50,
                    150,
                    450,
                    625,
                    750,
                    100,
                    false,
                    3,
                    bank.address,
                );
            self
                .generate_properties(
                    12,
                    game_id,
                    'Chainlink Power Plant',
                    150,
                    PropertyType::Utility,
                    0,
                    0,
                    0,
                    0,
                    0,
                    0,
                    0,
                    false,
                    0,
                    bank.address,
                );
            self
                .generate_properties(
                    13,
                    game_id,
                    'Optimistic Avenue',
                    140,
                    PropertyType::Property,
                    10,
                    50,
                    150,
                    450,
                    625,
                    750,
                    100,
                    false,
                    3,
                    bank.address,
                );
            self
                .generate_properties(
                    14,
                    game_id,
                    'Community Chest',
                    0,
                    PropertyType::CommunityChest,
                    0,
                    0,
                    0,
                    0,
                    0,
                    0,
                    0,
                    false,
                    0,
                    bank.address,
                );
            self
                .generate_properties(
                    15,
                    game_id,
                    'Pinata Railroad',
                    200,
                    PropertyType::RailRoad,
                    25,
                    50,
                    100,
                    200,
                    400,
                    0,
                    0,
                    false,
                    0,
                    bank.address,
                );
            self
                .generate_properties(
                    16,
                    game_id,
                    'Base Avenue',
                    160,
                    PropertyType::Property,
                    12,
                    60,
                    180,
                    500,
                    700,
                    900,
                    100,
                    false,
                    3,
                    bank.address,
                );
            self
                .generate_properties(
                    17,
                    game_id,
                    'Chance',
                    0,
                    PropertyType::Chance,
                    0,
                    0,
                    0,
                    0,
                    0,
                    0,
                    0,
                    false,
                    0,
                    bank.address,
                );
            self
                .generate_properties(
                    18,
                    game_id,
                    'Cosmos Lane',
                    180,
                    PropertyType::Property,
                    14,
                    70,
                    200,
                    550,
                    750,
                    950,
                    100,
                    false,
                    4,
                    bank.address,
                );
            self
                .generate_properties(
                    19,
                    game_id,
                    'Polkadot Lane',
                    180,
                    PropertyType::Property,
                    14,
                    70,
                    200,
                    550,
                    750,
                    950,
                    100,
                    false,
                    4,
                    bank.address,
                );
            self
                .generate_properties(
                    20,
                    game_id,
                    'Free Parking',
                    0,
                    PropertyType::FreeParking,
                    0,
                    0,
                    0,
                    0,
                    0,
                    0,
                    0,
                    false,
                    0,
                    bank.address,
                );

            self
                .generate_properties(
                    21,
                    game_id,
                    'Near Lane',
                    200,
                    PropertyType::Property,
                    16,
                    80,
                    220,
                    600,
                    800,
                    1000,
                    100,
                    false,
                    4,
                    bank.address,
                );
            self
                .generate_properties(
                    22,
                    game_id,
                    'Community Chest',
                    0,
                    PropertyType::CommunityChest,
                    0,
                    0,
                    0,
                    0,
                    0,
                    0,
                    0,
                    false,
                    0,
                    bank.address,
                );
            self
                .generate_properties(
                    23,
                    game_id,
                    'Uniswap Avenue',
                    220,
                    PropertyType::Property,
                    18,
                    90,
                    250,
                    700,
                    875,
                    1050,
                    150,
                    false,
                    5,
                    bank.address,
                );
            self
                .generate_properties(
                    24,
                    game_id,
                    'MakerDAO Avenue',
                    220,
                    PropertyType::Property,
                    18,
                    90,
                    250,
                    700,
                    875,
                    1050,
                    150,
                    false,
                    5,
                    bank.address,
                );
            self
                .generate_properties(
                    25,
                    game_id,
                    'OpenZeppelin Railroad',
                    200,
                    PropertyType::RailRoad,
                    25,
                    50,
                    100,
                    200,
                    400,
                    0,
                    0,
                    false,
                    0,
                    bank.address,
                );
            self
                .generate_properties(
                    26,
                    game_id,
                    'Aave Avenue',
                    240,
                    PropertyType::Property,
                    20,
                    100,
                    300,
                    750,
                    925,
                    1100,
                    150,
                    false,
                    5,
                    bank.address,
                );
            self
                .generate_properties(
                    27,
                    game_id,
                    'Graph Water Works',
                    150,
                    PropertyType::Utility,
                    0,
                    0,
                    0,
                    0,
                    0,
                    0,
                    0,
                    false,
                    0,
                    bank.address,
                );
            self
                .generate_properties(
                    28,
                    game_id,
                    'Lisk Lane',
                    260,
                    PropertyType::Property,
                    22,
                    110,
                    330,
                    800,
                    975,
                    1150,
                    150,
                    false,
                    6,
                    bank.address,
                );
            self
                .generate_properties(
                    29,
                    game_id,
                    'Chance',
                    0,
                    PropertyType::Chance,
                    0,
                    0,
                    0,
                    0,
                    0,
                    0,
                    0,
                    false,
                    0,
                    bank.address,
                );
            self
                .generate_properties(
                    30,
                    game_id,
                    'Go To Jail',
                    0,
                    PropertyType::Jail,
                    0,
                    0,
                    0,
                    0,
                    0,
                    0,
                    0,
                    false,
                    0,
                    bank.address,
                );

            self
                .generate_properties(
                    31,
                    game_id,
                    'Rootstock Lane',
                    260,
                    PropertyType::Property,
                    22,
                    110,
                    330,
                    800,
                    975,
                    1150,
                    150,
                    false,
                    6,
                    bank.address,
                );
            self
                .generate_properties(
                    32,
                    game_id,
                    'Ark Lane',
                    280,
                    PropertyType::Property,
                    24,
                    120,
                    360,
                    850,
                    1025,
                    1200,
                    150,
                    false,
                    6,
                    bank.address,
                );
            self
                .generate_properties(
                    33,
                    game_id,
                    'Community Chest',
                    0,
                    PropertyType::CommunityChest,
                    0,
                    0,
                    0,
                    0,
                    0,
                    0,
                    0,
                    false,
                    0,
                    bank.address,
                );
            self
                .generate_properties(
                    34,
                    game_id,
                    'Avalanche Avenue',
                    300,
                    PropertyType::Property,
                    26,
                    130,
                    390,
                    900,
                    1100,
                    1275,
                    200,
                    false,
                    7,
                    bank.address,
                );
            self
                .generate_properties(
                    35,
                    game_id,
                    'Cartridge Railroad',
                    200,
                    PropertyType::RailRoad,
                    25,
                    50,
                    100,
                    200,
                    400,
                    0,
                    0,
                    false,
                    0,
                    bank.address,
                );
            self
                .generate_properties(
                    36,
                    game_id,
                    'Chance',
                    0,
                    PropertyType::Chance,
                    0,
                    0,
                    0,
                    0,
                    0,
                    0,
                    0,
                    false,
                    0,
                    bank.address,
                );
            self
                .generate_properties(
                    37,
                    game_id,
                    'Solana Drive',
                    300,
                    PropertyType::Property,
                    26,
                    130,
                    390,
                    900,
                    1100,
                    1275,
                    200,
                    false,
                    7,
                    bank.address,
                );
            self
                .generate_properties(
                    38,
                    game_id,
                    'Luxury Tax',
                    100,
                    PropertyType::Tax,
                    0,
                    0,
                    0,
                    0,
                    0,
                    0,
                    0,
                    false,
                    0,
                    bank.address,
                );
            self
                .generate_properties(
                    39,
                    game_id,
                    'Ethereum Avenue',
                    320,
                    PropertyType::Property,
                    28,
                    150,
                    450,
                    1000,
                    1200,
                    1400,
                    200,
                    false,
                    7,
                    bank.address,
                );
            self
                .generate_properties(
                    40,
                    game_id,
                    'Bitcoin Lane',
                    400,
                    PropertyType::Property,
                    50,
                    200,
                    600,
                    1400,
                    1700,
                    2000,
                    200,
                    false,
                    8,
                    bank.address,
                );
        }


        fn try_join_symbol(
            ref self: ContractState,
            mut game: Game,
            symbol: PlayerSymbol,
            username: felt252,
            game_id: u256,
        ) {
            match symbol {
                PlayerSymbol::Hat => {
                    assert(game.player_hat == 0, 'HAT already selected');
                    game.player_hat = username;
                },
                PlayerSymbol::Car => {
                    assert(game.player_car == 0, 'CAR already selected');
                    game.player_car = username;
                },
                PlayerSymbol::Dog => {
                    assert(game.player_dog == 0, 'DOG already selected');
                    game.player_dog = username;
                },
                PlayerSymbol::Thimble => {
                    assert(game.player_thimble == 0, 'THIMBLE already selected');
                    game.player_thimble = username;
                },
                PlayerSymbol::Iron => {
                    assert(game.player_iron == 0, 'IRON already selected');
                    game.player_iron = username;
                },
                PlayerSymbol::Battleship => {
                    assert(game.player_battleship == 0, 'BATTLESHIP already selected');
                    game.player_battleship = username;
                },
                PlayerSymbol::Boot => {
                    assert(game.player_boot == 0, 'BOOT already selected');
                    game.player_boot = username;
                },
                PlayerSymbol::Wheelbarrow => {
                    assert(game.player_wheelbarrow == 0, 'WHEELBARROW already selected');
                    game.player_wheelbarrow = username;
                },
            }
        }

        fn count_joined_players(ref self: ContractState, mut game: Game) -> u8 {
            let mut count: u8 = 0;

            if game.player_hat != 0 {
                count += 1; // self.transfer_funds(caller, property.rent_site_only);
                // self.credit_owner(property.owner, property.rent_site_only);
            }
            if game.player_car != 0 {
                count += 1;
            }
            if game.player_dog != 0 {
                count += 1;
            }
            if game.player_thimble != 0 {
                count += 1;
            }
            if game.player_iron != 0 {
                count += 1;
            }
            if game.player_battleship != 0 {
                count += 1;
            }
            if game.player_boot != 0 {
                count += 1;
            }
            if game.player_wheelbarrow != 0 {
                count += 1;
            }

            count
        }

        fn assert_player_not_already_joined(
            ref self: ContractState,
            game: Game,
            username: felt252 // self.transfer_funds(caller,// self.transfer_funds(caller, property.rent_site_only);
            // self.credit_owner(property.owner, property.rent_site_only); property.rent_site_only);
        // self.credit_owner(property.owner, property.rent_site_only);
        ) {
            assert(game.player_hat != username, 'ALREADY SELECTED HAT');
            assert(game.player_car != username, 'ALREADY SELECTED CAR');
            assert(game.player_dog != username, 'ALREADY SELECTED DOG');
            assert(game.player_thimble != username, 'ALREADY SELECTED THIMBLE');
            assert(game.player_iron != username, 'ALREADY SELECTED IRON');
            assert(game.player_battleship != username, 'ALREADY SELECTED BATTLESHIP');
            assert(game.player_boot != username, 'ALREADY SELECTED BOOT');
            assert(game.player_wheelbarrow != username, 'ALREADY SELECTED WHEELBARROW');
        }

        fn handle_property_landing(
            ref self: ContractState, player: GamePlayer, mut property: Property,
        ) -> Property {
            let caller = get_caller_address();
            let bank_address = get_contract_address();

            if property.owner == bank_address {
                // Property is unowned
                println!(
                    "This property '{}' is owned by the bank. It costs {}.",
                    property.name,
                    property.cost_of_property,
                );
            } else if property.owner != caller {
                // Property owned by someone else, calculate rent dynamically
                let owner_railroads = self.count_owner_railroads(property.owner, property.game_id);
                let owner_utilities = self.count_owner_utilities(property.owner, property.game_id);

                let rent_amount = property
                    .get_rent_amount(owner_railroads, owner_utilities, player.dice_rolled.into());

                match property.property_type {
                    PropertyType::RailRoad => {
                        println!(
                            "This railroad '{}' is owned by {:?}. Player {:?} must pay rent: {}.",
                            property.name,
                            property.owner,
                            caller,
                            rent_amount,
                        );
                    },
                    PropertyType::Utility => {
                        println!(
                            "This utility '{}' is owned by {:?}. Player {:?} must pay rent: {}.",
                            property.name,
                            property.owner,
                            caller,
                            rent_amount,
                        );
                    },
                    PropertyType::Property => {
                        println!(
                            "This property '{}' is owned by {:?}. Player {:?} must pay rent: {}.",
                            property.name,
                            property.owner,
                            caller,
                            rent_amount,
                        );
                    },
                    _ => {
                        println!(
                            "This space '{}' is owned by {:?}. Player {:?} may owe rent: {}.",
                            property.name,
                            property.owner,
                            caller,
                            rent_amount,
                        );
                    },
                }
            } else {
                // Property owned by caller
                println!("Player {:?} landed on their own property '{}'.", caller, property.name);
            }

            property
        }
    }


    #[generate_trait]
    impl PlayerGameBalanceImpl of IPlayerGameBalance {
        fn check_if_player_is_capable_of_trans(
            ref self: ContractState, amount: u256, balance: u256,
        ) {
            assert!(amount <= balance, "Insufficient balance");
        }
    }

    #[generate_trait]
    impl BoardTilesImpl of IBoardTiles {
        fn generate_properties(
            ref self: ContractState,
            id: u8,
            game_id: u256,
            name: felt252,
            cost_of_property: u256,
            property_type: PropertyType,
            rent_site_only: u256,
            rent_one_house: u256,
            rent_two_houses: u256,
            rent_three_houses: u256,
            rent_four_houses: u256,
            cost_of_house: u256,
            rent_hotel: u256,
            is_mortgaged: bool,
            group_id: u8,
            owner: ContractAddress,
        ) {
            let mut world = self.world_default();
            let mut property: Property = world.read_model((id, game_id));

            property =
                PropertyTrait::new(
                    id,
                    game_id,
                    name,
                    cost_of_property,
                    property_type,
                    rent_site_only,
                    rent_one_house,
                    rent_two_houses,
                    rent_three_houses,
                    rent_four_houses,
                    rent_hotel,
                    cost_of_house,
                    group_id,
                    owner,
                );

            let property_to_id: PropertyToId = PropertyToId { name, id };
            let id_to_property: IdToProperty = IdToProperty { id, name };

            world.write_model(@property);
            world.write_model(@property_to_id);
            world.write_model(@id_to_property);
        }

        fn create_new_game_id(ref self: ContractState) -> u256 {
            let mut world = self.world_default();
            let mut game_counter: GameCounter = world.read_model('v0');
            let new_val = game_counter.current_val + 1;
            game_counter.current_val = new_val;
            world.write_model(@game_counter);
            new_val
        }
    }
}

