use starknet::{ContractAddress, contract_address_const};

// #[derive(Copy, Drop, Serde, Debug)]
#[derive(Drop, Copy, Serde)]
#[dojo::model]
pub struct Player {
    #[key]
    pub player: ContractAddress,
    pub username: felt252,
    pub is_bot: bool,
    pub total_games_played: u256,
    pub total_games_completed: u256,
    pub total_games_won: u256,
}


pub trait PlayerTrait {
    // Create a new player
    // `username` - Username to assign to the new player
    // `owner` - Account owner of player
    // returns the created player
    fn new(username: felt252, player: ContractAddress, is_bot: bool) -> Player;
}

impl PlayerImpl of PlayerTrait {
    fn new(username: felt252, player: ContractAddress, is_bot: bool) -> Player {
        Player {
            player,
            username,
            is_bot,
            total_games_played: 0,
            total_games_completed: 0,
            total_games_won: 0,
        }
    }
}

#[derive(Serde, Copy, Drop, Introspect, PartialEq)]
pub enum PlayerSymbol {
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
