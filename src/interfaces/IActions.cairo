use dojo_starter::model::game_model::{GameType, Game};
use dojo_starter::model::game_player_model::{PlayerSymbol, GamePlayer};
use dojo_starter::model::player_model::Player;
use dojo_starter::model::property_model::{Property, TradeOffer, TradeOfferDetails};
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
    fn finish_turn(ref self: T, game: Game) -> Game;

    // Game state retrieval
    fn retrieve_game(self: @T, game_id: u256) -> Game;
    fn retrieve_game_player(self: @T, addr: ContractAddress, game_id: u256) -> GamePlayer;
    fn is_game_started(self: @T, game_id: u256) -> u8;

    // Board spaces retrieval
    fn get_property(self: @T, id: u8, game_id: u256) -> Property;

    fn use_getout_of_jail_chance(ref self: T, game_id: u256) -> bool;
    fn use_getout_of_jail_community_chest(ref self: T, game_id: u256) -> bool;

    fn calculate_net_worth(ref self: T, player: GamePlayer) -> u256;

    fn get_winner_by_net_worth(ref self: T, players: Array<GamePlayer>) -> ContractAddress;
    fn end_game(ref self: T, game: Game) -> ContractAddress;

    fn offer_trade(
        ref self: T,
        game_id: u256,
        to: ContractAddress,
        offered_property_ids: Array<u8>,
        requested_property_ids: Array<u8>,
        cash_offer: u256,
        cash_request: u256,
        trade_type: TradeOffer,
    ) -> u256;

    fn accept_trade(ref self: T, trade_id: u256, game_id: u256) -> bool;

    fn reject_trade(ref self: T, trade_id: u256, game_id: u256) -> bool;

    fn leave_game(ref self: T, game_id: u256, transfer_to: ContractAddress);
    fn counter_trade(
        ref self: T,
        game_id: u256,
        original_offer_id: u256,
        offered_property_ids: Array<u8>,
        requested_property_ids: Array<u8>,
        cash_offer: u256,
        cash_request: u256,
        trade_type: TradeOffer,
    ) -> u256;
    fn approve_counter_trade(ref self: T, trade_id: u256) -> bool;
    fn get_trade(self: @T, trade_id: u256) -> TradeOfferDetails;

    // Dice & player movement
    fn roll_dice(ref self: T) -> (u8, u8);
    fn move_player(ref self: T, game_id: u256, steps: u8) -> u8;
    fn pay_jail_fine(ref self: T, game_id: u256) -> bool;


    // Property transactions
    fn buy_property(ref self: T, property: Property) -> bool;
    fn mortgage_property(ref self: T, property: Property) -> bool;
    fn unmortgage_property(ref self: T, property: Property) -> bool;
    fn pay_rent(ref self: T, property: Property) -> bool;
    fn buy_house_or_hotel(ref self: T, property: Property) -> bool;
    fn sell_house_or_hotel(ref self: T, property_id: u8, game_id: u256) -> bool;

    fn handle_community_chest(ref self: T, game_id: u256, random_index: u32) -> ByteArray;
    fn handle_chance(ref self: T, game_id: u256, random_index: u32) -> ByteArray;
    fn process_chance_card(
        ref self: T, game: Game, player: GamePlayer, card: ByteArray,
    ) -> (Game, GamePlayer);

    fn process_community_chest_card(
        ref self: T, game: Game, player: GamePlayer, card: ByteArray,
    ) -> (Game, GamePlayer);

    fn bankruptcy_check(ref self: T, player: GamePlayer, amount_owed: u256);
    fn vote_to_kick_player(ref self: T, game_id: u256, target_player: ContractAddress);

    // // Auctions
    // fn start_auction(ref self: T, property_id: u8, game_id: u256);
    // fn bid_on_property(ref self: T, game_id: u256, bid_amount: u256);

    // Player balance & payments
    fn get_players_balance(self: @T, player: ContractAddress, game_id: u256) -> u256;
    fn transfer_from(
        ref self: T, from: GamePlayer, to: GamePlayer, amount: u256,
    ) -> Array<GamePlayer>;
    fn mint(ref self: T, recepient: ContractAddress, game_id: u256, amount: u256);
}
