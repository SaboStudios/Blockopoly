#[cfg(test)]
mod tests {
    use dojo_cairo_test::WorldStorageTestTrait;
    use dojo::model::{ModelStorage, ModelStorageTest};
    use dojo::world::WorldStorageTrait;
    use dojo_cairo_test::{
        spawn_test_world, NamespaceDef, TestResource, ContractDefTrait, ContractDef,
    };

    use dojo_starter::systems::actions::{actions};

    use dojo_starter::interfaces::IActions::{IActionsDispatcher, IActionsDispatcherTrait};


    use dojo_starter::model::game_model::{
        Game, m_Game, GameType, GameStatus, GameCounter, m_GameCounter, GameBalance, m_GameBalance,
    };

    use dojo_starter::model::player_model::{
        Player, m_Player, UsernameToAddress, m_UsernameToAddress, AddressToUsername,
        m_AddressToUsername, IsRegistered, m_IsRegistered,
    };

    use dojo_starter::model::game_player_model::{GamePlayer, m_GamePlayer, PlayerSymbol};

    use dojo_starter::model::property_model::{
        Property, m_Property, IdToProperty, m_IdToProperty, PropertyToId, m_PropertyToId,
        TradeCounter, m_TradeCounter, TradeOfferDetails, m_TradeOfferDetails, TradeOffer,
        TradeStatus,
    };

    use starknet::{testing, get_caller_address, contract_address_const};

    fn namespace_def() -> NamespaceDef {
        let ndef = NamespaceDef {
            namespace: "blockopoly",
            resources: [
                TestResource::Model(m_Player::TEST_CLASS_HASH),
                TestResource::Model(m_Property::TEST_CLASS_HASH),
                TestResource::Model(m_IdToProperty::TEST_CLASS_HASH),
                TestResource::Model(m_PropertyToId::TEST_CLASS_HASH),
                TestResource::Model(m_Game::TEST_CLASS_HASH),
                TestResource::Model(m_GameBalance::TEST_CLASS_HASH),
                TestResource::Model(m_UsernameToAddress::TEST_CLASS_HASH),
                TestResource::Model(m_AddressToUsername::TEST_CLASS_HASH),
                TestResource::Model(m_IsRegistered::TEST_CLASS_HASH),
                TestResource::Model(m_GameCounter::TEST_CLASS_HASH),
                TestResource::Model(m_GamePlayer::TEST_CLASS_HASH),
                TestResource::Model(m_TradeCounter::TEST_CLASS_HASH),
                TestResource::Model(m_TradeOfferDetails::TEST_CLASS_HASH),
                TestResource::Event(actions::e_PlayerCreated::TEST_CLASS_HASH),
                TestResource::Event(actions::e_GameCreated::TEST_CLASS_HASH),
                TestResource::Event(actions::e_PlayerJoined::TEST_CLASS_HASH),
                TestResource::Event(actions::e_GameStarted::TEST_CLASS_HASH),
                TestResource::Contract(actions::TEST_CLASS_HASH),
            ]
                .span(),
        };

        ndef
    }

    fn contract_defs() -> Span<ContractDef> {
        [
            ContractDefTrait::new(@"blockopoly", @"actions")
                .with_writer_of([dojo::utils::bytearray_hash(@"blockopoly")].span())
        ]
            .span()
    }


    #[test]
    fn test_roll_dice() {
        let ndef = namespace_def();
        let mut world = spawn_test_world([ndef].span());
        world.sync_perms_and_inits(contract_defs());

        let (contract_address, _) = world.dns(@"actions").unwrap();
        let actions_system = IActionsDispatcher { contract_address };

        let (dice_1, dice_2) = actions_system.roll_dice();

        assert(dice_2 <= 6, 'incorrect roll');
        assert(dice_1 <= 6, 'incorrect roll');
        assert(dice_2 > 0, 'incorrect roll');
        assert(dice_1 > 0, 'incorrect roll');
    }

    #[test]
    fn test_player_registration() {
        let caller_1 = contract_address_const::<'aji'>();
        let username = 'Aji';

        let ndef = namespace_def();
        let mut world = spawn_test_world([ndef].span());
        world.sync_perms_and_inits(contract_defs());

        let (contract_address, _) = world.dns(@"actions").unwrap();
        let actions_system = IActionsDispatcher { contract_address };

        testing::set_contract_address(caller_1);
        actions_system.register_new_player(username);

        let player: Player = actions_system.retrieve_player(caller_1);

        assert(player.address == caller_1, 'incorrect address');
        assert(player.username == 'Aji', 'incorrect username');
    }
    #[test]
    #[should_panic]
    fn test_player_registration_same_user_name() {
        let caller_1 = contract_address_const::<'aji'>();
        let caller_2 = contract_address_const::<'dreamer'>();
        let username = 'Aji';

        let ndef = namespace_def();
        let mut world = spawn_test_world([ndef].span());
        world.sync_perms_and_inits(contract_defs());

        let (contract_address, _) = world.dns(@"actions").unwrap();
        let actions_system = IActionsDispatcher { contract_address };

        testing::set_contract_address(caller_1);
        actions_system.register_new_player(username);

        testing::set_contract_address(caller_2);
        actions_system.register_new_player(username);
    }

    #[test]
    #[should_panic]
    fn test_player_registration_same_user_tries_to_register_twice_with_different_username() {
        let caller_1 = contract_address_const::<'aji'>();
        let username = 'Aji';
        let username1 = 'Ajidokwu';

        let ndef = namespace_def();
        let mut world = spawn_test_world([ndef].span());
        world.sync_perms_and_inits(contract_defs());

        let (contract_address, _) = world.dns(@"actions").unwrap();
        let actions_system = IActionsDispatcher { contract_address };

        testing::set_contract_address(caller_1);
        actions_system.register_new_player(username);

        testing::set_contract_address(caller_1);
        actions_system.register_new_player(username1);
    }
    #[test]
    #[should_panic]
    fn test_player_registration_same_user_tries_to_register_twice_with_the_same_username() {
        let caller_1 = contract_address_const::<'aji'>();
        let username = 'Aji';
        let username1 = 'Aji';

        let ndef = namespace_def();
        let mut world = spawn_test_world([ndef].span());
        world.sync_perms_and_inits(contract_defs());

        let (contract_address, _) = world.dns(@"actions").unwrap();
        let actions_system = IActionsDispatcher { contract_address };

        testing::set_contract_address(caller_1);
        actions_system.register_new_player(username);

        testing::set_contract_address(caller_1);
        actions_system.register_new_player(username1);
    }


    #[test]
    fn test_create_game() {
        let caller_1 = contract_address_const::<'aji'>();
        let username = 'Ajidokwu';

        let ndef = namespace_def();
        let mut world = spawn_test_world([ndef].span());
        world.sync_perms_and_inits(contract_defs());

        let (contract_address, _) = world.dns(@"actions").unwrap();
        let actions_system = IActionsDispatcher { contract_address };

        testing::set_contract_address(caller_1);
        actions_system.register_new_player(username);

        testing::set_contract_address(caller_1);
        let game_id = actions_system.create_new_game(GameType::PublicGame, PlayerSymbol::Hat, 4);
        assert(game_id == 1, 'Wrong game id');

        let game: Game = actions_system.retrieve_game(game_id);
        assert(game.created_by == username, 'Wrong game id');
    }

    #[test]
    fn test_create_two_games() {
        let caller_1 = contract_address_const::<'aji'>();

        let username = 'Ajidokwu';

        let ndef = namespace_def();
        let mut world = spawn_test_world([ndef].span());
        world.sync_perms_and_inits(contract_defs());

        let (contract_address, _) = world.dns(@"actions").unwrap();
        let actions_system = IActionsDispatcher { contract_address };

        testing::set_contract_address(caller_1);
        actions_system.register_new_player(username);

        testing::set_contract_address(caller_1);
        let _game_id = actions_system.create_new_game(GameType::PublicGame, PlayerSymbol::Hat, 4);

        testing::set_contract_address(caller_1);
        let game_id_1 = actions_system.create_new_game(GameType::PublicGame, PlayerSymbol::Hat, 4);
        assert(game_id_1 == 2, 'Wrong game id');
    }

    #[test]
    #[should_panic]
    fn test_create_game_unregistered_player() {
        let caller_1 = contract_address_const::<'aji'>();

        let ndef = namespace_def();
        let mut world = spawn_test_world([ndef].span());
        world.sync_perms_and_inits(contract_defs());

        let (contract_address, _) = world.dns(@"actions").unwrap();
        let actions_system = IActionsDispatcher { contract_address };

        testing::set_contract_address(caller_1);
        let game_id = actions_system.create_new_game(GameType::PublicGame, PlayerSymbol::Hat, 4);
        assert(game_id == 1, 'Wrong game id');
    }

    #[test]
    fn test_join_game() {
        let caller_1 = contract_address_const::<'aji'>();
        let caller_2 = contract_address_const::<'john'>();
        let username = 'Ajidokwu';
        let username_1 = 'John';

        let ndef = namespace_def();
        let mut world = spawn_test_world([ndef].span());
        world.sync_perms_and_inits(contract_defs());

        let (contract_address, _) = world.dns(@"actions").unwrap();
        let actions_system = IActionsDispatcher { contract_address };

        testing::set_contract_address(caller_2);
        actions_system.register_new_player(username_1);

        testing::set_contract_address(caller_1);
        actions_system.register_new_player(username);

        testing::set_contract_address(caller_1);
        actions_system.create_new_game(GameType::PublicGame, PlayerSymbol::Hat, 4);

        testing::set_contract_address(caller_2);
        actions_system.join_game(PlayerSymbol::Dog, 1);
    }

    #[test]
    #[should_panic]
    fn test_join_game_with_same_symbol_as_creator() {
        let caller_1 = contract_address_const::<'aji'>();
        let caller_2 = contract_address_const::<'john'>();
        let username = 'Ajidokwu';
        let username_1 = 'John';

        let ndef = namespace_def();
        let mut world = spawn_test_world([ndef].span());
        world.sync_perms_and_inits(contract_defs());

        let (contract_address, _) = world.dns(@"actions").unwrap();
        let actions_system = IActionsDispatcher { contract_address };

        testing::set_contract_address(caller_2);
        actions_system.register_new_player(username_1);

        testing::set_contract_address(caller_1);
        actions_system.register_new_player(username);

        testing::set_contract_address(caller_1);
        actions_system.create_new_game(GameType::PublicGame, PlayerSymbol::Hat, 4);

        testing::set_contract_address(caller_2);
        actions_system.join_game(PlayerSymbol::Hat, 1);
    }

    #[test]
    #[should_panic]
    fn test_join_yet_to_be_created_game_() {
        let caller_1 = contract_address_const::<'aji'>();
        let caller_2 = contract_address_const::<'john'>();
        let username = 'Ajidokwu';
        let username_1 = 'John';

        let ndef = namespace_def();
        let mut world = spawn_test_world([ndef].span());
        world.sync_perms_and_inits(contract_defs());

        let (contract_address, _) = world.dns(@"actions").unwrap();
        let actions_system = IActionsDispatcher { contract_address };

        testing::set_contract_address(caller_2);
        actions_system.register_new_player(username_1);

        testing::set_contract_address(caller_1);
        actions_system.register_new_player(username);

        testing::set_contract_address(caller_2);
        actions_system.join_game(PlayerSymbol::Hat, 1);
    }


    #[test]
    fn test_each_player_gets_starting_balance() {
        let caller_1 = contract_address_const::<'aji'>();
        let caller_2 = contract_address_const::<'collins'>();
        let caller_3 = contract_address_const::<'jerry'>();
        let caller_4 = contract_address_const::<'aliyu'>();
        let username = 'Ajidokwu';
        let username_1 = 'Collins';
        let username_2 = 'Jerry';
        let username_3 = 'Aliyu';

        let ndef = namespace_def();
        let mut world = spawn_test_world([ndef].span());
        world.sync_perms_and_inits(contract_defs());

        let (contract_address, _) = world.dns(@"actions").unwrap();
        let actions_system = IActionsDispatcher { contract_address };

        testing::set_contract_address(caller_2);
        actions_system.register_new_player(username_1);

        testing::set_contract_address(caller_1);
        actions_system.register_new_player(username);

        testing::set_contract_address(caller_3);
        actions_system.register_new_player(username_2);

        testing::set_contract_address(caller_4);
        actions_system.register_new_player(username_3);

        testing::set_contract_address(caller_1);
        actions_system.create_new_game(GameType::PublicGame, PlayerSymbol::Hat, 4);

        testing::set_contract_address(caller_2);
        actions_system.join_game(PlayerSymbol::Dog, 1);

        testing::set_contract_address(caller_3);
        actions_system.join_game(PlayerSymbol::Car, 1);

        testing::set_contract_address(caller_4);
        actions_system.join_game(PlayerSymbol::Iron, 1);

        testing::set_contract_address(caller_1);
        let started = actions_system.start_game(1);
        assert(started, 'Game start fail');

        let game_p = actions_system.retrieve_game(1);

        testing::set_contract_address(caller_1);
        actions_system.move_player(1, 5);

        // print_players_positions();
        let aji = actions_system.retrieve_game_player(caller_1, 1);
        let collins = actions_system.retrieve_game_player(caller_2, 1);
        let jerry = actions_system.retrieve_game_player(caller_3, 1);
        let aliyu = actions_system.retrieve_game_player(caller_4, 1);

        assert(aji.balance == 1500, 'Aji bal fail');
        assert(collins.balance == 1500, 'Collins bal fail');
        assert(jerry.balance == 1500, 'jerry bal fail');
        assert(aliyu.balance == 1500, 'aliyu bal fail');
    }
    #[test]
    fn test_generate_properties() {
        let caller_1 = contract_address_const::<'aji'>();
        let caller_2 = contract_address_const::<'collins'>();
        let caller_3 = contract_address_const::<'jerry'>();
        let caller_4 = contract_address_const::<'aliyu'>();
        let username = 'Ajidokwu';
        let username_1 = 'Collins';
        let username_2 = 'Jerry';
        let username_3 = 'Aliyu';

        let ndef = namespace_def();
        let mut world = spawn_test_world([ndef].span());
        world.sync_perms_and_inits(contract_defs());

        let (contract_address, _) = world.dns(@"actions").unwrap();
        let actions_system = IActionsDispatcher { contract_address };

        testing::set_contract_address(caller_2);
        actions_system.register_new_player(username_1);

        testing::set_contract_address(caller_1);
        actions_system.register_new_player(username);

        testing::set_contract_address(caller_3);
        actions_system.register_new_player(username_2);

        testing::set_contract_address(caller_4);
        actions_system.register_new_player(username_3);

        testing::set_contract_address(caller_1);
        actions_system.create_new_game(GameType::PublicGame, PlayerSymbol::Hat, 4);

        testing::set_contract_address(caller_2);
        actions_system.join_game(PlayerSymbol::Dog, 1);

        testing::set_contract_address(caller_3);
        actions_system.join_game(PlayerSymbol::Car, 1);

        testing::set_contract_address(caller_4);
        actions_system.join_game(PlayerSymbol::Iron, 1);

        testing::set_contract_address(caller_1);
        let started = actions_system.start_game(1);
        assert(started, 'Game start fail');

        let game_p = actions_system.retrieve_game(1);

        testing::set_contract_address(caller_1);
        actions_system.move_player(1, 5);
        let _property = actions_system.get_property(39, 1);
    }

    #[test]
    fn test_move_handle_landing_buy_property_from_bank() {
        let caller_1 = contract_address_const::<'aji'>();
        let caller_2 = contract_address_const::<'collins'>();
        let caller_3 = contract_address_const::<'jerry'>();
        let caller_4 = contract_address_const::<'aliyu'>();
        let username = 'Ajidokwu';
        let username_1 = 'Collins';
        let username_2 = 'Jerry';
        let username_3 = 'Aliyu';

        let ndef = namespace_def();
        let mut world = spawn_test_world([ndef].span());
        world.sync_perms_and_inits(contract_defs());

        let (contract_address, _) = world.dns(@"actions").unwrap();
        let actions_system = IActionsDispatcher { contract_address };

        testing::set_contract_address(caller_2);
        actions_system.register_new_player(username_1);

        testing::set_contract_address(caller_1);
        actions_system.register_new_player(username);

        testing::set_contract_address(caller_3);
        actions_system.register_new_player(username_2);

        testing::set_contract_address(caller_4);
        actions_system.register_new_player(username_3);

        testing::set_contract_address(caller_1);
        actions_system.create_new_game(GameType::PublicGame, PlayerSymbol::Hat, 4);

        testing::set_contract_address(caller_2);
        actions_system.join_game(PlayerSymbol::Dog, 1);

        testing::set_contract_address(caller_3);
        actions_system.join_game(PlayerSymbol::Car, 1);

        testing::set_contract_address(caller_4);
        actions_system.join_game(PlayerSymbol::Iron, 1);

        testing::set_contract_address(caller_1);
        let started = actions_system.start_game(1);
        assert(started, 'Game start fail');

        let game_p = actions_system.retrieve_game(1);

        testing::set_contract_address(caller_1);
        actions_system.move_player(1, 5);
        let ppt = actions_system.get_property(5, 1);

        let buyppt = actions_system.buy_property(ppt);

        assert(buyppt, 'Buy property failed');
        let aji = actions_system.retrieve_game_player(caller_1, 1);

        assert(aji.balance == 1300, 'debit failed');
        assert(*aji.properties_owned[0] == ppt.id, 'ownership transfer failed');
    }

