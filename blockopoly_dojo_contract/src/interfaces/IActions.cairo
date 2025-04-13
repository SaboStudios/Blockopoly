use dojo_starter::models::{Direction, Position, Player};

use starknet::{ContractAddress};

// define the interface
#[starknet::interface]
pub trait IActions<T> {
    fn spawn(ref self: T);
    fn move(ref self: T, direction: Direction);
    fn roll_dice(ref self: T) -> (u8, u8);
    fn register(ref self: T, player_address: ContractAddress, username: felt252);
    fn retrieve_player(ref self: T, player_address: ContractAddress) -> Player;
}
