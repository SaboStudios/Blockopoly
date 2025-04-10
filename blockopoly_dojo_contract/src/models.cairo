use starknet::{ContractAddress};

#[derive(Serde, Copy, Drop, Introspect, PartialEq, Debug)]
pub enum PropertyColors {
    PINK,
    YELLOW,
    BLUE,
    ORANGE,
    RED,
    GREEN,
    PURPLE,
    BROWN,
}


#[derive(Serde, Copy, Drop, Introspect, PartialEq, Debug)]
pub enum PropertyType {
    Property,
    RailStation,
    Utility,
    Special,
}


#[derive(Copy, Drop, Serde, Debug)]
#[dojo::model]
pub struct Player {
    #[key]
    pub player: ContractAddress,
    pub username: felt252,
    pub player_current_position: u8,
    pub in_jail: bool,
    pub jailAttemptCount: u8,
    pub cash_at_hand: u256,
    pub diceRolled: u8,
    pub bankrupt: bool,
    pub netWorth: u256,
}

#[derive(Copy, Drop, Serde, Debug)]
#[dojo::model]
pub struct Property {
    #[key]
    pub owner: ContractAddress,
    pub name: felt252,
    pub amount: u256,
    pub cost_of_house: u256,
    pub rent_site_only: u256,
    pub rent_one_house: u256,
    pub rent_two_houses: u256,
    pub rent_three_houses: u256,
    pub rent_four_houses: u256,
    pub rent_one_hotel: u256,
    pub mortgaged: bool,
    pub no_of_houses: u256,
    pub property_type: PropertyType,
    pub property_color: PropertyColors,
}

#[derive(Copy, Drop, Serde, Debug)]
#[dojo::model]
pub struct Moves {
    #[key]
    pub player: ContractAddress,
    pub remaining: u8,
    pub last_direction: Option<Direction>,
    pub can_move: bool,
}

#[derive(Drop, Serde, Debug)]
#[dojo::model]
pub struct DirectionsAvailable {
    #[key]
    pub player: ContractAddress,
    pub directions: Array<Direction>,
}

#[derive(Copy, Drop, Serde, Debug)]
#[dojo::model]
pub struct Position {
    #[key]
    pub player: ContractAddress,
    pub vec: Vec2,
}


#[derive(Serde, Copy, Drop, Introspect, PartialEq, Debug)]
pub enum Direction {
    Left,
    Right,
    Up,
    Down,
}


#[derive(Copy, Drop, Serde, IntrospectPacked, Debug)]
pub struct Vec2 {
    pub x: u32,
    pub y: u32,
}


impl DirectionIntoFelt252 of Into<Direction, felt252> {
    fn into(self: Direction) -> felt252 {
        match self {
            Direction::Left => 1,
            Direction::Right => 2,
            Direction::Up => 3,
            Direction::Down => 4,
        }
    }
}

impl OptionDirectionIntoFelt252 of Into<Option<Direction>, felt252> {
    fn into(self: Option<Direction>) -> felt252 {
        match self {
            Option::None => 0,
            Option::Some(d) => d.into(),
        }
    }
}

#[generate_trait]
impl Vec2Impl of Vec2Trait {
    fn is_zero(self: Vec2) -> bool {
        if self.x - self.y == 0 {
            return true;
        }
        false
    }

    fn is_equal(self: Vec2, b: Vec2) -> bool {
        self.x == b.x && self.y == b.y
    }
}

#[cfg(test)]
mod tests {
    use super::{Vec2, Vec2Trait};

    #[test]
    fn test_vec_is_zero() {
        assert(Vec2Trait::is_zero(Vec2 { x: 0, y: 0 }), 'not zero');
    }

    #[test]
    fn test_vec_is_equal() {
        let position = Vec2 { x: 420, y: 0 };
        assert(position.is_equal(Vec2 { x: 420, y: 0 }), 'not equal');
    }
}
