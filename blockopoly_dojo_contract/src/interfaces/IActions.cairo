use dojo_starter::models::{Direction, Position};

// define the interface
#[starknet::interface]
pub trait IActions<T> {
    fn spawn(ref self: T);
    fn move(ref self: T, direction: Direction);
    fn roll_dice(ref self: T) -> (u8, u8);
}