    #[test]
    fn test_pay_rent() {
        let caller_1 = contract_address_const::<'aji'>();
        let caller_2 = contract_address_const::<'collins'>();
        let caller_3 = contract_address_const::<'jerry'>();
        let caller_4 = contract_address_const::<'aliyu'>();
        let username = 'Ajidokwu';
        let username_1 = 'Collins';
        let username_2 = 'Jerry';
        let username_3 = 'Aliyu';

        let ndef = namespace_def();
        let mut world = spawn_test_world([ndef].span());
        world.sync_perms_and_inits(contract_defs());

        let (contract_address, _) = world.dns(@"actions").unwrap();
        let actions_system = IActionsDispatcher { contract_address };

        testing::set_contract_address(caller_2);
        actions_system.register_new_player(username_1);

        testing::set_contract_address(caller_1);
        actions_system.register_new_player(username);

        testing::set_contract_address(caller_3);
        actions_system.register_new_player(username_2);

        testing::set_contract_address(caller_4);
        actions_system.register_new_player(username_3);

        testing::set_contract_address(caller_1);
        actions_system.create_new_game(GameType::PublicGame, PlayerSymbol::Hat, 4);

        testing::set_contract_address(caller_2);
        actions_system.join_game(PlayerSymbol::Dog, 1);

        testing::set_contract_address(caller_3);
        actions_system.join_game(PlayerSymbol::Car, 1);

        testing::set_contract_address(caller_4);
        actions_system.join_game(PlayerSymbol::Iron, 1);

        testing::set_contract_address(caller_1);
        let started = actions_system.start_game(1);
        assert(started, 'Game start fail');

        testing::set_contract_address(caller_1);
        actions_system.move_player(1, 5);
        let ppt = actions_system.get_property(5, 1);
        actions_system.buy_property(ppt);

        testing::set_contract_address(caller_2);
        actions_system.move_player(1, 5);
        let ppt1 = actions_system.get_property(5, 1);

        testing::set_contract_address(caller_2);
        actions_system.pay_rent(ppt1);

        let aji = actions_system.retrieve_game_player(caller_1, 1);
        assert(aji.balance == 1325, 'rent addition failed');

        let collins = actions_system.retrieve_game_player(caller_2, 1);
        assert(collins.balance == 1475, 'rent deduction failed');
    }

    #[test]
    #[available_gas(9223372036854775807)]
    fn test_rent_on_all_railways_owned_by_one_player() {
        let caller_1 = contract_address_const::<'aji'>();
        let caller_2 = contract_address_const::<'collins'>();

        let username = 'Ajidokwu';
        let username_1 = 'Collins';

        let ndef = namespace_def();
        let mut world = spawn_test_world([ndef].span());
        world.sync_perms_and_inits(contract_defs());

        let (contract_address, _) = world.dns(@"actions").unwrap();
        let actions_system = IActionsDispatcher { contract_address };

        testing::set_contract_address(caller_2);
        actions_system.register_new_player(username_1);

        testing::set_contract_address(caller_1);
        actions_system.register_new_player(username);

        testing::set_contract_address(caller_1);
        actions_system.create_new_game(GameType::PublicGame, PlayerSymbol::Hat, 2);

        testing::set_contract_address(caller_2);
        actions_system.join_game(PlayerSymbol::Dog, 1);

        testing::set_contract_address(caller_1);
        let started = actions_system.start_game(1);
        assert(started, 'Game start fail');

        testing::set_contract_address(caller_1);
        actions_system.move_player(1, 5);
        let mut property = actions_system.get_property(5, 1);
        actions_system.buy_property(property);

        testing::set_contract_address(caller_2);
        actions_system.move_player(1, 5);
        property = actions_system.get_property(5, 1);

        testing::set_contract_address(caller_2);
        actions_system.pay_rent(property);

        // Assertion after one railway
        let mut aji = actions_system.retrieve_game_player(caller_1, 1);
        assert(aji.balance == 1325, 'rent addition failed');

        let mut collins = actions_system.retrieve_game_player(caller_2, 1);
        assert(collins.balance == 1475, 'rent deduction failed');

        testing::set_contract_address(caller_1);
        actions_system.move_player(1, 10);
        property = actions_system.get_property(15, 1);
        actions_system.buy_property(property);
        testing::set_contract_address(caller_2);
        actions_system.move_player(1, 10);
        property = actions_system.get_property(15, 1);
        actions_system.pay_rent(property);

        // Assertion after two railways
        aji = actions_system.retrieve_game_player(caller_1, 1);
        assert(aji.balance == 1175, 'rent addition failed');

        collins = actions_system.retrieve_game_player(caller_2, 1);
        assert(collins.balance == 1425, 'rent deduction failed');

        testing::set_contract_address(caller_1);
        actions_system.move_player(1, 10);
        property = actions_system.get_property(25, 1);
        actions_system.buy_property(property);
        testing::set_contract_address(caller_2);
        actions_system.move_player(1, 10);
        property = actions_system.get_property(25, 1);
        actions_system.pay_rent(property);

        // Assertion after three railways
        aji = actions_system.retrieve_game_player(caller_1, 1);
        assert(aji.balance == 1075, 'rent addition failed');

        collins = actions_system.retrieve_game_player(caller_2, 1);
        assert(collins.balance == 1325, 'rent deduction failed');

        testing::set_contract_address(caller_1);
        actions_system.move_player(1, 10);
        property = actions_system.get_property(35, 1);
        actions_system.buy_property(property);
        testing::set_contract_address(caller_2);
        actions_system.move_player(1, 10);
        property = actions_system.get_property(35, 1);
        actions_system.pay_rent(property);

        // Assertion after four railways
        aji = actions_system.retrieve_game_player(caller_1, 1);
        assert(aji.balance == 1075, 'rent addition failed');

        collins = actions_system.retrieve_game_player(caller_2, 1);
        assert(collins.balance == 1125, 'rent deduction failed');
    }

    #[test]
    fn test_pay_on_two_utilities() {
        let caller_1 = contract_address_const::<'aji'>();
        let caller_2 = contract_address_const::<'collins'>();
        let username = 'Ajidokwu';
        let username_1 = 'Collins';

        let ndef = namespace_def();
        let mut world = spawn_test_world([ndef].span());
        world.sync_perms_and_inits(contract_defs());

        let (contract_address, _) = world.dns(@"actions").unwrap();
        let actions_system = IActionsDispatcher { contract_address };

        testing::set_contract_address(caller_2);
        actions_system.register_new_player(username_1);

        testing::set_contract_address(caller_1);
        actions_system.register_new_player(username);

        testing::set_contract_address(caller_1);
        actions_system.create_new_game(GameType::PublicGame, PlayerSymbol::Hat, 2);

        testing::set_contract_address(caller_2);
        actions_system.join_game(PlayerSymbol::Dog, 1);

        testing::set_contract_address(caller_1);
        let started = actions_system.start_game(1);
        assert(started, 'Game start fail');

        testing::set_contract_address(caller_1);
        actions_system.move_player(1, 12);
        let mut property = actions_system.get_property(12, 1);
        actions_system.buy_property(property);

        testing::set_contract_address(caller_2);
        actions_system.move_player(1, 12);
        property = actions_system.get_property(12, 1);
        actions_system.pay_rent(property);

        // Assertion after one utility
        let mut aji = actions_system.retrieve_game_player(caller_1, 1);
        assert(aji.balance == 1398, 'rent addition failed');

        let mut collins = actions_system.retrieve_game_player(caller_2, 1);
        assert(collins.balance == 1452, 'rent deduction failed');

        testing::set_contract_address(caller_1);
        actions_system.move_player(1, 16);
        property = actions_system.get_property(28, 1);
        actions_system.buy_property(property);
        testing::set_contract_address(caller_2);
        actions_system.move_player(1, 16);
        property = actions_system.get_property(28, 1);
        actions_system.pay_rent(property);

        // Assertion after two utility
        aji = actions_system.retrieve_game_player(caller_1, 1);
        assert(aji.balance == 1408, 'rent addition failed');

        collins = actions_system.retrieve_game_player(caller_2, 1);
        assert(collins.balance == 1292, 'rent deduction failed');
    }
    #[test]
    fn test_get_200_pass_go() {
        let caller_1 = contract_address_const::<'aji'>();
        let caller_2 = contract_address_const::<'collins'>();
        let caller_3 = contract_address_const::<'jerry'>();
        let caller_4 = contract_address_const::<'aliyu'>();
        let username = 'Ajidokwu';
        let username_1 = 'Collins';
        let username_2 = 'Jerry';
        let username_3 = 'Aliyu';

        let ndef = namespace_def();
        let mut world = spawn_test_world([ndef].span());
        world.sync_perms_and_inits(contract_defs());

        let (contract_address, _) = world.dns(@"actions").unwrap();
        let actions_system = IActionsDispatcher { contract_address };

        testing::set_contract_address(caller_2);
        actions_system.register_new_player(username_1);

        testing::set_contract_address(caller_1);
        actions_system.register_new_player(username);

        testing::set_contract_address(caller_3);
        actions_system.register_new_player(username_2);

        testing::set_contract_address(caller_4);
        actions_system.register_new_player(username_3);

        testing::set_contract_address(caller_1);
        actions_system.create_new_game(GameType::PublicGame, PlayerSymbol::Hat, 4);

        testing::set_contract_address(caller_2);
        actions_system.join_game(PlayerSymbol::Dog, 1);

        testing::set_contract_address(caller_3);
        actions_system.join_game(PlayerSymbol::Car, 1);

        testing::set_contract_address(caller_4);
        actions_system.join_game(PlayerSymbol::Iron, 1);

        testing::set_contract_address(caller_1);
        let started = actions_system.start_game(1);
        assert(started, 'Game start fail');

        testing::set_contract_address(caller_1);
        actions_system.move_player(1, 5);
        let ppt = actions_system.get_property(5, 1);
        actions_system.buy_property(ppt);

        testing::set_contract_address(caller_2);
        actions_system.move_player(1, 49);

        let collins = actions_system.retrieve_game_player(caller_2, 1);

        assert(collins.balance == 1700, '200 on go failed');
    }

    #[test]
    fn test_mortgage_and_unmortgage() {
        let caller_1 = contract_address_const::<'aji'>();
        let caller_2 = contract_address_const::<'collins'>();
        let caller_3 = contract_address_const::<'jerry'>();
        let caller_4 = contract_address_const::<'aliyu'>();
        let username = 'Ajidokwu';
        let username_1 = 'Collins';
        let username_2 = 'Jerry';
        let username_3 = 'Aliyu';

        let ndef = namespace_def();
        let mut world = spawn_test_world([ndef].span());
        world.sync_perms_and_inits(contract_defs());

        let (contract_address, _) = world.dns(@"actions").unwrap();
        let actions_system = IActionsDispatcher { contract_address };

        testing::set_contract_address(caller_2);
        actions_system.register_new_player(username_1);

        testing::set_contract_address(caller_1);
        actions_system.register_new_player(username);

        testing::set_contract_address(caller_3);
        actions_system.register_new_player(username_2);

        testing::set_contract_address(caller_4);
        actions_system.register_new_player(username_3);

        testing::set_contract_address(caller_1);
        actions_system.create_new_game(GameType::PublicGame, PlayerSymbol::Hat, 4);

        testing::set_contract_address(caller_2);
        actions_system.join_game(PlayerSymbol::Dog, 1);

        testing::set_contract_address(caller_3);
        actions_system.join_game(PlayerSymbol::Car, 1);

        testing::set_contract_address(caller_4);
        actions_system.join_game(PlayerSymbol::Iron, 1);

        testing::set_contract_address(caller_1);
        let started = actions_system.start_game(1);
        assert(started, 'Game start fail');

        testing::set_contract_address(caller_1);
        actions_system.move_player(1, 5);
        let ppt = actions_system.get_property(5, 1);
        actions_system.buy_property(ppt);

        let ppt1 = actions_system.get_property(5, 1);
        actions_system.mortgage_property(ppt1);

        let ppt11 = actions_system.get_property(5, 1);

        let aji = actions_system.retrieve_game_player(caller_1, 1);
        assert(aji.balance == 1400, 'morgage inbursement failed');
        assert(ppt11.is_mortgaged, 'morgage failed');

        let ppt2 = actions_system.get_property(5, 1);
        actions_system.unmortgage_property(ppt2);

        let ppt21 = actions_system.get_property(5, 1);

        let aji1 = actions_system.retrieve_game_player(caller_1, 1);

        assert(aji1.balance == 1290, 'morgage inbursement failed');
        assert(!ppt21.is_mortgaged, 'morgage failed');

        assert(ppt11.is_mortgaged, 'morgage failed')
    }

    #[test]
    fn test_buy_houses_and_hotel_game() {
        let caller_1 = contract_address_const::<'aji'>();
        let caller_2 = contract_address_const::<'collins'>();
        let caller_3 = contract_address_const::<'jerry'>();
        let caller_4 = contract_address_const::<'aliyu'>();
        let username = 'Ajidokwu';
        let username_1 = 'Collins';
        let username_2 = 'Jerry';
        let username_3 = 'Aliyu';

        let ndef = namespace_def();
        let mut world = spawn_test_world([ndef].span());
        world.sync_perms_and_inits(contract_defs());

        let (contract_address, _) = world.dns(@"actions").unwrap();
        let actions_system = IActionsDispatcher { contract_address };

        testing::set_contract_address(caller_2);
        actions_system.register_new_player(username_1);

        testing::set_contract_address(caller_1);
        actions_system.register_new_player(username);

        testing::set_contract_address(caller_3);
        actions_system.register_new_player(username_2);

        testing::set_contract_address(caller_4);
        actions_system.register_new_player(username_3);

        testing::set_contract_address(caller_1);
        actions_system.create_new_game(GameType::PublicGame, PlayerSymbol::Hat, 4);

        testing::set_contract_address(caller_2);
        actions_system.join_game(PlayerSymbol::Dog, 1);

        testing::set_contract_address(caller_3);
        actions_system.join_game(PlayerSymbol::Car, 1);

        testing::set_contract_address(caller_4);
        actions_system.join_game(PlayerSymbol::Iron, 1);

        testing::set_contract_address(caller_1);
        let started = actions_system.start_game(1);
        assert(started, 'Game start fail');

        testing::set_contract_address(caller_1);
        actions_system.move_player(1, 1);
        let mut property = actions_system.get_property(1, 1);
        actions_system.buy_property(property);

        testing::set_contract_address(caller_2);
        actions_system.move_player(1, 12);

        let mut game = actions_system.retrieve_game(1);
        actions_system.finish_turn(game);

        testing::set_contract_address(caller_3);
        actions_system.move_player(1, 8);
        game = actions_system.retrieve_game(1);
        actions_system.finish_turn(game);

        testing::set_contract_address(caller_4);
        actions_system.move_player(1, 8);
        game = actions_system.retrieve_game(1);
        actions_system.finish_turn(game);

        testing::set_contract_address(caller_1);
        actions_system.move_player(1, 2);
        property = actions_system.get_property(3, 1);
        actions_system.buy_property(property);

        testing::set_contract_address(caller_2);
        actions_system.move_player(1, 12);

        game = actions_system.retrieve_game(1);
        actions_system.finish_turn(game);

        testing::set_contract_address(caller_3);
        actions_system.move_player(1, 8);
        game = actions_system.retrieve_game(1);
        actions_system.finish_turn(game);

        testing::set_contract_address(caller_4);
        actions_system.move_player(1, 8);
        game = actions_system.retrieve_game(1);
        actions_system.finish_turn(game);

        testing::set_contract_address(caller_1);
        property = actions_system.get_property(3, 1);
        actions_system.buy_house_or_hotel(property);

        property = actions_system.get_property(1, 1);
        actions_system.buy_house_or_hotel(property);

        property = actions_system.get_property(3, 1);
        actions_system.buy_house_or_hotel(property);

        property = actions_system.get_property(1, 1);
        actions_system.buy_house_or_hotel(property);

        property = actions_system.get_property(3, 1);
        actions_system.buy_house_or_hotel(property);

        property = actions_system.get_property(1, 1);
        actions_system.buy_house_or_hotel(property);

        property = actions_system.get_property(3, 1);
        actions_system.buy_house_or_hotel(property);

        property = actions_system.get_property(1, 1);
        actions_system.buy_house_or_hotel(property);

        property = actions_system.get_property(3, 1);
        actions_system.buy_house_or_hotel(property);

        property = actions_system.get_property(1, 1);
        let success = actions_system.buy_house_or_hotel(property);
        assert(success, 'house failed');
        property = actions_system.get_property(3, 1);
        assert(property.development == 5, 'dev correct');

        let aji = actions_system.retrieve_game_player(caller_1, 1);

        assert(aji.total_hotels_owned == 2, 'house count error');
        assert(aji.total_houses_owned == 8, 'house count error');
    }

