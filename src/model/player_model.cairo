use starknet::{ContractAddress, contract_address_const};



// #[derive(Copy, Drop, Serde, Debug)]
#[derive(Drop, Copy, Serde)]
#[dojo::model]
pub struct Player {
    #[key]
    pub address: ContractAddress,
    pub id: u256,    
    pub username: felt252,
    pub is_bot: bool,
    pub created_at: u64,
    pub updated_at: u64,
    pub new_owner: ContractAddress,
    pub player_symbol: PlayerSymbol,
    pub balance: u64,
    pub position: u64,
    pub jailed: bool,
    pub total_games_played: u256,
    pub total_games_completed: u256,
    pub total_games_won: u256,

}


pub trait PlayerTrait {
    fn new(username: felt252, id: u256, address: ContractAddress, is_bot: bool, created_at: u64) -> Player;
}

impl PlayerImpl of PlayerTrait {
    fn new(username: felt252, id: u256, address: ContractAddress, is_bot: bool, created_at: u64) -> Player {
        let zero_address: ContractAddress = contract_address_const::<0>();
        Player {
            address,
            id,
            username,
            is_bot,
            created_at,
            updated_at: created_at,
            new_owner: zero_address,
            player_symbol: PlayerSymbol::Undefined,
            balance: 0,
            position: 0,
            jailed: false,
            total_games_played: 0,
            total_games_completed: 0,
            total_games_won: 0,

        }
    }
}

#[derive(Serde, Copy, Drop, Introspect, PartialEq)]
pub enum PlayerSymbol {
    Undefined,
    Hat,
    Car,
    Dog,
    Thimble,
    Iron,
    Battleship,
    Boot,
    Wheelbarrow,
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
