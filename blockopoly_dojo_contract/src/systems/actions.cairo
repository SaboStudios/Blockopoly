use dojo_starter::models::{Direction, Position};
use dojo_starter::game_model::{
    Player, GameMode, PlayerSymbol, Game, GameTrait, UsernameToAddress, AddressToUsername,
    PlayerTrait, GameCounter, GameStatus,
};
use dojo_starter::interfaces::IActions::IActions;


// dojo decorator
#[dojo::contract]
pub mod actions {
    use super::{
        IActions, Direction, Position, next_position, Player, GameMode, PlayerSymbol, Game,
        GameTrait, UsernameToAddress, AddressToUsername, PlayerTrait, GameCounter, GameStatus,
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
    pub struct GameCreated {
        #[key]
        pub game_id: u64,
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
        pub game_id: u64,
        pub timestamp: u64,
    }

    #[derive(Copy, Drop, Serde)]
    #[dojo::event]
    pub struct PlayerJoined {
        #[key]
        pub game_id: u64,
        #[key]
        pub username: felt252,
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
                    @PlayerCreated { username, player: caller, timestamp: get_block_timestamp() },
                );
        }


        fn create_new_game_id(ref self: ContractState) -> u64 {
            let mut world = self.world_default();
            let mut game_counter: GameCounter = world.read_model('v0');
            let new_val = game_counter.current_val + 1;
            game_counter.current_val = new_val;
            world.write_model(@game_counter);
            new_val
        }

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
            let caller_username = self.get_username_from_address(caller_address);
            assert(caller_username != 0, 'PLAYER NOT REGISTERED');

            let game_id = self.create_new_game_id();
            let timestamp = get_block_timestamp();

            let player_hat = match player_symbol {
                PlayerSymbol::Hat => caller_username,
                _ => 0,
            };

            let player_car = match player_symbol {
                PlayerSymbol::Car => caller_username,
                _ => 0,
            };
            let player_dog = match player_symbol {
                PlayerSymbol::Dog => caller_username,
                _ => 0,
            };
            let player_thimble = match player_symbol {
                PlayerSymbol::Thimble => caller_username,
                _ => 0,
            };
            let player_iron = match player_symbol {
                PlayerSymbol::Iron => caller_username,
                _ => 0,
            };
            let player_battleship = match player_symbol {
                PlayerSymbol::Battleship => caller_username,
                _ => 0,
            };
            let player_boot = match player_symbol {
                PlayerSymbol::Boot => caller_username,
                _ => 0,
            };
            let player_wheelbarrow = match player_symbol {
                PlayerSymbol::Wheelbarrow => caller_username,
                _ => 0,
            };

            // Create a new game
            let mut new_game: Game = GameTrait::new(
                game_id,
                caller_username,
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
            if game_mode == GameMode::MultiPlayer {
                new_game.status = GameStatus::Pending;
            } else {
                new_game.status = GameStatus::Ongoing;
            }

            world.write_model(@new_game);

            world.emit_event(@GameCreated { game_id, timestamp });

            game_id
        }