    #[test]
    fn test_pay_rent_on_site_only() {
        let caller_1 = contract_address_const::<'aji'>();
        let caller_2 = contract_address_const::<'collins'>();
        let username = 'Ajidokwu';
        let username_1 = 'Collins';

        let ndef = namespace_def();
        let mut world = spawn_test_world([ndef].span());
        world.sync_perms_and_inits(contract_defs());

        let (contract_address, _) = world.dns(@"actions").unwrap();
        let actions_system = IActionsDispatcher { contract_address };

        testing::set_contract_address(caller_2);
        actions_system.register_new_player(username_1);

        testing::set_contract_address(caller_1);
        actions_system.register_new_player(username);

        testing::set_contract_address(caller_1);
        actions_system.create_new_game(GameType::PublicGame, PlayerSymbol::Hat, 2);

        testing::set_contract_address(caller_2);
        actions_system.join_game(PlayerSymbol::Dog, 1);

        testing::set_contract_address(caller_1);
        let started = actions_system.start_game(1);
        assert!(started, "Game start failed");

        // Player 1 buys property at position 4
        testing::set_contract_address(caller_1);
        actions_system.move_player(1, 1);
        let mut property = actions_system.get_property(1, 1);
        actions_system.buy_property(property);

        // Player 2 lands and pays rent
        testing::set_contract_address(caller_2);
        actions_system.move_player(1, 1);
        let landed_property = actions_system.get_property(1, 1);
        actions_system.pay_rent(landed_property);

        // Player 1 buys property at position 4
        testing::set_contract_address(caller_1);
        actions_system.move_player(1, 2);
        let mut property = actions_system.get_property(3, 1);
        actions_system.buy_property(property);

        // Player 2 lands and pays rent
        testing::set_contract_address(caller_2);
        actions_system.move_player(1, 2);
        let landed_property = actions_system.get_property(3, 1);
        actions_system.pay_rent(landed_property);

        let aji = actions_system.retrieve_game_player(caller_1, 1);
        let collins = actions_system.retrieve_game_player(caller_2, 1);
        assert(aji.balance == 1386, 'Aji bal error');
        assert(collins.balance == 1494, 'Collins bal error');
        assert(property.development == 0, 'development error');
    }

    #[test]
    fn test_pay_rent_on_one_house() {
        let caller_1 = contract_address_const::<'aji'>();
        let caller_2 = contract_address_const::<'collins'>();
        let username = 'Ajidokwu';
        let username_1 = 'Collins';

        let ndef = namespace_def();
        let mut world = spawn_test_world([ndef].span());
        world.sync_perms_and_inits(contract_defs());

        let (contract_address, _) = world.dns(@"actions").unwrap();
        let actions_system = IActionsDispatcher { contract_address };

        testing::set_contract_address(caller_2);
        actions_system.register_new_player(username_1);

        testing::set_contract_address(caller_1);
        actions_system.register_new_player(username);

        testing::set_contract_address(caller_1);
        actions_system.create_new_game(GameType::PublicGame, PlayerSymbol::Hat, 2);

        testing::set_contract_address(caller_2);
        actions_system.join_game(PlayerSymbol::Dog, 1);

        testing::set_contract_address(caller_1);
        let started = actions_system.start_game(1);
        assert!(started, "Game start failed");

        // SITE ONLY
        testing::set_contract_address(caller_1);
        actions_system.move_player(1, 1);
        let mut property = actions_system.get_property(1, 1);
        actions_system.buy_property(property);

        // Player 2 lands and pays rent
        testing::set_contract_address(caller_2);
        actions_system.move_player(1, 1);
        let landed_property = actions_system.get_property(1, 1);
        actions_system.pay_rent(landed_property);

        testing::set_contract_address(caller_1);
        actions_system.move_player(1, 2);
        let mut property = actions_system.get_property(3, 1);
        actions_system.buy_property(property);

        testing::set_contract_address(caller_2);
        actions_system.move_player(1, 2);
        let landed_property = actions_system.get_property(3, 1);
        actions_system.pay_rent(landed_property);

        // ONE HOUSE
        testing::set_contract_address(caller_1);
        actions_system.move_player(1, 40);
        let mut property = actions_system.get_property(3, 1);
        let mut property1 = actions_system.get_property(1, 1);
        actions_system.buy_house_or_hotel(property);
        actions_system.buy_house_or_hotel(property1);

        let mut game = actions_system.retrieve_game(1);
        actions_system.finish_turn(game);

        testing::set_contract_address(caller_2);
        actions_system.move_player(1, 40);
        let landed_property = actions_system.get_property(3, 1);
        actions_system.pay_rent(landed_property);

        property = actions_system.get_property(3, 1);
        property1 = actions_system.get_property(1, 1);
        let aji = actions_system.retrieve_game_player(caller_1, 1);
        let collins = actions_system.retrieve_game_player(caller_2, 1);

        assert(aji.balance == 1506, 'Aji bal error');
        assert(collins.balance == 1674, 'Collins bal error');
        assert(property.development == 1, 'Property dev error');
        assert(property1.development == 1, 'Property dev error');
    }

    #[test]
    #[available_gas(9223372036854775807)]
    fn test_pay_rent_on_two_houses() {
        let caller_1 = contract_address_const::<'aji'>();
        let caller_2 = contract_address_const::<'collins'>();
        let username = 'Ajidokwu';
        let username_1 = 'Collins';

        let ndef = namespace_def();
        let mut world = spawn_test_world([ndef].span());
        world.sync_perms_and_inits(contract_defs());

        let (contract_address, _) = world.dns(@"actions").unwrap();
        let actions_system = IActionsDispatcher { contract_address };

        testing::set_contract_address(caller_2);
        actions_system.register_new_player(username_1);

        testing::set_contract_address(caller_1);
        actions_system.register_new_player(username);

        testing::set_contract_address(caller_1);
        actions_system.create_new_game(GameType::PublicGame, PlayerSymbol::Hat, 2);

        testing::set_contract_address(caller_2);
        actions_system.join_game(PlayerSymbol::Dog, 1);

        testing::set_contract_address(caller_1);
        let started = actions_system.start_game(1);
        assert!(started, "Game start failed");

        // SITE ONLY

        testing::set_contract_address(caller_1);
        actions_system.move_player(1, 1);
        let mut property = actions_system.get_property(1, 1);
        actions_system.buy_property(property);

        // Player 2 lands and pays rent
        testing::set_contract_address(caller_2);
        actions_system.move_player(1, 1);
        let landed_property = actions_system.get_property(1, 1);
        actions_system.pay_rent(landed_property);

        testing::set_contract_address(caller_1);
        actions_system.move_player(1, 2);
        let mut property = actions_system.get_property(3, 1);
        actions_system.buy_property(property);

        testing::set_contract_address(caller_2);
        actions_system.move_player(1, 2);
        let landed_property = actions_system.get_property(3, 1);
        actions_system.pay_rent(landed_property);

        // ONE HOUSE

        testing::set_contract_address(caller_1);
        actions_system.move_player(1, 40);
        let mut property = actions_system.get_property(3, 1);
        let mut property1 = actions_system.get_property(1, 1);
        actions_system.buy_house_or_hotel(property);
        actions_system.buy_house_or_hotel(property1);

        property = actions_system.get_property(3, 1);
        property1 = actions_system.get_property(1, 1);

        actions_system.buy_house_or_hotel(property);
        actions_system.buy_house_or_hotel(property1);

        let mut game = actions_system.retrieve_game(1);
        actions_system.finish_turn(game);

        testing::set_contract_address(caller_2);
        actions_system.move_player(1, 40);
        let landed_property = actions_system.get_property(3, 1);
        actions_system.pay_rent(landed_property);

        property = actions_system.get_property(3, 1);
        property1 = actions_system.get_property(1, 1);
        let aji = actions_system.retrieve_game_player(caller_1, 1);
        let collins = actions_system.retrieve_game_player(caller_2, 1);

        assert(aji.balance == 1446, 'Aji bal error');
        assert(collins.balance == 1634, 'Collins bal error');
        assert(property.development == 2, 'Property dev error');
        assert(property1.development == 2, 'Property dev error');
    }

    #[test]
    #[available_gas(9223372036854775807)]
    fn test_pay_rent_on_three_houses() {
        let caller_1 = contract_address_const::<'aji'>();
        let caller_2 = contract_address_const::<'collins'>();
        let username = 'Ajidokwu';
        let username_1 = 'Collins';

        let ndef = namespace_def();
        let mut world = spawn_test_world([ndef].span());
        world.sync_perms_and_inits(contract_defs());

        let (contract_address, _) = world.dns(@"actions").unwrap();
        let actions_system = IActionsDispatcher { contract_address };

        testing::set_contract_address(caller_2);
        actions_system.register_new_player(username_1);

        testing::set_contract_address(caller_1);
        actions_system.register_new_player(username);

        testing::set_contract_address(caller_1);
        actions_system.create_new_game(GameType::PublicGame, PlayerSymbol::Hat, 2);

        testing::set_contract_address(caller_2);
        actions_system.join_game(PlayerSymbol::Dog, 1);

        testing::set_contract_address(caller_1);
        let started = actions_system.start_game(1);
        assert!(started, "Game start failed");

        // SITE ONLY

        testing::set_contract_address(caller_1);
        actions_system.move_player(1, 1);
        let mut property = actions_system.get_property(1, 1);
        actions_system.buy_property(property);

        // Player 2 lands and pays rent
        testing::set_contract_address(caller_2);
        actions_system.move_player(1, 1);
        let landed_property = actions_system.get_property(1, 1);
        actions_system.pay_rent(landed_property);

        testing::set_contract_address(caller_1);
        actions_system.move_player(1, 2);
        let mut property = actions_system.get_property(3, 1);
        actions_system.buy_property(property);

        testing::set_contract_address(caller_2);
        actions_system.move_player(1, 2);
        let landed_property = actions_system.get_property(3, 1);
        actions_system.pay_rent(landed_property);

        // THREE HOUSES
        testing::set_contract_address(caller_1);
        actions_system.move_player(1, 40);
        let mut property = actions_system.get_property(3, 1);
        let mut property1 = actions_system.get_property(1, 1);
        actions_system.buy_house_or_hotel(property);
        actions_system.buy_house_or_hotel(property1);

        property = actions_system.get_property(3, 1);
        property1 = actions_system.get_property(1, 1);

        actions_system.buy_house_or_hotel(property);
        actions_system.buy_house_or_hotel(property1);

        property = actions_system.get_property(3, 1);
        property1 = actions_system.get_property(1, 1);

        actions_system.buy_house_or_hotel(property);
        actions_system.buy_house_or_hotel(property1);

        let mut game = actions_system.retrieve_game(1);
        actions_system.finish_turn(game);

        testing::set_contract_address(caller_2);
        actions_system.move_player(1, 40);
        let landed_property = actions_system.get_property(3, 1);
        actions_system.pay_rent(landed_property);

        property = actions_system.get_property(3, 1);
        property1 = actions_system.get_property(1, 1);
        let aji = actions_system.retrieve_game_player(caller_1, 1);
        let collins = actions_system.retrieve_game_player(caller_2, 1);

        assert(aji.balance == 1466, 'Aji bal error');
        assert(collins.balance == 1514, 'Collins bal error');
        assert(property.development == 3, 'Property dev error');
        assert(property1.development == 3, 'Property dev error');
    }


    #[test]
    #[available_gas(9223372036854775807)]
    fn test_pay_rent_on_four_houses() {
        let caller_1 = contract_address_const::<'aji'>();
        let caller_2 = contract_address_const::<'collins'>();
        let username = 'Ajidokwu';
        let username_1 = 'Collins';

        let ndef = namespace_def();
        let mut world = spawn_test_world([ndef].span());
        world.sync_perms_and_inits(contract_defs());

        let (contract_address, _) = world.dns(@"actions").unwrap();
        let actions_system = IActionsDispatcher { contract_address };

        testing::set_contract_address(caller_2);
        actions_system.register_new_player(username_1);

        testing::set_contract_address(caller_1);
        actions_system.register_new_player(username);

        testing::set_contract_address(caller_1);
        actions_system.create_new_game(GameType::PublicGame, PlayerSymbol::Hat, 2);

        testing::set_contract_address(caller_2);
        actions_system.join_game(PlayerSymbol::Dog, 1);

        testing::set_contract_address(caller_1);
        let started = actions_system.start_game(1);
        assert!(started, "Game start failed");

        // SITE ONLY

        testing::set_contract_address(caller_1);
        actions_system.move_player(1, 1);
        let mut property = actions_system.get_property(1, 1);
        actions_system.buy_property(property);

        // Player 2 lands and pays rent
        testing::set_contract_address(caller_2);
        actions_system.move_player(1, 1);
        let landed_property = actions_system.get_property(1, 1);
        actions_system.pay_rent(landed_property);

        testing::set_contract_address(caller_1);
        actions_system.move_player(1, 2);
        let mut property = actions_system.get_property(3, 1);
        actions_system.buy_property(property);

        testing::set_contract_address(caller_2);
        actions_system.move_player(1, 2);
        let landed_property = actions_system.get_property(3, 1);
        actions_system.pay_rent(landed_property);

        // Four HOUSES
        testing::set_contract_address(caller_1);
        actions_system.move_player(1, 40);
        let mut property = actions_system.get_property(1, 1);
        let mut property1 = actions_system.get_property(3, 1);
        actions_system.buy_house_or_hotel(property);
        actions_system.buy_house_or_hotel(property1);

        property = actions_system.get_property(3, 1);
        property1 = actions_system.get_property(1, 1);

        actions_system.buy_house_or_hotel(property);
        actions_system.buy_house_or_hotel(property1);

        property = actions_system.get_property(3, 1);
        property1 = actions_system.get_property(1, 1);

        actions_system.buy_house_or_hotel(property);
        actions_system.buy_house_or_hotel(property1);

        property = actions_system.get_property(3, 1);
        property1 = actions_system.get_property(1, 1);

        actions_system.buy_house_or_hotel(property);
        actions_system.buy_house_or_hotel(property1);

        let mut game = actions_system.retrieve_game(1);
        actions_system.finish_turn(game);

        testing::set_contract_address(caller_2);
        actions_system.move_player(1, 40);
        let landed_property = actions_system.get_property(3, 1);
        actions_system.pay_rent(landed_property);

        property = actions_system.get_property(3, 1);
        property1 = actions_system.get_property(1, 1);
        let aji = actions_system.retrieve_game_player(caller_1, 1);
        let collins = actions_system.retrieve_game_player(caller_2, 1);

        assert(aji.balance == 1506, 'Aji bal error');
        assert(collins.balance == 1374, 'Collins bal error');
        assert(property.development == 4, 'Property dev error');
        assert(property1.development == 4, 'Property dev error');
    }

    #[test]
    #[available_gas(9223372036854775807)]
    fn test_pay_rent_on_hotel() {
        let caller_1 = contract_address_const::<'aji'>();
        let caller_2 = contract_address_const::<'collins'>();
        let username = 'Ajidokwu';
        let username_1 = 'Collins';

        let ndef = namespace_def();
        let mut world = spawn_test_world([ndef].span());
        world.sync_perms_and_inits(contract_defs());

        let (contract_address, _) = world.dns(@"actions").unwrap();
        let actions_system = IActionsDispatcher { contract_address };

        testing::set_contract_address(caller_2);
        actions_system.register_new_player(username_1);

        testing::set_contract_address(caller_1);
        actions_system.register_new_player(username);

        testing::set_contract_address(caller_1);
        actions_system.create_new_game(GameType::PublicGame, PlayerSymbol::Hat, 2);

        testing::set_contract_address(caller_2);
        actions_system.join_game(PlayerSymbol::Dog, 1);

        testing::set_contract_address(caller_1);
        let started = actions_system.start_game(1);
        assert!(started, "Game start failed");

        // SITE ONLY

        testing::set_contract_address(caller_1);
        actions_system.move_player(1, 1);
        let mut property = actions_system.get_property(1, 1);
        actions_system.buy_property(property);

        // Player 2 lands and pays rent
        testing::set_contract_address(caller_2);
        actions_system.move_player(1, 1);
        let landed_property = actions_system.get_property(1, 1);
        actions_system.pay_rent(landed_property);

        testing::set_contract_address(caller_1);
        actions_system.move_player(1, 2);
        let mut property = actions_system.get_property(3, 1);
        actions_system.buy_property(property);

        testing::set_contract_address(caller_2);
        actions_system.move_player(1, 2);
        let landed_property = actions_system.get_property(3, 1);
        actions_system.pay_rent(landed_property);

        // Four HOUSES
        testing::set_contract_address(caller_1);
        actions_system.move_player(1, 40);
        let mut property = actions_system.get_property(3, 1);
        let mut property1 = actions_system.get_property(1, 1);
        actions_system.buy_house_or_hotel(property);
        actions_system.buy_house_or_hotel(property1);

        property = actions_system.get_property(3, 1);
        property1 = actions_system.get_property(1, 1);

        actions_system.buy_house_or_hotel(property);
        actions_system.buy_house_or_hotel(property1);

        property = actions_system.get_property(3, 1);
        property1 = actions_system.get_property(1, 1);

        actions_system.buy_house_or_hotel(property);
        actions_system.buy_house_or_hotel(property1);

        property = actions_system.get_property(3, 1);
        property1 = actions_system.get_property(1, 1);

        actions_system.buy_house_or_hotel(property);
        actions_system.buy_house_or_hotel(property1);

        property = actions_system.get_property(3, 1);
        property1 = actions_system.get_property(1, 1);

        actions_system.buy_house_or_hotel(property);
        actions_system.buy_house_or_hotel(property1);

        let mut game = actions_system.retrieve_game(1);
        actions_system.finish_turn(game);

        testing::set_contract_address(caller_2);
        actions_system.move_player(1, 40);
        let landed_property = actions_system.get_property(3, 1);
        actions_system.pay_rent(landed_property);

        property = actions_system.get_property(3, 1);
        property1 = actions_system.get_property(1, 1);
        let aji = actions_system.retrieve_game_player(caller_1, 1);
        let collins = actions_system.retrieve_game_player(caller_2, 1);

        assert(aji.balance == 1536, 'Aji bal error');
        assert(collins.balance == 1244, 'Collins bal error');
        assert(property.development == 5, 'Property dev error');
        assert(property1.development == 5, 'Property dev error');
    }

