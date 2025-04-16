use dojo_starter::models::{Direction, Position};
use dojo_starter::game_model::{
    Player, GameMode, PlayerSymbol, Game, GameTrait, UsernameToAddress, AddressToUsername,
    PlayerTrait,
};
use dojo_starter::interfaces::IActions::IActions;


// dojo decorator
#[dojo::contract]
pub mod actions {
    use super::{
        IActions, Direction, Position, next_position, Player, GameMode, PlayerSymbol, Game,
        GameTrait, UsernameToAddress, AddressToUsername, PlayerTrait,
    };
    use starknet::{
        ContractAddress, get_caller_address, get_block_timestamp, contract_address_const,
    };
    use dojo_starter::models::{Vec2, Moves};

    use dojo::model::{ModelStorage};
    use dojo::event::EventStorage;
    use origami_random::dice::{Dice, DiceTrait};

    #[derive(Copy, Drop, Serde)]
    #[dojo::event]
    pub struct Moved {
        #[key]
        pub player: ContractAddress,
        pub direction: Direction,
    }

    #[derive(Copy, Drop, Serde)]
    #[dojo::event]
    pub struct PlayerCreated {
        #[key]
        pub username: felt252,
        #[key]
        pub owner: ContractAddress,
        pub timestamp: u64,
    }


    #[abi(embed_v0)]
    impl ActionsImpl of IActions<ContractState> {
        fn spawn(ref self: ContractState) {
            // Get the default world.
            let mut world = self.world_default();

            // Get the address of the current caller, possibly the player's address.
            let player = get_caller_address();
            // Retrieve the player's current position from the world.
            let position: Position = world.read_model(player);

            // Update the world state with the new data.

            // 1. Move the player's position 10 units in both the x and y direction.
            let new_position = Position {
                player, vec: Vec2 { x: position.vec.x + 10, y: position.vec.y + 10 },
            };

            // Write the new position to the world.
            world.write_model(@new_position);

            // 2. Set the player's remaining moves to 100.
            let moves = Moves {
                player, remaining: 100, last_direction: Option::None, can_move: true,
            };

            // Write the new moves to the world.
            world.write_model(@moves);
        }

        // Implementation of the move function for the ContractState struct.
        fn move(ref self: ContractState, direction: Direction) {
            // Get the address of the current caller, possibly the player's address.

            let mut world = self.world_default();

            let player = get_caller_address();

            // Retrieve the player's current position and moves data from the world.
            let position: Position = world.read_model(player);
            let mut moves: Moves = world.read_model(player);
            // if player hasn't spawn, read returns model default values. This leads to sub overflow
            // afterwards.
            // Plus it's generally considered as a good pratice to fast-return on matching
            // conditions.
            if !moves.can_move {
                return;
            }

            // Deduct one from the player's remaining moves.
            moves.remaining -= 1;

            // Update the last direction the player moved in.
            moves.last_direction = Option::Some(direction);

            // Calculate the player's next position based on the provided direction.
            let next = next_position(position, moves.last_direction);

            // Write the new position to the world.
            world.write_model(@next);

            // Write the new moves to the world.
            world.write_model(@moves);

            // Emit an event to the world to notify about the player's move.
            world.emit_event(@Moved { player, direction });
        }


        fn roll_dice(ref self: ContractState) -> (u8, u8) {
            let seed = get_block_timestamp();

            let mut dice1 = DiceTrait::new(6, seed.try_into().unwrap());
            let mut dice2 = DiceTrait::new(6, (seed + 1).try_into().unwrap());

            let dice1_roll = dice1.roll();
            let dice2_roll = dice2.roll();

            (dice1_roll, dice2_roll)
        }

