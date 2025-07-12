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


    // #[test]
    // fn test_buy_property_from_a_player() {
    //     let caller_1 = contract_address_const::<'aji'>();
    //     let caller_2 = contract_address_const::<'ajidokwu'>();
    //     let username = 'Ajidokwu';

    //     let ndef = namespace_def();
    //     let mut world = spawn_test_world([ndef].span());
    //     world.sync_perms_and_inits(contract_defs());

    //     let (contract_address, _) = world.dns(@"actions").unwrap();
    //     let actions_system = IActionsDispatcher { contract_address };

    //     testing::set_contract_address(caller_1);
    //     actions_system.register_new_player(username);

    //     testing::set_contract_address(caller_1);
    //     let game_id = actions_system.create_new_game(GameType::PublicGame, PlayerSymbol::Hat, 4);
    //     assert(game_id == 1, 'Wrong game id');

    //     actions_system.mint(caller_1, game_id, 10000);
    //     actions_system.mint(caller_2, game_id, 10000);

    //     testing::set_contract_address(caller_1);
    //     actions_system.buy_property(11, game_id);
    //     actions_system.sell_property(11, game_id);

    //     testing::set_contract_address(caller_2);
    //     actions_system.buy_property(11, game_id);

    //     let property = actions_system.get_property(11, game_id);
    //     assert(property.owner == caller_2, 'invalid property txn');
    // }

    // #[test]
    // #[should_panic]
    // fn test_put_another_player_property_for_sale() {
    //     let caller_1 = contract_address_const::<'aji'>();
    //     let caller_2 = contract_address_const::<'ajidokwu'>();
    //     let username = 'Ajidokwu';

    //     let ndef = namespace_def();
    //     let mut world = spawn_test_world([ndef].span());
    //     world.sync_perms_and_inits(contract_defs());

    //     let (contract_address, _) = world.dns(@"actions").unwrap();
    //     let actions_system = IActionsDispatcher { contract_address };

    //     testing::set_contract_address(caller_1);
    //     actions_system.register_new_player(username);

    //     testing::set_contract_address(caller_1);
    //     let game_id = actions_system.create_new_game(GameType::PublicGame, PlayerSymbol::Hat, 4);
    //     assert(game_id == 1, 'Wrong game id');

    //     actions_system.mint(caller_1, game_id, 10000);
    //     actions_system.mint(caller_2, game_id, 10000);

    //     testing::set_contract_address(caller_1);

    //     actions_system.buy_property(11, game_id);

    //     testing::set_contract_address(caller_2);
    //     actions_system.sell_property(1, game_id);
    // }

    // #[test]
    // #[should_panic]
    // fn test_buy_property_thats_not_for_sale_from_a_player() {
    //     let caller_1 = contract_address_const::<'aji'>();
    //     let caller_2 = contract_address_const::<'ajidokwu'>();
    //     let username = 'Ajidokwu';

    //     let ndef = namespace_def();
    //     let mut world = spawn_test_world([ndef].span());
    //     world.sync_perms_and_inits(contract_defs());

    //     let (contract_address, _) = world.dns(@"actions").unwrap();
    //     let actions_system = IActionsDispatcher { contract_address };

    //     testing::set_contract_address(caller_1);
    //     actions_system.register_new_player(username);

    //     testing::set_contract_address(caller_1);
    //     let game_id = actions_system.create_new_game(GameType::PublicGame, PlayerSymbol::Hat, 4);
    //     assert(game_id == 1, 'Wrong game id');

    //     actions_system.mint(caller_1, game_id, 10000);
    //     actions_system.mint(caller_2, game_id, 10000);

    //     testing::set_contract_address(caller_1);
    //     actions_system.buy_property(11, game_id);

    //     testing::set_contract_address(caller_2);
    //     actions_system.buy_property(11, game_id);

    //     let property = actions_system.get_property(11, game_id);
    //     assert(property.owner == caller_2, 'invalid property txn');
    // }

    // #[test]
    // fn test_upgrade_property() {
    //     let caller_1 = contract_address_const::<'aji'>();
    //     let username = 'Ajidokwu';

    //     let ndef = namespace_def();
    //     let mut world = spawn_test_world([ndef].span());
    //     world.sync_perms_and_inits(contract_defs());

    //     let (contract_address, _) = world.dns(@"actions").unwrap();
    //     let actions_system = IActionsDispatcher { contract_address };

    //     testing::set_contract_address(caller_1);
    //     actions_system.register_new_player(username);

    //     testing::set_contract_address(caller_1);
    //     let game_id = actions_system.create_new_game(GameType::PublicGame, PlayerSymbol::Hat, 4);
    //     assert(game_id == 1, 'Wrong game id');

    //     actions_system.mint(caller_1, game_id, 10000);

    //     testing::set_contract_address(caller_1);
    //     actions_system.buy_property(11, game_id);

    //     actions_system.buy_house_or_hotel(11, game_id);

    //     let property = actions_system.get_property(11, game_id);
    //     assert(property.development == 1, 'invalid  uy property txn');
    // }

    // #[test]
    // #[should_panic]
    // fn test_upgrade_someone_else_property() {
    //     let caller_1 = contract_address_const::<'aji'>();
    //     let caller_2 = contract_address_const::<'ajidokwu'>();
    //     let username = 'Ajidokwu';

    //     let ndef = namespace_def();
    //     let mut world = spawn_test_world([ndef].span());
    //     world.sync_perms_and_inits(contract_defs());

    //     let (contract_address, _) = world.dns(@"actions").unwrap();
    //     let actions_system = IActionsDispatcher { contract_address };

    //     testing::set_contract_address(caller_1);
    //     actions_system.register_new_player(username);

    //     testing::set_contract_address(caller_1);
    //     let game_id = actions_system.create_new_game(GameType::PublicGame, PlayerSymbol::Hat, 4);
    //     assert(game_id == 1, 'Wrong game id');

    //     actions_system.mint(caller_1, game_id, 10000);
    //     actions_system.mint(caller_2, game_id, 10000);

    //     testing::set_contract_address(caller_1);
    //     actions_system.buy_property(11, game_id);

    //     testing::set_contract_address(caller_2);
    //     actions_system.buy_house_or_hotel(1, game_id);

    //     let property = actions_system.get_property(11, game_id);
    //     assert(property.development == 1, 'invalid  uy property txn');
    // }

    // #[test]
    // #[should_panic]
    // fn test_upgrade_property_more_than_allowed() {
    //     let caller_1 = contract_address_const::<'aji'>();
    //     let username = 'Ajidokwu';

    //     let ndef = namespace_def();
    //     let mut world = spawn_test_world([ndef].span());
    //     world.sync_perms_and_inits(contract_defs());

    //     let (contract_address, _) = world.dns(@"actions").unwrap();
    //     let actions_system = IActionsDispatcher { contract_address };

    //     testing::set_contract_address(caller_1);
    //     actions_system.register_new_player(username);

    //     testing::set_contract_address(caller_1);
    //     let game_id = actions_system.create_new_game(GameType::PublicGame, PlayerSymbol::Hat, 4);
    //     assert(game_id == 1, 'Wrong game id');

    //     actions_system.mint(caller_1, game_id, 10000);

    //     testing::set_contract_address(caller_1);
    //     actions_system.buy_property(11, game_id);

    //     actions_system.buy_house_or_hotel(1, game_id);
    //     actions_system.buy_house_or_hotel(1, game_id);
    //     actions_system.buy_house_or_hotel(1, game_id);
    //     actions_system.buy_house_or_hotel(1, game_id);
    //     actions_system.buy_house_or_hotel(1, game_id);
    //     actions_system.buy_house_or_hotel(1, game_id);
    // }

    // #[test]
    // fn test_downgrade_property() {
    //     let caller_1 = contract_address_const::<'aji'>();
    //     let username = 'Ajidokwu';

    //     let ndef = namespace_def();
    //     let mut world = spawn_test_world([ndef].span());
    //     world.sync_perms_and_inits(contract_defs());

    //     let (contract_address, _) = world.dns(@"actions").unwrap();
    //     let actions_system = IActionsDispatcher { contract_address };

    //     testing::set_contract_address(caller_1);
    //     actions_system.register_new_player(username);

    //     testing::set_contract_address(caller_1);
    //     let game_id = actions_system.create_new_game(GameType::PublicGame, PlayerSymbol::Hat, 4);
    //     assert(game_id == 1, 'Wrong game id');

    //     actions_system.mint(caller_1, game_id, 10000);

    //     testing::set_contract_address(caller_1);
    //     actions_system.buy_property(11, game_id);

    //     actions_system.buy_house_or_hotel(11, game_id);
    //     actions_system.buy_house_or_hotel(11, game_id);
    //     actions_system.buy_house_or_hotel(11, game_id);
    //     actions_system.sell_house_or_hotel(11, game_id);

    //     let property = actions_system.get_property(11, game_id);
    //     assert(property.development == 2, 'invalid  uy property txn');
    // }

    // #[test]
    // #[should_panic]
    // fn test_downgrade_someone_else_property() {
    //     let caller_1 = contract_address_const::<'aji'>();
    //     let caller_2 = contract_address_const::<'ajidokwu'>();
    //     let username = 'Ajidokwu';

    //     let ndef = namespace_def();
    //     let mut world = spawn_test_world([ndef].span());
    //     world.sync_perms_and_inits(contract_defs());

    //     let (contract_address, _) = world.dns(@"actions").unwrap();
    //     let actions_system = IActionsDispatcher { contract_address };

    //     testing::set_contract_address(caller_1);
    //     actions_system.register_new_player(username);

    //     testing::set_contract_address(caller_1);
    //     let game_id = actions_system.create_new_game(GameType::PublicGame, PlayerSymbol::Hat, 4);
    //     assert(game_id == 1, 'Wrong game id');

    //     actions_system.mint(caller_1, game_id, 10000);
    //     actions_system.mint(caller_2, game_id, 10000);

    //     testing::set_contract_address(caller_1);
    //     actions_system.buy_property(11, game_id);

    //     testing::set_contract_address(caller_2);
    //     actions_system.sell_house_or_hotel(1, game_id);

    //     let property = actions_system.get_property(11, game_id);
    //     assert(property.development == 1, 'invalid  uy property txn');
    // }

    // #[test]
    // #[should_panic]
    // fn test_downgrade_property_more_than_allowed() {
    //     let caller_1 = contract_address_const::<'aji'>();
    //     let username = 'Ajidokwu';

    //     let ndef = namespace_def();
    //     let mut world = spawn_test_world([ndef].span());
    //     world.sync_perms_and_inits(contract_defs());

    //     let (contract_address, _) = world.dns(@"actions").unwrap();
    //     let actions_system = IActionsDispatcher { contract_address };

    //     testing::set_contract_address(caller_1);
    //     actions_system.register_new_player(username);

    //     testing::set_contract_address(caller_1);
    //     let game_id = actions_system.create_new_game(GameType::PublicGame, PlayerSymbol::Hat, 4);
    //     assert(game_id == 1, 'Wrong game id');

    //     actions_system.mint(caller_1, game_id, 10000);

    //     testing::set_contract_address(caller_1);
    //     actions_system.buy_property(11, game_id);

    //     actions_system.buy_house_or_hotel(1, game_id);
    //     actions_system.buy_house_or_hotel(1, game_id);
    //     actions_system.sell_house_or_hotel(1, game_id);
    //     actions_system.sell_house_or_hotel(1, game_id);
    //     actions_system.sell_house_or_hotel(1, game_id);
    // }
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

        // let game =  actions_system.retrieve_game(1);
        // println!("game id : {}", game.id);

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
        // print_players_positions();
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
        let ppt1 = actions_system.get_property(4, 1);

        testing::set_contract_address(caller_2);
        actions_system.pay_rent(ppt1);

        let aji = actions_system.retrieve_game_player(caller_1, 1);
        assert(aji.balance == 1325, 'rent addition failed');

        let collins = actions_system.retrieve_game_player(caller_2, 1);
        assert(collins.balance == 1475, 'rent deduction failed');
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
    fn test_buy_houses_in_and_hotel_game() {
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
    fn test_play_game() {
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
        let success = actions_system.buy_house_or_hotel(property);

        assert(success, 'house failed');
        // let aji = actions_system.retrieve_game_player(caller_1, 1);
    // property = actions_system.get_property(4, 1);
    // println!("no of total_houses_owned :{}", aji.total_houses_owned);
    // println!("no of property :{}", property.development);
    // testing::set_contract_address(caller_3);
    // actions_system.move_player(1, 5);
    // testing::set_contract_address(caller_4);
    // actions_system.move_player(1, 5);

        // testing::set_contract_address(caller_1);
    // actions_system.move_player(1, 5);

        // let game_p = actions_system.retrieve_game(1);
    // assert(game_p.next_player == caller_2, 'next player failed');

        // let c = *game_p.game_players[1];
    // let j =  *game_p.game_players[2];
    // let al = *game_p.game_players[3];
    // let a = game_p.next_player;

        // let a_felt: felt252 = a.into();
    // let c_felt: felt252 = c.into();
    // let j_felt: felt252 = j.into();
    // let al_felt: felt252 = al.into();

        // println!("a : {}", a_felt);
    // println!("c : {}", c_felt );
    // println!("j : {}", j_felt );
    // println!("al : {}", al_felt );

        // println!("Game  players :{}", game_p.game_players.len());

        // // print_players_positions();
    // println!("owned property id : {}", *aji.properties_owned[0]);
    // let collins = actions_system.retrieve_game_player(caller_2, 1);
    // let jerry = actions_system.retrieve_game_player(caller_3, 1);
    // let aliyu = actions_system.retrieve_game_player(caller_4, 1);

        // let property = actions_system.get_property(39, 1);

        // println!(" name property : {}", property.name);
    // println!("id property : {}", property.id);
    // println!("game_id property : {}", property.game_id);
    // println!("name property : {}", property.name);
    // println!("owner property : {:?}", property.owner);
    // println!("cost_of_property property : {}", property.cost_of_property);
    // println!("property_level property : {}", property.property_level);
    // println!("rent_site_only property : {}", property.rent_site_only);
    // println!("rent_one_house property : {}", property.rent_one_house);
    // println!("rent_two_houses property : {}", property.rent_two_houses);
    // println!("rent_three_houses property : {}", property.rent_three_houses);
    // println!("rent_four_houses property : {}", property.rent_four_houses);
    // println!("cost_of_house property : {}", property.cost_of_house);
    // println!("rent_hotel property : {}", property.rent_hotel);
    // println!("is_mortgaged property : {}", property.is_mortgaged);
    // println!("group_id property : {}", property.group_id);
    // println!("for_sale property : {}", property.for_sale);
    // println!("development property : {}", property.development);
    }
    // fn print_players_positions() {
//     let ndef = namespace_def();
//     let mut world = spawn_test_world([ndef].span());
//     world.sync_perms_and_inits(contract_defs());

    //     let (contract_address, _) = world.dns(@"actions").unwrap();
//     let actions_system = IActionsDispatcher { contract_address };

    //     let caller_1 = contract_address_const::<'aji'>();
//     let caller_2 = contract_address_const::<'collins'>();
//     let caller_3 = contract_address_const::<'jerry'>();
//     let caller_4 = contract_address_const::<'aliyu'>();

    //     let aji = actions_system.retrieve_game_player(caller_1);
//     let collins = actions_system.retrieve_game_player(caller_2);
//     let jerry = actions_system.retrieve_game_player(caller_3);
//     let aliyu = actions_system.retrieve_game_player(caller_4);

    //     println!("aji position: {}", aji.position);
//     println!("collins position: {}", collins.position);
//     println!("jerry position: {}", jerry.position);
//     println!("aliyu position: {}", aliyu.position);

    //     println!("aji balance: {}", aji.balance);
//     println!("collins balance: {}", collins.balance);
//     println!("jerry balance: {}", jerry.balance);
//     println!("aliyu balance: {}", aliyu.balance);
// }
}