    #[test]
    #[available_gas(9223372036854775807)]
    #[should_panic]
    fn test_pay_rent_on_six_houses() {
        let caller_1 = contract_address_const::<'aji'>();
        let caller_2 = contract_address_const::<'collins'>();
        let username = 'Ajidokwu';
        let username_1 = 'Collins';

        let ndef = namespace_def();
        let mut world = spawn_test_world([ndef].span());
        world.sync_perms_and_inits(contract_defs());

        let (contract_address, _) = world.dns(@"actions").unwrap();
        let actions_system = IActionsDispatcher { contract_address };

        testing::set_contract_address(caller_2);
        actions_system.register_new_player(username_1);

        testing::set_contract_address(caller_1);
        actions_system.register_new_player(username);

        testing::set_contract_address(caller_1);
        actions_system.create_new_game(GameType::PublicGame, PlayerSymbol::Hat, 2);

        testing::set_contract_address(caller_2);
        actions_system.join_game(PlayerSymbol::Dog, 1);

        testing::set_contract_address(caller_1);
        let started = actions_system.start_game(1);
        assert!(started, "Game start failed");

        // SITE ONLY

        testing::set_contract_address(caller_1);
        actions_system.move_player(1, 1);
        let mut property = actions_system.get_property(1, 1);
        actions_system.buy_property(property);

        // Player 2 lands and pays rent
        testing::set_contract_address(caller_2);
        actions_system.move_player(1, 1);
        let landed_property = actions_system.get_property(1, 1);
        actions_system.pay_rent(landed_property);

        testing::set_contract_address(caller_1);
        actions_system.move_player(1, 2);
        let mut property = actions_system.get_property(3, 1);
        actions_system.buy_property(property);

        testing::set_contract_address(caller_2);
        actions_system.move_player(1, 2);
        let landed_property = actions_system.get_property(4, 1);
        actions_system.pay_rent(landed_property);

        // Four HOUSES
        testing::set_contract_address(caller_1);
        actions_system.move_player(1, 40);
        let mut property = actions_system.get_property(3, 1);
        let mut property1 = actions_system.get_property(1, 1);
        actions_system.buy_house_or_hotel(property);
        actions_system.buy_house_or_hotel(property1);

        property = actions_system.get_property(3, 1);
        property1 = actions_system.get_property(1, 1);

        actions_system.buy_house_or_hotel(property);
        actions_system.buy_house_or_hotel(property1);

        property = actions_system.get_property(3, 1);
        property1 = actions_system.get_property(1, 1);

        actions_system.buy_house_or_hotel(property);
        actions_system.buy_house_or_hotel(property1);

        property = actions_system.get_property(3, 1);
        property1 = actions_system.get_property(1, 1);

        actions_system.buy_house_or_hotel(property);
        actions_system.buy_house_or_hotel(property1);

        property = actions_system.get_property(3, 1);
        property1 = actions_system.get_property(1, 1);

        actions_system.buy_house_or_hotel(property);
        actions_system.buy_house_or_hotel(property1);

        property = actions_system.get_property(3, 1);
        property1 = actions_system.get_property(1, 1);

        actions_system.buy_house_or_hotel(property);
        actions_system.buy_house_or_hotel(property1);

        let mut game = actions_system.retrieve_game(1);
        actions_system.finish_turn(game);

        testing::set_contract_address(caller_2);
        actions_system.move_player(1, 40);
        let landed_property = actions_system.get_property(3, 1);
        actions_system.pay_rent(landed_property);
    }

    #[test]
    fn test_community_chest() {
        let caller_1 = contract_address_const::<'aji'>();
        let caller_2 = contract_address_const::<'collins'>();
        let caller_3 = contract_address_const::<'jerry'>();
        let caller_4 = contract_address_const::<'aliyu'>();
        let username = 'Ajidokwu';
        let username_1 = 'Collins';
        let username_2 = 'Jerry';
        let username_3 = 'Aliyu';

        let ndef = namespace_def();
        let mut world = spawn_test_world([ndef].span());
        world.sync_perms_and_inits(contract_defs());

        let (contract_address, _) = world.dns(@"actions").unwrap();
        let actions_system = IActionsDispatcher { contract_address };

        testing::set_contract_address(caller_2);
        actions_system.register_new_player(username_1);

        testing::set_contract_address(caller_1);
        actions_system.register_new_player(username);

        testing::set_contract_address(caller_3);
        actions_system.register_new_player(username_2);

        testing::set_contract_address(caller_4);
        actions_system.register_new_player(username_3);

        testing::set_contract_address(caller_1);
        actions_system.create_new_game(GameType::PublicGame, PlayerSymbol::Hat, 4);

        testing::set_contract_address(caller_2);
        actions_system.join_game(PlayerSymbol::Dog, 1);

        testing::set_contract_address(caller_3);
        actions_system.join_game(PlayerSymbol::Car, 1);

        testing::set_contract_address(caller_4);
        actions_system.join_game(PlayerSymbol::Iron, 1);

        testing::set_contract_address(caller_1);
        let started = actions_system.start_game(1);
        assert(started, 'Game start fail');

        testing::set_contract_address(caller_1);
        actions_system.move_player(1, 2);

        let ppt = actions_system.get_property(5, 1);
        let mut community = actions_system.handle_community_chest(1, 3);
        println!("community chest 1 : {}", community);
        community = actions_system.handle_community_chest(1, 3);
        println!("community chest 2: {}", community);
        community = actions_system.handle_community_chest(1, 3);
        println!("community chest 3: {}", community);
        community = actions_system.handle_community_chest(1, 3);
        println!("community chest 4: {}", community);
        community = actions_system.handle_community_chest(1, 3);
        println!("community chest 5: {}", community);
        community = actions_system.handle_community_chest(1, 3);
        println!("community chest 6: {}", community);
        community = actions_system.handle_community_chest(1, 3);
        println!("community chest 7: {}", community);
        community = actions_system.handle_community_chest(1, 3);
        println!("community chest 8: {}", community);
        community = actions_system.handle_community_chest(1, 3);
        println!("community chest 9 : {}", community);
        community = actions_system.handle_community_chest(1, 3);
        println!("community chest 10 : {}", community);
        community = actions_system.handle_community_chest(1, 3);
        println!("community chest 11 : {}", community);
        community = actions_system.handle_community_chest(1, 3);
        println!("community chest 12 : {}", community);
        community = actions_system.handle_community_chest(1, 3);
        println!("community chest 13 : {}", community);
        community = actions_system.handle_community_chest(1, 3);
        println!("community chest 14 : {}", community);
        community = actions_system.handle_community_chest(1, 3);
        println!("community chest 15 : {}", community);
        community = actions_system.handle_community_chest(1, 3);
        println!("community chest 16 : {}", community);
        community = actions_system.handle_community_chest(1, 3);
        println!("community chest 17 : {}", community);
    }

    #[test]
    fn test_community_chance() {
        let caller_1 = contract_address_const::<'aji'>();
        let caller_2 = contract_address_const::<'collins'>();
        let caller_3 = contract_address_const::<'jerry'>();
        let caller_4 = contract_address_const::<'aliyu'>();
        let username = 'Ajidokwu';
        let username_1 = 'Collins';
        let username_2 = 'Jerry';
        let username_3 = 'Aliyu';

        let ndef = namespace_def();
        let mut world = spawn_test_world([ndef].span());
        world.sync_perms_and_inits(contract_defs());

        let (contract_address, _) = world.dns(@"actions").unwrap();
        let actions_system = IActionsDispatcher { contract_address };

        testing::set_contract_address(caller_2);
        actions_system.register_new_player(username_1);

        testing::set_contract_address(caller_1);
        actions_system.register_new_player(username);

        testing::set_contract_address(caller_3);
        actions_system.register_new_player(username_2);

        testing::set_contract_address(caller_4);
        actions_system.register_new_player(username_3);

        testing::set_contract_address(caller_1);
        actions_system.create_new_game(GameType::PublicGame, PlayerSymbol::Hat, 4);

        testing::set_contract_address(caller_2);
        actions_system.join_game(PlayerSymbol::Dog, 1);

        testing::set_contract_address(caller_3);
        actions_system.join_game(PlayerSymbol::Car, 1);

        testing::set_contract_address(caller_4);
        actions_system.join_game(PlayerSymbol::Iron, 1);

        testing::set_contract_address(caller_1);
        let started = actions_system.start_game(1);
        assert(started, 'Game start fail');

        testing::set_contract_address(caller_1);
        actions_system.move_player(1, 2);

        let ppt = actions_system.get_property(5, 1);

        let mut chance = actions_system.handle_chance(1, 3);
        println!("chance 1 : {}", chance);
        chance = actions_system.handle_chance(1, 3);
        println!("chance 2 : {}", chance);
        chance = actions_system.handle_chance(1, 3);
        println!("chance 3 : {}", chance);
        chance = actions_system.handle_chance(1, 3);
        println!("chance 4 : {}", chance);
        chance = actions_system.handle_chance(1, 3);
        println!("chance 5 : {}", chance);
        chance = actions_system.handle_chance(1, 3);
        println!("chance 6 : {}", chance);
        chance = actions_system.handle_chance(1, 3);
        println!("chance 7 : {}", chance);
        chance = actions_system.handle_chance(1, 3);
        println!("chance 8 : {}", chance);
        chance = actions_system.handle_chance(1, 3);
        println!("chance 9 : {}", chance);
        chance = actions_system.handle_chance(1, 3);
        println!("chance 10 : {}", chance);
        chance = actions_system.handle_chance(1, 3);
        println!("chance 11 : {}", chance);
        chance = actions_system.handle_chance(1, 3);
        println!("chance 12 : {}", chance);
        chance = actions_system.handle_chance(1, 3);
        println!("chance 13 : {}", chance);
        chance = actions_system.handle_chance(1, 3);
        println!("chance 14 : {}", chance);
        chance = actions_system.handle_chance(1, 3);
        println!("chance 15 : {}", chance);
        chance = actions_system.handle_chance(1, 3);
        println!("chance 16 : {}", chance);
        chance = actions_system.handle_chance(1, 3);
        println!("chance 17 : {}", chance);
    }
    #[test]
    fn test_process_only_chance() {
        let caller_1 = contract_address_const::<'aji'>();
        let caller_2 = contract_address_const::<'collins'>();
        let caller_3 = contract_address_const::<'jerry'>();
        let caller_4 = contract_address_const::<'aliyu'>();
        let username = 'Ajidokwu';
        let username_1 = 'Collins';
        let username_2 = 'Jerry';
        let username_3 = 'Aliyu';

        let ndef = namespace_def();
        let mut world = spawn_test_world([ndef].span());
        world.sync_perms_and_inits(contract_defs());

        let (contract_address, _) = world.dns(@"actions").unwrap();
        let actions_system = IActionsDispatcher { contract_address };

        testing::set_contract_address(caller_2);
        actions_system.register_new_player(username_1);

        testing::set_contract_address(caller_1);
        actions_system.register_new_player(username);

        testing::set_contract_address(caller_3);
        actions_system.register_new_player(username_2);

        testing::set_contract_address(caller_4);
        actions_system.register_new_player(username_3);

        testing::set_contract_address(caller_1);
        actions_system.create_new_game(GameType::PublicGame, PlayerSymbol::Hat, 4);

        testing::set_contract_address(caller_2);
        actions_system.join_game(PlayerSymbol::Dog, 1);

        testing::set_contract_address(caller_3);
        actions_system.join_game(PlayerSymbol::Car, 1);

        testing::set_contract_address(caller_4);
        actions_system.join_game(PlayerSymbol::Iron, 1);

        testing::set_contract_address(caller_1);
        let started = actions_system.start_game(1);
        assert(started, 'Game start fail');

        testing::set_contract_address(caller_1);
        actions_system.move_player(1, 7);

        let mut g = actions_system.retrieve_game(1);
        let mut p = actions_system.retrieve_game_player(caller_1, 1);

        let mut chance = actions_system.handle_chance(1, 3);

        let (game, ply) = actions_system.process_chance_card(g, p, chance.clone());

        assert(ply.position == 12, 'position error');
        assert(ply.balance == 1430, 'bal error');
    }

    #[test]
    fn test_process_chance_individually() {
        let caller_1 = contract_address_const::<'aji'>();
        let caller_2 = contract_address_const::<'collins'>();

        let username = 'Ajidokwu';
        let username_1 = 'Collins';

        let ndef = namespace_def();
        let mut world = spawn_test_world([ndef].span());
        world.sync_perms_and_inits(contract_defs());

        let (contract_address, _) = world.dns(@"actions").unwrap();
        let actions_system = IActionsDispatcher { contract_address };

        testing::set_contract_address(caller_2);
        actions_system.register_new_player(username_1);

        testing::set_contract_address(caller_1);
        actions_system.register_new_player(username);

        testing::set_contract_address(caller_1);
        actions_system.create_new_game(GameType::PublicGame, PlayerSymbol::Hat, 2);

        testing::set_contract_address(caller_2);
        actions_system.join_game(PlayerSymbol::Dog, 1);

        testing::set_contract_address(caller_1);
        let started = actions_system.start_game(1);
        assert(started, 'Game start fail');

        testing::set_contract_address(caller_1);
        actions_system.move_player(1, 7);

        let mut g = actions_system.retrieve_game(1);
        let mut p = actions_system.retrieve_game_player(caller_1, 1);

        let mut chance: ByteArray = "Advance to Go (Collect $200)";

        let (_, ply) = actions_system.process_chance_card(g.clone(), p, chance);
        assert(ply.position == 0, 'position error');
        assert(ply.balance == 1700, 'bal error');

        g = actions_system.finish_turn(g);
        testing::set_contract_address(caller_2);
        actions_system.move_player(1, 7);

        g = actions_system.retrieve_game(1);
        p = actions_system.retrieve_game_player(caller_2, 1);

        chance = "Advance to MakerDAO Avenue - If you pass Go, collect $200";

        let (_, ply) = actions_system.process_chance_card(g.clone(), p, chance);
        g = actions_system.finish_turn(g);

        assert(ply.position == 24, 'position error');
        assert(ply.balance == 1500, 'bal error');

        testing::set_contract_address(caller_1);
        actions_system.move_player(1, 7);

        g = actions_system.retrieve_game(1);
        p = actions_system.retrieve_game_player(caller_1, 1);

        chance = "Advance to Arbitrium Avenue - If you pass Go, collect $200";

        let (_, ply) = actions_system.process_chance_card(g.clone(), p, chance);
        actions_system.finish_turn(g);

        assert(ply.position == 11, 'position error');
        assert(ply.balance == 1700, 'bal error');

        testing::set_contract_address(caller_2);
        actions_system.move_player(1, 12);

        g = actions_system.retrieve_game(1);
        p = actions_system.retrieve_game_player(caller_2, 1);

        chance = "Advance token to nearest Utility. Pay 10x dice.";

        let (g, ply) = actions_system.process_chance_card(g.clone(), p, chance);
        actions_system.finish_turn(g);

        assert(ply.position == 12, 'position error');
        assert(ply.balance == 1380, 'bal error');

        testing::set_contract_address(caller_1);
        actions_system.move_player(1, 11);

        let g = actions_system.retrieve_game(1);
        p = actions_system.retrieve_game_player(caller_1, 1);

        chance = "Advance token to nearest Railroad. Pay 2x rent.";

        let (g, ply) = actions_system.process_chance_card(g.clone(), p, chance);
        actions_system.finish_turn(g);

        assert(ply.position == 25, 'position error');
        assert(ply.balance == 1700, 'bal error');

        testing::set_contract_address(caller_2);
        actions_system.move_player(1, 10);

        let g = actions_system.retrieve_game(1);
        p = actions_system.retrieve_game_player(caller_2, 1);

        chance = "Bank pays you dividend of $50";

        let (g, ply) = actions_system.process_chance_card(g.clone(), p, chance);
        actions_system.finish_turn(g);

        assert(ply.position == 22, 'position error');
        assert(ply.balance == 1430, 'bal error');

        testing::set_contract_address(caller_1);
        actions_system.move_player(1, 11);

        let g = actions_system.retrieve_game(1);
        p = actions_system.retrieve_game_player(caller_1, 1);

        chance = "Get out of Jail Free";

        let (g, ply) = actions_system.process_chance_card(g.clone(), p, chance);
        actions_system.finish_turn(g);

        assert(ply.position == 36, 'position error');
        assert(ply.balance == 1700, 'bal error');
        assert(ply.chance_jail_card, 'get out jail error');

        testing::set_contract_address(caller_2);
        actions_system.move_player(1, 14);

        let g = actions_system.retrieve_game(1);
        p = actions_system.retrieve_game_player(caller_2, 1);

        chance = "Pay poor tax of $15";

        let (g, ply) = actions_system.process_chance_card(g.clone(), p, chance);
        actions_system.finish_turn(g);

        assert(ply.position == 36, 'position error');
        assert(ply.balance == 1415, 'bal error');

        testing::set_contract_address(caller_1);
        actions_system.move_player(1, 11);

        let g = actions_system.retrieve_game(1);
        p = actions_system.retrieve_game_player(caller_1, 1);

        chance = "Make general repairs - $25 house, $100 hotel";

        let (g, ply) = actions_system.process_chance_card(g.clone(), p, chance);
        actions_system.finish_turn(g);

        assert(ply.position == 7, 'position error');
        assert(ply.balance == 1900, 'bal error');

        testing::set_contract_address(caller_2);
        actions_system.move_player(1, 11);

        let g = actions_system.retrieve_game(1);
        p = actions_system.retrieve_game_player(caller_2, 1);

        chance = "Go Back 3 Spaces";

        let (g, ply) = actions_system.process_chance_card(g.clone(), p, chance);
        actions_system.finish_turn(g);

        assert(ply.position == 4, 'position error');
        assert(ply.balance == 1615, 'bal error');

        // HERE

        testing::set_contract_address(caller_1);
        actions_system.move_player(1, 15);

        let g = actions_system.retrieve_game(1);
        p = actions_system.retrieve_game_player(caller_1, 1);

        chance = "Make general repairs - $25 house, $100 hotel";

        let (g, ply) = actions_system.process_chance_card(g.clone(), p, chance);
        actions_system.finish_turn(g);

        assert(ply.position == 22, 'position error');
        assert(ply.balance == 1900, 'bal error');

        testing::set_contract_address(caller_2);
        actions_system.move_player(1, 3);

        let g = actions_system.retrieve_game(1);
        p = actions_system.retrieve_game_player(caller_2, 1);

        chance = "Take a trip to IPFS Railroad";

        let (g, ply) = actions_system.process_chance_card(g.clone(), p, chance);
        actions_system.finish_turn(g);

        assert(ply.position == 5, 'position error');
        assert(ply.balance == 1815, 'bal error');

        testing::set_contract_address(caller_1);
        actions_system.move_player(1, 14);

        let g = actions_system.retrieve_game(1);
        p = actions_system.retrieve_game_player(caller_1, 1);

        chance = "Take a walk on the Bitcoin Lane";

        let (g, ply) = actions_system.process_chance_card(g.clone(), p, chance);
        actions_system.finish_turn(g);

        assert(ply.position == 39, 'position error');
        assert(ply.balance == 1900, 'bal error');

        testing::set_contract_address(caller_2);
        actions_system.move_player(1, 2);

        let g = actions_system.retrieve_game(1);
        p = actions_system.retrieve_game_player(caller_2, 1);

        chance = "Speeding fine $200";

        let (g, ply) = actions_system.process_chance_card(g.clone(), p, chance);
        actions_system.finish_turn(g);

        assert(ply.position == 7, 'position error');
        assert(ply.balance == 1615, 'bal error');

        testing::set_contract_address(caller_1);
        actions_system.move_player(1, 8);

        let g = actions_system.retrieve_game(1);
        p = actions_system.retrieve_game_player(caller_1, 1);

        chance = "Building loan matures - collect $150";

        let (g, ply) = actions_system.process_chance_card(g.clone(), p, chance);
        actions_system.finish_turn(g);

        assert(ply.position == 7, 'position error');
        assert(ply.balance == 2250, 'bal error');
    }

