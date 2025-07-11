use starknet::{ContractAddress};

#[derive(Drop, Serde, Clone, Introspect)]
#[dojo::model]
pub struct GamePlayer {
    #[key]
    pub address: ContractAddress, // links to Player
    #[key]
    pub game_id: u256, // unique per game
    pub player_symbol: PlayerSymbol,
    pub is_next: bool,
    pub position: u8,
    pub jailed: bool,
    pub balance: u256,
    pub properties_owned: Array<u8>,
    pub is_bankrupt: bool,
    pub is_active: bool,
}


// the GamePlayerTrait tell imposes the actions a player can perform within a game

pub trait GamePlayerTrait {
    fn create_game_player(
        username: felt252, address: ContractAddress, game_id: u256, player_symbol: PlayerSymbol,
    ) -> GamePlayer;
    fn move(player: GamePlayer, steps: u8) -> GamePlayer;
    fn pay_game_player(ref self: GamePlayer, amount: u256) -> bool;
    fn deduct_game_player(ref self: GamePlayer, amount: u256) -> bool;
    fn add_property_to_game_player(ref self: GamePlayer, property_id: u8) -> bool;
    fn remove_property_from_game_player(ref self: GamePlayer, property_id: u8) -> bool;
    fn declare_bankruptcy(ref self: GamePlayer) -> bool;
    fn jail_game_player(ref self: GamePlayer) -> bool;
}

impl GamePlayerImpl of GamePlayerTrait {
    fn create_game_player(
        username: felt252, address: ContractAddress, game_id: u256, player_symbol: PlayerSymbol,
    ) -> GamePlayer {
        GamePlayer {
            address,
            game_id,
            player_symbol: player_symbol,
            balance: 0,
            is_next: true,
            position: 0,
            jailed: false,
            is_bankrupt: false,
            is_active: true,
            properties_owned: array![],
        }
    }

    fn move(mut player: GamePlayer, steps: u8) -> GamePlayer {
        player.position += steps;
        player
    }

    fn pay_game_player(ref self: GamePlayer, amount: u256) -> bool {
        true
    }

    fn deduct_game_player(ref self: GamePlayer, amount: u256) -> bool {
        true
    }

    fn add_property_to_game_player(ref self: GamePlayer, property_id: u8) -> bool {
        true
    }

    fn remove_property_from_game_player(ref self: GamePlayer, property_id: u8) -> bool {
        true
    }

    fn declare_bankruptcy(ref self: GamePlayer) -> bool {
        true
    }

    fn jail_game_player(ref self: GamePlayer) -> bool {
        true
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

