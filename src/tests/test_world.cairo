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
    };
    use dojo_starter::model::utility_model::{
        Utility, m_Utility, IdToUtility, m_IdToUtility, UtilityToId, m_UtilityToId,
    };
    use dojo_starter::model::rail_road_model::{
        RailRoad, m_RailRoad, IdToRailRoad, m_IdToRailRoad, RailRoadToId, m_RailRoadToId,
    };
    use dojo_starter::model::chance_model::{Chance, m_Chance};
    use dojo_starter::model::community_chest_model::{CommunityChest, m_CommunityChest};
    use dojo_starter::model::jail_model::{Jail, m_Jail};
    use dojo_starter::model::go_free_parking_model::{Go, m_Go};
    use dojo_starter::model::tax_model::{Tax, m_Tax};
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
                TestResource::Model(m_Utility::TEST_CLASS_HASH),
                TestResource::Model(m_IdToUtility::TEST_CLASS_HASH),
                TestResource::Model(m_UtilityToId::TEST_CLASS_HASH),
                TestResource::Model(m_RailRoad::TEST_CLASS_HASH),
                TestResource::Model(m_IdToRailRoad::TEST_CLASS_HASH),
                TestResource::Model(m_RailRoadToId::TEST_CLASS_HASH),
                TestResource::Model(m_Chance::TEST_CLASS_HASH),
                TestResource::Model(m_CommunityChest::TEST_CLASS_HASH),
                TestResource::Model(m_Jail::TEST_CLASS_HASH),
                TestResource::Model(m_Go::TEST_CLASS_HASH),
                TestResource::Model(m_Tax::TEST_CLASS_HASH),
                TestResource::Model(m_GamePlayer::TEST_CLASS_HASH),
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
        println!("Game  players :{}", game_p.game_players.len());
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
        println!("Game  players :{}", game_p.game_players.len());
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
        println!("Game  players :{}", game_p.game_players.len());

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
        actions_system.move_player(1, 2);
        let mut property = actions_system.get_property(2, 1);
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
        property = actions_system.get_property(4, 1);
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
        property = actions_system.get_property(4, 1);
        actions_system.buy_house_or_hotel(property);

        property = actions_system.get_property(2, 1);
        actions_system.buy_house_or_hotel(property);

        property = actions_system.get_property(4, 1);
        actions_system.buy_house_or_hotel(property);

        property = actions_system.get_property(2, 1);
        actions_system.buy_house_or_hotel(property);

        property = actions_system.get_property(4, 1);
        actions_system.buy_house_or_hotel(property);

        property = actions_system.get_property(2, 1);
        actions_system.buy_house_or_hotel(property);

        property = actions_system.get_property(4, 1);
        actions_system.buy_house_or_hotel(property);

        property = actions_system.get_property(2, 1);
        actions_system.buy_house_or_hotel(property);

        property = actions_system.get_property(4, 1);
        actions_system.buy_house_or_hotel(property);

        property = actions_system.get_property(2, 1);
        let success = actions_system.buy_house_or_hotel(property);
        assert(success, 'house failed');
        property = actions_system.get_property(4, 1);
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
        actions_system.move_player(1, 2);
        let mut property = actions_system.get_property(2, 1);
        actions_system.buy_property(property);

        // Player 2 lands and pays rent
        testing::set_contract_address(caller_2);
        actions_system.move_player(1, 2);
        let landed_property = actions_system.get_property(2, 1);
        actions_system.pay_rent(landed_property);

        // Player 1 buys property at position 4
        testing::set_contract_address(caller_1);
        actions_system.move_player(1, 2);
        let mut property = actions_system.get_property(4, 1);
        actions_system.buy_property(property);

        // Player 2 lands and pays rent
        testing::set_contract_address(caller_2);
        actions_system.move_player(1, 2);
        let landed_property = actions_system.get_property(4, 1);
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
        actions_system.move_player(1, 2);
        let mut property = actions_system.get_property(2, 1);
        actions_system.buy_property(property);

        // Player 2 lands and pays rent
        testing::set_contract_address(caller_2);
        actions_system.move_player(1, 2);
        let landed_property = actions_system.get_property(2, 1);
        actions_system.pay_rent(landed_property);

        testing::set_contract_address(caller_1);
        actions_system.move_player(1, 2);
        let mut property = actions_system.get_property(4, 1);
        actions_system.buy_property(property);

        testing::set_contract_address(caller_2);
        actions_system.move_player(1, 2);
        let landed_property = actions_system.get_property(4, 1);
        actions_system.pay_rent(landed_property);

        // ONE HOUSE
        testing::set_contract_address(caller_1);
        actions_system.move_player(1, 40);
        let mut property = actions_system.get_property(4, 1);
        let mut property1 = actions_system.get_property(2, 1);
        actions_system.buy_house_or_hotel(property);
        actions_system.buy_house_or_hotel(property1);

        let mut game = actions_system.retrieve_game(1);
        actions_system.finish_turn(game);

        testing::set_contract_address(caller_2);
        actions_system.move_player(1, 40);
        let landed_property = actions_system.get_property(4, 1);
        actions_system.pay_rent(landed_property);

        property = actions_system.get_property(4, 1);
        property1 = actions_system.get_property(2, 1);
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
        actions_system.move_player(1, 2);
        let mut property = actions_system.get_property(2, 1);
        actions_system.buy_property(property);

        // Player 2 lands and pays rent
        testing::set_contract_address(caller_2);
        actions_system.move_player(1, 2);
        let landed_property = actions_system.get_property(2, 1);
        actions_system.pay_rent(landed_property);

        testing::set_contract_address(caller_1);
        actions_system.move_player(1, 2);
        let mut property = actions_system.get_property(4, 1);
        actions_system.buy_property(property);

        testing::set_contract_address(caller_2);
        actions_system.move_player(1, 2);
        let landed_property = actions_system.get_property(4, 1);
        actions_system.pay_rent(landed_property);

        // ONE HOUSE

        testing::set_contract_address(caller_1);
        actions_system.move_player(1, 40);
        let mut property = actions_system.get_property(4, 1);
        let mut property1 = actions_system.get_property(2, 1);
        actions_system.buy_house_or_hotel(property);
        actions_system.buy_house_or_hotel(property1);

        property = actions_system.get_property(4, 1);
        property1 = actions_system.get_property(2, 1);

        actions_system.buy_house_or_hotel(property);
        actions_system.buy_house_or_hotel(property1);

        let mut game = actions_system.retrieve_game(1);
        actions_system.finish_turn(game);

        testing::set_contract_address(caller_2);
        actions_system.move_player(1, 40);
        let landed_property = actions_system.get_property(4, 1);
        actions_system.pay_rent(landed_property);

        property = actions_system.get_property(4, 1);
        property1 = actions_system.get_property(2, 1);
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
        actions_system.move_player(1, 2);
        let mut property = actions_system.get_property(2, 1);
        actions_system.buy_property(property);

        // Player 2 lands and pays rent
        testing::set_contract_address(caller_2);
        actions_system.move_player(1, 2);
        let landed_property = actions_system.get_property(2, 1);
        actions_system.pay_rent(landed_property);

        testing::set_contract_address(caller_1);
        actions_system.move_player(1, 2);
        let mut property = actions_system.get_property(4, 1);
        actions_system.buy_property(property);

        testing::set_contract_address(caller_2);
        actions_system.move_player(1, 2);
        let landed_property = actions_system.get_property(4, 1);
        actions_system.pay_rent(landed_property);

        // THREE HOUSES
        testing::set_contract_address(caller_1);
        actions_system.move_player(1, 40);
        let mut property = actions_system.get_property(4, 1);
        let mut property1 = actions_system.get_property(2, 1);
        actions_system.buy_house_or_hotel(property);
        actions_system.buy_house_or_hotel(property1);

        property = actions_system.get_property(4, 1);
        property1 = actions_system.get_property(2, 1);

        actions_system.buy_house_or_hotel(property);
        actions_system.buy_house_or_hotel(property1);

        property = actions_system.get_property(4, 1);
        property1 = actions_system.get_property(2, 1);

        actions_system.buy_house_or_hotel(property);
        actions_system.buy_house_or_hotel(property1);

        let mut game = actions_system.retrieve_game(1);
        actions_system.finish_turn(game);

        testing::set_contract_address(caller_2);
        actions_system.move_player(1, 40);
        let landed_property = actions_system.get_property(4, 1);
        actions_system.pay_rent(landed_property);

        property = actions_system.get_property(4, 1);
        property1 = actions_system.get_property(2, 1);
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
        actions_system.move_player(1, 2);
        let mut property = actions_system.get_property(2, 1);
        actions_system.buy_property(property);

        // Player 2 lands and pays rent
        testing::set_contract_address(caller_2);
        actions_system.move_player(1, 2);
        let landed_property = actions_system.get_property(2, 1);
        actions_system.pay_rent(landed_property);

        testing::set_contract_address(caller_1);
        actions_system.move_player(1, 2);
        let mut property = actions_system.get_property(4, 1);
        actions_system.buy_property(property);

        testing::set_contract_address(caller_2);
        actions_system.move_player(1, 2);
        let landed_property = actions_system.get_property(4, 1);
        actions_system.pay_rent(landed_property);

        // Four HOUSES
        testing::set_contract_address(caller_1);
        actions_system.move_player(1, 40);
        let mut property = actions_system.get_property(4, 1);
        let mut property1 = actions_system.get_property(2, 1);
        actions_system.buy_house_or_hotel(property);
        actions_system.buy_house_or_hotel(property1);

        property = actions_system.get_property(4, 1);
        property1 = actions_system.get_property(2, 1);

        actions_system.buy_house_or_hotel(property);
        actions_system.buy_house_or_hotel(property1);

        property = actions_system.get_property(4, 1);
        property1 = actions_system.get_property(2, 1);

        actions_system.buy_house_or_hotel(property);
        actions_system.buy_house_or_hotel(property1);

        property = actions_system.get_property(4, 1);
        property1 = actions_system.get_property(2, 1);

        actions_system.buy_house_or_hotel(property);
        actions_system.buy_house_or_hotel(property1);

        let mut game = actions_system.retrieve_game(1);
        actions_system.finish_turn(game);

        testing::set_contract_address(caller_2);
        actions_system.move_player(1, 40);
        let landed_property = actions_system.get_property(4, 1);
        actions_system.pay_rent(landed_property);

        property = actions_system.get_property(4, 1);
        property1 = actions_system.get_property(2, 1);
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
        actions_system.move_player(1, 2);
        let mut property = actions_system.get_property(2, 1);
        actions_system.buy_property(property);

        // Player 2 lands and pays rent
        testing::set_contract_address(caller_2);
        actions_system.move_player(1, 2);
        let landed_property = actions_system.get_property(2, 1);
        actions_system.pay_rent(landed_property);

        testing::set_contract_address(caller_1);
        actions_system.move_player(1, 2);
        let mut property = actions_system.get_property(4, 1);
        actions_system.buy_property(property);

        testing::set_contract_address(caller_2);
        actions_system.move_player(1, 2);
        let landed_property = actions_system.get_property(4, 1);
        actions_system.pay_rent(landed_property);

        // Four HOUSES
        testing::set_contract_address(caller_1);
        actions_system.move_player(1, 40);
        let mut property = actions_system.get_property(4, 1);
        let mut property1 = actions_system.get_property(2, 1);
        actions_system.buy_house_or_hotel(property);
        actions_system.buy_house_or_hotel(property1);

        property = actions_system.get_property(4, 1);
        property1 = actions_system.get_property(2, 1);

        actions_system.buy_house_or_hotel(property);
        actions_system.buy_house_or_hotel(property1);

        property = actions_system.get_property(4, 1);
        property1 = actions_system.get_property(2, 1);

        actions_system.buy_house_or_hotel(property);
        actions_system.buy_house_or_hotel(property1);

        property = actions_system.get_property(4, 1);
        property1 = actions_system.get_property(2, 1);

        actions_system.buy_house_or_hotel(property);
        actions_system.buy_house_or_hotel(property1);

        property = actions_system.get_property(4, 1);
        property1 = actions_system.get_property(2, 1);

        actions_system.buy_house_or_hotel(property);
        actions_system.buy_house_or_hotel(property1);

        let mut game = actions_system.retrieve_game(1);
        actions_system.finish_turn(game);

        testing::set_contract_address(caller_2);
        actions_system.move_player(1, 40);
        let landed_property = actions_system.get_property(4, 1);
        actions_system.pay_rent(landed_property);

        property = actions_system.get_property(4, 1);
        property1 = actions_system.get_property(2, 1);
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
        actions_system.move_player(1, 2);
        let mut property = actions_system.get_property(2, 1);
        actions_system.buy_property(property);

        // Player 2 lands and pays rent
        testing::set_contract_address(caller_2);
        actions_system.move_player(1, 2);
        let landed_property = actions_system.get_property(2, 1);
        actions_system.pay_rent(landed_property);

        testing::set_contract_address(caller_1);
        actions_system.move_player(1, 2);
        let mut property = actions_system.get_property(4, 1);
        actions_system.buy_property(property);

        testing::set_contract_address(caller_2);
        actions_system.move_player(1, 2);
        let landed_property = actions_system.get_property(4, 1);
        actions_system.pay_rent(landed_property);

        // Four HOUSES
        testing::set_contract_address(caller_1);
        actions_system.move_player(1, 40);
        let mut property = actions_system.get_property(4, 1);
        let mut property1 = actions_system.get_property(2, 1);
        actions_system.buy_house_or_hotel(property);
        actions_system.buy_house_or_hotel(property1);

        property = actions_system.get_property(4, 1);
        property1 = actions_system.get_property(2, 1);

        actions_system.buy_house_or_hotel(property);
        actions_system.buy_house_or_hotel(property1);

        property = actions_system.get_property(4, 1);
        property1 = actions_system.get_property(2, 1);

        actions_system.buy_house_or_hotel(property);
        actions_system.buy_house_or_hotel(property1);

        property = actions_system.get_property(4, 1);
        property1 = actions_system.get_property(2, 1);

        actions_system.buy_house_or_hotel(property);
        actions_system.buy_house_or_hotel(property1);

        property = actions_system.get_property(4, 1);
        property1 = actions_system.get_property(2, 1);

        actions_system.buy_house_or_hotel(property);
        actions_system.buy_house_or_hotel(property1);

        property = actions_system.get_property(4, 1);
        property1 = actions_system.get_property(2, 1);

        actions_system.buy_house_or_hotel(property);
        actions_system.buy_house_or_hotel(property1);

        let mut game = actions_system.retrieve_game(1);
        actions_system.finish_turn(game);

        testing::set_contract_address(caller_2);
        actions_system.move_player(1, 40);
        let landed_property = actions_system.get_property(4, 1);
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
        actions_system.move_player(1, 4);

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
        actions_system.move_player(1, 4);

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
    fn test_process_chance() {
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
        println!("array len b4 : {} ", g.chance.len());

        let mut p = actions_system.retrieve_game_player(caller_1, 1);

        let mut chance = actions_system.handle_chance(1, 3);
        println!("chance 1 : {}", chance);
        let (game, ply) = actions_system.process_chance_card(g, p, chance);

        assert(ply.position == 12, 'position error');
        assert(ply.balance == 1430, 'bal error');
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
        actions_system.move_player(1, 3);

        let mut g = actions_system.retrieve_game(1);
        println!("array len b4 : {} ", g.chance.len());

        let mut p = actions_system.retrieve_game_player(caller_1, 1);

        let mut community_chest = actions_system.handle_community_chest(1, 3);
        println!("community_chest: {}", community_chest);

        let (_, ply) = actions_system.process_community_chest_card(g, p, community_chest);

        assert(ply.position == 3, 'position error');
        assert(ply.balance == 1550, 'bal error');
    }
}