    #[test]
    fn test_process_community_chest() {
        let caller_1 = contract_address_const::<'aji'>();
        let caller_2 = contract_address_const::<'collins'>();
        let caller_3 = contract_address_const::<'jerry'>();
        let caller_4 = contract_address_const::<'aliyu'>();
        let username = 'Ajidokwu';
        let username_1 = 'Collins';
        let username_2 = 'Jerry';
        let username_3 = 'Aliyu';

        let ndef = namespace_def();
        let mut world = spawn_test_world([ndef].span());
        world.sync_perms_and_inits(contract_defs());

        let (contract_address, _) = world.dns(@"actions").unwrap();
        let actions_system = IActionsDispatcher { contract_address };

        testing::set_contract_address(caller_2);
        actions_system.register_new_player(username_1);

        testing::set_contract_address(caller_1);
        actions_system.register_new_player(username);

        testing::set_contract_address(caller_3);
        actions_system.register_new_player(username_2);

        testing::set_contract_address(caller_4);
        actions_system.register_new_player(username_3);

        testing::set_contract_address(caller_1);
        actions_system.create_new_game(GameType::PublicGame, PlayerSymbol::Hat, 4);

        testing::set_contract_address(caller_2);
        actions_system.join_game(PlayerSymbol::Dog, 1);

        testing::set_contract_address(caller_3);
        actions_system.join_game(PlayerSymbol::Car, 1);

        testing::set_contract_address(caller_4);
        actions_system.join_game(PlayerSymbol::Iron, 1);

        testing::set_contract_address(caller_1);
        let started = actions_system.start_game(1);
        assert(started, 'Game start fail');

        testing::set_contract_address(caller_1);
        actions_system.move_player(1, 2);

        let mut g = actions_system.retrieve_game(1);

        let mut p = actions_system.retrieve_game_player(caller_1, 1);

        let mut community_chest = actions_system.handle_community_chest(1, 2);

        let (_, ply) = actions_system.process_community_chest_card(g, p, community_chest.clone());

        assert(ply.position == 2, 'position error');
        assert(ply.balance == 1450, 'bal error');
    }

    #[test]
    fn test_process_community_chest_individually() {
        let caller_1 = contract_address_const::<'aji'>();
        let caller_2 = contract_address_const::<'collins'>();

        let username = 'Ajidokwu';
        let username_1 = 'Collins';

        let ndef = namespace_def();
        let mut world = spawn_test_world([ndef].span());
        world.sync_perms_and_inits(contract_defs());

        let (contract_address, _) = world.dns(@"actions").unwrap();
        let actions_system = IActionsDispatcher { contract_address };

        testing::set_contract_address(caller_2);
        actions_system.register_new_player(username_1);

        testing::set_contract_address(caller_1);
        actions_system.register_new_player(username);

        testing::set_contract_address(caller_1);
        actions_system.create_new_game(GameType::PublicGame, PlayerSymbol::Hat, 2);

        testing::set_contract_address(caller_2);
        actions_system.join_game(PlayerSymbol::Dog, 1);

        testing::set_contract_address(caller_1);
        let started = actions_system.start_game(1);
        assert(started, 'Game start fail');

        testing::set_contract_address(caller_1);
        actions_system.move_player(1, 2);

        let mut g = actions_system.retrieve_game(1);
        let mut p = actions_system.retrieve_game_player(caller_1, 1);

        let mut community_chest: ByteArray = "Advance to Go (Collect $200)";

        let (_, ply) = actions_system.process_community_chest_card(g.clone(), p, community_chest);
        assert(ply.position == 0, 'position error');
        assert(ply.balance == 1700, 'bal error');

        g = actions_system.finish_turn(g);
        testing::set_contract_address(caller_2);
        actions_system.move_player(1, 2);

        g = actions_system.retrieve_game(1);
        p = actions_system.retrieve_game_player(caller_2, 1);

        community_chest = "Bank error in your favor - Collect $200";

        let (_, ply) = actions_system.process_community_chest_card(g.clone(), p, community_chest);
        g = actions_system.finish_turn(g);

        assert(ply.position == 2, 'position error');
        assert(ply.balance == 1700, 'bal error');

        testing::set_contract_address(caller_1);
        actions_system.move_player(1, 2);

        g = actions_system.retrieve_game(1);
        p = actions_system.retrieve_game_player(caller_1, 1);

        community_chest = "Bank error in your favor - Collect $200";

        let (_, ply) = actions_system.process_community_chest_card(g.clone(), p, community_chest);
        actions_system.finish_turn(g);

        assert(ply.position == 2, 'position error');
        assert(ply.balance == 1900, 'bal error');

        testing::set_contract_address(caller_2);
        actions_system.move_player(1, 15);

        g = actions_system.retrieve_game(1);
        p = actions_system.retrieve_game_player(caller_2, 1);

        community_chest = "Doctor fee - Pay $50";

        let (g, ply) = actions_system.process_community_chest_card(g.clone(), p, community_chest);
        actions_system.finish_turn(g);

        assert(ply.position == 17, 'position error');
        assert(ply.balance == 1650, 'bal error');

        testing::set_contract_address(caller_1);
        actions_system.move_player(1, 15);

        let g = actions_system.retrieve_game(1);
        p = actions_system.retrieve_game_player(caller_1, 1);

        community_chest = "From sale of stock - collect $50";

        let (g, ply) = actions_system.process_community_chest_card(g.clone(), p, community_chest);
        actions_system.finish_turn(g);

        assert(ply.position == 17, 'position error');
        assert(ply.balance == 1950, 'bal error');

        testing::set_contract_address(caller_2);
        actions_system.move_player(1, 16);

        let g = actions_system.retrieve_game(1);
        p = actions_system.retrieve_game_player(caller_2, 1);

        community_chest = "Get Out of Jail Free";

        let (g, ply) = actions_system.process_community_chest_card(g.clone(), p, community_chest);
        actions_system.finish_turn(g);

        assert(ply.position == 33, 'position error');
        assert(ply.balance == 1650, 'bal error');
        assert(ply.comm_free_card, 'jail card error');

        testing::set_contract_address(caller_1);
        actions_system.move_player(1, 16);

        let g = actions_system.retrieve_game(1);
        p = actions_system.retrieve_game_player(caller_1, 1);

        community_chest = "Grand Opera Night - collect $50 from every player";

        let (g, ply) = actions_system.process_community_chest_card(g.clone(), p, community_chest);
        actions_system.finish_turn(g);

        assert(ply.position == 33, 'position error');
        assert(ply.balance == 2000, 'bal error');

        testing::set_contract_address(caller_2);
        actions_system.move_player(1, 9);

        let g = actions_system.retrieve_game(1);
        p = actions_system.retrieve_game_player(caller_2, 1);

        community_chest = "Go to Jail";

        let (g, ply) = actions_system.process_community_chest_card(g.clone(), p, community_chest);
        actions_system.finish_turn(g);

        assert(ply.position == 10, 'position error');
        assert(ply.balance == 1800, 'bal error');

        testing::set_contract_address(caller_1);
        actions_system.move_player(1, 9);

        let g = actions_system.retrieve_game(1);
        p = actions_system.retrieve_game_player(caller_1, 1);

        community_chest = "Holiday Fund matures - Receive $100";

        let (g, ply) = actions_system.process_community_chest_card(g.clone(), p, community_chest);
        actions_system.finish_turn(g);

        assert(ply.position == 2, 'position error');
        assert(ply.balance == 2300, 'bal error');

        testing::set_contract_address(caller_2);
        actions_system.use_getout_of_jail_community_chest(1);
        actions_system.move_player(1, 7);

        let g = actions_system.retrieve_game(1);
        p = actions_system.retrieve_game_player(caller_2, 1);

        community_chest = "Income tax refund - Collect $20";

        let (g, ply) = actions_system.process_community_chest_card(g.clone(), p, community_chest);
        actions_system.finish_turn(g);

        assert(ply.position == 17, 'position error');
        assert(ply.balance == 1820, 'bal error');

        // // // HERE

        testing::set_contract_address(caller_1);
        actions_system.move_player(1, 15);

        let g = actions_system.retrieve_game(1);
        p = actions_system.retrieve_game_player(caller_1, 1);

        community_chest = "Life insurance matures - Collect $100";

        let (g, ply) = actions_system.process_community_chest_card(g.clone(), p, community_chest);
        actions_system.finish_turn(g);

        assert(ply.position == 17, 'position error');
        assert(ply.balance == 2400, 'bal error');

        testing::set_contract_address(caller_2);
        actions_system.move_player(1, 16);

        let g = actions_system.retrieve_game(1);
        p = actions_system.retrieve_game_player(caller_2, 1);

        community_chest = "Pay hospital fees of $100";

        let (g, ply) = actions_system.process_community_chest_card(g.clone(), p, community_chest);
        actions_system.finish_turn(g);

        assert(ply.position == 33, 'position error');
        assert(ply.balance == 1720, 'bal error');

        testing::set_contract_address(caller_1);
        actions_system.move_player(1, 16);

        let g = actions_system.retrieve_game(1);
        p = actions_system.retrieve_game_player(caller_1, 1);

        community_chest = "Pay school fees of $150";

        let (g, ply) = actions_system.process_community_chest_card(g.clone(), p, community_chest);
        actions_system.finish_turn(g);

        assert(ply.position == 33, 'position error');
        assert(ply.balance == 2250, 'bal error');

        testing::set_contract_address(caller_2);
        actions_system.move_player(1, 9);

        let g = actions_system.retrieve_game(1);
        p = actions_system.retrieve_game_player(caller_2, 1);

        community_chest = "Street repairs - $40 per house, $115 per hotel";

        let (g, ply) = actions_system.process_community_chest_card(g.clone(), p, community_chest);
        actions_system.finish_turn(g);

        assert(ply.position == 2, 'position error');
        assert(ply.balance == 1920, 'bal error');

        testing::set_contract_address(caller_1);
        actions_system.move_player(1, 9);

        let g = actions_system.retrieve_game(1);
        p = actions_system.retrieve_game_player(caller_1, 1);

        community_chest = "Won second prize in beauty contest - Collect $10";

        let (g, ply) = actions_system.process_community_chest_card(g.clone(), p, community_chest);
        actions_system.finish_turn(g);

        assert(ply.position == 2, 'position error');
        assert(ply.balance == 2460, 'bal error');

        testing::set_contract_address(caller_2);
        actions_system.move_player(1, 15);

        let g = actions_system.retrieve_game(1);
        p = actions_system.retrieve_game_player(caller_2, 1);

        community_chest = "You inherit $100";

        let (g, ply) = actions_system.process_community_chest_card(g.clone(), p, community_chest);
        actions_system.finish_turn(g);

        assert(ply.position == 17, 'position error');
        assert(ply.balance == 2020, 'bal error');
    }

    #[test]
    fn test_going_jail_and_using_community_and_chance_cards() {
        let caller_1 = contract_address_const::<'aji'>();
        let caller_2 = contract_address_const::<'collins'>();

        let username = 'Ajidokwu';
        let username_1 = 'Collins';

        let ndef = namespace_def();
        let mut world = spawn_test_world([ndef].span());
        world.sync_perms_and_inits(contract_defs());

        let (contract_address, _) = world.dns(@"actions").unwrap();
        let actions_system = IActionsDispatcher { contract_address };

        testing::set_contract_address(caller_2);
        actions_system.register_new_player(username_1);

        testing::set_contract_address(caller_1);
        actions_system.register_new_player(username);

        testing::set_contract_address(caller_1);
        actions_system.create_new_game(GameType::PublicGame, PlayerSymbol::Hat, 2);

        testing::set_contract_address(caller_2);
        actions_system.join_game(PlayerSymbol::Dog, 1);

        testing::set_contract_address(caller_1);
        let started = actions_system.start_game(1);
        assert(started, 'Game start fail');

        testing::set_contract_address(caller_1);
        actions_system.move_player(1, 2);

        let mut g = actions_system.retrieve_game(1);
        let mut p = actions_system.retrieve_game_player(caller_1, 1);

        let mut community_chest: ByteArray = "Get Out of Jail Free";

        let (_, ply) = actions_system.process_community_chest_card(g.clone(), p, community_chest);
        g = actions_system.finish_turn(g);

        testing::set_contract_address(caller_2);
        actions_system.move_player(1, 7);

        g = actions_system.retrieve_game(1);
        p = actions_system.retrieve_game_player(caller_2, 1);

        let chance = "Get out of Jail Free";

        let (_, ply1) = actions_system.process_chance_card(g.clone(), p, chance);
        g = actions_system.finish_turn(g);

        testing::set_contract_address(caller_1);
        actions_system.move_player(1, 5);

        g = actions_system.retrieve_game(1);
        p = actions_system.retrieve_game_player(caller_1, 1);

        let chance = "Go to Jail";

        let (_, ply) = actions_system.process_chance_card(g.clone(), p, chance);
        g = actions_system.finish_turn(g);

        testing::set_contract_address(caller_2);
        actions_system.move_player(1, 10);

        g = actions_system.retrieve_game(1);
        p = actions_system.retrieve_game_player(caller_2, 1);

        let chance = "Go to Jail";

        let (game, ply1) = actions_system.process_community_chest_card(g.clone(), p, chance);
        g = actions_system.finish_turn(g);

        testing::set_contract_address(caller_1);
        actions_system.use_getout_of_jail_community_chest(game.id);
        actions_system.move_player(1, 5);
        g = actions_system.finish_turn(g);

        g = actions_system.retrieve_game(1);
        p = actions_system.retrieve_game_player(caller_1, 1);

        testing::set_contract_address(caller_2);
        actions_system.use_getout_of_jail_chance(game.id);
        actions_system.move_player(1, 10);
        g = actions_system.finish_turn(g);

        g = actions_system.retrieve_game(1);
        let pl = actions_system.retrieve_game_player(caller_2, 1);

        assert!(p.jail_turns == 0, "p jail_turns not zero");
        assert!(!p.jailed, "p still jailed");
        assert!(!p.chance_jail_card, "p still has chance card");
        assert!(!p.comm_free_card, "p still has community card");

        assert!(pl.jail_turns == 0, "pl jail_turns not zero");
        assert!(!pl.jailed, "pl still jailed");
        assert!(!pl.chance_jail_card, "pl still has chance card");
        assert!(!pl.comm_free_card, "pl still has community card");
    }