        /// Start game
        /// Change game status to ONGOING
        fn join_game(ref self: ContractState, player_symbol: PlayerSymbol, game_id: u64) {
            // Get world state
            let mut world = self.world_default();

            //get the game state
            let mut game: Game = world.read_model(game_id);

            assert(game.is_initialised, 'GAME NOT INITIALISED');

            // Assert that game is a Multiplayer game
            assert(game.mode == GameMode::MultiPlayer, 'GAME NOT MULTIPLAYER');

            // Assert that game is in Pending state
            assert(game.status == GameStatus::Pending, 'GAME NOT PENDING');

            // Get the account address of the caller
            let caller_address = get_caller_address();
            let caller_username = self.get_username_from_address(caller_address);

            assert(caller_username != 0, 'PLAYER NOT REGISTERED');

            // Verify that player has not already joined the game
            assert(game.player_hat != caller_username, 'ALREADY SELECTED HAT');
            assert(game.player_car != caller_username, 'ALREADY SELECTED CAR');
            assert(game.player_dog != caller_username, 'ALREADY SELECTED DOG');
            assert(game.player_thimble != caller_username, 'ALREADY SELECTED THIMBLE');
            assert(game.player_iron != caller_username, 'ALREADY SELECTED IRON');
            assert(game.player_battleship != caller_username, 'ALREADY SELECTED BATTLESHIP');
            assert(game.player_boot != caller_username, 'ALREADY SELECTED BOOT');
            assert(game.player_wheelbarrow != caller_username, 'ALREADY SELECTED WHEELBARROW');

            /// Game starts automatically once the last player joins

            // Verify that symbol is available
            // Assign symbol to player if available

            match player_symbol {
                PlayerSymbol::Hat => {
                    if (game.player_hat == 0) {
                        game.player_hat = caller_username;
                        world
                            .emit_event(
                                @PlayerJoined {
                                    game_id,
                                    username: caller_username,
                                    timestamp: get_block_timestamp(),
                                },
                            )
                    } else {
                        panic!("HAT already selected");
                    }
                },
                PlayerSymbol::Car => {
                    if (game.player_car == 0) {
                        game.player_car = caller_username;
                        world
                            .emit_event(
                                @PlayerJoined {
                                    game_id,
                                    username: caller_username,
                                    timestamp: get_block_timestamp(),
                                },
                            )
                    } else {
                        panic!("CAR already selected");
                    }
                },
                PlayerSymbol::Dog => {
                    if (game.player_dog == 0) {
                        game.player_dog = caller_username;
                        world
                            .emit_event(
                                @PlayerJoined {
                                    game_id,
                                    username: caller_username,
                                    timestamp: get_block_timestamp(),
                                },
                            )
                    } else {
                        panic!("Dog already selected");
                    }
                },
                PlayerSymbol::Thimble => {
                    if (game.player_thimble == 0) {
                        game.player_thimble = caller_username;
                        world
                            .emit_event(
                                @PlayerJoined {
                                    game_id,
                                    username: caller_username,
                                    timestamp: get_block_timestamp(),
                                },
                            )
                    } else {
                        panic!("Thimble already selected");
                    }
                },
                PlayerSymbol::Iron => {
                    if (game.player_iron == 0) {
                        game.player_iron = caller_username;
                        world
                            .emit_event(
                                @PlayerJoined {
                                    game_id,
                                    username: caller_username,
                                    timestamp: get_block_timestamp(),
                                },
                            )
                    } else {
                        panic!("Iron already selected");
                    }
                },
                PlayerSymbol::Battleship => {
                    if (game.player_battleship == 0) {
                        game.player_battleship = caller_username;
                        world
                            .emit_event(
                                @PlayerJoined {
                                    game_id,
                                    username: caller_username,
                                    timestamp: get_block_timestamp(),
                                },
                            )
                    } else {
                        panic!("Battleship already selected");
                    }
                },
                PlayerSymbol::Boot => {
                    if (game.player_boot == 0) {
                        game.player_boot = caller_username;
                        world
                            .emit_event(
                                @PlayerJoined {
                                    game_id,
                                    username: caller_username,
                                    timestamp: get_block_timestamp(),
                                },
                            )
                    } else {
                        panic!("Boot already selected");
                    }
                },
                PlayerSymbol::Wheelbarrow => {
                    if (game.player_wheelbarrow == 0) {
                        game.player_wheelbarrow = caller_username;
                        world
                            .emit_event(
                                @PlayerJoined {
                                    game_id,
                                    username: caller_username,
                                    timestamp: get_block_timestamp(),
                                },
                            )
                    } else {
                        panic!("Wheelbarrow already selected");
                    }
                },
            }

            // Start game automatically once the last player joins

            const TWO_PLAYERS: u8 = 2;
            const THREE_PLAYERS: u8 = 3;
            const FOUR_PLAYERS: u8 = 4;
            const FIVE_PLAYERS: u8 = 5;
            const SIX_PLAYERS: u8 = 6;
            const SEVEN_PLAYERS: u8 = 7;
            const EIGHT_PLAYERS: u8 = 8;

            match game.number_of_players {
                0 => panic!("Number of players cannot be 0"),
                1 => panic!("Number of players cannot be 1"),
                2 => {
                    let mut players_joined_count: u8 = 0;

                    if (game.player_hat != 0) {
                        players_joined_count += 1;
                    }
                    if (game.player_car != 0) {
                        players_joined_count += 1;
                    }
                    if (game.player_dog != 0) {
                        players_joined_count += 1;
                    }
                    if (game.player_thimble != 0) {
                        players_joined_count += 1;
                    }
                    if (game.player_iron != 0) {
                        players_joined_count += 1;
                    }
                    if (game.player_battleship != 0) {
                        players_joined_count += 1;
                    }
                    if (game.player_boot != 0) {
                        players_joined_count += 1;
                    }
                    if (game.player_wheelbarrow != 0) {
                        players_joined_count += 1;
                    }

                    // Start game once all players have joined
                    if (players_joined_count == TWO_PLAYERS) {
                        game.status = GameStatus::Ongoing;
                        world
                            .emit_event(@GameStarted { game_id, timestamp: get_block_timestamp() });
                    }
                },
                3 => {
                    let mut players_joined_count: u8 = 0;

                    if (game.player_hat != 0) {
                        players_joined_count += 1;
                    }
                    if (game.player_car != 0) {
                        players_joined_count += 1;
                    }
                    if (game.player_dog != 0) {
                        players_joined_count += 1;
                    }
                    if (game.player_thimble != 0) {
                        players_joined_count += 1;
                    }
                    if (game.player_iron != 0) {
                        players_joined_count += 1;
                    }
                    if (game.player_battleship != 0) {
                        players_joined_count += 1;
                    }
                    if (game.player_boot != 0) {
                        players_joined_count += 1;
                    }
                    if (game.player_wheelbarrow != 0) {
                        players_joined_count += 1;
                    }

                    // Start game once all players have joined
                    if (players_joined_count == THREE_PLAYERS) {
                        game.status = GameStatus::Ongoing;
                        world
                            .emit_event(@GameStarted { game_id, timestamp: get_block_timestamp() });
                    }
                },
                4 => {
                    let mut players_joined_count: u8 = 0;

                    if (game.player_hat != 0) {
                        players_joined_count += 1;
                    }
                    if (game.player_car != 0) {
                        players_joined_count += 1;
                    }
                    if (game.player_dog != 0) {
                        players_joined_count += 1;
                    }
                    if (game.player_thimble != 0) {
                        players_joined_count += 1;
                    }
                    if (game.player_iron != 0) {
                        players_joined_count += 1;
                    }
                    if (game.player_battleship != 0) {
                        players_joined_count += 1;
                    }
                    if (game.player_boot != 0) {
                        players_joined_count += 1;
                    }
                    if (game.player_wheelbarrow != 0) {
                        players_joined_count += 1;
                    }

                    // Start game once all players have joined
                    if (players_joined_count == FOUR_PLAYERS) {
                        game.status = GameStatus::Ongoing;
                        world
                            .emit_event(@GameStarted { game_id, timestamp: get_block_timestamp() });
                    }
                },
                5 => {
                    let mut players_joined_count: u8 = 0;

                    if (game.player_hat != 0) {
                        players_joined_count += 1;
                    }
                    if (game.player_car != 0) {
                        players_joined_count += 1;
                    }
                    if (game.player_dog != 0) {
                        players_joined_count += 1;
                    }
                    if (game.player_thimble != 0) {
                        players_joined_count += 1;
                    }
                    if (game.player_iron != 0) {
                        players_joined_count += 1;
                    }
                    if (game.player_battleship != 0) {
                        players_joined_count += 1;
                    }
                    if (game.player_boot != 0) {
                        players_joined_count += 1;
                    }
                    if (game.player_wheelbarrow != 0) {
                        players_joined_count += 1;
                    }

                    // Start game once all players have joined
                    if (players_joined_count == FIVE_PLAYERS) {
                        game.status = GameStatus::Ongoing;
                        world
                            .emit_event(@GameStarted { game_id, timestamp: get_block_timestamp() });
                    }
                },
                6 => {
                    let mut players_joined_count: u8 = 0;

                    if (game.player_hat != 0) {
                        players_joined_count += 1;
                    }
                    if (game.player_car != 0) {
                        players_joined_count += 1;
                    }
                    if (game.player_dog != 0) {
                        players_joined_count += 1;
                    }
                    if (game.player_thimble != 0) {
                        players_joined_count += 1;
                    }
                    if (game.player_iron != 0) {
                        players_joined_count += 1;
                    }
                    if (game.player_battleship != 0) {
                        players_joined_count += 1;
                    }
                    if (game.player_boot != 0) {
                        players_joined_count += 1;
                    }
                    if (game.player_wheelbarrow != 0) {
                        players_joined_count += 1;
                    }

                    // Start game once all players have joined
                    if (players_joined_count == SIX_PLAYERS) {
                        game.status = GameStatus::Ongoing;
                        world
                            .emit_event(@GameStarted { game_id, timestamp: get_block_timestamp() });
                    }
                },
                7 => {
                    let mut players_joined_count: u8 = 0;

                    if (game.player_hat != 0) {
                        players_joined_count += 1;
                    }
                    if (game.player_car != 0) {
                        players_joined_count += 1;
                    }
                    if (game.player_dog != 0) {
                        players_joined_count += 1;
                    }
                    if (game.player_thimble != 0) {
                        players_joined_count += 1;
                    }
                    if (game.player_iron != 0) {
                        players_joined_count += 1;
                    }
                    if (game.player_battleship != 0) {
                        players_joined_count += 1;
                    }
                    if (game.player_boot != 0) {
                        players_joined_count += 1;
                    }
                    if (game.player_wheelbarrow != 0) {
                        players_joined_count += 1;
                    }

                    // Start game once all players have joined
                    if (players_joined_count == SEVEN_PLAYERS) {
                        game.status = GameStatus::Ongoing;
                        world
                            .emit_event(@GameStarted { game_id, timestamp: get_block_timestamp() });
                    }
                },
                8 => {
                    let mut players_joined_count: u8 = 0;

                    if (game.player_hat != 0) {
                        players_joined_count += 1;
                    }
                    if (game.player_car != 0) {
                        players_joined_count += 1;
                    }
                    if (game.player_dog != 0) {
                        players_joined_count += 1;
                    }
                    if (game.player_thimble != 0) {
                        players_joined_count += 1;
                    }
                    if (game.player_iron != 0) {
                        players_joined_count += 1;
                    }
                    if (game.player_battleship != 0) {
                        players_joined_count += 1;
                    }
                    if (game.player_boot != 0) {
                        players_joined_count += 1;
                    }
                    if (game.player_wheelbarrow != 0) {
                        players_joined_count += 1;
                    }

                    // Start game once all players have joined
                    if (players_joined_count == EIGHT_PLAYERS) {
                        game.status = GameStatus::Ongoing;
                        world
                            .emit_event(@GameStarted { game_id, timestamp: get_block_timestamp() });
                    }
                },
                _ => panic!("Invalid number of players"),
            };

            // Update the game state in the world
            world.write_model(@game);
        }

        fn retrive_game(ref self: ContractState, game_id: u256) -> Game {
            // Get default world
            let mut world = self.world_default();
            //get the game state
            let game: Game = world.read_model(game_id);
            game
        }

        fn retrive_player(ref self: ContractState, addr: ContractAddress) -> Player {
            // Get default world
            let mut world = self.world_default();
            let player: Player = world.read_model(addr);

            player
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
