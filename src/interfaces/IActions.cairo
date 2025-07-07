use dojo_starter::model::game_model::{GameType, Game};
use dojo_starter::model::game_player_model::{PlayerSymbol, GamePlayer};
use dojo_starter::model::player_model::Player;
use dojo_starter::model::property_model::Property;
use dojo_starter::model::utility_model::Utility;
use dojo_starter::model::rail_road_model::RailRoad;
use dojo_starter::model::community_chest_model::CommunityChest;
use dojo_starter::model::chance_model::Chance;
use dojo_starter::model::jail_model::Jail;
use dojo_starter::model::go_free_parking_model::Go;
use dojo_starter::model::tax_model::Tax;
use starknet::{ContractAddress};


#[starknet::interface]
pub trait IActions<T> {
    // Player registration & account
    fn register_new_player(ref self: T, username: felt252);
    fn is_registered(self: @T, address: ContractAddress) -> bool;
    fn get_username_from_address(self: @T, address: ContractAddress) -> felt252;
    fn retrieve_player(self: @T, addr: ContractAddress) -> Player;

    // Game creation & joining
    fn create_new_game(
        ref self: T, game_type: GameType, player_symbol: PlayerSymbol, number_of_players: u8,
    ) -> u256;
    fn join_game(ref self: T, player_symbol: PlayerSymbol, game_id: u256);
    fn start_game(ref self: T, game_id: u256) -> bool;

    // Game state retrieval
    fn retrieve_game(self: @T, game_id: u256) -> Game;
    fn retrieve_game_player(self: @T, addr: ContractAddress) -> GamePlayer;

    // Board spaces retrieval
    fn get_property(self: @T, id: u8, game_id: u256) -> Property;
    fn get_utility(self: @T, id: u8, game_id: u256) -> Utility;
    fn get_chance(self: @T, id: u8, game_id: u256) -> Chance;
    fn get_jail(self: @T, id: u8, game_id: u256) -> Jail;
    fn get_go(self: @T, id: u8, game_id: u256) -> Go;
    fn get_community_chest(self: @T, id: u8, game_id: u256) -> CommunityChest;
    fn get_railroad(self: @T, id: u8, game_id: u256) -> RailRoad;
    fn get_tax(self: @T, id: u8, game_id: u256) -> Tax;

    // Dice & player movement
    fn roll_dice(ref self: T) -> (u8, u8);
    // fn move_player(ref self: T, game_id: u256, steps: u8) -> u8;

    // Handling landings on board
    // fn draw_chance_card(ref self: T, game_id: u256) -> Chance;
    // fn draw_community_chest_card(ref self: T, game_id: u256) -> CommunityChest;
    // fn pay_tax(ref self: T, game_id: u256, tax_id: u8) -> bool;
    // fn go_to_jail(ref self: T, game_id: u256) -> bool;

    // Jail specific actions
    // fn pay_jail_fee(ref self: T, game_id: u256) -> bool;
    // fn use_jail_card(ref self: T, game_id: u256) -> bool;

    // Property transactions
    fn buy_property(ref self: T, property_id: u8, game_id: u256) -> bool;
    fn sell_property(ref self: T, property_id: u8, game_id: u256) -> bool;
    fn mortgage_property(ref self: T, property_id: u8, game_id: u256) -> bool;
    fn unmortgage_property(ref self: T, property_id: u8, game_id: u256) -> bool;
    fn collect_rent(ref self: T, property_id: u8, game_id: u256) -> bool;
    fn buy_house_or_hotel(ref self: T, property_id: u8, game_id: u256) -> bool;
    fn sell_house_or_hotel(ref self: T, property_id: u8, game_id: u256) -> bool;

    // Trading system
    // fn offer_trade(
    //     ref self: T,
    //     game_id: u256,
    //     to: ContractAddress,
    //     offered_property_ids: Array<u8>,
    //     requested_property_ids: Array<u8>,
    //     cash_offer: u256,
    //     cash_request: u256
    // );
    // fn accept_trade(ref self: T, game_id: u256, trade_id: u256) -> bool;
    // fn decline_trade(ref self: T, game_id: u256, trade_id: u256) -> bool;

    // // Auctions
    // fn start_auction(ref self: T, property_id: u8, game_id: u256);
    // fn bid_on_property(ref self: T, game_id: u256, bid_amount: u256);

    // Player balance & payments
    fn get_players_balance(self: @T, player: ContractAddress, game_id: u256) -> u256;
    fn transfer_from(
        ref self: T, from: ContractAddress, to: ContractAddress, game_id: u256, amount: u256,
    );
    fn mint(ref self: T, recepient: ContractAddress, game_id: u256, amount: u256);
    // Bankruptcy & ending game
// fn declare_bankruptcy(ref self: T, game_id: u256) -> bool;
// fn check_winner(self: @T, game_id: u256) -> Option<ContractAddress>;
// fn end_game(ref self: T, game_id: u256) -> bool;
}
