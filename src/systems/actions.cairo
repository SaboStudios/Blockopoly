// dojo decorator
#[dojo::contract]
pub mod actions {
    use dojo_starter::interfaces::IActions::IActions;
    use dojo_starter::model::property_model::{
        Property, PropertyType, PropertyTrait, PropertyToId, IdToProperty, TradeOffer,
        TradeOfferDetails, TradeCounter, TradeStatus,
    };
    use dojo_starter::model::game_model::{
        GameType, Game, GameBalance, GameTrait, GameCounter, GameStatus, IGameBalance,
    };
    use dojo_starter::model::player_model::{
        Player, UsernameToAddress, AddressToUsername, PlayerTrait, IsRegistered,
    };
    use dojo_starter::model::game_player_model::{GamePlayer, PlayerSymbol, GamePlayerTrait};
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


        fn get_property(self: @ContractState, id: u8, game_id: u256) -> Property {
            let world = self.world_default();
            let property: Property = world.read_model((id, game_id));
            property
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
            let mut property = self.get_property(game_player.position, game_id);
            property = self.handle_property_landing(game_player.clone(), property);

            // Update state
            world.write_model(@game_player);
            world.write_model(@game);
            world.write_model(@property);

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


        fn offer_trade(
            ref self: ContractState,
            game_id: u256,
            to: ContractAddress,
            offered_property_ids: Array<u8>,
            requested_property_ids: Array<u8>,
            cash_offer: u256,
            cash_request: u256,
            trade_type: TradeOffer,
        ) -> u256 {
            let caller = get_caller_address();

            let mut world = self.world_default();
            let mut game: Game = world.read_model(game_id);

            assert!(game.next_player == caller, "Not your turn");
            assert!(game.status == GameStatus::Ongoing, "Game is not ongoing");

            let id = self.create_trade_id();

            // Validate inputs here (as you do)
            let mut offer: TradeOfferDetails = world.read_model(id);
            // Create the offer struct

            offer.id = id;
            offer.from = caller;
            offer.to = to;
            offer.game_id = game_id;
            offer.offered_property_ids = offered_property_ids;
            offer.requested_property_ids = requested_property_ids;
            offer.cash_offer = cash_offer;
            offer.cash_request = cash_request;
            offer.trade_type = trade_type;
            offer.status = TradeStatus::Pending;

            world.write_model(@offer);

            id
        }

        fn accept_trade(ref self: ContractState, trade_id: u256, game_id: u256) -> bool {
            let mut world = self.world_default();
            let caller = get_caller_address();

            let mut offer: TradeOfferDetails = world.read_model(trade_id);
            assert!(caller == offer.to, "Only recipient can accept trade");

            // Load offer

            let mut initiator: GamePlayer = world.read_model((offer.from, offer.game_id));
            let mut receiver: GamePlayer = world.read_model((offer.to, offer.game_id));

            if offer.trade_type == TradeOffer::PropertyForCash {
                // Transfer properties from initiator to receiver
                let mut i = 0;
                while i < offer.offered_property_ids.len() {
                    let prop_id = *offer.offered_property_ids[i];
                    let mut property: Property = world.read_model((prop_id, game_id));

                    // Manual transfer of ownership
                    assert!(
                        property.owner == initiator.address, "Initiator does not own this property",
                    );
                    property.owner = receiver.address;

                    // Create a new array excluding the property being traded
                    let mut new_properties_owned: Array<u8> = ArrayTrait::new();
                    let mut j = 0;

                    while j < initiator.properties_owned.len() {
                        let owned_prop_id = *initiator.properties_owned[j];
                        if owned_prop_id != prop_id {
                            new_properties_owned.append(owned_prop_id);
                        }
                        j += 1;
                    };

                    // Assign back the new array
                    initiator.properties_owned = new_properties_owned;

                    // Now add the property to the receiver
                    receiver.properties_owned.append(prop_id);
                    match property.group_id {
                        0 => {},
                        1 => receiver.no_section1 += 1,
                        2 => receiver.no_section2 += 1,
                        3 => receiver.no_section3 += 1,
                        4 => receiver.no_section4 += 1,
                        5 => receiver.no_section5 += 1,
                        6 => receiver.no_section6 += 1,
                        7 => receiver.no_section7 += 1,
                        8 => receiver.no_section8 += 1,
                        _ => {},
                    }
                    match property.group_id {
                        0 => {},
                        1 => initiator.no_section1 -= 1,
                        2 => initiator.no_section2 -= 1,
                        3 => initiator.no_section3 -= 1,
                        4 => initiator.no_section4 -= 1,
                        5 => initiator.no_section5 -= 1,
                        6 => initiator.no_section6 -= 1,
                        7 => initiator.no_section7 -= 1,
                        8 => initiator.no_section8 -= 1,
                        _ => {},
                    }

                    // Save updated property
                    world.write_model(@property);

                    i += 1;
                };

                // Transfer cash from receiver to initiator
                assert!(receiver.balance >= offer.cash_request, "Receiver has insufficient cash");
                receiver.balance -= offer.cash_request;
                initiator.balance += offer.cash_request;

                // Persist updated players
                world.write_model(@initiator);
                world.write_model(@receiver);
            } else if offer.trade_type == TradeOffer::PropertyForProperty {
                // Transfer offered properties from initiator to receiver
                let mut i = 0;
                while i < offer.offered_property_ids.len() {
                    let prop_id = *offer.offered_property_ids[i];
                    let mut property: Property = world.read_model((prop_id, game_id));

                    // Ensure the initiator owns it
                    assert!(
                        property.owner == initiator.address, "Initiator does not own this property",
                    );
                    property.owner = receiver.address;

                    // Remove from initiator properties_owned
                    let mut new_properties_owned: Array<u8> = ArrayTrait::new();
                    let mut k = 0;
                    while k < initiator.properties_owned.len() {
                        let owned_prop_id = *initiator.properties_owned[k];
                        if owned_prop_id != prop_id {
                            new_properties_owned.append(owned_prop_id);
                        }
                        k += 1;
                    };
                    initiator.properties_owned = new_properties_owned;

                    // Add to receiver properties_owned
                    receiver.properties_owned.append(prop_id);

                    // Update section counters
                    match property.group_id {
                        0 => {},
                        1 => {
                            receiver.no_section1 += 1;
                            initiator.no_section1 -= 1;
                        },
                        2 => {
                            receiver.no_section2 += 1;
                            initiator.no_section2 -= 1;
                        },
                        3 => {
                            receiver.no_section3 += 1;
                            initiator.no_section3 -= 1;
                        },
                        4 => {
                            receiver.no_section4 += 1;
                            initiator.no_section4 -= 1;
                        },
                        5 => {
                            receiver.no_section5 += 1;
                            initiator.no_section5 -= 1;
                        },
                        6 => {
                            receiver.no_section6 += 1;
                            initiator.no_section6 -= 1;
                        },
                        7 => {
                            receiver.no_section7 += 1;
                            initiator.no_section7 -= 1;
                        },
                        8 => {
                            receiver.no_section8 += 1;
                            initiator.no_section8 -= 1;
                        },
                        _ => {},
                    }

                    // Write updated property
                    world.write_model(@property);

                    i += 1;
                };

                // Transfer requested properties from receiver to initiator
                let mut j = 0;
                while j < offer.requested_property_ids.len() {
                    let prop_id = *offer.requested_property_ids[j];
                    let mut property: Property = world.read_model((prop_id, game_id));

                    // Ensure the receiver owns it
                    assert!(
                        property.owner == receiver.address, "Receiver does not own this property",
                    );
                    property.owner = initiator.address;

                    // Remove from receiver properties_owned
                    let mut new_properties_owned: Array<u8> = ArrayTrait::new();
                    let mut l = 0;
                    while l < receiver.properties_owned.len() {
                        let owned_prop_id = *receiver.properties_owned[l];
                        if owned_prop_id != prop_id {
                            new_properties_owned.append(owned_prop_id);
                        }
                        l += 1;
                    };
                    receiver.properties_owned = new_properties_owned;

                    // Add to initiator properties_owned
                    initiator.properties_owned.append(prop_id);

                    // Update section counters
                    match property.group_id {
                        0 => {},
                        1 => {
                            initiator.no_section1 += 1;
                            receiver.no_section1 -= 1;
                        },
                        2 => {
                            initiator.no_section2 += 1;
                            receiver.no_section2 -= 1;
                        },
                        3 => {
                            initiator.no_section3 += 1;
                            receiver.no_section3 -= 1;
                        },
                        4 => {
                            initiator.no_section4 += 1;
                            receiver.no_section4 -= 1;
                        },
                        5 => {
                            initiator.no_section5 += 1;
                            receiver.no_section5 -= 1;
                        },
                        6 => {
                            initiator.no_section6 += 1;
                            receiver.no_section6 -= 1;
                        },
                        7 => {
                            initiator.no_section7 += 1;
                            receiver.no_section7 -= 1;
                        },
                        8 => {
                            initiator.no_section8 += 1;
                            receiver.no_section8 -= 1;
                        },
                        _ => {},
                    }

                    // Write updated property
                    world.write_model(@property);

                    j += 1;
                };

                // Write updated players
                world.write_model(@initiator);
                world.write_model(@receiver);
            } else if offer.trade_type == TradeOffer::CashForProperty {
                // Transfer cash from initiator to receiver
                assert!(initiator.balance >= offer.cash_offer, "Initiator has insufficient cash");
                initiator.balance -= offer.cash_offer;
                receiver.balance += offer.cash_offer;

                // Transfer requested properties from receiver to initiator
                let mut j = 0;
                while j < offer.requested_property_ids.len() {
                    let prop_id = *offer.requested_property_ids[j];
                    let mut property: Property = world.read_model((prop_id, game_id));

                    // Ensure the receiver owns it
                    assert!(
                        property.owner == receiver.address, "Receiver does not own this property",
                    );
                    property.owner = initiator.address;

                    // Remove from receiver properties_owned
                    let mut new_properties_owned: Array<u8> = ArrayTrait::new();
                    let mut l = 0;
                    while l < receiver.properties_owned.len() {
                        let owned_prop_id = *receiver.properties_owned[l];
                        if owned_prop_id != prop_id {
                            new_properties_owned.append(owned_prop_id);
                        }
                        l += 1;
                    };
                    receiver.properties_owned = new_properties_owned;

                    // Add to initiator properties_owned
                    initiator.properties_owned.append(prop_id);

                    // Update section counters
                    match property.group_id {
                        0 => {},
                        1 => {
                            initiator.no_section1 += 1;
                            receiver.no_section1 -= 1;
                        },
                        2 => {
                            initiator.no_section2 += 1;
                            receiver.no_section2 -= 1;
                        },
                        3 => {
                            initiator.no_section3 += 1;
                            receiver.no_section3 -= 1;
                        },
                        4 => {
                            initiator.no_section4 += 1;
                            receiver.no_section4 -= 1;
                        },
                        5 => {
                            initiator.no_section5 += 1;
                            receiver.no_section5 -= 1;
                        },
                        6 => {
                            initiator.no_section6 += 1;
                            receiver.no_section6 -= 1;
                        },
                        7 => {
                            initiator.no_section7 += 1;
                            receiver.no_section7 -= 1;
                        },
                        8 => {
                            initiator.no_section8 += 1;
                            receiver.no_section8 -= 1;
                        },
                        _ => {},
                    }

                    // Write updated property
                    world.write_model(@property);

                    j += 1;
                };

                // Write updated players
                world.write_model(@initiator);
                world.write_model(@receiver);
            } else if offer.trade_type == TradeOffer::CashPlusPropertyForProperty {
                // Transfer offered properties from initiator to receiver
                let mut i = 0;
                while i < offer.offered_property_ids.len() {
                    let prop_id = *offer.offered_property_ids[i];
                    let mut property: Property = world.read_model((prop_id, game_id));

                    // Ensure the initiator owns it
                    assert!(
                        property.owner == initiator.address, "Initiator does not own this property",
                    );
                    property.owner = receiver.address;

                    // Remove from initiator properties_owned
                    let mut new_properties_owned: Array<u8> = ArrayTrait::new();
                    let mut k = 0;
                    while k < initiator.properties_owned.len() {
                        let owned_prop_id = *initiator.properties_owned[k];
                        if owned_prop_id != prop_id {
                            new_properties_owned.append(owned_prop_id);
                        }
                        k += 1;
                    };
                    initiator.properties_owned = new_properties_owned;

                    // Add to receiver properties_owned
                    receiver.properties_owned.append(prop_id);

                    // Update section counters
                    match property.group_id {
                        0 => {},
                        1 => {
                            receiver.no_section1 += 1;
                            initiator.no_section1 -= 1;
                        },
                        2 => {
                            receiver.no_section2 += 1;
                            initiator.no_section2 -= 1;
                        },
                        3 => {
                            receiver.no_section3 += 1;
                            initiator.no_section3 -= 1;
                        },
                        4 => {
                            receiver.no_section4 += 1;
                            initiator.no_section4 -= 1;
                        },
                        5 => {
                            receiver.no_section5 += 1;
                            initiator.no_section5 -= 1;
                        },
                        6 => {
                            receiver.no_section6 += 1;
                            initiator.no_section6 -= 1;
                        },
                        7 => {
                            receiver.no_section7 += 1;
                            initiator.no_section7 -= 1;
                        },
                        8 => {
                            receiver.no_section8 += 1;
                            initiator.no_section8 -= 1;
                        },
                        _ => {},
                    }

                    // Write updated property
                    world.write_model(@property);

                    i += 1;
                };

                // Transfer cash from initiator to receiver
                assert!(initiator.balance >= offer.cash_offer, "Initiator has insufficient cash");
                initiator.balance -= offer.cash_offer;
                receiver.balance += offer.cash_offer;

                // Transfer requested properties from receiver to initiator
                let mut j = 0;
                while j < offer.requested_property_ids.len() {
                    let prop_id = *offer.requested_property_ids[j];
                    let mut property: Property = world.read_model((prop_id, game_id));

                    // Ensure the receiver owns it
                    assert!(
                        property.owner == receiver.address, "Receiver does not own this property",
                    );
                    property.owner = initiator.address;

                    // Remove from receiver properties_owned
                    let mut new_properties_owned: Array<u8> = ArrayTrait::new();
                    let mut l = 0;
                    while l < receiver.properties_owned.len() {
                        let owned_prop_id = *receiver.properties_owned[l];
                        if owned_prop_id != prop_id {
                            new_properties_owned.append(owned_prop_id);
                        }
                        l += 1;
                    };
                    receiver.properties_owned = new_properties_owned;

                    // Add to initiator properties_owned
                    initiator.properties_owned.append(prop_id);

                    // Update section counters
                    match property.group_id {
                        0 => {},
                        1 => {
                            initiator.no_section1 += 1;
                            receiver.no_section1 -= 1;
                        },
                        2 => {
                            initiator.no_section2 += 1;
                            receiver.no_section2 -= 1;
                        },
                        3 => {
                            initiator.no_section3 += 1;
                            receiver.no_section3 -= 1;
                        },
                        4 => {
                            initiator.no_section4 += 1;
                            receiver.no_section4 -= 1;
                        },
                        5 => {
                            initiator.no_section5 += 1;
                            receiver.no_section5 -= 1;
                        },
                        6 => {
                            initiator.no_section6 += 1;
                            receiver.no_section6 -= 1;
                        },
                        7 => {
                            initiator.no_section7 += 1;
                            receiver.no_section7 -= 1;
                        },
                        8 => {
                            initiator.no_section8 += 1;
                            receiver.no_section8 -= 1;
                        },
                        _ => {},
                    }

                    // Write updated property
                    world.write_model(@property);

                    j += 1;
                };

                // Write updated players
                world.write_model(@initiator);
                world.write_model(@receiver);
            } else if offer.trade_type == TradeOffer::PropertyForCashPlusProperty {
                // Transfer offered properties from initiator to receiver
                let mut i = 0;
                while i < offer.offered_property_ids.len() {
                    let prop_id = *offer.offered_property_ids[i];
                    let mut property: Property = world.read_model((prop_id, game_id));

                    // Ensure the initiator owns it
                    assert!(
                        property.owner == initiator.address, "Initiator does not own this property",
                    );
                    property.owner = receiver.address;

                    // Remove from initiator properties_owned
                    let mut new_properties_owned: Array<u8> = ArrayTrait::new();
                    let mut k = 0;
                    while k < initiator.properties_owned.len() {
                        let owned_prop_id = *initiator.properties_owned[k];
                        if owned_prop_id != prop_id {
                            new_properties_owned.append(owned_prop_id);
                        }
                        k += 1;
                    };
                    initiator.properties_owned = new_properties_owned;

                    // Add to receiver properties_owned
                    receiver.properties_owned.append(prop_id);

                    // Update section counters
                    match property.group_id {
                        0 => {},
                        1 => {
                            receiver.no_section1 += 1;
                            initiator.no_section1 -= 1;
                        },
                        2 => {
                            receiver.no_section2 += 1;
                            initiator.no_section2 -= 1;
                        },
                        3 => {
                            receiver.no_section3 += 1;
                            initiator.no_section3 -= 1;
                        },
                        4 => {
                            receiver.no_section4 += 1;
                            initiator.no_section4 -= 1;
                        },
                        5 => {
                            receiver.no_section5 += 1;
                            initiator.no_section5 -= 1;
                        },
                        6 => {
                            receiver.no_section6 += 1;
                            initiator.no_section6 -= 1;
                        },
                        7 => {
                            receiver.no_section7 += 1;
                            initiator.no_section7 -= 1;
                        },
                        8 => {
                            receiver.no_section8 += 1;
                            initiator.no_section8 -= 1;
                        },
                        _ => {},
                    }

                    // Write updated property
                    world.write_model(@property);

                    i += 1;
                };

                // Transfer cash from receiver to initiator
                assert!(receiver.balance >= offer.cash_request, "Receiver has insufficient cash");
                receiver.balance -= offer.cash_request;
                initiator.balance += offer.cash_request;

                // Transfer requested properties from receiver to initiator
                let mut j = 0;
                while j < offer.requested_property_ids.len() {
                    let prop_id = *offer.requested_property_ids[j];
                    let mut property: Property = world.read_model((prop_id, game_id));

                    // Ensure the receiver owns it
                    assert!(
                        property.owner == receiver.address, "Receiver does not own this property",
                    );
                    property.owner = initiator.address;

                    // Remove from receiver properties_owned
                    let mut new_properties_owned: Array<u8> = ArrayTrait::new();
                    let mut l = 0;
                    while l < receiver.properties_owned.len() {
                        let owned_prop_id = *receiver.properties_owned[l];
                        if owned_prop_id != prop_id {
                            new_properties_owned.append(owned_prop_id);
                        }
                        l += 1;
                    };
                    receiver.properties_owned = new_properties_owned;

                    // Add to initiator properties_owned
                    initiator.properties_owned.append(prop_id);

                    // Update section counters
                    match property.group_id {
                        0 => {},
                        1 => {
                            initiator.no_section1 += 1;
                            receiver.no_section1 -= 1;
                        },
                        2 => {
                            initiator.no_section2 += 1;
                            receiver.no_section2 -= 1;
                        },
                        3 => {
                            initiator.no_section3 += 1;
                            receiver.no_section3 -= 1;
                        },
                        4 => {
                            initiator.no_section4 += 1;
                            receiver.no_section4 -= 1;
                        },
                        5 => {
                            initiator.no_section5 += 1;
                            receiver.no_section5 -= 1;
                        },
                        6 => {
                            initiator.no_section6 += 1;
                            receiver.no_section6 -= 1;
                        },
                        7 => {
                            initiator.no_section7 += 1;
                            receiver.no_section7 -= 1;
                        },
                        8 => {
                            initiator.no_section8 += 1;
                            receiver.no_section8 -= 1;
                        },
                        _ => {},
                    }

                    // Write updated property
                    world.write_model(@property);

                    j += 1;
                };

                // Write updated players
                world.write_model(@initiator);
                world.write_model(@receiver);
            } else if offer.trade_type == TradeOffer::CashForChanceJailCard {
                // Initiator pays cash to receiver for receiver's chance jail card
                assert!(initiator.balance >= offer.cash_offer, "Initiator has insufficient cash");
                assert!(receiver.chance_jail_card, "Receiver does not have a chance jail card");
                assert!(!initiator.chance_jail_card, "Initiator already owns a chance jail card");

                // Transfer cash
                initiator.balance -= offer.cash_offer;
                receiver.balance += offer.cash_offer;

                // Transfer the card
                receiver.chance_jail_card = false;
                initiator.chance_jail_card = true;

                // Write back players
                world.write_model(@initiator);
                world.write_model(@receiver);
            } else if offer.trade_type == TradeOffer::CommunityJailCardForCash {
                // Initiator pays cash to receiver for receiver's community jail card
                assert!(initiator.balance >= offer.cash_offer, "Initiator has insufficient cash");
                assert!(receiver.comm_free_card, "Receiver does not have a community jail card");
                assert!(!initiator.comm_free_card, "Initiator already owns a community jail card");

                // Transfer cash
                initiator.balance -= offer.cash_offer;
                receiver.balance += offer.cash_offer;

                // Transfer the card
                receiver.comm_free_card = false;
                initiator.comm_free_card = true;

                // Write back players
                world.write_model(@initiator);
                world.write_model(@receiver);
            } else if offer.trade_type == TradeOffer::CashForCommunityJailCard {
                // Receiver pays cash to initiator for initiator's community jail card
                assert!(receiver.balance >= offer.cash_request, "Receiver has insufficient cash");
                assert!(initiator.comm_free_card, "Initiator does not have a community jail card");
                assert!(!receiver.comm_free_card, "Receiver already owns a community jail card");

                // Transfer cash
                receiver.balance -= offer.cash_request;
                initiator.balance += offer.cash_request;

                // Transfer the card
                initiator.comm_free_card = false;
                receiver.comm_free_card = true;

                // Write back players
                world.write_model(@initiator);
                world.write_model(@receiver);
            } else if offer.trade_type == TradeOffer::ChanceJailCardForCash {
                // Receiver pays cash to initiator for initiator's chance jail card
                assert!(receiver.balance >= offer.cash_request, "Receiver has insufficient cash");
                assert!(initiator.chance_jail_card, "Initiator does not have a chance jail card");
                assert!(!receiver.chance_jail_card, "Receiver already owns a chance jail card");

                // Transfer cash
                receiver.balance -= offer.cash_request;
                initiator.balance += offer.cash_request;

                // Transfer the card
                initiator.chance_jail_card = false;
                receiver.chance_jail_card = true;

                // Write back players
                world.write_model(@initiator);
                world.write_model(@receiver);
            }

            offer.status = TradeStatus::Accepted;

            // Save updated player and property data
            world.write_model(@initiator);
            world.write_model(@receiver);
            world.write_model(@offer);

            true
        }
        fn calculate_net_worth(ref self: ContractState, player: GamePlayer) -> u256 {
            let mut world = self.world_default();

            let mut total_property_value: u256 = 0;
            let mut total_house_cost: u256 = 0;
            let mut total_rent_value: u256 = 0;
            let mut card_value: u256 = 0;
            let mut i = 0;
            let properties_len = player.properties_owned.len();

            while i < properties_len {
                let prop_id = *player.properties_owned.at(i);
                let game_id = player.game_id;
                let property: Property = self.get_property(prop_id, game_id);

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

            // Debug prints
            println!("Balance: {}", player.balance);
            println!("Total property value: {}", total_property_value);
            println!("Total house cost: {}", total_house_cost);
            println!("Total rent value: {}", total_rent_value);
            println!("Card value: {}", card_value);
            println!("NET WORTH: {}", net_worth);

            net_worth
        }
        fn get_winner_by_net_worth(
            ref self: ContractState, players: Array<GamePlayer>,
        ) -> ContractAddress {
            let mut i = 0;
            let mut max_net_worth: u256 = 0;
            let mut winner_address: ContractAddress = contract_address_const::<'0'>();

            let players_len = players.len();
            while i < players_len {
                let player = players.at(i);
                let net_worth = self.calculate_net_worth(player.clone());

                if net_worth > max_net_worth {
                    max_net_worth = net_worth;
                    winner_address = *player.address;
                };

                i += 1;
            };

            winner_address
        }


        fn end_game(ref self: ContractState, game: Game) -> ContractAddress {
            let mut world = self.world_default();
            let mut players: Array<GamePlayer> = ArrayTrait::new();

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
            let winner_address = self.get_winner_by_net_worth(players);
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


        fn reject_trade(ref self: ContractState, trade_id: u256, game_id: u256) -> bool {
            let mut world = self.world_default();
            let caller = get_caller_address();

            let mut offer: TradeOfferDetails = world.read_model(trade_id);
            assert!(caller == offer.to, "Only recipient can reject trade");
            offer.status = TradeStatus::Rejected;

            world.write_model(@offer);

            true
        }

        fn counter_trade(
            ref self: ContractState,
            game_id: u256,
            original_offer_id: u256,
            offered_property_ids: Array<u8>,
            requested_property_ids: Array<u8>,
            cash_offer: u256,
            cash_request: u256,
            trade_type: TradeOffer,
        ) -> u256 {
            let caller = get_caller_address();

            let mut world = self.world_default();
            let mut game: Game = world.read_model(game_id);

            assert!(game.status == GameStatus::Ongoing, "Game is not ongoing");

            let mut original_offer: TradeOfferDetails = world.read_model(original_offer_id);

            // Ensure the caller is the recipient of the original offer
            assert!(
                original_offer.to == caller, "Only the receiver of the original trade can counter",
            );

            original_offer.id = original_offer.id;
            original_offer.game_id = game_id;
            original_offer.offered_property_ids = offered_property_ids;
            original_offer.requested_property_ids = requested_property_ids;
            original_offer.cash_offer = cash_offer;
            original_offer.cash_request = cash_request;
            original_offer.trade_type = trade_type;
            original_offer.status = TradeStatus::Countered;
            original_offer.is_countered = true;

            world.write_model(@original_offer);

            original_offer.id
        }

        fn approve_counter_trade(ref self: ContractState, trade_id: u256) -> bool {
            let mut world = self.world_default();
            let caller = get_caller_address();

            let mut offer: TradeOfferDetails = world.read_model(trade_id);
            assert!(caller == offer.from, "Only the initiator can approve the counter trade");
            assert!(offer.status == TradeStatus::Countered, "Trade is not pending");

            // Process the trade
            offer.status = TradeStatus::Pending;
            offer.is_countered = false;
            offer.approve_counter = true;

            true
        }

        fn get_trade(self: @ContractState, trade_id: u256) -> TradeOfferDetails {
            let world = self.world_default();
            let trade: TradeOfferDetails = world.read_model(trade_id);
            trade
        }


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

        fn handle_chance(ref self: ContractState, game_id: u256, random_index: u32) -> ByteArray {
            let mut world = self.world_default();
            let mut game: Game = world.read_model(game_id);

            let mut len = game.chance.len();
            if len <= 1 {
                game.chance = self.generate_chance_deck();
                len = game.chance.len();
                world.write_model(@game);
            }

            let draw_index = random_index % len;

            let card = game.chance[draw_index].clone();

            // Build new deck excluding drawn card
            let mut new_deck = array![];
            let mut i = 0;
            while i < len {
                if i != draw_index {
                    new_deck.append(game.chance[i].clone());
                }
                i += 1;
            };
            game.chance = new_deck;
            world.write_model(@game);

            card
        }
        fn handle_community_chest(
            ref self: ContractState, game_id: u256, random_index: u32,
        ) -> ByteArray {
            let mut world = self.world_default();
            let mut game: Game = world.read_model(game_id);

            let mut len = game.community.len();
            if len <= 1 {
                game.community = self.generate_community_chest_deck();
                len = game.community.len();
                world.write_model(@game);
            }

            let draw_index = random_index % len;

            let card = game.community[draw_index].clone();

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

        fn process_chance_card(
            ref self: ContractState, mut game: Game, mut player: GamePlayer, card: ByteArray,
        ) -> (Game, GamePlayer) {
            // We'll decode by matching text.
            // NOTE: If you have enums or ids for cards, it's cleaner. With ByteArray, compare
            // strings.
            let mut world = self.world_default();
            let property = self.get_property(player.position, game.id);
            assert(property.property_type == PropertyType::Chance, 'not on chance');
            if card == "Advance to Go (Collect $200)" {
                player.position = 0;
                player.balance += 200;
            } else if card == "Advance to MakerDAO Avenue - If you pass Go, collect $200" {
                if player.position > 24 { // suppose Illinois is tile 24
                    player.balance += 200;
                }
                player.position = 24;
            } else if card == "Advance to Arbitrium Avenue - If you pass Go, collect $200" {
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
                let mut rail_owner: GamePlayer = self.retrieve_game_player(rail.owner, game.id);
                let railroads = self.count_owner_railroads(property.owner, property.game_id);
                let utilities = self.count_owner_utilities(property.owner, property.game_id);
                let mut rent_amount = rail
                    .get_rent_amount(railroads, utilities, player.dice_rolled.into());
                if (rail.owner == get_contract_address()) {
                    rent_amount = 0;
                }
                player.balance -= rent_amount;
                rail_owner.balance += rent_amount;

                world.write_model(@rail_owner);
            } else if card == "Bank pays you dividend of $50" {
                player.balance += 50;
            } else if card == "Get out of Jail Free" {
                player.chance_jail_card = true;
            } else if card == "Go Back 3 Spaces" {
                if player.position < 4 {
                    player.position = 39 - (4 - player.position);
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
            } else if card == "Take a trip to IPFS Railroad" {
                if player.position > 5 {
                    player.balance += 200;
                }
                player.position = 5; // reading railroad
            } else if card == "Take a walk on the Bitcoin Lane" {
                player.position = 39;
            } else if card == "Speeding fine $200" {
                player.balance -= 200;
            } else if card == "Building loan matures - collect $150" {
                player.balance += 150;
            }
            game = self.finish_turn(game);
            world.write_model(@player);
            world.write_model(@game);
            (game, player)
        }

        fn process_community_chest_card(
            ref self: ContractState, mut game: Game, mut player: GamePlayer, card: ByteArray,
        ) -> (Game, GamePlayer) {
            let mut world = self.world_default();
            let property = self.get_property(player.position, game.id);
            assert(
                property.property_type == PropertyType::CommunityChest, 'not on community chest',
            );
            if card == "Advance to Go (Collect $200)" {
                player.position = 0;
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
                player.position = 10; // jail position
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

            game = self.finish_turn(game);
            world.write_model(@player);
            world.write_model(@game);
            (game, player)
        }


        fn leave_game(ref self: ContractState, game_id: u256, transfer_to: ContractAddress) {
            let mut world = self.world_default();
            let caller = get_caller_address();

            // Load game and player
            let mut game: Game = world.read_model(game_id);
            let mut quitting_player: GamePlayer = world.read_model((caller, game_id));

            // assert(quitting_player.in_game, "Player not in game");

            // Transfer properties to another player
            let mut i = 0;
            let len = quitting_player.properties_owned.len();
            while i < len {
                if quitting_player.properties_owned.len() == 0 {
                    break;
                }
                let prop_id = *quitting_player.properties_owned.at(i);
                let mut prop: Property = world.read_model((game_id, prop_id));
                prop.owner = transfer_to;
                world.write_model(@prop);
                i += 1;
            };

            // Remove player from game
            let mut new_game_players: Array<ContractAddress> = array![];
            let mut i = 0;
            while i < game.game_players.len() {
                let candidate = *game.game_players.at(i);
                if candidate != caller {
                    new_game_players.append(candidate);
                }
                i += 1;
            };

            game.game_players = new_game_players;
            game.number_of_players -= 1;

            // End game if only one player left
            if game.number_of_players == 1 {
                if game.game_players.len() > 0 {
                    let winner = *game.game_players.at(0);
                    game.winner = winner;
                    game.status = GameStatus::Ended;
                } else {
                    // Fallback case: no players left, just mark game ended
                    game.status = GameStatus::Ended;
                }
            }

            // Save updates
            // quitting_player.in_game = false;
            quitting_player.properties_owned = array![];
            world.write_model(@quitting_player);
            world.write_model(@game);
        }

        fn bankruptcy_check(ref self: ContractState, player: GamePlayer, amount_owed: u256) {
            let mut world = self.world_default();

            let net_worth = self.calculate_net_worth(player.clone());

            if net_worth > amount_owed {
                return; // Not bankrupt
            }

            // Get property at player's current position
            let game_id = player.game_id;
            let tile_pos = player.position;
            let property: Property = self.get_property(tile_pos, game_id);

            // If no owner or already owned by the player, do nothing
            if property.owner == get_contract_address() || property.owner == player.address {
                println!("No valid new owner for bankrupt transfer");
                return;
            }

            // Transfer properties
            let mut i = 0;
            let props_len = player.properties_owned.len();
            while i < props_len {
                let prop_id = *player.properties_owned.at(i);
                let mut prop: Property = self.get_property(prop_id, game_id);
                prop.owner = property.owner;
                world.write_model(@prop);
                i += 1;
            };

            // Clear player's balance and properties
            let mut updated_player = player.clone();
            updated_player.balance = 0;
            updated_player.properties_owned = array![];
            world.write_model(@updated_player);

            println!(
                "Player {:?} is bankrupt. Assets transferred to {:?}",
                player.address,
                property.owner,
            );
        }

        fn vote_to_kick_player(
            ref self: ContractState, game_id: u256, target_player: ContractAddress,
        ) {
            let mut world = self.world_default();
            let caller = get_caller_address();

            // Ensure caller is not voting for himself
            assert!(caller != target_player, "You can't vote to kick yourself");

            // Load target and caller players
            let mut target: GamePlayer = world.read_model((target_player, game_id));
            let caller_player: GamePlayer = world.read_model((caller, game_id));

            // Ensure both are in the same game
            assert!(target.game_id == game_id, "Not same game");

            // Increase strike (can also implement vote tracking to prevent multiple votes)
            target.strikes += 1;

            // Save updated target player
            world.write_model(@target);

            // Count total players
            let game: Game = world.read_model(game_id);
            let total_players: u8 = game.number_of_players;
            let strike_percent = (target.strikes * 100) / total_players;

            // Kick if strikes >= 70%
            if strike_percent >= 70 {
                // Transfer all properties to the bank
                let bank = get_contract_address();
                let mut i = 0;
                while i < target.properties_owned.len() {
                    let prop_id = *target.properties_owned.at(i);
                    let mut property: Property = world.read_model((prop_id, game_id));
                    property.owner = bank;
                    world.write_model(@property);
                    i += 1;
                };

                // Clear player data
                target.properties_owned = array![];
                target.balance = 0;
                target.strikes = 0;
                // target.has_left = true;

                // Save updated player
                world.write_model(@target);
            }
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


        fn generate_board_tiles(ref self: ContractState, game_id: u256) {
            let mut world = self.world_default();
            let contract_address = get_contract_address();
            let bank: GamePlayer = world.read_model((contract_address, game_id));

            self
                .generate_properties(
                    0,
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
                    bank.address,
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
                    bank.address,
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
                    bank.address,
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
                    bank.address,
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
                    bank.address,
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
                    bank.address,
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
                    bank.address,
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

            match property.property_type {
                PropertyType::CommunityChest => {
                    println!(
                        "Player {:?} landed on Community Chest '{}'. Drawing a card...",
                        caller,
                        property.name,
                    );
                    // you could call self.draw_community_chest_card() here
                },
                PropertyType::Chance => {
                    println!(
                        "Player {:?} landed on Chance '{}'. Drawing a card...",
                        caller,
                        property.name,
                    );
                    // you could call self.draw_chance_card() here
                },
                _ => {
                    if property.owner == bank_address {
                        println!(
                            "This property '{}' is owned by the bank. It costs {}.",
                            property.name,
                            property.cost_of_property,
                        );
                    } else if property.owner != caller {
                        // Owned by someone else
                        let owner_railroads = self
                            .count_owner_railroads(property.owner, property.game_id);
                        let owner_utilities = self
                            .count_owner_utilities(property.owner, property.game_id);

                        let rent_amount = property
                            .get_rent_amount(
                                owner_railroads, owner_utilities, player.dice_rolled.into(),
                            );

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
                        // Player owns this property
                        println!(
                            "Player {:?} landed on their own property '{}'.", caller, property.name,
                        );
                    }
                },
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

        fn create_trade_id(ref self: ContractState) -> u256 {
            let mut world = self.world_default();
            let mut trade_counter: TradeCounter = world.read_model('v0');
            let new_val = trade_counter.current_val + 1;
            trade_counter.current_val = new_val;
            world.write_model(@trade_counter);
            new_val
        }


        fn property_transfer(
            ref self: ContractState,
            mut initiator_property: Property,
            mut initiator: GamePlayer,
            mut receiver: GamePlayer,
        ) -> (GamePlayer, GamePlayer, Property) {
            let mut world = self.world_default();
            assert(initiator_property.game_id == receiver.game_id, 'Not in the same Game');

            // Update property owner
            initiator_property.owner = receiver.address;

            // Build new properties array excluding the transferred property
            let mut new_properties = array![];
            let mut i = 0;
            while (i < initiator.properties_owned.len()) {
                let prop_id = *initiator.properties_owned[i];
                let prop = self.get_property(prop_id, initiator.game_id);
                if prop.id != initiator_property.id {
                    new_properties.append(prop.id);
                }
                i += 1;
            };
            initiator.properties_owned = new_properties;

            // Add property to receiver's properties
            receiver.properties_owned.append(initiator_property.id);

            world.write_model(@initiator);
            world.write_model(@receiver);
            world.write_model(@initiator_property);

            (initiator, receiver, initiator_property)
        }
    }
}
