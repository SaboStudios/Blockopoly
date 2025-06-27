use starknet::{ContractAddress, contract_address_const};
#[derive(Copy, Drop, Serde)]
#[dojo::model]
pub struct RailRoad {
    #[key]
    pub id: u8,
    #[key]
    game_id: u256,
    pub name: felt252,
    pub owner: ContractAddress,
    pub cost_of_railroad: u256,
    pub is_mortgaged: bool,
    pub for_sale: bool,
}

#[derive(Drop, Copy, Serde)]
#[dojo::model]
pub struct RailRoadToId {
    #[key]
    pub name: felt252,
    pub id: u8,
}

#[derive(Drop, Copy, Serde)]
#[dojo::model]
pub struct IdToRailRoad {
    #[key]
    pub id: u8,
    pub name: felt252,
}

pub trait RailRoadTrait {
    fn new(id: u8, game_id: u256, name: felt252) -> RailRoad;
    fn change_railroad_ownership(
        railroad: RailRoad, new_owner: ContractAddress, owner: ContractAddress,
    ) -> bool;
    fn get_rent_amount(railroad: RailRoad, railroad_owned: u8) -> u256;
    fn mortgage(railroad: RailRoad, owner: ContractAddress);
    fn lift_mortgage(railroad: RailRoad, owner: ContractAddress);
}

impl RailRoadImpl of RailRoadTrait {
    fn new(id: u8, game_id: u256, name: felt252) -> RailRoad {
        let zero_address: ContractAddress = contract_address_const::<0>();
        RailRoad {
            id,
            game_id,
            name,
            owner: zero_address,
            cost_of_railroad: 200,
            is_mortgaged: false,
            for_sale: true,
        }
    }


    // change to ref
    fn change_railroad_ownership(
        railroad: RailRoad, new_owner: ContractAddress, owner: ContractAddress,
    ) -> bool {
        // after checks

        true
    }

    // change to non changing state
    fn get_rent_amount(mut railroad: RailRoad, railroad_owned: u8) -> u256 {
        let mut rent = 0;
        if railroad.is_mortgaged {
            return rent;
        }
        if railroad_owned == 1 {
            rent = 25;
        }
        if railroad_owned == 2 {
            rent = 50;
        }
        if railroad_owned == 3 {
            rent = 100;
        }
        if railroad_owned == 4 {
            rent = 200;
        } else {
            rent = 0;
        }

        rent
    }


    // change to ref
    fn mortgage(mut railroad: RailRoad, owner: ContractAddress) {// railroad.is_mortgaged = true;
    }

    fn lift_mortgage(mut railroad: RailRoad, owner: ContractAddress) {// railroad.is_mortgaged = false;
    }
}
