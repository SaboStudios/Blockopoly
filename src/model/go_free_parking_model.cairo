#[derive(Copy, Drop, Serde)]
#[dojo::model]
pub struct Go {
    #[key]
    pub id: u8,
    #[key]
    pub game_id: u256,
    pub name: felt252,
}

#[derive(Drop, Copy, Serde)]
#[dojo::model]
pub struct GoToId {
    #[key]
    pub name: felt252,
    pub id: u8,
}

#[derive(Drop, Copy, Serde)]
#[dojo::model]
pub struct IdToGo {
    #[key]
    pub id: u8,
    pub name: felt252,
}

