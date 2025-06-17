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
        Game, m_Game, GameMode, GameStatus, GameCounter, m_GameCounter, GameBalance, m_GameBalance,
    };

    use dojo_starter::model::player_model::{
        Player, m_Player, UsernameToAddress, m_UsernameToAddress, AddressToUsername,
        m_AddressToUsername,
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
        let game_id = actions_system.create_new_game(GameMode::MultiPlayer, PlayerSymbol::Hat, 4);
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
        let _game_id = actions_system.create_new_game(GameMode::MultiPlayer, PlayerSymbol::Hat, 4);

        testing::set_contract_address(caller_1);
        let game_id_1 = actions_system.create_new_game(GameMode::MultiPlayer, PlayerSymbol::Hat, 4);
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
        let game_id = actions_system.create_new_game(GameMode::MultiPlayer, PlayerSymbol::Hat, 4);
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
        actions_system.create_new_game(GameMode::MultiPlayer, PlayerSymbol::Hat, 4);

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
        actions_system.create_new_game(GameMode::MultiPlayer, PlayerSymbol::Hat, 4);

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
    fn test_property() {
        let ndef = namespace_def();
        let mut world = spawn_test_world([ndef].span());
        world.sync_perms_and_inits(contract_defs());

        let (contract_address, _) = world.dns(@"actions").unwrap();
        let actions_system = IActionsDispatcher { contract_address };

        actions_system
            .generate_properties(1, 1, 'Eth_Lane', 200, 10, 100, 200, 300, 400, 300, 500, false, 4);

        let property = actions_system.get_property(1, 1);

        assert(property.id == 1, 'wrong id');
    }
    #[test]
    fn test_buy_property() {
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
        let game_id = actions_system.create_new_game(GameMode::MultiPlayer, PlayerSymbol::Hat, 4);
        assert(game_id == 1, 'Wrong game id');

        actions_system.mint(caller_1, game_id, 10000);

        testing::set_contract_address(caller_1);
        actions_system.buy_property(11, game_id);

        let game: Game = actions_system.retrieve_game(game_id);
        assert(game.created_by == username, 'Wrong game id');
        let property = actions_system.get_property(11, game_id);
        assert(property.owner == caller_1, 'invalid property txn');
    }


    #[test]
    fn test_mint_and_balance() {
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
        let game_id = actions_system.create_new_game(GameMode::MultiPlayer, PlayerSymbol::Hat, 4);
        assert(game_id == 1, 'Wrong game id');

        actions_system.mint(caller_1, game_id, 10000);

        let player_balance = actions_system.get_players_balance(caller_1, game_id);
        assert(player_balance == 10000, 'mint failure');
    }

    #[test]
    fn test_buy_property_from_a_player() {
        let caller_1 = contract_address_const::<'aji'>();
        let caller_2 = contract_address_const::<'ajidokwu'>();
        let username = 'Ajidokwu';

        let ndef = namespace_def();
        let mut world = spawn_test_world([ndef].span());
        world.sync_perms_and_inits(contract_defs());

        let (contract_address, _) = world.dns(@"actions").unwrap();
        let actions_system = IActionsDispatcher { contract_address };

        testing::set_contract_address(caller_1);
        actions_system.register_new_player(username);

        testing::set_contract_address(caller_1);
        let game_id = actions_system.create_new_game(GameMode::MultiPlayer, PlayerSymbol::Hat, 4);
        assert(game_id == 1, 'Wrong game id');

        actions_system.mint(caller_1, game_id, 10000);
        actions_system.mint(caller_2, game_id, 10000);

        testing::set_contract_address(caller_1);
        actions_system.buy_property(11, game_id);
        actions_system.sell_property(11, game_id);

        testing::set_contract_address(caller_2);
        actions_system.buy_property(11, game_id);

        let property = actions_system.get_property(11, game_id);
        assert(property.owner == caller_2, 'invalid property txn');
    }

    #[test]
    #[should_panic]
    fn test_put_another_player_property_for_sale() {
        let caller_1 = contract_address_const::<'aji'>();
        let caller_2 = contract_address_const::<'ajidokwu'>();
        let username = 'Ajidokwu';

        let ndef = namespace_def();
        let mut world = spawn_test_world([ndef].span());
        world.sync_perms_and_inits(contract_defs());

        let (contract_address, _) = world.dns(@"actions").unwrap();
        let actions_system = IActionsDispatcher { contract_address };

        testing::set_contract_address(caller_1);
        actions_system.register_new_player(username);

        testing::set_contract_address(caller_1);
        let game_id = actions_system.create_new_game(GameMode::MultiPlayer, PlayerSymbol::Hat, 4);
        assert(game_id == 1, 'Wrong game id');

        actions_system.mint(caller_1, game_id, 10000);
        actions_system.mint(caller_2, game_id, 10000);

        testing::set_contract_address(caller_1);

        actions_system.buy_property(11, game_id);

        testing::set_contract_address(caller_2);
        actions_system.sell_property(1, game_id);
    }


    #[test]
    #[should_panic]
    fn test_buy_property_thats_not_for_sale_from_a_player() {
        let caller_1 = contract_address_const::<'aji'>();
        let caller_2 = contract_address_const::<'ajidokwu'>();
        let username = 'Ajidokwu';

        let ndef = namespace_def();
        let mut world = spawn_test_world([ndef].span());
        world.sync_perms_and_inits(contract_defs());

        let (contract_address, _) = world.dns(@"actions").unwrap();
        let actions_system = IActionsDispatcher { contract_address };

        testing::set_contract_address(caller_1);
        actions_system.register_new_player(username);

        testing::set_contract_address(caller_1);
        let game_id = actions_system.create_new_game(GameMode::MultiPlayer, PlayerSymbol::Hat, 4);
        assert(game_id == 1, 'Wrong game id');

        actions_system.mint(caller_1, game_id, 10000);
        actions_system.mint(caller_2, game_id, 10000);

        testing::set_contract_address(caller_1);
        actions_system.buy_property(11, game_id);

        testing::set_contract_address(caller_2);
        actions_system.buy_property(11, game_id);

        let property = actions_system.get_property(11, game_id);
        assert(property.owner == caller_2, 'invalid property txn');
    }

    #[test]
    fn test_mortgage_property() {
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
        let game_id = actions_system.create_new_game(GameMode::MultiPlayer, PlayerSymbol::Hat, 4);
        assert(game_id == 1, 'Wrong game id');

        actions_system.mint(caller_1, game_id, 10000);

        testing::set_contract_address(caller_1);
        actions_system.buy_property(11, game_id);
        let balance_before_mortgage = actions_system.get_players_balance(caller_1, game_id);
        actions_system.mortgage_property(11, game_id);
        let balance_after_mortgage = actions_system.get_players_balance(caller_1, game_id);
        let property = actions_system.get_property(11, game_id);
        assert(property.is_mortgaged, 'invalid is_mortgaged txn');
        println!(
            "Balance before mortgage: {}, Balance after mortgage: {}",
            balance_before_mortgage,
            balance_after_mortgage,
        );
        assert(balance_after_mortgage > balance_before_mortgage, 'Mortgage Bal update failed');
    }

    #[test]
    #[should_panic]
    fn test_mortgage_another_player_property() {
        let caller_1 = contract_address_const::<'aji'>();
        let caller_2 = contract_address_const::<'ajidokwu'>();
        let username = 'Ajidokwu';

        let ndef = namespace_def();
        let mut world = spawn_test_world([ndef].span());
        world.sync_perms_and_inits(contract_defs());

        let (contract_address, _) = world.dns(@"actions").unwrap();
        let actions_system = IActionsDispatcher { contract_address };

        testing::set_contract_address(caller_1);
        actions_system.register_new_player(username);

        testing::set_contract_address(caller_1);
        let game_id = actions_system.create_new_game(GameMode::MultiPlayer, PlayerSymbol::Hat, 4);
        assert(game_id == 1, 'Wrong game id');

        actions_system.mint(caller_1, game_id, 10000);

        testing::set_contract_address(caller_1);
        actions_system.buy_property(11, game_id);
        testing::set_contract_address(caller_2);
        actions_system.mortgage_property(11, game_id);
        let property = actions_system.get_property(11, game_id);
        assert(property.is_mortgaged, 'invalid is_mortgaged txn');
    }

    #[test]
    fn test_unmortgage_property() {
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
        let game_id = actions_system.create_new_game(GameMode::MultiPlayer, PlayerSymbol::Hat, 4);
        assert(game_id == 1, 'Wrong game id');

        actions_system.mint(caller_1, game_id, 10000);

        testing::set_contract_address(caller_1);
        actions_system.buy_property(11, game_id);
        actions_system.mortgage_property(11, game_id);
        let balance_before_unmortgage = actions_system.get_players_balance(caller_1, game_id);
        actions_system.unmortgage_property(11, game_id);
        let balance_after_unmortgage = actions_system.get_players_balance(caller_1, game_id);
        let property = actions_system.get_property(11, game_id);
        assert(!property.is_mortgaged, 'invalid is_mortgaged txn');
        assert(balance_after_unmortgage < balance_before_unmortgage, 'Mortgage Bal update failed');
    }

    #[test]
    fn test_upgrade_property() {
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
        let game_id = actions_system.create_new_game(GameMode::MultiPlayer, PlayerSymbol::Hat, 4);
        assert(game_id == 1, 'Wrong game id');

        actions_system.mint(caller_1, game_id, 10000);

        testing::set_contract_address(caller_1);
        actions_system.buy_property(11, game_id);

        actions_system.buy_house_or_hotel(11, game_id);

        let property = actions_system.get_property(11, game_id);
        assert(property.development == 1, 'invalid  uy property txn');
    }

    #[test]
    #[should_panic]
    fn test_upgrade_someone_else_property() {
        let caller_1 = contract_address_const::<'aji'>();
        let caller_2 = contract_address_const::<'ajidokwu'>();
        let username = 'Ajidokwu';

        let ndef = namespace_def();
        let mut world = spawn_test_world([ndef].span());
        world.sync_perms_and_inits(contract_defs());

        let (contract_address, _) = world.dns(@"actions").unwrap();
        let actions_system = IActionsDispatcher { contract_address };

        testing::set_contract_address(caller_1);
        actions_system.register_new_player(username);

        testing::set_contract_address(caller_1);
        let game_id = actions_system.create_new_game(GameMode::MultiPlayer, PlayerSymbol::Hat, 4);
        assert(game_id == 1, 'Wrong game id');

        actions_system.mint(caller_1, game_id, 10000);
        actions_system.mint(caller_2, game_id, 10000);

        testing::set_contract_address(caller_1);
        actions_system.buy_property(11, game_id);

        testing::set_contract_address(caller_2);
        actions_system.buy_house_or_hotel(1, game_id);

        let property = actions_system.get_property(11, game_id);
        assert(property.development == 1, 'invalid  uy property txn');
    }

    #[test]
    #[should_panic]
    fn test_upgrade_property_more_than_allowed() {
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
        let game_id = actions_system.create_new_game(GameMode::MultiPlayer, PlayerSymbol::Hat, 4);
        assert(game_id == 1, 'Wrong game id');

        actions_system.mint(caller_1, game_id, 10000);

        testing::set_contract_address(caller_1);
        actions_system.buy_property(11, game_id);

        actions_system.buy_house_or_hotel(1, game_id);
        actions_system.buy_house_or_hotel(1, game_id);
        actions_system.buy_house_or_hotel(1, game_id);
        actions_system.buy_house_or_hotel(1, game_id);
        actions_system.buy_house_or_hotel(1, game_id);
        actions_system.buy_house_or_hotel(1, game_id);
    }

    #[test]
    fn test_downgrade_property() {
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
        let game_id = actions_system.create_new_game(GameMode::MultiPlayer, PlayerSymbol::Hat, 4);
        assert(game_id == 1, 'Wrong game id');

        actions_system.mint(caller_1, game_id, 10000);

        testing::set_contract_address(caller_1);
        actions_system.buy_property(11, game_id);

        actions_system.buy_house_or_hotel(11, game_id);
        actions_system.buy_house_or_hotel(11, game_id);
        actions_system.buy_house_or_hotel(11, game_id);
        actions_system.sell_house_or_hotel(11, game_id);

        let property = actions_system.get_property(11, game_id);
        assert(property.development == 2, 'invalid  uy property txn');
    }

    #[test]
    #[should_panic]
    fn test_downgrade_someone_else_property() {
        let caller_1 = contract_address_const::<'aji'>();
        let caller_2 = contract_address_const::<'ajidokwu'>();
        let username = 'Ajidokwu';

        let ndef = namespace_def();
        let mut world = spawn_test_world([ndef].span());
        world.sync_perms_and_inits(contract_defs());

        let (contract_address, _) = world.dns(@"actions").unwrap();
        let actions_system = IActionsDispatcher { contract_address };

        testing::set_contract_address(caller_1);
        actions_system.register_new_player(username);

        testing::set_contract_address(caller_1);
        let game_id = actions_system.create_new_game(GameMode::MultiPlayer, PlayerSymbol::Hat, 4);
        assert(game_id == 1, 'Wrong game id');

        actions_system.mint(caller_1, game_id, 10000);
        actions_system.mint(caller_2, game_id, 10000);

        testing::set_contract_address(caller_1);
        actions_system.buy_property(11, game_id);

        testing::set_contract_address(caller_2);
        actions_system.sell_house_or_hotel(1, game_id);

        let property = actions_system.get_property(11, game_id);
        assert(property.development == 1, 'invalid  uy property txn');
    }

    #[test]
    #[should_panic]
    fn test_downgrade_property_more_than_allowed() {
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
        let game_id = actions_system.create_new_game(GameMode::MultiPlayer, PlayerSymbol::Hat, 4);
        assert(game_id == 1, 'Wrong game id');

        actions_system.mint(caller_1, game_id, 10000);

        testing::set_contract_address(caller_1);
        actions_system.buy_property(11, game_id);

        actions_system.buy_house_or_hotel(1, game_id);
        actions_system.buy_house_or_hotel(1, game_id);
        actions_system.sell_house_or_hotel(1, game_id);
        actions_system.sell_house_or_hotel(1, game_id);
        actions_system.sell_house_or_hotel(1, game_id);
    }
}

