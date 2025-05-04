use starknet::{ContractAddress, contract_address_const};


#[derive(Drop, Copy, Serde)]
#[dojo::model]
pub struct Player {
    #[key]
    pub address: ContractAddress,
    pub username: felt252,
    pub is_bot: bool,
    pub created_at: u64,
    pub updated_at: u64,
    pub new_owner: ContractAddress,
    pub player_symbol: PlayerSymbol,
    pub balance: u256,
    pub position: u8,
    pub jailed: bool,
    pub total_games_played: u256,
    pub total_games_completed: u256,
    pub total_games_won: u256,
}


pub trait PlayerTrait {
    fn new(username: felt252, address: ContractAddress, is_bot: bool, created_at: u64) -> Player;
    fn move(player: Player, steps: u8);
    fn pay_rent_to(from: Player, to: Player, amount: u256);
    fn buy_property(from: Player, to: Player, amount: u256);
}

impl PlayerImpl of PlayerTrait {
    fn new(username: felt252, address: ContractAddress, is_bot: bool, created_at: u64) -> Player {
        let zero_address: ContractAddress = contract_address_const::<0>();
        Player {
            address,
            username,
            is_bot,
            created_at,
            updated_at: created_at,
            new_owner: zero_address,
            player_symbol: PlayerSymbol::Hat,
            balance: 0,
            position: 0,
            jailed: false,
            total_games_played: 0,
            total_games_completed: 0,
            total_games_won: 0,
        }
    }
    fn move(mut player: Player, steps: u8) {
        player.position += steps;
    }

    fn pay_rent_to(mut from: Player, mut to: Player, amount: u256) {
        assert(from.balance >= amount, 'insufficient amount');
        from.balance -= amount;
        to.balance += amount;
    }

    fn buy_property(mut from: Player, mut to: Player, amount: u256) {
        assert(from.balance >= amount, 'insufficient amount');
        from.balance -= amount;
        to.balance += amount;
    }
}

#[derive(Serde, Copy, Introspect, Drop, PartialEq)]
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
