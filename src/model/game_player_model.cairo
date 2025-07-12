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
    pub dice_rolled: u8,
    pub position: u8,
    pub jailed: bool,
    pub balance: u256,
    pub properties_owned: Array<u8>,
    pub chance_jail_card: bool,
    pub comm_free_card: bool,
    pub total_houses_owned: u8,
    pub total_hotels_owned: u8,
    pub no_of_utilities: u8,
    pub no_of_railways: u8,
    pub no_section1: u8,
    pub no_section2: u8,
    pub no_section3: u8,
    pub no_section4: u8,
    pub no_section5: u8,
    pub no_section6: u8,
    pub no_section7: u8,
    pub no_section8: u8,
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
            dice_rolled: 0,
            player_symbol: player_symbol,
            balance: 0,
            is_next: true,
            position: 0,
            jailed: false,
            is_bankrupt: false,
            is_active: true,
            properties_owned: array![],
            chance_jail_card: false,
            comm_free_card: false,
            total_houses_owned: 0,
            total_hotels_owned: 0,
            no_of_utilities: 0,
            no_of_railways: 0,
            no_section1: 0,
            no_section2: 0,
            no_section3: 0,
            no_section4: 0,
            no_section5: 0,
            no_section6: 0,
            no_section7: 0,
            no_section8: 0,
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

