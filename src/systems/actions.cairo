// dojo decorator
#[dojo::contract]
pub mod actions {
    use dojo_starter::interfaces::IActions::IActions;
    use dojo_starter::model::property_model::{Property, PropertyTrait, PropertyToId, IdToProperty};
    use dojo_starter::model::utility_model::{Utility, UtilityTrait, UtilityToId, IdToUtility};
    use dojo_starter::model::rail_road_model::{RailRoad, RailRoadTrait, RailRoadToId, IdToRailRoad};
    use dojo_starter::model::game_model::{
        GameType, Game, GameBalance, GameTrait, GameCounter, GameStatus, IGameBalance, GameListOfPlayers
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

        fn buy_property(ref self: ContractState, property_id: u8, game_id: u256) -> bool {
            // get the world
            let mut world = self.world_default();
            //get the game out and check it is ongoing
            let found_game: Game = world.read_model(game_id);
            assert!(found_game.status == GameStatus::Ongoing, "game has not started yet ");

            let caller = get_caller_address();

            let mut property: Property = world.read_model((property_id, game_id));
            let contract_address = get_contract_address();
            let zero_address: ContractAddress = contract_address_const::<0>();
            let amount: u256 = property.cost_of_property;

            if property.owner == zero_address {
                self.transfer_from(caller, contract_address, game_id, amount);
            } else {
                assert(property.for_sale == true, 'Property is not for sale');
                self.transfer_from(caller, property.owner, game_id, amount);
            }

            property.change_game_property_ownership(caller, property.owner);
            property.for_sale = false;

            world.write_model(@property);
            true
        }

        fn mortgage_property(ref self: ContractState, property_id: u8, game_id: u256) -> bool {
            let mut world = self.world_default();
            let caller = get_caller_address();
            let mut property: Property = world.read_model((property_id, game_id));

            // call the property model trait
            property.mortgage(caller);

            let amount: u256 = property.cost_of_property / 2;
            let contract_address = get_contract_address();

            // call the game player model
            self.transfer_from(contract_address, caller, game_id, amount);

            world.write_model(@property);

            true
        }

        fn unmortgage_property(ref self: ContractState, property_id: u8, game_id: u256) -> bool {
            let mut world = self.world_default();
            let caller = get_caller_address();
            let mut property: Property = world.read_model((property_id, game_id));

            // assert(property.owner == caller, 'Only the owner can unmortgage');
            // assert(property.is_mortgaged == true, 'Property is not mortgaged');

            let mortgage_amount: u256 = property.cost_of_property / 2;
            let interest: u256 = mortgage_amount * 10 / 100; // 10% interest
            let repay_amount: u256 = mortgage_amount + interest;

            let player_balance: GameBalance = world.read_model(());

            // self.transfer_from(caller, get_contract_address(), game_id, repay_amount);

            property.lift_mortgage(caller);

            self.transfer_from(caller, get_contract_address(), game_id, repay_amount);

            world.write_model(@property);

            true
        }

        fn collect_rent(ref self: ContractState, property_id: u8, game_id: u256) -> bool {
            let mut world = self.world_default();
            let caller = get_caller_address();
            let property: Property = world.read_model((property_id, game_id));
            let zero_address: ContractAddress = contract_address_const::<0>();

            assert(property.owner != zero_address, 'Property is unowned');
            assert(property.owner != caller, 'You cannot pay rent to yourself');
            assert(!property.is_mortgaged, 'No rent on mortgaged properties');

            let rent_amount: u256 = property.get_rent_amount();

            self.transfer_from(caller, property.owner, game_id, rent_amount);

            true
        }

        fn buy_house_or_hotel(ref self: ContractState, property_id: u8, game_id: u256) -> bool {
            let mut world = self.world_default();
            let caller = get_caller_address();
            let mut property: Property = world.read_model((property_id, game_id));
            let contract_address = get_contract_address();

            assert(property.owner == caller, 'Only the owner ');
            assert(property.is_mortgaged == false, 'Cannot develop');
            assert(property.development < 5, 'Maximum development ');

            let cost: u256 = property.cost_of_house;
            self.transfer_from(caller, contract_address, game_id, cost);

            property.development += 1; // Increases to 5 (hotel) max

            world.write_model(@property);

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

            self.transfer_from(contract_address, caller, game_id, refund);

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
            ref self: ContractState,
            from: ContractAddress,
            to: ContractAddress,
            game_id: u256,
            amount: u256,
        ) {
            let mut world = self.world_default();

            let mut sender: GameBalance = world.read_model((from, game_id));
            let mut recepient: GameBalance = world.read_model((to, game_id));
            sender.deduct_game_balance(amount);
            recepient.increase_game_balance(amount);

            world.write_model(@sender);
            world.write_model(@recepient);
        }


        fn mint(ref self: ContractState, recepient: ContractAddress, game_id: u256, amount: u256) {
            let mut world = self.world_default();

            let mut receiver: GameBalance = world.read_model((recepient, game_id));
            let balance = receiver.balance + amount;
            receiver.balance = balance;
            world.write_model(@receiver);
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

        fn retrieve_game_player(self: @ContractState, addr: ContractAddress) -> GamePlayer {
            // Get default world
            let mut world = self.world_default();
            let player: GamePlayer = world.read_model(addr);

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

        fn generate_board_tiles(ref self: ContractState, game_id: u256) {
            // Special tiles
            self.generate_go(1, game_id, 'Go');
            self.generate_community_chest(2, game_id);
            self
                .generate_properties(
                    3, game_id, 'Axone Avenue', 60, 2, 10, 30, 90, 160, 250, 50, false, 1,
                );
            self.generate_tax(4, game_id, 'Income Tax', 200);
            self.generate_railroad(5, game_id, 'IPFS Railroad', false);
            self
                .generate_properties(
                    6, game_id, 'Onlydust Avenue', 60, 4, 20, 60, 180, 320, 450, 50, false, 1,
                );
            self.generate_chance(7, game_id);
            self
                .generate_properties(
                    8, game_id, 'ZkSync Lane', 100, 6, 30, 90, 270, 400, 550, 50, false, 2,
                );
            self
                .generate_properties(
                    9, game_id, 'Starknet Lane', 100, 6, 30, 90, 270, 400, 550, 50, false, 2,
                );
            self.generate_jail(10, game_id, 'Visiting Jail');
            self
                .generate_properties(
                    11, game_id, 'Linea Lane', 120, 8, 40, 100, 300, 450, 600, 50, false, 2,
                );
            self.generate_utilitity(12, game_id, 'Chainlink Power Plant', false);
            self
                .generate_properties(
                    13, game_id, 'Arbitrium Avenue', 140, 10, 50, 150, 450, 625, 750, 100, false, 3,
                );
            self.generate_community_chest(14, game_id);
            self
                .generate_properties(
                    15,
                    game_id,
                    'Optimistic Avenue',
                    140,
                    10,
                    50,
                    150,
                    450,
                    625,
                    750,
                    100,
                    false,
                    3,
                );
            self.generate_railroad(16, game_id, 'Pinata Railroad', false);
            self
                .generate_properties(
                    17, game_id, 'Base Avenue', 160, 12, 60, 180, 500, 700, 900, 100, false, 3,
                );
            self
                .generate_properties(
                    18, game_id, 'Cosmos Lane', 180, 14, 70, 200, 550, 750, 950, 100, false, 4,
                );
            self.generate_chance(19, game_id);
            self
                .generate_properties(
                    20, game_id, 'Polkadot Lane', 180, 14, 70, 200, 550, 750, 950, 100, false, 4,
                );
            self.generate_go(21, game_id, 'Free Parking');
            self
                .generate_properties(
                    22, game_id, 'Near Lane', 200, 16, 80, 220, 600, 800, 1000, 100, false, 4,
                );
            self.generate_community_chest(23, game_id);
            self
                .generate_properties(
                    24, game_id, 'Uniswap Avenue', 220, 18, 90, 250, 700, 875, 1050, 150, false, 5,
                );
            self.generate_railroad(25, game_id, 'Open Zeppelin Railroad', false);
            self
                .generate_properties(
                    26, game_id, 'MakerDAO Avenue', 220, 18, 90, 250, 700, 875, 1050, 150, false, 5,
                );
            self
                .generate_properties(
                    27, game_id, 'Aave Avenue', 240, 20, 100, 300, 750, 925, 1100, 150, false, 5,
                );
            self.generate_utilitity(28, game_id, 'Graph Water Works', false);
            self
                .generate_properties(
                    29, game_id, 'Lisk Lane', 260, 22, 110, 330, 800, 975, 1150, 150, false, 6,
                );
            self.generate_jail(30, game_id, 'Go to Jail');
            self
                .generate_properties(
                    31, game_id, 'Rootstock Lane', 260, 22, 110, 330, 800, 975, 1150, 150, false, 6,
                );
            self
                .generate_properties(
                    32, game_id, 'Ark Lane', 280, 22, 120, 360, 850, 1025, 1200, 150, false, 6,
                );
            self.generate_community_chest(33, game_id);
            self
                .generate_properties(
                    34,
                    game_id,
                    'Avalanche Avenue',
                    300,
                    26,
                    130,
                    390,
                    900,
                    1100,
                    1275,
                    200,
                    false,
                    7,
                );
            self.generate_railroad(35, game_id, 'Cartridge Railroad', false);
            self.generate_chance(36, game_id);
            self
                .generate_properties(
                    37, game_id, 'Solana Drive', 300, 26, 130, 390, 900, 1100, 1275, 200, false, 7,
                );
            self.generate_tax(38, game_id, 'Luxury Tax', 100);
            self
                .generate_properties(
                    39,
                    game_id,
                    'Ethereum Avenue',
                    320,
                    28,
                    150,
                    450,
                    1000,
                    1200,
                    1400,
                    200,
                    false,
                    7,
                );
            self
                .generate_properties(
                    40, game_id, 'Bitcoin Lane', 400, 50, 200, 600, 1400, 1700, 2000, 200, false, 8,
                );
        }

        fn try_join_symbol(
            ref self: ContractState,
            mut game: Game,
            symbol: PlayerSymbol,
            username: felt252,
            game_id: u256,
        ) {
            let mut world = self.world_default();
            let timestamp = get_block_timestamp();

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

        fn assert_player_not_already_joined(
            ref self: ContractState, game: Game, username: felt252,
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
            rent_site_only: u256,
            rent_one_house: u256,
            rent_two_houses: u256,
            rent_three_houses: u256,
            rent_four_houses: u256,
            rent_hotel: u256,
            cost_of_house: u256,
            is_mortgaged: bool,
            group_id: u8,
        ) {
            let mut world = self.world_default();
            let mut property: Property = world.read_model((id, game_id));

            property =
                PropertyTrait::new(
                    id,
                    game_id,
                    name,
                    cost_of_property,
                    rent_site_only,
                    rent_one_house,
                    rent_two_houses,
                    rent_three_houses,
                    rent_four_houses,
                    rent_hotel,
                    cost_of_house,
                    group_id,
                );

            let property_to_id: PropertyToId = PropertyToId { name, id };
            let id_to_property: IdToProperty = IdToProperty { id, name };

            world.write_model(@property);
            world.write_model(@property_to_id);
            world.write_model(@id_to_property);
        }


        fn generate_go(ref self: ContractState, id: u8, game_id: u256, name: felt252) {
            let mut world = self.world_default();
            let mut go: Go = world.read_model((id, game_id));
            go = Go { id, game_id, name };
            world.write_model(@go);
        }

        fn create_new_game_id(ref self: ContractState) -> u256 {
            let mut world = self.world_default();
            let mut game_counter: GameCounter = world.read_model('v0');
            let new_val = game_counter.current_val + 1;
            game_counter.current_val = new_val;
            world.write_model(@game_counter);
            new_val
        }

        fn generate_tax(
            ref self: ContractState, id: u8, game_id: u256, name: felt252, tax_amount: u256,
        ) {
            let mut world = self.world_default();
            let mut tax: Tax = world.read_model((id, game_id));
            tax = Tax { id, game_id, name, tax_amount };
            world.write_model(@tax);
        }

        fn generate_utilitity(
            ref self: ContractState, id: u8, game_id: u256, name: felt252, is_mortgaged: bool,
        ) {
            let mut world = self.world_default();
            let mut utility: Utility = world.read_model((id, game_id));

            utility = UtilityTrait::new(id, game_id, name);

            let utility_to_id: UtilityToId = UtilityToId { name, id };
            let id_to_utility: IdToUtility = IdToUtility { id, name };

            world.write_model(@utility);
            world.write_model(@utility_to_id);
            world.write_model(@id_to_utility);
        }

        // to be moved to it model
        fn generate_railroad(
            ref self: ContractState, id: u8, game_id: u256, name: felt252, is_mortgaged: bool,
        ) {
            let mut world = self.world_default();
            let mut railroad: RailRoad = world.read_model((id, game_id));

            railroad = RailRoadTrait::new(id, game_id, name);

            let railroad_to_id: RailRoadToId = RailRoadToId { name, id };
            let id_to_railroad: IdToRailRoad = IdToRailRoad { id, name };

            world.write_model(@railroad);
            world.write_model(@railroad_to_id);
            world.write_model(@id_to_railroad);
        }

        // to be moved to it model
        fn generate_chance(ref self: ContractState, id: u8, game_id: u256) {
            let mut world = self.world_default();
            let mut chance: Chance = world.read_model((id, game_id));

            chance = ChanceTrait::new(id, game_id);

            world.write_model(@chance);
        }

        // to be moved to it model
        fn generate_community_chest(ref self: ContractState, id: u8, game_id: u256) {
            let mut world = self.world_default();
            let mut community_chest: CommunityChest = world.read_model((id, game_id));

            community_chest = CommunityChestTrait::new(id, game_id);

            world.write_model(@community_chest);
        }

        // to be moved to it model
        fn generate_jail(ref self: ContractState, id: u8, game_id: u256, name: felt252) {
            let mut world = self.world_default();
            let mut jail: Jail = world.read_model((id, game_id));
            jail = Jail { id, game_id, name };
        }
    }
}

