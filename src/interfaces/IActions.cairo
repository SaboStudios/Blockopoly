use dojo_starter::model::game_model::{GameMode, Game};
use dojo_starter::model::player_model::{PlayerSymbol, Player};
use dojo_starter::model::property_model::{Property};
use starknet::{ContractAddress};

// define the interface
#[starknet::interface]
pub trait IActions<T> {
    fn roll_dice(ref self: T) -> (u8, u8);
    fn register_new_player(ref self: T, username: felt252, is_bot: bool);
    fn create_new_game(
        ref self: T, game_mode: GameMode, player_symbol: PlayerSymbol, number_of_players: u8,
    ) -> u64;
    fn get_username_from_address(self: @T, address: ContractAddress) -> felt252;
    fn create_new_game_id(ref self: T) -> u64;
    fn generate_properties(
        ref self: T,
        id: u8,
        name: felt252,
        cost_of_property: u256,
        rent_site_only: u256,
        rent_one_house: u256,
        rent_two_houses: u256,
        rent_three_houses: u256,
        rent_four_houses: u256,
        cost_of_house: u256,
        rent_hotel: u256,
        is_mortgaged: bool,
        group_id: u8,
    );
    fn join_game(ref self: T, player_symbol: PlayerSymbol, game_id: u64);
    fn retrieve_game(ref self: T, game_id: u64) -> Game;
    fn retrieve_player(ref self: T, addr: ContractAddress) -> Player;
    fn get_property(ref self: T, id: u8) -> Property;
}
