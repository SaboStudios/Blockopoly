use starknet::{ContractAddress, contract_address_const};
#[derive(Copy, Drop, Serde)]
#[dojo::model]
pub struct Utility {
    #[key]
    pub id: u8,
    #[key]
    game_id: u256,
    pub name: felt252,
    pub owner: ContractAddress,
    pub cost_of_utility: u256,
    pub is_mortgaged: bool,
    pub for_sale: bool,
}

#[derive(Drop, Copy, Serde)]
#[dojo::model]
pub struct UtilityToId {
    #[key]
    pub name: felt252,
    pub id: u8,
}

#[derive(Drop, Copy, Serde)]
#[dojo::model]
pub struct IdToUtility {
    #[key]
    pub id: u8,
    pub name: felt252,
}

pub trait UtilityTrait {
    fn new(id: u8, game_id: u256, name: felt252, cost_of_utility: u256) -> Utility;
    fn set_owner(utility: Utility, new_owner: ContractAddress);
    fn get_rent_amount(utility: Utility, utilities_owned: u8, dice_rolled: u8) -> u256;
    fn mortgage(utility: Utility);
    fn lift_mortgage(utility: Utility);
}

impl UtilityImpl of UtilityTrait {
    fn new(id: u8, game_id: u256, name: felt252, cost_of_utility: u256) -> Utility {
        let zero_address: ContractAddress = contract_address_const::<0>();
        Utility {
            id,
            game_id,
            name,
            owner: zero_address,
            cost_of_utility,
            is_mortgaged: false,
            for_sale: true,
        }
    }


    fn set_owner(mut utility: Utility, new_owner: ContractAddress) {
        utility.owner = new_owner;
    }

    fn get_rent_amount(mut utility: Utility, utilities_owned: u8, dice_rolled: u8) -> u256 {
        let mut rent = 0;
        if utility.is_mortgaged {
            return rent;
        }
        if utilities_owned == 1 {
            rent = 4 * dice_rolled.into();
        }
        if utilities_owned == 2 {
            rent = 10 * dice_rolled.into();
        }

        rent
    }

    fn mortgage(mut utility: Utility) {
        utility.is_mortgaged = true;
    }

    fn lift_mortgage(mut utility: Utility) {
        utility.is_mortgaged = false;
    }
}
