use blockopoly::model::game_model::{Game, GameCounter, GameStatus, GameTrait, GameType};
use blockopoly::model::game_player_model::{GamePlayer, PlayerSymbol};
use blockopoly::model::player_model::{AddressToUsername, Player};
use blockopoly::model::property_model::{
    IdToProperty, Property, PropertyToId, PropertyTrait, PropertyType,
};
use starknet::ContractAddress;


// define the interface
#[starknet::interface]
pub trait IGame<T> {
    // 🎮 GameSystem - Game creation and lifecycle
    fn create_game(ref self: T, game_type: u8, player_symbol: u8, number_of_players: u8) -> u256;
    fn join_game(ref self: T, player_symbol: u8, game_id: u256);

    fn start_game(ref self: T, game_id: u256) -> bool;
    fn end_game(ref self: T, game_id: u256) -> ContractAddress;
    fn retrieve_game(self: @T, game_id: u256) -> Game;

    fn mint(ref self: T, recepient: ContractAddress, game_id: u256, amount: u256);

    fn get_game_player(self: @T, address: ContractAddress, game_id: u256) -> GamePlayer;
    fn get_game_player_balance(self: @T, address: ContractAddress, game_id: u256) -> u256;
}

// dojo decorator
#[dojo::contract]
pub mod game {
    use dojo::event::EventStorage;
    use dojo::model::ModelStorage;
    use starknet::{
        ContractAddress, contract_address_const, get_block_timestamp, get_caller_address,
    };
    use super::{
        AddressToUsername, Game, GameCounter, GamePlayer, GameStatus, GameTrait, GameType, IGame,
        IdToProperty, Player, PlayerSymbol, Property, PropertyToId, PropertyTrait, PropertyType,
    };

    #[derive(Copy, Drop, Serde)]
    #[dojo::event]
    pub struct GameCreated {
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

    #[derive(Copy, Drop, Serde)]
    #[dojo::event]
    pub struct GameStarted {
        #[key]
        pub game_id: u256,
        pub timestamp: u64,
    }


    #[abi(embed_v0)]
    impl GameImpl of IGame<ContractState> {
        // to stay and call models
        fn retrieve_game(self: @ContractState, game_id: u256) -> Game {
            // Get default world
            let mut world = self.world_default();
            //get the game state
            let game: Game = world.read_model(game_id);
            game
        }
        fn create_game(
            ref self: ContractState, game_type: u8, player_symbol: u8, number_of_players: u8,
        ) -> u256 {
            let player_symbol_enum = match player_symbol {
                0 => PlayerSymbol::Hat,
                1 => PlayerSymbol::Car,
                2 => PlayerSymbol::Dog,
                3 => PlayerSymbol::Thimble,
                4 => PlayerSymbol::Iron,
                5 => PlayerSymbol::Battleship,
                6 => PlayerSymbol::Boot,
                7 => PlayerSymbol::Wheelbarrow,
                _ => panic!("Invalid player symbol"),
            };

            let game_type_enum = match game_type {
                0 => GameType::PublicGame,
                1 => GameType::PrivateGame,
                _ => panic!("Invalid game type"),
            };

            let game_id = self
                .create_new_game(game_type_enum, player_symbol_enum, number_of_players);
            game_id
        }

        fn join_game(ref self: ContractState, player_symbol: u8, game_id: u256) {
            let player_symbol_enum = match player_symbol {
                0 => PlayerSymbol::Hat,
                1 => PlayerSymbol::Car,
                2 => PlayerSymbol::Dog,
                3 => PlayerSymbol::Thimble,
                4 => PlayerSymbol::Iron,
                5 => PlayerSymbol::Battleship,
                6 => PlayerSymbol::Boot,
                7 => PlayerSymbol::Wheelbarrow,
                _ => panic!("Invalid player symbol"),
            };

            self.join(player_symbol_enum, game_id);
        }

        fn start_game(ref self: ContractState, game_id: u256) -> bool {
            let mut world = self.world_default();
            let mut game: Game = world.read_model(game_id);

            assert(game.status == GameStatus::Pending, 'GAME NOT PENDING');

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

        fn mint(ref self: ContractState, recepient: ContractAddress, game_id: u256, amount: u256) {
            let mut world = self.world_default();
            let mut player: GamePlayer = world.read_model((recepient, game_id));
            player.balance += amount;
            world.write_model(@player);
        }

        fn end_game(ref self: ContractState, game_id: u256) -> ContractAddress {
            let mut world = self.world_default();
            let mut players: Array<GamePlayer> = ArrayTrait::new();

            let mut game: Game = world.read_model(game_id);
            let total_players = game.game_players.len();
            let mut i = 0;

            // Indexed loop over game.players
            while i < total_players {
                let player_address = game.game_players.at(i);
                let player_model: GamePlayer = world.read_model((*player_address, game.id));

                players.append(player_model);
                i += 1;
            };

            // Find the winner by net worth
            let winner_address = self.get_winner_by_net_worth(game.id);
            let winner: Player = world.read_model(winner_address);

            // Set game status to ended
            let mut updated_game = game;
            updated_game.status = GameStatus::Ended;
            updated_game.winner = winner.address;

            // Write back the updated game state
            world.write_model(@updated_game);

            // Return the winner's address
            winner.address
        }


        fn get_game_player(
            self: @ContractState, address: ContractAddress, game_id: u256,
        ) -> GamePlayer {
            let mut world = self.world_default();
            let player: GamePlayer = world.read_model((address, game_id));
            player
        }
        fn get_game_player_balance(
            self: @ContractState, address: ContractAddress, game_id: u256,
        ) -> u256 {
            let mut world = self.world_default();
            let player: GamePlayer = world.read_model((address, game_id));
            player.balance
        }
    }

