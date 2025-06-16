#[derive(Copy, Drop, Serde)]
#[dojo::model]
pub struct Chance {
    #[key]
    pub id: u8,
    #[key]
    game_id: u256,
    name: felt252,
}

#[derive(Drop, Copy, Serde)]
#[dojo::model]
pub struct ChanceToId {
    #[key]
    pub name: felt252,
    pub id: u8,
}

#[derive(Drop, Copy, Serde)]
#[dojo::model]
pub struct IdToChance {
    #[key]
    pub id: u8,
    pub name: felt252,
}

#[derive(Drop, Copy, Serde)]
#[dojo::model]
pub struct ChanceCard {
    #[key]
    pub id: u8,
    #[key]
    pub game_id: u256,
    pub text: ByteArray,
}

pub trait ChanceTrait {
    fn new(id: u8, game_id: u256) -> Chance;
}

impl ChanceImpl of ChanceTrait {
    fn new(id: u8, game_id: u256) -> Chance {
        Chance { id, game_id, name: 'Chance' }
    }
}