        fn register(ref self: ContractState, player_address: ContractAddress, username: felt252) {
            let mut world = self.world_default();

            let caller: ContractAddress = get_caller_address();
            // assert(player_address == caller, 'not you');

            // let mut player: Player = world.read_model(player_address);

            // let zero_address: ContractAddress = contract_address_const::<0x0>();

            // assert(caller != zero_address, 'ADDRESS ZERO');

            // player.player = caller;
        // player.username = username;
        // player.total_games_played = 0;
        // player.total_games_completed = 0;
        // player.total_games_won = 0;

            // Write the model back to the world state.
        // world.write_model(@player);
        // player.player_current_position = 0;
        // player.in_jail = false;
        // player.jail_attempt_count = 0;
        // player.cash_at_hand = 0;
        // player.dice_rolled = 0;
        // player.bankrupt = false;
        // player.networth = 0;

        }
        fn get_username_from_address(self: @ContractState, address: ContractAddress) -> felt252 {
            let mut world = self.world_default();

            let address_map: AddressToUsername = world.read_model(address);

            address_map.username
        }
        fn register_new_player(ref self: ContractState, username: felt252, is_bot: bool) {
            let mut world = self.world_default();

            let caller: ContractAddress = get_caller_address();

            let zero_address: ContractAddress = contract_address_const::<0x0>();

            // Validate username
            assert(username != 0, 'USERNAME CANNOT BE ZERO');

            let existing_player: Player = world.read_model(username);

            // Ensure player username is unique
            assert(existing_player.player == zero_address, 'USERNAME ALREADY TAKEN');

            // Ensure player cannot update username by calling this function
            let existing_username = self.get_username_from_address(caller);

            assert(existing_username == 0, 'USERNAME ALREADY CREATED');

            let new_player: Player = PlayerTrait::new(username, caller, is_bot);
            let username_to_address: UsernameToAddress = UsernameToAddress {
                username, address: caller,
            };
            let address_to_username: AddressToUsername = AddressToUsername {
                address: caller, username,
            };

            world.write_model(@new_player);
            world.write_model(@username_to_address);
            world.write_model(@address_to_username);
            world
            .emit_event(
                @PlayerCreated { username, owner: caller, timestamp: get_block_timestamp() },
            );
        }
        // fn retrieve_player(ref self: ContractState, player_address: ContractAddress) -> Player {
        //     let mut world = self.world_default();

        //     let player: Player = world.read_model(player_address);
        //     player
        // }
        fn create_new_game(
            ref self: ContractState,
            game_mode: GameMode,
            player_symbol: PlayerSymbol,
            player_hat: felt252,
            player_car: felt252,
            player_dog: felt252,
            player_thimble: felt252,
            player_iron: felt252,
            player_battleship: felt252,
            player_boot: felt252,
            player_wheelbarrow: felt252,
            number_of_players: u8,
        ) -> u64 {
            // Get default world
            let mut world = self.world_default();

            assert(number_of_players >= 2 && number_of_players <= 8, 'invalid no of players');

            // Get the account address of the caller
            let caller_address = get_caller_address();
            // let caller_username = self.get_username_from_address(caller_address);
            // assert(caller_username != 0, 'PLAYER NOT REGISTERED');

            // let game_id = self.create_new_game_id();
            let timestamp = get_block_timestamp();

            // let player_green = match player_color {
            //     PlayerColor::Green => caller_username,
            //     _ => 0,
            // };

            // let player_yellow = match player_color {
            //     PlayerColor::Yellow => caller_username,
            //     _ => 0,
            // };

            // let player_blue = match player_color {
            //     PlayerColor::Blue => caller_username,
            //     _ => 0,
            // };

            // let player_red = match player_color {
            //     PlayerColor::Red => caller_username,
            //     _ => 0,
            // };

            // Create a new game
            let mut new_game: Game = GameTrait::new(
                // game_id,
                1,
                // caller_address,
                'hat',
                game_mode,
                player_hat,
                player_car,
                player_dog,
                player_thimble,
                player_iron,
                player_battleship,
                player_boot,
                player_wheelbarrow,
                number_of_players,
            );

            // If it's a multiplayer game, set status to Pending,
            // else mark it as Ongoing (for single-player).
            // if game_mode == GameMode::MultiPlayer {
            //     new_game.status = GameStatus::Pending;
            // } else {
            //     new_game.status = GameStatus::Ongoing;
            // }

            // world.write_model(@new_game);

            // world.emit_event(@GameCreated { game_id, timestamp });

            2
        }
    }

    #[generate_trait]
    impl InternalImpl of InternalTrait {
        /// Use the default namespace "dojo_starter". This function is handy since the ByteArray
        /// can't be const.
        fn world_default(self: @ContractState) -> dojo::world::WorldStorage {
            self.world(@"blockopoly")
        }
    }
}

// Define function like this:
fn next_position(mut position: Position, direction: Option<Direction>) -> Position {
    match direction {
        Option::None => { return position; },
        Option::Some(d) => match d {
            Direction::Left => { position.vec.x -= 1; },
            Direction::Right => { position.vec.x += 1; },
            Direction::Up => { position.vec.y -= 1; },
            Direction::Down => { position.vec.y += 1; },
        },
    };
    position
}