    #[generate_trait]
    impl InternalImpl of InternalTrait {
        /// Use the default namespace "dojo_starter". This function is handy since the ByteArray
        /// can't be const.
        fn world_default(self: @ContractState) -> dojo::world::WorldStorage {
            self.world(@"blockopoly")
        }

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
            let caller_username1: AddressToUsername = world.read_model(caller_address);
            let caller_username = caller_username1.username;

            let game_id = self.create_new_game_id();
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

        fn get_winner_by_net_worth(ref self: ContractState, game_id: u256) -> ContractAddress {
            let mut world = self.world_default();
            let mut game: Game = world.read_model(game_id);
            let total_players = game.game_players.len();

            let mut i = 0;
            let mut max_net_worth: u256 = 0;
            let mut winner_address: ContractAddress = contract_address_const::<'0'>();

            while i < total_players {
                let player_address = game.game_players.at(i);
                let player: GamePlayer = world.read_model((*player_address, game.id));
                let net_worth = self.calculate_net_worth(player.address, player.game_id);

                if net_worth > max_net_worth {
                    max_net_worth = net_worth;
                    winner_address = player.address;
                }

                i += 1;
            };

            winner_address
        }

        // Allows a registered player to join a pending game by selecting a symbol.
        // Automatically starts the game once the required number of players have joined.
        fn join(ref self: ContractState, player_symbol: PlayerSymbol, game_id: u256) {
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
            let caller_username1: AddressToUsername = world.read_model(caller_address);
            let caller_username = caller_username1.username;

            // Ensure the caller is a registered player
            assert(caller_username != 0, 'PLAYER NOT REGISTERED');

            // Ensure the player hasn't already joined under a different symbol
            self.assert_player_not_already_joined(game.clone().id, caller_username);

            // Attempt to join the game with the selected symbol
            self.try_join_symbol(game.clone().id, player_symbol, caller_username);

            // Emit event for player joining
            world
                .emit_event(
                    @PlayerJoined {
                        game_id, username: caller_username, timestamp: get_block_timestamp(),
                    },
                );

            // Recount players and update the joined count
            game.players_joined = self.count_joined_players(game.id);
            game.game_players.append(get_caller_address());

            // Start the game if all players have joined
            if game.players_joined == game.number_of_players {
                game.status = GameStatus::Ongoing;
                world.emit_event(@GameStarted { game_id, timestamp: get_block_timestamp() });
            }

            // Persist the updated game state
            world.write_model(@game);
        }


        fn calculate_net_worth(
            ref self: ContractState, player_address: ContractAddress, game_id: u256,
        ) -> u256 {
            let mut world = self.world_default();
            let mut player: GamePlayer = world.read_model((player_address, game_id));
            let mut total_property_value: u256 = 0;
            let mut total_house_cost: u256 = 0;
            let mut total_rent_value: u256 = 0;
            let mut card_value: u256 = 0;
            let mut i = 0;
            let properties_len = player.properties_owned.len();

            while i < properties_len {
                let prop_id = *player.properties_owned.at(i);
                let game_id = player.game_id;
                // Retrieve the property model
                let property: Property = world.read_model((prop_id, game_id));

                // Property value (half if mortgaged)
                if property.is_mortgaged {
                    total_property_value += property.cost_of_property / 2;
                } else {
                    total_property_value += property.cost_of_property;
                }

                // House/hotel cost
                if property.development < 5 {
                    total_house_cost += property.cost_of_house * property.development.into();
                } else if property.development == 5 {
                    total_house_cost += property.cost_of_house * 5;
                }

                // Rent value (always add — mortgaged or not, since it's dev level based)
                let rent = match property.development {
                    0 => property.rent_site_only,
                    1 => property.rent_one_house,
                    2 => property.rent_two_houses,
                    3 => property.rent_three_houses,
                    4 => property.rent_four_houses,
                    _ => property.rent_hotel,
                };
                total_rent_value += rent;

                i += 1;
            };

            // Jail/Chance card value
            if player.chance_jail_card {
                card_value += 50;
            }
            if player.comm_free_card {
                card_value += 50;
            }

            let net_worth = player.balance
                + total_property_value
                + total_house_cost
                + total_rent_value
                + card_value;

            net_worth
        }

