use starknet::ContractAddress;
// define the interface
#[starknet::interface]
pub trait IMovement<T> {
    // fn roll_dice(ref self: T) -> (u8, u8);
    fn move_player(ref self: T, game_id: u256, steps: u8) -> u8;
    fn pay_jail_fine(ref self: T, game_id: u256) -> bool;
    fn use_getout_of_jail_chance(ref self: T, game_id: u256) -> bool;
    fn use_getout_of_jail_community_chest(ref self: T, game_id: u256) -> bool;

    fn current_player(self: @T, game_id: u256) -> ContractAddress;
    fn current_playername(self: @T, game_id: u256) -> felt252;
}

// dojo decorator
#[dojo::contract]
pub mod movement {
    use blockopoly::model::game_model::{Game, GameStatus};
    use blockopoly::model::game_player_model::{GamePlayer, GamePlayerTrait};
    use blockopoly::model::player_model::AddressToUsername;
    use blockopoly::model::property_model::{Property, PropertyType};

    // use dojo::event::EventStorage;
    use dojo::model::ModelStorage;
    use starknet::{ContractAddress, get_caller_address};

    // #[derive(Copy, Drop, Serde)]
    // #[dojo::event]
    // pub struct PlayerCreated {
    //     #[key]
    //     pub username: felt252,
    //     #[key]
    //     pub player: ContractAddress,
    //     pub timestamp: u64,
    // }

    #[abi(embed_v0)]
    impl MovementImpl of super::IMovement<ContractState> {
        fn move_player(ref self: ContractState, game_id: u256, steps: u8) -> u8 {
            let mut world = self.world_default();
            let caller = get_caller_address();
            let mut game_player: GamePlayer = world.read_model((caller, game_id));
            let mut game: Game = world.read_model(game_id);

            assert!(game.next_player == caller, "Not your turn");
            assert!(game.status == GameStatus::Ongoing, "Game is not ongoing");

            // Handle jailed players
            if game_player.jailed {
                game_player.jail_turns += 1;

                if game_player.jail_turns > 3 {
                    // Automatically release player after 3 turns
                    game_player.jailed = false;
                    game_player.jail_turns = 0;
                } else {
                    // Still in jail, no move
                    world.write_model(@game_player);
                    return game_player.position;
                }
            }

            // Now free to move
            game_player = GamePlayerTrait::move(game_player, steps);
            game_player.dice_rolled = steps;

            // Passed or landed on Go
            if game_player.position >= 40 {
                game_player.position %= 40;
                game_player.balance += 200;
            }

            // Landing on "Go To Jail" space
            if game_player.position == 30 {
                game_player.position = 10;
                game_player.jailed = true;
                game_player.jail_turns = 0;

                world.write_model(@game_player);
                world.write_model(@game);
                return game_player.position;
            }

            // Handle landing on property

            // let mut property: Property = world.read_model((game_player.position, game_id));
            let mut property: Property = world.read_model((game_player.position, game_id));
            // property = self.handle_property_landing(game_player.clone(), property);

            // Update state
            world.write_model(@game_player);
            world.write_model(@game);
            world.write_model(@property);

            game_player.position
        }

        fn use_getout_of_jail_chance(ref self: ContractState, game_id: u256) -> bool {
            let mut world = self.world_default();
            let caller = get_caller_address();
            let mut player: GamePlayer = world.read_model((caller, game_id));
            let mut game: Game = world.read_model(game_id);
            assert(player.chance_jail_card, 'No chance card');
            assert(player.jailed, 'Not in jail');
            assert(game.status == GameStatus::Ongoing, 'Game not started');
            // Use the card
            player.chance_jail_card = false;
            player.jailed = false;
            player.jail_turns = 0;
            world.write_model(@game);
            world.write_model(@player);
            true
        }

        fn use_getout_of_jail_community_chest(ref self: ContractState, game_id: u256) -> bool {
            let mut world = self.world_default();
            let caller = get_caller_address();
            let mut player: GamePlayer = world.read_model((caller, game_id));
            let mut game: Game = world.read_model(game_id);
            assert(player.comm_free_card, 'No community chest card');
            assert(player.jailed, 'Not in jail');
            assert(game.status == GameStatus::Ongoing, 'Game not started');
            // Use the card
            player.comm_free_card = false;
            player.jailed = false;
            player.jail_turns = 0;
            world.write_model(@game);
            world.write_model(@player);
            true
        }


        fn pay_jail_fine(ref self: ContractState, game_id: u256) -> bool {
            let mut world = self.world_default();
            let caller = get_caller_address();
            let mut player: GamePlayer = world.read_model((caller, game_id));
            let mut game: Game = world.read_model(game_id);

            assert(game.status == GameStatus::Ongoing, 'Game not started');
            assert(player.jailed, 'Not in jail');

            // Pay the fine
            let fine_amount: u256 = 50;
            assert(player.balance >= fine_amount, 'Insufficient funds to pay fine');

            player.balance -= fine_amount;
            player.jailed = false;
            player.jail_turns = 0;

            world.write_model(@game);
            world.write_model(@player);

            true
        }

        fn current_player(self: @ContractState, game_id: u256) -> ContractAddress {
            let mut world = self.world_default();
            let game: Game = world.read_model(game_id);
            game.next_player
        }

        fn current_playername(self: @ContractState, game_id: u256) -> felt252 {
            let mut world = self.world_default();
            let game: Game = world.read_model(game_id);
            let player: AddressToUsername = world.read_model(game.next_player);
            player.username
        }
    }

    #[generate_trait]
    impl InternalImpl of InternalTrait {
        /// Use the default namespace "dojo_starter". This function is handy since the ByteArray
        /// can't be const.
        fn world_default(self: @ContractState) -> dojo::world::WorldStorage {
            self.world(@"blockopoly")
        }

        fn count_owner_railroadss(
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
        fn count_owner_utilitiess(
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

