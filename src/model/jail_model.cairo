#[derive(Copy, Drop, Serde)]
#[dojo::model]
pub struct Jail {
    #[key]
    pub id: u8,
    #[key]
    pub game_id: u256,
    pub name: felt252,
}

#[derive(Drop, Copy, Serde)]
#[dojo::model]
pub struct JailToId {
    #[key]
    pub name: felt252,
    pub id: u8,
}

#[derive(Drop, Copy, Serde)]
#[dojo::model]
pub struct IdToJail {
    #[key]
    pub id: u8,
    pub name: felt252,
}

#[derive(Drop, Copy, Serde)]
#[dojo::model]
pub struct JailCard {
    #[key]
    pub id: u8,
    #[key]
    pub game_id: u256,
    pub text: felt252,
}