        fn assert_player_not_already_joined(
            ref self: ContractState, game_id: u256, username: felt252,
        ) {
            let mut world = self.world_default();
            let game: Game = world.read_model(game_id);

            assert(game.player_hat != username, 'ALREADY SELECTED HAT');
            assert(game.player_car != username, 'ALREADY SELECTED CAR');
            assert(game.player_dog != username, 'ALREADY SELECTED DOG');
            assert(game.player_thimble != username, 'ALREADY SELECTED THIMBLE');
            assert(game.player_iron != username, 'ALREADY SELECTED IRON');
            assert(game.player_battleship != username, 'ALREADY SELECTED BATTLESHIP');
            assert(game.player_boot != username, 'ALREADY SELECTED BOOT');
            assert(game.player_wheelbarrow != username, 'ALREADY SELECTED WHEELBARROW');
        }

        fn try_join_symbol(
            ref self: ContractState, game_id: u256, symbol: PlayerSymbol, username: felt252,
        ) {
            let mut world = self.world_default();
            let mut game: Game = world.read_model(game_id);

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

        fn count_joined_players(ref self: ContractState, game_id: u256) -> u8 {
            let mut count: u8 = 0;
            let mut world = self.world_default();
            let game: Game = world.read_model(game_id);

            if game.player_hat != 0 {
                count += 1;
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

        fn create_new_game_id(ref self: ContractState) -> u256 {
            let mut world = self.world_default();
            let mut game_counter: GameCounter = world.read_model('v0');
            let new_val = game_counter.current_val + 1;
            game_counter.current_val = new_val;
            world.write_model(@game_counter);
            new_val
        }


        fn generate_chance_deck(ref self: ContractState) -> Array<ByteArray> {
            let mut deck: Array<ByteArray> = array![];

            deck.append("Advance to Go (Collect $200)");
            deck.append("Advance to MakerDAO Avenue - If you pass Go, collect $200");
            deck.append("Advance to Arbitrium Avenue - If you pass Go, collect $200");
            deck.append("Advance token to nearest Utility. Pay 10x dice.");
            deck.append("Advance token to nearest Railroad. Pay 2x rent.");
            deck.append("Bank pays you dividend of $50");
            deck.append("Get out of Jail Free");
            deck.append("Go Back 3 Spaces");
            deck.append("Go to Jail dirctly do not pass Go do not collect $200");
            deck.append("Make general repairs - $25 house, $100 hotel");
            deck.append("Pay poor tax of $15");
            deck.append("Take a trip to Reading Railroad");
            deck.append("Take a walk on the Bitcoin Lane");
            deck.append("Speeding fine $200");
            deck.append("Building loan matures - collect $150");

            // self.shuffle_array(deck);

            deck
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

        fn generate_board_tiles(ref self: ContractState, game_id: u256) {
            let bank: ContractAddress = contract_address_const::<0>();

            self
                .generate_properties(
                    0, game_id, 'Go', 0, PropertyType::Go, 0, 0, 0, 0, 0, 0, 0, false, 0, bank,
                );
            self
                .generate_properties(
                    1,
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
                    bank,
                );
            self
                .generate_properties(
                    2,
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
                    bank,
                );
            self
                .generate_properties(
                    3,
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
                    bank,
                );
            self
                .generate_properties(
                    4,
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
                    bank,
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
                    bank,
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
                    bank,
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
                    bank,
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
                    bank,
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
                    bank,
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
                    bank,
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
                    bank,
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
                    bank,
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
                    bank,
                );
            self
                .generate_properties(
                    14,
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
                    bank,
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
                    bank,
                );

            self
                .generate_properties(
                    16,
                    game_id,
                    'Near Lane',
                    200,
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
                    bank,
                );
            self
                .generate_properties(
                    17,
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
                    bank,
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
                    bank,
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
                    bank,
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
                    bank,
                );
            self
                .generate_properties(
                    21,
                    game_id,
                    'Dune Lane',
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
                    bank,
                );
            self
                .generate_properties(
                    22,
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
                    bank,
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
                    bank,
                );
            self
                .generate_properties(
                    24,
                    game_id,
                    'MakerDAO Avenue',
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
                    bank,
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
                    bank,
                );

            self
                .generate_properties(
                    26,
                    game_id,
                    'Aave Avenue',
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
                    bank,
                );
            self
                .generate_properties(
                    27,
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
                    bank,
                );
            self
                .generate_properties(
                    28,
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
                    bank,
                );
            self
                .generate_properties(
                    29,
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
                    bank,
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
                    bank,
                );
            self
                .generate_properties(
                    31,
                    game_id,
                    'Rootstock Lane',
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
                    bank,
                );
            self
                .generate_properties(
                    32,
                    game_id,
                    'Ark Lane',
                    280,
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
                    bank,
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
                    bank,
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
                    bank,
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
                    bank,
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
                    bank,
                );
            self
                .generate_properties(
                    37,
                    game_id,
                    'Solana Drive',
                    350,
                    PropertyType::Property,
                    35,
                    175,
                    500,
                    1100,
                    1300,
                    1500,
                    200,
                    false,
                    8,
                    bank,
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
                    bank,
                );
            self
                .generate_properties(
                    39,
                    game_id,
                    'Ethereum Avenue',
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
                    bank,
                );
        }
    }
}
