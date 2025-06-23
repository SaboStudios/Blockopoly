use dojo_starter::model::game_model::{GameMode, Game};
use dojo_starter::model::game_player_model::{PlayerSymbol, GamePlayer};
use dojo_starter::model::player_model::{Player};
use dojo_starter::model::property_model::{Property};
use dojo_starter::model::utility_model::{Utility};
use dojo_starter::model::rail_road_model::{RailRoad};
use dojo_starter::model::community_chest_model::{CommunityChest};
use dojo_starter::model::chance_model::{Chance};
use dojo_starter::model::jail_model::{Jail};
use dojo_starter::model::go_free_parking_model::{Go};
use dojo_starter::model::tax_model::{Tax};
use starknet::{ContractAddress};

// define the interface
#[starknet::interface]
pub trait IActions<T> {
    fn roll_dice(ref self: T) -> (u8, u8);
    fn register_new_player(ref self: T, username: felt252);
    fn create_new_game(
        ref self: T, game_mode: GameMode, player_symbol: PlayerSymbol, number_of_players: u8,
    ) -> u256;
    fn get_username_from_address(self: @T, address: ContractAddress) -> felt252;
    fn create_new_game_id(ref self: T) -> u256;
    fn generate_properties(
        ref self: T,
        id: u8,
        game_id: u256,
        name: felt252,
        cost_of_property: u256,
        rent_site_only: u256,
        rent_one_house: u256,
        rent_two_houses: u256,
        rent_three_houses: u256,
        rent_four_houses: u256,
        rent_hotel: u256,
        cost_of_house: u256,
        is_mortgaged: bool,
        group_id: u8,
    );

    fn generate_chance(ref self: T, id: u8, game_id: u256);
    fn generate_jail(ref self: T, id: u8, game_id: u256, name: felt252);
    fn generate_go(ref self: T, id: u8, game_id: u256, name: felt252);
    fn generate_community_chest(ref self: T, id: u8, game_id: u256);
    fn generate_utilitity(ref self: T, id: u8, game_id: u256, name: felt252, is_mortgaged: bool);
    fn generate_railroad(ref self: T, id: u8, game_id: u256, name: felt252, is_mortgaged: bool);
    fn generate_tax(ref self: T, id: u8, game_id: u256, name: felt252, tax_amount: u256);
    fn join_game(ref self: T, player_symbol: PlayerSymbol, game_id: u256);
    fn retrieve_game(self: @T, game_id: u256) -> Game;
    fn retrieve_player(self: @T, addr: ContractAddress) -> Player;
    fn retrieve_game_player(self: @T, addr: ContractAddress) -> GamePlayer;
    fn get_property(self: @T, id: u8, game_id: u256) -> Property;
    fn get_utility(self: @T, id: u8, game_id: u256) -> Utility;
    fn get_chance(self: @T, id: u8, game_id: u256) -> Chance;
    fn get_jail(self: @T, id: u8, game_id: u256) -> Jail;
    fn get_go(self: @T, id: u8, game_id: u256) -> Go;
    fn get_community_chest(self: @T, id: u8, game_id: u256) -> CommunityChest;
    fn get_railroad(self: @T, id: u8, game_id: u256) -> RailRoad;
    fn get_tax(self: @T, id: u8, game_id: u256) -> Tax;
    fn is_registered(self: @T, address: ContractAddress) -> bool;
    fn buy_property(ref self: T, property_id: u8, game_id: u256) -> bool;
    fn sell_property(ref self: T, property_id: u8, game_id: u256) -> bool;
    fn mortgage_property(ref self: T, property_id: u8, game_id: u256) -> bool;
    fn unmortgage_property(ref self: T, property_id: u8, game_id: u256) -> bool;
    fn collect_rent(ref self: T, property_id: u8, game_id: u256) -> bool;
    fn buy_house_or_hotel(ref self: T, property_id: u8, game_id: u256) -> bool;
    fn sell_house_or_hotel(ref self: T, property_id: u8, game_id: u256) -> bool;
    fn get_players_balance(self: @T, player: ContractAddress, game_id: u256) -> u256;
    fn transfer_from(
        ref self: T, from: ContractAddress, to: ContractAddress, game_id: u256, amount: u256,
    );
    fn mint(ref self: T, recepient: ContractAddress, game_id: u256, amount: u256);
}
