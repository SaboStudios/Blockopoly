#[cfg(test)]
mod tests {
    use dojo_cairo_test::WorldStorageTestTrait;
    use dojo::model::{ModelStorage, ModelStorageTest};
    use dojo::world::WorldStorageTrait;
    use dojo_cairo_test::{
        spawn_test_world, NamespaceDef, TestResource, ContractDefTrait, ContractDef,
    };

    use dojo_starter::systems::actions::{actions};
    use dojo_starter::systems::Blockopoly::{Blockopoly};
    use dojo_starter::interfaces::IActions::{IActionsDispatcher, IActionsDispatcherTrait};
    use dojo_starter::interfaces::IBlockopoly::{IBlockopolyDispatcher, IBlockopolyDispatcherTrait};

    use dojo_starter::model::game_model::{
        Game, m_Game, GameMode, GameStatus, GameCounter, m_GameCounter,
    };
    use dojo_starter::model::player_model::{
        Player, m_Player, UsernameToAddress, m_UsernameToAddress, AddressToUsername,
        m_AddressToUsername, PlayerSymbol,
    };
    use starknet::{testing, get_caller_address, contract_address_const};

    fn namespace_def() -> NamespaceDef {
        let ndef = NamespaceDef {
            namespace: "blockopoly",
            resources: [
                TestResource::Model(m_Player::TEST_CLASS_HASH),
                TestResource::Model(m_Game::TEST_CLASS_HASH),
                TestResource::Model(m_UsernameToAddress::TEST_CLASS_HASH),
                TestResource::Model(m_AddressToUsername::TEST_CLASS_HASH),
                TestResource::Model(m_GameCounter::TEST_CLASS_HASH),
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
        println!("dice_1: {}", dice_1);
        println!("dice_2: {}", dice_2);

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
        actions_system.register_new_player(username, false);

        let player: Player = actions_system.retrieve_player(caller_1);
        println!("username: {}", player.username);
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
        actions_system.register_new_player(username, false);

        testing::set_contract_address(caller_2);
        actions_system.register_new_player(username, false);
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
        actions_system.register_new_player(username, false);

        testing::set_contract_address(caller_1);
        actions_system.register_new_player(username1, false);
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
        actions_system.register_new_player(username, false);

        testing::set_contract_address(caller_1);
        actions_system.register_new_player(username1, false);
    }

    #[test]
    #[should_panic]
    fn test_player_registration_bot_tries_registering() {
        let caller_1 = contract_address_const::<'aji'>();
        let username = 'Aji';

        let ndef = namespace_def();
        let mut world = spawn_test_world([ndef].span());
        world.sync_perms_and_inits(contract_defs());

        let (contract_address, _) = world.dns(@"actions").unwrap();
        let actions_system = IActionsDispatcher { contract_address };

        testing::set_contract_address(caller_1);
        actions_system.register_new_player(username, true);
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
        actions_system.register_new_player(username, false);

        testing::set_contract_address(caller_1);
        let game_id = actions_system.create_new_game(GameMode::MultiPlayer, PlayerSymbol::Hat, 4);
        assert(game_id == 1, 'Wrong game id');
        println!("game_id: {}", game_id);

        let game: Game = actions_system.retrieve_game(game_id);
        assert(game.created_by == username, 'Wrong game id');
        println!("creator: {}", game.created_by);
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
        actions_system.register_new_player(username, false);

        testing::set_contract_address(caller_1);
        let _game_id = actions_system.create_new_game(GameMode::MultiPlayer, PlayerSymbol::Hat, 4);

        testing::set_contract_address(caller_1);
        let game_id_1 = actions_system.create_new_game(GameMode::MultiPlayer, PlayerSymbol::Hat, 4);
        assert(game_id_1 == 2, 'Wrong game id');
        println!("game_id: {}", game_id_1);
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
        println!("game_id: {}", game_id);
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
        actions_system.register_new_player(username_1, false);

        testing::set_contract_address(caller_1);
        actions_system.register_new_player(username, false);

        testing::set_contract_address(caller_1);
        let game_id = actions_system.create_new_game(GameMode::MultiPlayer, PlayerSymbol::Hat, 4);

        testing::set_contract_address(caller_2);
        let game_id = actions_system.join_game(PlayerSymbol::Dog, 1);
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
        actions_system.register_new_player(username_1, false);

        testing::set_contract_address(caller_1);
        actions_system.register_new_player(username, false);

        testing::set_contract_address(caller_1);
        let game_id = actions_system.create_new_game(GameMode::MultiPlayer, PlayerSymbol::Hat, 4);

        testing::set_contract_address(caller_2);
        let game_id = actions_system.join_game(PlayerSymbol::Hat, 1);
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
        actions_system.register_new_player(username_1, false);

        testing::set_contract_address(caller_1);
        actions_system.register_new_player(username, false);

        testing::set_contract_address(caller_2);
        let game_id = actions_system.join_game(PlayerSymbol::Hat, 1);
    }
}