    #[test]
    fn test_going_to_jail_pay_fine_and_miss_3_turns() {
        let caller_1 = contract_address_const::<'aji'>();
        let caller_2 = contract_address_const::<'collins'>();

        let username = 'Ajidokwu';
        let username_1 = 'Collins';

        let ndef = namespace_def();
        let mut world = spawn_test_world([ndef].span());
        world.sync_perms_and_inits(contract_defs());

        let (contract_address, _) = world.dns(@"actions").unwrap();
        let actions_system = IActionsDispatcher { contract_address };

        testing::set_contract_address(caller_2);
        actions_system.register_new_player(username_1);

        testing::set_contract_address(caller_1);
        actions_system.register_new_player(username);

        testing::set_contract_address(caller_1);
        actions_system.create_new_game(GameType::PublicGame, PlayerSymbol::Hat, 2);

        testing::set_contract_address(caller_2);
        actions_system.join_game(PlayerSymbol::Dog, 1);

        testing::set_contract_address(caller_1);
        let started = actions_system.start_game(1);
        assert(started, 'Game start fail');

        testing::set_contract_address(caller_1);
        actions_system.move_player(1, 2);

        let mut g = actions_system.retrieve_game(1);
        let mut p = actions_system.retrieve_game_player(caller_1, 1);

        let mut community_chest: ByteArray = "Get Out of Jail Free";

        let (_, ply) = actions_system.process_community_chest_card(g.clone(), p, community_chest);
        g = actions_system.finish_turn(g);

        testing::set_contract_address(caller_2);
        actions_system.move_player(1, 7);

        g = actions_system.retrieve_game(1);
        p = actions_system.retrieve_game_player(caller_2, 1);

        let chance = "Get out of Jail Free";

        let (_, ply1) = actions_system.process_chance_card(g.clone(), p, chance);
        g = actions_system.finish_turn(g);

        testing::set_contract_address(caller_1);
        actions_system.move_player(1, 5);

        g = actions_system.retrieve_game(1);
        p = actions_system.retrieve_game_player(caller_1, 1);

        let chance = "Go to Jail";

        let (_, ply) = actions_system.process_chance_card(g.clone(), p, chance);
        g = actions_system.finish_turn(g);

        testing::set_contract_address(caller_2);
        actions_system.move_player(1, 10);

        g = actions_system.retrieve_game(1);
        p = actions_system.retrieve_game_player(caller_2, 1);

        let chance = "Go to Jail";

        let (game, ply1) = actions_system.process_community_chest_card(g.clone(), p, chance);
        g = actions_system.finish_turn(g);

        testing::set_contract_address(caller_1);
        actions_system.pay_jail_fine(game.id);
        actions_system.move_player(1, 5);
        g = actions_system.finish_turn(g);

        g = actions_system.retrieve_game(1);
        p = actions_system.retrieve_game_player(caller_1, 1);
        assert!(p.jail_turns == 0, "p jail_turns not zero");
        assert!(!p.jailed, "p still jailed");
        assert!(p.balance == 1450, "pl balance error");

        testing::set_contract_address(caller_2);
        actions_system.move_player(1, 10);
        g = actions_system.finish_turn(g);

        g = actions_system.retrieve_game(1);
        let pl = actions_system.retrieve_game_player(caller_2, 1);

        testing::set_contract_address(caller_1);

        actions_system.move_player(1, 5);
        g = actions_system.finish_turn(g);

        g = actions_system.retrieve_game(1);
        p = actions_system.retrieve_game_player(caller_1, 1);

        testing::set_contract_address(caller_2);
        actions_system.move_player(1, 10);
        g = actions_system.finish_turn(g);

        g = actions_system.retrieve_game(1);
        let pl = actions_system.retrieve_game_player(caller_2, 1);

        testing::set_contract_address(caller_1);
        actions_system.move_player(1, 10);
        g = actions_system.finish_turn(g);

        testing::set_contract_address(caller_2);

        actions_system.move_player(1, 5);
        g = actions_system.finish_turn(g);

        g = actions_system.retrieve_game(1);
        p = actions_system.retrieve_game_player(caller_2, 1);

        testing::set_contract_address(caller_1);
        actions_system.move_player(1, 10);
        g = actions_system.finish_turn(g);

        testing::set_contract_address(caller_2);

        actions_system.move_player(1, 5);
        g = actions_system.finish_turn(g);

        g = actions_system.retrieve_game(1);
        p = actions_system.retrieve_game_player(caller_2, 1);

        g = actions_system.retrieve_game(1);
        let pl = actions_system.retrieve_game_player(caller_2, 1);

        assert!(pl.jail_turns == 0, "pl.jail_turns not zero");
        assert!(pl.balance == 1500, "pl.balance not 1500");
        assert!(!pl.jailed, "pl is still jailed");
        assert!(pl.chance_jail_card, "pl does not have chance jail card");
        assert!(!pl.comm_free_card, "pl still has community jail card");
        assert!(pl.position == 15, "pl.position not 15");
    }

    #[test]
    fn test_offer_trade_property_for_cash() {
        let caller_1 = contract_address_const::<'aji'>();
        let caller_2 = contract_address_const::<'collins'>();
        let username = 'Ajidokwu';
        let username_1 = 'Collins';

        let ndef = namespace_def();
        let mut world = spawn_test_world([ndef].span());
        world.sync_perms_and_inits(contract_defs());

        let (contract_address, _) = world.dns(@"actions").unwrap();
        let actions_system = IActionsDispatcher { contract_address };

        testing::set_contract_address(caller_2);
        actions_system.register_new_player(username_1);

        testing::set_contract_address(caller_1);
        actions_system.register_new_player(username);

        testing::set_contract_address(caller_1);
        actions_system.create_new_game(GameType::PublicGame, PlayerSymbol::Hat, 4);

        testing::set_contract_address(caller_2);
        actions_system.join_game(PlayerSymbol::Dog, 1);

        testing::set_contract_address(caller_1);
        let started = actions_system.start_game(1);
        assert(started, 'Game start fail');

        let game_p = actions_system.retrieve_game(1);

        testing::set_contract_address(caller_1);
        actions_system.move_player(1, 5);
        let ppt = actions_system.get_property(5, 1);

        let buyppt = actions_system.buy_property(ppt);

        testing::set_contract_address(caller_2);
        actions_system.move_player(1, 1);
        let mut property = actions_system.get_property(1, 1);

        actions_system.buy_property(property);

        assert(buyppt, 'Buy property failed');

        testing::set_contract_address(caller_1);
        // let ppt = actions_system.get_property(5, 1);

        let mut offered_property_ids: Array<u8> = array![];
        let mut requested_property_ids: Array<u8> = array![];
        offered_property_ids.append(5);
        requested_property_ids.append(1);
        let mut trade_id = actions_system
            .offer_trade(
                1,
                caller_2,
                offered_property_ids,
                requested_property_ids,
                0,
                250,
                TradeOffer::PropertyForCash,
            );

        println!("trade id : {} ", trade_id);

        actions_system.move_player(1, 5);
        let g = actions_system.retrieve_game(1);
        actions_system.finish_turn(g);

        testing::set_contract_address(caller_2);
        let s = actions_system.accept_trade(1, 1);
        assert(s, 'accept failed');

        //  requested_property_ids, cash_offer, cash_request, trade_type );

        let aji = actions_system.retrieve_game_player(caller_1, 1);
        let mut collins = actions_system.retrieve_game_player(caller_2, 1);

        actions_system.move_player(1, 5);
        let ppt = actions_system.get_property(5, 1);

        let pptfelt: felt252 = ppt.owner.into();

        assert(ppt.owner == caller_2, 'property tf failed');
        assert(aji.balance == 1550, 'debit failed');
        assert(aji.properties_owned.len() == 0, 'aji .len failed');
        assert(*collins.properties_owned[1] == ppt.id, 'ownership transfer failed');
        assert(aji.no_section1 == 0, 'Section update');
        assert(collins.no_section1 == 1, 'Section update');
    }

    #[test]
    fn test_offer_trade_property_for_property() {
        let caller_1 = contract_address_const::<'aji'>();
        let caller_2 = contract_address_const::<'collins'>();
        let username = 'Ajidokwu';
        let username_1 = 'Collins';

        let ndef = namespace_def();
        let mut world = spawn_test_world([ndef].span());
        world.sync_perms_and_inits(contract_defs());

        let (contract_address, _) = world.dns(@"actions").unwrap();
        let actions_system = IActionsDispatcher { contract_address };

        testing::set_contract_address(caller_2);
        actions_system.register_new_player(username_1);

        testing::set_contract_address(caller_1);
        actions_system.register_new_player(username);

        testing::set_contract_address(caller_1);
        actions_system.create_new_game(GameType::PublicGame, PlayerSymbol::Hat, 4);

        testing::set_contract_address(caller_2);
        actions_system.join_game(PlayerSymbol::Dog, 1);

        testing::set_contract_address(caller_1);
        let started = actions_system.start_game(1);
        assert(started, 'Game start fail');

        let game_p = actions_system.retrieve_game(1);

        testing::set_contract_address(caller_1);
        actions_system.move_player(1, 6);
        let ppt = actions_system.get_property(6, 1);

        let buyppt = actions_system.buy_property(ppt);

        testing::set_contract_address(caller_2);
        actions_system.move_player(1, 1);
        let mut property = actions_system.get_property(1, 1);

        actions_system.buy_property(property);

        assert(buyppt, 'Buy property failed');

        testing::set_contract_address(caller_1);
        // let ppt = actions_system.get_property(5, 1);

        let mut offered_property_ids: Array<u8> = array![];
        let mut requested_property_ids: Array<u8> = array![];
        offered_property_ids.append(6);
        requested_property_ids.append(1);
        let mut trade_id = actions_system
            .offer_trade(
                1,
                caller_2,
                offered_property_ids,
                requested_property_ids,
                0,
                0,
                TradeOffer::PropertyForProperty,
            );

        println!("trade id : {} ", trade_id);

        actions_system.move_player(1, 5);
        let g = actions_system.retrieve_game(1);
        actions_system.finish_turn(g);

        testing::set_contract_address(caller_2);
        let s = actions_system.accept_trade(1, 1);
        assert(s, 'accept failed');

        //  requested_property_ids, cash_offer, cash_request, trade_type );

        let aji = actions_system.retrieve_game_player(caller_1, 1);
        let mut collins = actions_system.retrieve_game_player(caller_2, 1);

        actions_system.move_player(1, 5);
        let ppt = actions_system.get_property(6, 1);
        let ppp = actions_system.get_property(1, 1);

        let ppt_felt: felt252 = ppt.owner.into();
        let ppp_felt: felt252 = ppp.owner.into();

        println!("ppt_felt : {}", ppt_felt);
        println!("ppp_felt : {}", ppp_felt);

        assert(ppt.owner == caller_2, 'trade failed');
        assert(ppp.owner == caller_1, 'trade failed');
        assert(aji.no_section1 == 1, 'Section update');
        assert(collins.no_section1 == 0, 'Section update');
        assert(aji.no_section2 == 0, 'Section update');
        assert(collins.no_section2 == 1, 'Section update');
    }

    #[test]
    fn test_offer_trade_cash_for_property() {
        let caller_1 = contract_address_const::<'aji'>();
        let caller_2 = contract_address_const::<'collins'>();
        let username = 'Ajidokwu';
        let username_1 = 'Collins';

        let ndef = namespace_def();
        let mut world = spawn_test_world([ndef].span());
        world.sync_perms_and_inits(contract_defs());

        let (contract_address, _) = world.dns(@"actions").unwrap();
        let actions_system = IActionsDispatcher { contract_address };

        testing::set_contract_address(caller_2);
        actions_system.register_new_player(username_1);

        testing::set_contract_address(caller_1);
        actions_system.register_new_player(username);

        testing::set_contract_address(caller_1);
        actions_system.create_new_game(GameType::PublicGame, PlayerSymbol::Hat, 4);

        testing::set_contract_address(caller_2);
        actions_system.join_game(PlayerSymbol::Dog, 1);

        testing::set_contract_address(caller_1);
        let started = actions_system.start_game(1);
        assert(started, 'Game start fail');

        let game_p = actions_system.retrieve_game(1);

        testing::set_contract_address(caller_1);
        actions_system.move_player(1, 6);
        let ppt = actions_system.get_property(6, 1);

        let buyppt = actions_system.buy_property(ppt);

        testing::set_contract_address(caller_2);
        actions_system.move_player(1, 1);
        let mut property = actions_system.get_property(1, 1);

        actions_system.buy_property(property);

        assert(buyppt, 'Buy property failed');

        testing::set_contract_address(caller_1);
        // let ppt = actions_system.get_property(5, 1);

        let mut offered_property_ids: Array<u8> = array![];
        let mut requested_property_ids: Array<u8> = array![];
        offered_property_ids.append(6);
        requested_property_ids.append(1);
        let mut trade_id = actions_system
            .offer_trade(
                1,
                caller_2,
                offered_property_ids,
                requested_property_ids,
                250,
                0,
                TradeOffer::CashForProperty,
            );

        println!("trade id : {} ", trade_id);

        actions_system.move_player(1, 5);
        let g = actions_system.retrieve_game(1);
        actions_system.finish_turn(g);

        testing::set_contract_address(caller_2);
        let s = actions_system.accept_trade(1, 1);
        assert(s, 'accept failed');

        //  requested_property_ids, cash_offer, cash_request, trade_type );

        let aji = actions_system.retrieve_game_player(caller_1, 1);
        let mut collins = actions_system.retrieve_game_player(caller_2, 1);

        actions_system.move_player(1, 5);
        let ppt = actions_system.get_property(6, 1);
        let ppp = actions_system.get_property(1, 1);

        let ppt_felt: felt252 = ppt.owner.into();
        let ppp_felt: felt252 = ppp.owner.into();

        println!("aji balance : {} ", aji.balance);
        println!("collins balance : {} ", collins.balance);

        assert(ppt.owner == caller_1, 'trade failed');
        assert(ppp.owner == caller_1, 'trade failed');
        assert(aji.no_section1 == 1, 'Section update');
        assert(collins.no_section1 == 0, 'Section update');
        assert(aji.no_section2 == 1, 'Section update');
        assert(collins.no_section2 == 0, 'Section update');
    }
    #[test]
    // fn test_offer_trade_property_for_cash_and_property() {
    fn test_offer_cash_plus_property_for_property() {
        let caller_1 = contract_address_const::<'aji'>();
        let caller_2 = contract_address_const::<'collins'>();
        let username = 'Ajidokwu';
        let username_1 = 'Collins';

        let ndef = namespace_def();
        let mut world = spawn_test_world([ndef].span());
        world.sync_perms_and_inits(contract_defs());

        let (contract_address, _) = world.dns(@"actions").unwrap();
        let actions_system = IActionsDispatcher { contract_address };

        testing::set_contract_address(caller_2);
        actions_system.register_new_player(username_1);

        testing::set_contract_address(caller_1);
        actions_system.register_new_player(username);

        testing::set_contract_address(caller_1);
        actions_system.create_new_game(GameType::PublicGame, PlayerSymbol::Hat, 4);

        testing::set_contract_address(caller_2);
        actions_system.join_game(PlayerSymbol::Dog, 1);

        testing::set_contract_address(caller_1);
        let started = actions_system.start_game(1);
        assert(started, 'Game start fail');

        let game_p = actions_system.retrieve_game(1);

        testing::set_contract_address(caller_1);
        actions_system.move_player(1, 6);
        let ppt = actions_system.get_property(6, 1);

        let buyppt = actions_system.buy_property(ppt);

        testing::set_contract_address(caller_2);
        actions_system.move_player(1, 1);
        let mut property = actions_system.get_property(1, 1);

        actions_system.buy_property(property);

        assert(buyppt, 'Buy property failed');

        testing::set_contract_address(caller_1);
        // let ppt = actions_system.get_property(5, 1);

        let mut offered_property_ids: Array<u8> = array![];
        let mut requested_property_ids: Array<u8> = array![];
        offered_property_ids.append(6);
        requested_property_ids.append(1);
        let mut trade_id = actions_system
            .offer_trade(
                1,
                caller_2,
                offered_property_ids,
                requested_property_ids,
                250,
                0,
                TradeOffer::CashPlusPropertyForProperty,
            );

        println!("trade id : {} ", trade_id);

        actions_system.move_player(1, 5);
        let g = actions_system.retrieve_game(1);
        actions_system.finish_turn(g);

        testing::set_contract_address(caller_2);
        let s = actions_system.accept_trade(1, 1);
        assert(s, 'accept failed');

        //  requested_property_ids, cash_offer, cash_request, trade_type );

        let aji = actions_system.retrieve_game_player(caller_1, 1);
        let mut collins = actions_system.retrieve_game_player(caller_2, 1);

        actions_system.move_player(1, 5);
        let ppt = actions_system.get_property(6, 1);
        let ppp = actions_system.get_property(1, 1);

        let ppt_felt: felt252 = ppt.owner.into();
        let ppp_felt: felt252 = ppp.owner.into();

        println!("ppt_felt : {}", ppt_felt);
        println!("ppp_felt : {}", ppp_felt);
        println!("aji balance : {} ", aji.balance);
        println!("collins balance : {} ", collins.balance);

        assert(ppt.owner == caller_2, 'trade failed');
        assert(ppp.owner == caller_1, 'trade failed');
        assert(aji.no_section1 == 1, 'Section update');
        assert(collins.no_section1 == 0, 'Section update');
        assert(aji.no_section2 == 0, 'Section update');
        assert(collins.no_section2 == 1, 'Section update');
    }
    #[test]
    fn test_offer_trade_property_for_cash_and_property() {
        let caller_1 = contract_address_const::<'aji'>();
        let caller_2 = contract_address_const::<'collins'>();
        let username = 'Ajidokwu';
        let username_1 = 'Collins';

        let ndef = namespace_def();
        let mut world = spawn_test_world([ndef].span());
        world.sync_perms_and_inits(contract_defs());

        let (contract_address, _) = world.dns(@"actions").unwrap();
        let actions_system = IActionsDispatcher { contract_address };

        testing::set_contract_address(caller_2);
        actions_system.register_new_player(username_1);

        testing::set_contract_address(caller_1);
        actions_system.register_new_player(username);

        testing::set_contract_address(caller_1);
        actions_system.create_new_game(GameType::PublicGame, PlayerSymbol::Hat, 4);

        testing::set_contract_address(caller_2);
        actions_system.join_game(PlayerSymbol::Dog, 1);

        testing::set_contract_address(caller_1);
        let started = actions_system.start_game(1);
        assert(started, 'Game start fail');

        let game_p = actions_system.retrieve_game(1);

        testing::set_contract_address(caller_1);
        actions_system.move_player(1, 6);
        let ppt = actions_system.get_property(6, 1);

        let buyppt = actions_system.buy_property(ppt);

        testing::set_contract_address(caller_2);
        actions_system.move_player(1, 1);
        let mut property = actions_system.get_property(1, 1);

        actions_system.buy_property(property);

        assert(buyppt, 'Buy property failed');

        testing::set_contract_address(caller_1);
        // let ppt = actions_system.get_property(5, 1);

        let mut offered_property_ids: Array<u8> = array![];
        let mut requested_property_ids: Array<u8> = array![];
        offered_property_ids.append(6);
        requested_property_ids.append(1);
        let mut trade_id = actions_system
            .offer_trade(
                1,
                caller_2,
                offered_property_ids,
                requested_property_ids,
                0,
                250,
                TradeOffer::PropertyForCashPlusProperty,
            );

        println!("trade id : {} ", trade_id);

        actions_system.move_player(1, 5);
        let g = actions_system.retrieve_game(1);
        actions_system.finish_turn(g);

        testing::set_contract_address(caller_2);
        let s = actions_system.accept_trade(1, 1);
        assert(s, 'accept failed');

        //  requested_property_ids, cash_offer, cash_request, trade_type );

        let aji = actions_system.retrieve_game_player(caller_1, 1);
        let mut collins = actions_system.retrieve_game_player(caller_2, 1);

        actions_system.move_player(1, 5);
        let ppt = actions_system.get_property(6, 1);
        let ppp = actions_system.get_property(1, 1);

        let ppt_felt: felt252 = ppt.owner.into();
        let ppp_felt: felt252 = ppp.owner.into();

        println!("ppt_felt : {}", ppt_felt);
        println!("ppp_felt : {}", ppp_felt);
        println!("aji balance : {} ", aji.balance);
        println!("collins balance : {} ", collins.balance);

        assert(ppt.owner == caller_2, 'trade failed');
        assert(ppp.owner == caller_1, 'trade failed');
        assert(aji.no_section1 == 1, 'Section update');
        assert(collins.no_section1 == 0, 'Section update');
        assert(aji.no_section2 == 0, 'Section update');
        assert(collins.no_section2 == 1, 'Section update');
    }

