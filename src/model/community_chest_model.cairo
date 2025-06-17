#[derive(Copy, Drop, Serde)]
#[dojo::model]
pub struct CommunityChest {
    #[key]
    pub id: u8,
    #[key]
    game_id: u256,
    name: felt252,
}

#[derive(Drop, Copy, Serde)]
#[dojo::model]
pub struct CommunityChestToId {
    #[key]
    pub name: felt252,
    pub id: u8,
}

#[derive(Drop, Copy, Serde)]
#[dojo::model]
pub struct IdToCommunityChest {
    #[key]
    pub id: u8,
    pub name: felt252,
}

pub trait CommunityChestTrait {
    fn new(id: u8, game_id: u256) -> CommunityChest;
}

impl CommunityChestImpl of CommunityChestTrait {
    fn new(id: u8, game_id: u256) -> CommunityChest {
        CommunityChest { id, game_id, name: 'Community Chest' }
    }
}
