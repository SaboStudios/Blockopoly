#[derive(Copy, Drop, Serde)]
#[dojo::model]
pub struct Tax {
    #[key]
    pub id: u8,
    #[key]
    pub game_id: u256,
    pub name: felt252,
    pub tax_amount: u256,
}

#[derive(Drop, Copy, Serde)]
#[dojo::model]
pub struct TaxToId {
    #[key]
    pub name: felt252,
    pub id: u8,
}

#[derive(Drop, Copy, Serde)]
#[dojo::model]
pub struct IdToTax {
    #[key]
    pub id: u8,
    pub name: felt252,
}

