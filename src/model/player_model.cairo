use starknet::{ContractAddress, contract_address_const};


#[derive(Drop, Copy, Serde)]
#[dojo::model]
pub struct Player {
    #[key]
    pub address: ContractAddress,
    pub username: felt252,
    pub is_registered: bool,
    pub new_owner: ContractAddress,
    pub balance: u256,
    pub total_games_played: u256,
    pub total_games_completed: u256,
    pub total_games_won: u256,
    pub created_at: u64,
    pub updated_at: u64,
}


pub trait PlayerTrait {
    fn new(username: felt252, address: ContractAddress, created_at: u64) -> Player;
}

impl PlayerImpl of PlayerTrait {
    fn new(username: felt252, address: ContractAddress, created_at: u64) -> Player {
        let zero_address: ContractAddress = contract_address_const::<0>();
        Player {
            address,
            username,
            is_registered: true,
            created_at,
            updated_at: created_at,
            new_owner: zero_address,
            balance: 0,
            total_games_played: 0,
            total_games_completed: 0,
            total_games_won: 0,
        }
    }
}


#[derive(Drop, Copy, Serde)]
#[dojo::model]
pub struct UsernameToAddress {
    #[key]
    pub username: felt252,
    pub address: ContractAddress,
}

#[derive(Drop, Copy, Serde)]
#[dojo::model]
pub struct AddressToUsername {
    #[key]
    pub address: ContractAddress,
    pub username: felt252,
}

#[derive(Drop, Copy, Serde)]
#[dojo::model]
pub struct IsRegistered {
    #[key]
    pub address: ContractAddress,
    pub is_registered: bool,
}