    #[test]
    fn test_offer_trade_cash_for_chaance_jail_card() {
        let caller_1 = contract_address_const::<'aji'>();
        let caller_2 = contract_address_const::<'collins'>();
        let username = 'Ajidokwu';
        let username_1 = 'Collins';

        let ndef = namespace_def();
        let mut world = spawn_test_world([ndef].span());
        world.sync_perms_and_inits(contract_defs());

        let (contract_address, _) = world.dns(@"actions").unwrap();
        let actions_system = IActionsDispatcher { contract_address };

        testing::set_contract_address(caller_2);
        actions_system.register_new_player(username_1);

        testing::set_contract_address(caller_1);
        actions_system.register_new_player(username);

        testing::set_contract_address(caller_1);
        actions_system.create_new_game(GameType::PublicGame, PlayerSymbol::Hat, 4);

        testing::set_contract_address(caller_2);
        actions_system.join_game(PlayerSymbol::Dog, 1);

        testing::set_contract_address(caller_1);
        let started = actions_system.start_game(1);
        assert(started, 'Game start fail');

        let game_p = actions_system.retrieve_game(1);

        testing::set_contract_address(caller_1);
        actions_system.move_player(1, 7);
        let chance = "Get out of Jail Free";

        let mut g = actions_system.retrieve_game(1);
        let mut p = actions_system.retrieve_game_player(caller_1, 1);

        let (g, ply) = actions_system.process_chance_card(g.clone(), p, chance);
        actions_system.finish_turn(g);

        testing::set_contract_address(caller_2);
        actions_system.move_player(1, 1);
        let mut property = actions_system.get_property(1, 1);
        actions_system.buy_property(property);

        testing::set_contract_address(caller_1);
        let mut ga = actions_system.retrieve_game(1);
        actions_system.move_player(1, 1);
        actions_system.finish_turn(ga);

        testing::set_contract_address(caller_2);
        let mut offered_property_ids: Array<u8> = array![];
        let mut requested_property_ids: Array<u8> = array![];
        offered_property_ids.append(6);
        requested_property_ids.append(1);
        let mut trade_id = actions_system
            .offer_trade(
                1,
                caller_1,
                offered_property_ids,
                requested_property_ids,
                50,
                0,
                TradeOffer::CashForChanceJailCard,
            );

        println!("trade id : {} ", trade_id);

        actions_system.move_player(1, 5);
        let g = actions_system.retrieve_game(1);
        actions_system.finish_turn(g);

        testing::set_contract_address(caller_1);
        let s = actions_system.accept_trade(1, 1);
        assert(s, 'accept failed');

        let aji = actions_system.retrieve_game_player(caller_1, 1);
        let mut collins = actions_system.retrieve_game_player(caller_2, 1);

        actions_system.move_player(1, 5);

        println!("aji balance : {} ", aji.balance);
        println!("collins balance : {} ", collins.balance);

        assert(!aji.chance_jail_card, 'Section update');
        assert(collins.chance_jail_card, 'Section update');
    }

    #[test]
    fn test_offer_trade_chance_jail_card_for_cash() {
        let caller_1 = contract_address_const::<'aji'>();
        let caller_2 = contract_address_const::<'collins'>();
        let username = 'Ajidokwu';
        let username_1 = 'Collins';

        let ndef = namespace_def();
        let mut world = spawn_test_world([ndef].span());
        world.sync_perms_and_inits(contract_defs());

        let (contract_address, _) = world.dns(@"actions").unwrap();
        let actions_system = IActionsDispatcher { contract_address };

        testing::set_contract_address(caller_2);
        actions_system.register_new_player(username_1);

        testing::set_contract_address(caller_1);
        actions_system.register_new_player(username);

        testing::set_contract_address(caller_1);
        actions_system.create_new_game(GameType::PublicGame, PlayerSymbol::Hat, 4);

        testing::set_contract_address(caller_2);
        actions_system.join_game(PlayerSymbol::Dog, 1);

        testing::set_contract_address(caller_1);
        let started = actions_system.start_game(1);
        assert(started, 'Game start fail');

        let game_p = actions_system.retrieve_game(1);

        testing::set_contract_address(caller_1);
        actions_system.move_player(1, 7);
        let chance = "Get out of Jail Free";

        let mut g = actions_system.retrieve_game(1);
        let mut p = actions_system.retrieve_game_player(caller_1, 1);

        let (g, ply) = actions_system.process_chance_card(g.clone(), p, chance);
        actions_system.finish_turn(g.clone());

        testing::set_contract_address(caller_2);
        actions_system.move_player(1, 1);
        actions_system.finish_turn(g);

        testing::set_contract_address(caller_1);
        let mut offered_property_ids: Array<u8> = array![];
        let mut requested_property_ids: Array<u8> = array![];
        offered_property_ids.append(6);
        requested_property_ids.append(1);
        let mut trade_id = actions_system
            .offer_trade(
                1,
                caller_2,
                offered_property_ids,
                requested_property_ids,
                0,
                50,
                TradeOffer::ChanceJailCardForCash,
            );

        println!("trade id : {} ", trade_id);

        actions_system.move_player(1, 5);
        let g = actions_system.retrieve_game(1);
        actions_system.finish_turn(g);

        testing::set_contract_address(caller_2);
        let s = actions_system.accept_trade(1, 1);
        assert(s, 'accept failed');

        let aji = actions_system.retrieve_game_player(caller_1, 1);
        let mut collins = actions_system.retrieve_game_player(caller_2, 1);

        actions_system.move_player(1, 5);

        println!("aji balance : {} ", aji.balance);
        println!("collins balance : {} ", collins.balance);

        assert(!aji.chance_jail_card, 'Section update');
        assert(collins.chance_jail_card, 'Section update');
    }

    #[test]
    fn test_offer_trade_cash_for_community_jail_card() {
        let caller_1 = contract_address_const::<'aji'>();
        let caller_2 = contract_address_const::<'collins'>();
        let username = 'Ajidokwu';
        let username_1 = 'Collins';

        let ndef = namespace_def();
        let mut world = spawn_test_world([ndef].span());
        world.sync_perms_and_inits(contract_defs());

        let (contract_address, _) = world.dns(@"actions").unwrap();
        let actions_system = IActionsDispatcher { contract_address };

        testing::set_contract_address(caller_2);
        actions_system.register_new_player(username_1);

        testing::set_contract_address(caller_1);
        actions_system.register_new_player(username);

        testing::set_contract_address(caller_1);
        actions_system.create_new_game(GameType::PublicGame, PlayerSymbol::Hat, 4);

        testing::set_contract_address(caller_2);
        actions_system.join_game(PlayerSymbol::Dog, 1);

        testing::set_contract_address(caller_1);
        let started = actions_system.start_game(1);
        assert(started, 'Game start fail');

        let game_p = actions_system.retrieve_game(1);

        testing::set_contract_address(caller_1);
        actions_system.move_player(1, 2);
        let chance = "Get Out of Jail Free";

        let mut g = actions_system.retrieve_game(1);
        let mut p = actions_system.retrieve_game_player(caller_1, 1);

        let (g, ply) = actions_system.process_community_chest_card(g.clone(), p, chance);
        actions_system.finish_turn(g);

        p = actions_system.retrieve_game_player(caller_1, 1);
        assert!(p.comm_free_card, "p does not have community jail card");

        testing::set_contract_address(caller_2);
        actions_system.move_player(1, 1);
        let mut property = actions_system.get_property(1, 1);
        actions_system.buy_property(property);

        testing::set_contract_address(caller_1);
        let mut offered_property_ids: Array<u8> = array![];
        let mut requested_property_ids: Array<u8> = array![];
        offered_property_ids.append(6);
        requested_property_ids.append(1);
        let mut trade_id = actions_system
            .offer_trade(
                1,
                caller_2,
                offered_property_ids,
                requested_property_ids,
                0,
                50,
                TradeOffer::CashForCommunityJailCard,
            );

        println!("trade id : {} ", trade_id);

        actions_system.move_player(1, 2);
        let g = actions_system.retrieve_game(1);
        actions_system.finish_turn(g);

        testing::set_contract_address(caller_2);
        let s = actions_system.accept_trade(1, 1);
        assert(s, 'accept failed');

        let aji = actions_system.retrieve_game_player(caller_1, 1);
        let mut collins = actions_system.retrieve_game_player(caller_2, 1);

        actions_system.move_player(1, 5);

        println!("aji balance : {} ", aji.balance);
        println!("collins balance : {} ", collins.balance);

        assert(!aji.comm_free_card, 'Section update');
        assert(collins.comm_free_card, 'Section update');
    }

    #[test]
    fn test_offer_trade_community_jail_card_for_cash() {
        let caller_1 = contract_address_const::<'aji'>();
        let caller_2 = contract_address_const::<'collins'>();
        let username = 'Ajidokwu';
        let username_1 = 'Collins';

        let ndef = namespace_def();
        let mut world = spawn_test_world([ndef].span());
        world.sync_perms_and_inits(contract_defs());

        let (contract_address, _) = world.dns(@"actions").unwrap();
        let actions_system = IActionsDispatcher { contract_address };

        testing::set_contract_address(caller_2);
        actions_system.register_new_player(username_1);

        testing::set_contract_address(caller_1);
        actions_system.register_new_player(username);

        testing::set_contract_address(caller_1);
        actions_system.create_new_game(GameType::PublicGame, PlayerSymbol::Hat, 4);

        testing::set_contract_address(caller_2);
        actions_system.join_game(PlayerSymbol::Dog, 1);

        testing::set_contract_address(caller_1);
        let started = actions_system.start_game(1);
        assert(started, 'Game start fail');

        let game_p = actions_system.retrieve_game(1);

        testing::set_contract_address(caller_1);
        actions_system.move_player(1, 2);
        let chance = "Get Out of Jail Free";

        let mut g = actions_system.retrieve_game(1);
        let mut p = actions_system.retrieve_game_player(caller_1, 1);

        let (g, ply) = actions_system.process_community_chest_card(g.clone(), p, chance);
        actions_system.finish_turn(g);

        p = actions_system.retrieve_game_player(caller_1, 1);
        assert!(p.comm_free_card, "p does not have community jail card");

        testing::set_contract_address(caller_2);
        let mut offered_property_ids: Array<u8> = array![];
        let mut requested_property_ids: Array<u8> = array![];
        offered_property_ids.append(6);
        requested_property_ids.append(1);
        let mut trade_id = actions_system
            .offer_trade(
                1,
                caller_1,
                offered_property_ids,
                requested_property_ids,
                50,
                0,
                TradeOffer::CommunityJailCardForCash,
            );

        println!("trade id : {} ", trade_id);

        actions_system.move_player(1, 5);
        let g = actions_system.retrieve_game(1);
        actions_system.finish_turn(g);

        testing::set_contract_address(caller_1);
        let s = actions_system.accept_trade(1, 1);
        assert(s, 'accept failed');

        let aji = actions_system.retrieve_game_player(caller_1, 1);
        let mut collins = actions_system.retrieve_game_player(caller_2, 1);

        assert(!aji.comm_free_card, 'Section update');
        assert(collins.comm_free_card, 'Section update');
    }

    #[test]
    fn test_offer_test_counter_trade() {
        let caller_1 = contract_address_const::<'aji'>();
        let caller_2 = contract_address_const::<'collins'>();
        let username = 'Ajidokwu';
        let username_1 = 'Collins';

        let ndef = namespace_def();
        let mut world = spawn_test_world([ndef].span());
        world.sync_perms_and_inits(contract_defs());

        let (contract_address, _) = world.dns(@"actions").unwrap();
        let actions_system = IActionsDispatcher { contract_address };

        testing::set_contract_address(caller_2);
        actions_system.register_new_player(username_1);

        testing::set_contract_address(caller_1);
        actions_system.register_new_player(username);

        testing::set_contract_address(caller_1);
        actions_system.create_new_game(GameType::PublicGame, PlayerSymbol::Hat, 4);

        testing::set_contract_address(caller_2);
        actions_system.join_game(PlayerSymbol::Dog, 1);

        testing::set_contract_address(caller_1);
        let started = actions_system.start_game(1);
        assert(started, 'Game start fail');

        let game_p = actions_system.retrieve_game(1);

        testing::set_contract_address(caller_1);
        actions_system.move_player(1, 2);
        let chance = "Get Out of Jail Free";

        let mut g = actions_system.retrieve_game(1);
        let mut p = actions_system.retrieve_game_player(caller_1, 1);

        let (g, ply) = actions_system.process_community_chest_card(g.clone(), p, chance);
        actions_system.finish_turn(g);

        p = actions_system.retrieve_game_player(caller_1, 1);
        assert!(p.comm_free_card, "p does not have community jail card");

        testing::set_contract_address(caller_2);
        let mut offered_property_ids: Array<u8> = array![];
        let mut requested_property_ids: Array<u8> = array![];
        offered_property_ids.append(6);
        requested_property_ids.append(1);
        let mut trade_id = actions_system
            .offer_trade(
                1,
                caller_1,
                offered_property_ids.clone(),
                requested_property_ids.clone(),
                50,
                0,
                TradeOffer::ChanceJailCardForCash,
            );

        actions_system.move_player(1, 5);
        let g = actions_system.retrieve_game(1);
        actions_system.finish_turn(g);

        testing::set_contract_address(caller_1);
        actions_system
            .counter_trade(
                1,
                1,
                offered_property_ids,
                requested_property_ids.clone(),
                50,
                0,
                TradeOffer::CommunityJailCardForCash,
            );

        testing::set_contract_address(caller_2);
        testing::set_contract_address(caller_2);
        actions_system.approve_counter_trade(1);

        testing::set_contract_address(caller_1);
        let s = actions_system.accept_trade(1, 1);
        assert(s, 'accept failed');

        let aji = actions_system.retrieve_game_player(caller_1, 1);
        let mut collins = actions_system.retrieve_game_player(caller_2, 1);
        assert(!aji.comm_free_card, 'Section update');
        assert(collins.comm_free_card, 'Section update');
    }

    #[test]
    fn test_offer_test_reject_trade() {
        let caller_1 = contract_address_const::<'aji'>();
        let caller_2 = contract_address_const::<'collins'>();
        let username = 'Ajidokwu';
        let username_1 = 'Collins';

        let ndef = namespace_def();
        let mut world = spawn_test_world([ndef].span());
        world.sync_perms_and_inits(contract_defs());

        let (contract_address, _) = world.dns(@"actions").unwrap();
        let actions_system = IActionsDispatcher { contract_address };

        testing::set_contract_address(caller_2);
        actions_system.register_new_player(username_1);

        testing::set_contract_address(caller_1);
        actions_system.register_new_player(username);

        testing::set_contract_address(caller_1);
        actions_system.create_new_game(GameType::PublicGame, PlayerSymbol::Hat, 4);

        testing::set_contract_address(caller_2);
        actions_system.join_game(PlayerSymbol::Dog, 1);

        testing::set_contract_address(caller_1);
        let started = actions_system.start_game(1);
        assert(started, 'Game start fail');

        let game_p = actions_system.retrieve_game(1);

        testing::set_contract_address(caller_1);
        actions_system.move_player(1, 2);
        let chance = "Get Out of Jail Free";

        let mut g = actions_system.retrieve_game(1);
        let mut p = actions_system.retrieve_game_player(caller_1, 1);

        let (g, ply) = actions_system.process_community_chest_card(g.clone(), p, chance);
        actions_system.finish_turn(g);

        p = actions_system.retrieve_game_player(caller_1, 1);
        assert!(p.comm_free_card, "p does not have community jail card");

        testing::set_contract_address(caller_2);
        let mut offered_property_ids: Array<u8> = array![];
        let mut requested_property_ids: Array<u8> = array![];
        offered_property_ids.append(6);
        requested_property_ids.append(1);
        let mut trade_id = actions_system
            .offer_trade(
                1,
                caller_1,
                offered_property_ids.clone(),
                requested_property_ids.clone(),
                50,
                0,
                TradeOffer::ChanceJailCardForCash,
            );

        actions_system.move_player(1, 5);
        let g = actions_system.retrieve_game(1);
        actions_system.finish_turn(g);

        testing::set_contract_address(caller_1);
        actions_system.reject_trade(trade_id, 1);

        let trade = actions_system.get_trade(trade_id);
        assert(trade.status == TradeStatus::Rejected, 'Trade not rejected');
    }

