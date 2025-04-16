use dojo_starter::models::{Direction, Position};
use dojo_starter::game_model::{Player, GameMode, PlayerSymbol};
use starknet::{ContractAddress};

// define the interface
#[starknet::interface]
pub trait IActions<T> {
    fn spawn(ref self: T);
    fn move(ref self: T, direction: Direction);
    fn roll_dice(ref self: T) -> (u8, u8);
    fn register(ref self: T, player_address: ContractAddress, username: felt252);
    fn register_new_player(ref self: T, username: felt252, is_bot: bool);
    fn create_new_game(
        ref self: T,
        game_mode: GameMode,
        player_symbol: PlayerSymbol,
        player_hat: felt252,
        player_car: felt252,
        player_dog: felt252,
        player_thimble: felt252,
        player_iron: felt252,
        player_battleship: felt252,
        player_boot: felt252,
        player_wheelbarrow: felt252,
        number_of_players: u8,
    ) -> u64;
    fn get_username_from_address(self: @T, address: ContractAddress) -> felt252;
    // fn retrieve_player(ref self: T, player_address: ContractAddress) -> Player;
}
