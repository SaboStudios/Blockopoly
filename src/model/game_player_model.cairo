use starknet::{ContractAddress};

#[derive(Drop, Copy, Serde)]
#[dojo::model]
pub struct GamePlayer {
    #[key]
    pub address: ContractAddress, // links to Player
    #[key]
    pub game_id: u256, // unique per game
    pub player_symbol: PlayerSymbol,
    pub position: u8,
    pub jailed: bool,
    pub balance: u256,
}


pub trait GamePlayerTrait {
    fn new(username: felt252, address: ContractAddress, game_id: u256) -> GamePlayer;
    fn move(player: GamePlayer, steps: u8);
    fn join_game(
        address: ContractAddress, game_id: u256, player_symbol: PlayerSymbol,
    ) -> GamePlayer;
    fn pay_rent_to(from: GamePlayer, to: GamePlayer, amount: u256);
    fn buy_property(from: GamePlayer, to: GamePlayer, amount: u256);
}

impl GamePlayerImpl of GamePlayerTrait {
    fn new(username: felt252, address: ContractAddress, game_id: u256) -> GamePlayer {
        GamePlayer {
            address,
            game_id,
            player_symbol: PlayerSymbol::Hat,
            balance: 0,
            position: 0,
            jailed: false,
        }
    }

    fn join_game(
        address: ContractAddress, game_id: u256, player_symbol: PlayerSymbol,
    ) -> GamePlayer {
        GamePlayer {
            address,
            game_id,
            player_symbol: PlayerSymbol::Hat,
            position: 0,
            jailed: false,
            balance: 0,
        }
    }

    fn move(mut player: GamePlayer, steps: u8) {
        player.position += steps;
    }

    fn pay_rent_to(mut from: GamePlayer, mut to: GamePlayer, amount: u256) {
        assert(from.balance >= amount, 'insufficient amount');
        from.balance -= amount;
        to.balance += amount;
    }

    fn buy_property(mut from: GamePlayer, mut to: GamePlayer, amount: u256) {
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

