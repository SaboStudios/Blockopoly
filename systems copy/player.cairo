use blockopoly::models::{AddressToUsername, IsRegistered, Player, PlayerTrait, UsernameToAddress};
use starknet::ContractAddress;
// define the interface
#[starknet::interface]
pub trait IActions<T> {
    fn register_new_player(ref self: T, username: felt252);
    fn is_registered(self: @T, address: ContractAddress) -> bool;
    fn get_username_from_address(self: @T, address: ContractAddress) -> felt252;
    fn retrieve_player(self: @T, addr: ContractAddress) -> Player;
}

// dojo decorator
#[dojo::contract]
pub mod player {
    use dojo::event::EventStorage;
    use dojo::model::ModelStorage;
    use starknet::{
        ContractAddress, contract_address_const, get_block_timestamp, get_caller_address,
    };
    use super::{AddressToUsername, IActions, IsRegistered, Player, PlayerTrait, UsernameToAddress};

    #[derive(Copy, Drop, Serde)]
    #[dojo::event]
    pub struct PlayerCreated {
        #[key]
        pub username: felt252,
        #[key]
        pub player: ContractAddress,
        pub timestamp: u64,
    }

    #[abi(embed_v0)]
    impl ActionsImpl of IActions<ContractState> {
        fn is_registered(self: @ContractState, address: ContractAddress) -> bool {
            let world = self.world_default();
            let is_registered: IsRegistered = world.read_model(address);
            is_registered.is_registered
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
        fn retrieve_player(self: @ContractState, addr: ContractAddress) -> Player {
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
            self.world(@"blockopolyyy")
        }
    }
}