    #[test]
    fn test_player_net_worth() {
        let caller_1 = contract_address_const::<'aji'>();
        let caller_2 = contract_address_const::<'collins'>();
        let caller_3 = contract_address_const::<'jerry'>();
        let caller_4 = contract_address_const::<'aliyu'>();
        let username = 'Ajidokwu';
        let username_1 = 'Collins';
        let username_2 = 'Jerry';
        let username_3 = 'Aliyu';

        let ndef = namespace_def();
        let mut world = spawn_test_world([ndef].span());
        world.sync_perms_and_inits(contract_defs());

        let (contract_address, _) = world.dns(@"actions").unwrap();
        let actions_system = IActionsDispatcher { contract_address };

        testing::set_contract_address(caller_2);
        actions_system.register_new_player(username_1);

        testing::set_contract_address(caller_1);
        actions_system.register_new_player(username);

        testing::set_contract_address(caller_3);
        actions_system.register_new_player(username_2);

        testing::set_contract_address(caller_4);
        actions_system.register_new_player(username_3);

        testing::set_contract_address(caller_1);
        actions_system.create_new_game(GameType::PublicGame, PlayerSymbol::Hat, 4);

        testing::set_contract_address(caller_2);
        actions_system.join_game(PlayerSymbol::Dog, 1);

        testing::set_contract_address(caller_3);
        actions_system.join_game(PlayerSymbol::Car, 1);

        testing::set_contract_address(caller_4);
        actions_system.join_game(PlayerSymbol::Iron, 1);

        testing::set_contract_address(caller_1);
        let started = actions_system.start_game(1);
        assert(started, 'Game start fail');

        testing::set_contract_address(caller_1);
        actions_system.move_player(1, 1);
        let mut property = actions_system.get_property(1, 1);
        actions_system.buy_property(property);

        testing::set_contract_address(caller_2);
        actions_system.move_player(1, 12);

        let mut game = actions_system.retrieve_game(1);
        actions_system.finish_turn(game);

        testing::set_contract_address(caller_3);
        actions_system.move_player(1, 8);
        game = actions_system.retrieve_game(1);
        actions_system.finish_turn(game);

        testing::set_contract_address(caller_4);
        actions_system.move_player(1, 8);
        game = actions_system.retrieve_game(1);
        actions_system.finish_turn(game);

        testing::set_contract_address(caller_1);
        actions_system.move_player(1, 2);
        property = actions_system.get_property(3, 1);
        actions_system.buy_property(property);

        testing::set_contract_address(caller_2);
        actions_system.move_player(1, 12);

        game = actions_system.retrieve_game(1);
        actions_system.finish_turn(game);

        testing::set_contract_address(caller_3);
        actions_system.move_player(1, 8);
        game = actions_system.retrieve_game(1);
        actions_system.finish_turn(game);

        testing::set_contract_address(caller_4);
        actions_system.move_player(1, 8);
        game = actions_system.retrieve_game(1);
        actions_system.finish_turn(game);

        testing::set_contract_address(caller_1);
        property = actions_system.get_property(3, 1);
        actions_system.buy_house_or_hotel(property);

        property = actions_system.get_property(1, 1);
        actions_system.buy_house_or_hotel(property);

        property = actions_system.get_property(3, 1);
        actions_system.buy_house_or_hotel(property);

        property = actions_system.get_property(1, 1);
        actions_system.buy_house_or_hotel(property);

        property = actions_system.get_property(3, 1);
        actions_system.buy_house_or_hotel(property);

        property = actions_system.get_property(1, 1);
        actions_system.buy_house_or_hotel(property);

        property = actions_system.get_property(3, 1);
        actions_system.buy_house_or_hotel(property);

        property = actions_system.get_property(1, 1);
        actions_system.buy_house_or_hotel(property);

        property = actions_system.get_property(3, 1);
        actions_system.buy_house_or_hotel(property);

        property = actions_system.get_property(1, 1);
        let success = actions_system.buy_house_or_hotel(property);
        assert(success, 'house failed');
        property = actions_system.get_property(3, 1);
        assert(property.development == 5, 'dev correct');

        let aji = actions_system.retrieve_game_player(caller_1, 1);

        assert(aji.total_hotels_owned == 2, 'house count error');
        assert(aji.total_houses_owned == 8, 'house count error');

        let aji_networth = actions_system.calculate_net_worth(aji);
        let collins_networth = actions_system
            .calculate_net_worth(actions_system.retrieve_game_player(caller_2, 1));
        let jerry_networth = actions_system
            .calculate_net_worth(actions_system.retrieve_game_player(caller_3, 1));
        let ali_networth = actions_system
            .calculate_net_worth(actions_system.retrieve_game_player(caller_4, 1));
        println!("aji net worth : {}", aji_networth);
        println!("collins net worth : {}", collins_networth);
        println!("jerry net worth : {}", jerry_networth);
        println!("ali net worth : {}", ali_networth);
    }

    #[test]
    fn test_winner() {
        let caller_1 = contract_address_const::<'aji'>();
        let caller_2 = contract_address_const::<'collins'>();
        let caller_3 = contract_address_const::<'jerry'>();
        let caller_4 = contract_address_const::<'aliyu'>();
        let username = 'Ajidokwu';
        let username_1 = 'Collins';
        let username_2 = 'Jerry';
        let username_3 = 'Aliyu';

        let ndef = namespace_def();
        let mut world = spawn_test_world([ndef].span());
        world.sync_perms_and_inits(contract_defs());

        let (contract_address, _) = world.dns(@"actions").unwrap();
        let actions_system = IActionsDispatcher { contract_address };

        testing::set_contract_address(caller_2);
        actions_system.register_new_player(username_1);

        testing::set_contract_address(caller_1);
        actions_system.register_new_player(username);

        testing::set_contract_address(caller_3);
        actions_system.register_new_player(username_2);

        testing::set_contract_address(caller_4);
        actions_system.register_new_player(username_3);

        testing::set_contract_address(caller_1);
        actions_system.create_new_game(GameType::PublicGame, PlayerSymbol::Hat, 4);

        testing::set_contract_address(caller_2);
        actions_system.join_game(PlayerSymbol::Dog, 1);

        testing::set_contract_address(caller_3);
        actions_system.join_game(PlayerSymbol::Car, 1);

        testing::set_contract_address(caller_4);
        actions_system.join_game(PlayerSymbol::Iron, 1);

        testing::set_contract_address(caller_1);
        let started = actions_system.start_game(1);
        assert(started, 'Game start fail');

        testing::set_contract_address(caller_1);
        actions_system.move_player(1, 1);
        let mut property = actions_system.get_property(1, 1);
        actions_system.buy_property(property);

        testing::set_contract_address(caller_2);
        actions_system.move_player(1, 12);

        let mut game = actions_system.retrieve_game(1);
        actions_system.finish_turn(game);

        testing::set_contract_address(caller_3);
        actions_system.move_player(1, 8);
        game = actions_system.retrieve_game(1);
        actions_system.finish_turn(game);

        testing::set_contract_address(caller_4);
        actions_system.move_player(1, 8);
        game = actions_system.retrieve_game(1);
        actions_system.finish_turn(game);

        testing::set_contract_address(caller_1);
        actions_system.move_player(1, 2);
        property = actions_system.get_property(3, 1);
        actions_system.buy_property(property);

        testing::set_contract_address(caller_2);
        actions_system.move_player(1, 12);

        game = actions_system.retrieve_game(1);
        actions_system.finish_turn(game);

        testing::set_contract_address(caller_3);
        actions_system.move_player(1, 8);
        game = actions_system.retrieve_game(1);
        actions_system.finish_turn(game);

        testing::set_contract_address(caller_4);
        actions_system.move_player(1, 8);
        game = actions_system.retrieve_game(1);
        actions_system.finish_turn(game);

        testing::set_contract_address(caller_1);
        property = actions_system.get_property(3, 1);
        actions_system.buy_house_or_hotel(property);

        property = actions_system.get_property(1, 1);
        actions_system.buy_house_or_hotel(property);

        property = actions_system.get_property(3, 1);
        actions_system.buy_house_or_hotel(property);

        property = actions_system.get_property(1, 1);
        actions_system.buy_house_or_hotel(property);

        property = actions_system.get_property(3, 1);
        actions_system.buy_house_or_hotel(property);

        property = actions_system.get_property(1, 1);
        actions_system.buy_house_or_hotel(property);

        property = actions_system.get_property(3, 1);
        actions_system.buy_house_or_hotel(property);

        property = actions_system.get_property(1, 1);
        actions_system.buy_house_or_hotel(property);

        property = actions_system.get_property(3, 1);
        actions_system.buy_house_or_hotel(property);

        property = actions_system.get_property(1, 1);
        let success = actions_system.buy_house_or_hotel(property);
        assert(success, 'house failed');
        property = actions_system.get_property(3, 1);
        assert(property.development == 5, 'dev correct');

        let aji = actions_system.retrieve_game_player(caller_1, 1);

        assert(aji.total_hotels_owned == 2, 'house count error');
        assert(aji.total_houses_owned == 8, 'house count error');

        let aji_networth = actions_system.calculate_net_worth(aji);
        let collins_networth = actions_system
            .calculate_net_worth(actions_system.retrieve_game_player(caller_2, 1));
        let jerry_networth = actions_system
            .calculate_net_worth(actions_system.retrieve_game_player(caller_3, 1));
        let ali_networth = actions_system
            .calculate_net_worth(actions_system.retrieve_game_player(caller_4, 1));
        println!("aji net worth : {}", aji_networth);
        println!("collins net worth : {}", collins_networth);
        println!("jerry net worth : {}", jerry_networth);
        println!("ali net worth : {}", ali_networth);

        let mut players = array![
            actions_system.retrieve_game_player(caller_1, 1),
            actions_system.retrieve_game_player(caller_2, 1),
            actions_system.retrieve_game_player(caller_3, 1),
            actions_system.retrieve_game_player(caller_4, 1),
        ];

        let winner = actions_system.get_winner_by_net_worth(players);

        let winner_felt: felt252 = winner.into();
        println!("Winner is: {}", winner_felt);
        assert(winner == caller_1, 'Winner is not Aji');
    }


    #[test]
    fn test_end_game() {
        let caller_1 = contract_address_const::<'aji'>();
        let caller_2 = contract_address_const::<'collins'>();
        let caller_3 = contract_address_const::<'jerry'>();
        let caller_4 = contract_address_const::<'aliyu'>();
        let username = 'Ajidokwu';
        let username_1 = 'Collins';
        let username_2 = 'Jerry';
        let username_3 = 'Aliyu';

        let ndef = namespace_def();
        let mut world = spawn_test_world([ndef].span());
        world.sync_perms_and_inits(contract_defs());

        let (contract_address, _) = world.dns(@"actions").unwrap();
        let actions_system = IActionsDispatcher { contract_address };

        testing::set_contract_address(caller_2);
        actions_system.register_new_player(username_1);

        testing::set_contract_address(caller_1);
        actions_system.register_new_player(username);

        testing::set_contract_address(caller_3);
        actions_system.register_new_player(username_2);

        testing::set_contract_address(caller_4);
        actions_system.register_new_player(username_3);

        testing::set_contract_address(caller_1);
        actions_system.create_new_game(GameType::PublicGame, PlayerSymbol::Hat, 4);

        testing::set_contract_address(caller_2);
        actions_system.join_game(PlayerSymbol::Dog, 1);

        testing::set_contract_address(caller_3);
        actions_system.join_game(PlayerSymbol::Car, 1);

        testing::set_contract_address(caller_4);
        actions_system.join_game(PlayerSymbol::Iron, 1);

        testing::set_contract_address(caller_1);
        let started = actions_system.start_game(1);
        assert(started, 'Game start fail');

        testing::set_contract_address(caller_1);
        actions_system.move_player(1, 1);
        let mut property = actions_system.get_property(1, 1);
        actions_system.buy_property(property);

        testing::set_contract_address(caller_2);
        actions_system.move_player(1, 12);

        let mut game = actions_system.retrieve_game(1);
        actions_system.finish_turn(game);

        testing::set_contract_address(caller_3);
        actions_system.move_player(1, 8);
        game = actions_system.retrieve_game(1);
        actions_system.finish_turn(game);

        testing::set_contract_address(caller_4);
        actions_system.move_player(1, 8);
        game = actions_system.retrieve_game(1);
        actions_system.finish_turn(game);

        testing::set_contract_address(caller_1);
        actions_system.move_player(1, 2);
        property = actions_system.get_property(3, 1);
        actions_system.buy_property(property);

        testing::set_contract_address(caller_2);
        actions_system.move_player(1, 12);

        game = actions_system.retrieve_game(1);
        actions_system.finish_turn(game);

        testing::set_contract_address(caller_3);
        actions_system.move_player(1, 8);
        game = actions_system.retrieve_game(1);
        actions_system.finish_turn(game);

        testing::set_contract_address(caller_4);
        actions_system.move_player(1, 8);
        game = actions_system.retrieve_game(1);
        actions_system.finish_turn(game);

        testing::set_contract_address(caller_1);
        property = actions_system.get_property(3, 1);
        actions_system.buy_house_or_hotel(property);

        property = actions_system.get_property(1, 1);
        actions_system.buy_house_or_hotel(property);

        property = actions_system.get_property(3, 1);
        actions_system.buy_house_or_hotel(property);

        property = actions_system.get_property(1, 1);
        actions_system.buy_house_or_hotel(property);

        property = actions_system.get_property(3, 1);
        actions_system.buy_house_or_hotel(property);

        property = actions_system.get_property(1, 1);
        actions_system.buy_house_or_hotel(property);

        property = actions_system.get_property(3, 1);
        actions_system.buy_house_or_hotel(property);

        property = actions_system.get_property(1, 1);
        actions_system.buy_house_or_hotel(property);

        property = actions_system.get_property(3, 1);
        actions_system.buy_house_or_hotel(property);

        property = actions_system.get_property(1, 1);
        let success = actions_system.buy_house_or_hotel(property);
        assert(success, 'house failed');
        property = actions_system.get_property(3, 1);
        assert(property.development == 5, 'dev correct');

        let mut game = actions_system.retrieve_game(1);

        let winner = actions_system.end_game(game.clone());
        game = actions_system.retrieve_game(1);
        let winner_felt: felt252 = winner.into();
        println!("Winner is: {}", winner_felt);
        assert(winner == caller_1, 'Winner is not Aji');
        assert(game.status == GameStatus::Ended, 'Game not finished');
    }

    #[test]
    fn test_leave_game() {
        let caller_1 = contract_address_const::<'aji'>();
        let caller_2 = contract_address_const::<'collins'>();
        let username = 'Ajidokwu';
        let username_1 = 'Collins';

        let ndef = namespace_def();
        let mut world = spawn_test_world([ndef].span());
        world.sync_perms_and_inits(contract_defs());

        let (contract_address, _) = world.dns(@"actions").unwrap();
        let actions_system = IActionsDispatcher { contract_address };

        testing::set_contract_address(caller_2);
        actions_system.register_new_player(username_1);

        testing::set_contract_address(caller_1);
        actions_system.register_new_player(username);

        testing::set_contract_address(caller_1);
        actions_system.create_new_game(GameType::PublicGame, PlayerSymbol::Hat, 2);

        testing::set_contract_address(caller_2);
        actions_system.join_game(PlayerSymbol::Dog, 1);

        testing::set_contract_address(caller_1);
        let started = actions_system.start_game(1);
        assert(started, 'Game start fail');

        let game_p = actions_system.retrieve_game(1);

        testing::set_contract_address(caller_1);
        actions_system.move_player(1, 2);
        let chance = "Get Out of Jail Free";

        let mut g = actions_system.retrieve_game(1);
        let mut p = actions_system.retrieve_game_player(caller_1, 1);

        let (g, ply) = actions_system.process_community_chest_card(g.clone(), p, chance);
        actions_system.finish_turn(g);

        p = actions_system.retrieve_game_player(caller_1, 1);
        assert!(p.comm_free_card, "p does not have community jail card");

        testing::set_contract_address(caller_2);
        let mut offered_property_ids: Array<u8> = array![];
        let mut requested_property_ids: Array<u8> = array![];
        offered_property_ids.append(6);
        requested_property_ids.append(1);
        let mut trade_id = actions_system
            .offer_trade(
                1,
                caller_1,
                offered_property_ids.clone(),
                requested_property_ids.clone(),
                50,
                0,
                TradeOffer::ChanceJailCardForCash,
            );

        actions_system.move_player(1, 5);
        let g = actions_system.retrieve_game(1);
        actions_system.finish_turn(g);

        testing::set_contract_address(caller_1);
        actions_system.leave_game(1, caller_2);

        let game = actions_system.retrieve_game(1);
        println!("players from array left : {}", game.game_players.len());
        println!("number_of_players left : {}", game.number_of_players);
        assert!(game.game_players.len() == 1, "Game has more than one player");
        assert!(game.status == GameStatus::Ended, "Game is not finished");
    }
}

