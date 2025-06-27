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
    fn new(id: u8, game_id: u256, name: felt252) -> Utility;
    fn change_utility_ownership(
        utility: Utility, new_owner: ContractAddress, owner: ContractAddress,
    );
    fn get_rent_amount(utility: Utility, utilities_owned: u8, dice_rolled: u8) -> u256;
    fn mortgage_utility(utility: Utility, owner: ContractAddress) -> bool;
    fn lift_utility_mortgage(utility: Utility, owner: ContractAddress) -> bool;
    fn up_utility_up_for_sale(ref self: Utility, owner: ContractAddress) -> bool;
}

impl UtilityImpl of UtilityTrait {
    fn new(id: u8, game_id: u256, name: felt252) -> Utility {
        let zero_address: ContractAddress = contract_address_const::<0>();
        Utility {
            id,
            game_id,
            name,
            owner: zero_address,
            cost_of_utility: 150,
            is_mortgaged: false,
            for_sale: true,
        }
    }


    // use ref state
    fn change_utility_ownership(
        mut utility: Utility, new_owner: ContractAddress, owner: ContractAddress,
    ) { //implement after checks especially ownership ...
    }

    // change to no change state
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

    //change to ref state changing
    fn mortgage_utility(mut utility: Utility, owner: ContractAddress) -> bool {
        true
    }

    //change to ref state changing
    fn lift_utility_mortgage(mut utility: Utility, owner: ContractAddress) -> bool {
        true
    }

    //
    fn up_utility_up_for_sale(ref self: Utility, owner: ContractAddress) -> bool {
        // implement after checks ... to chage the state for_sale
        true
    }
}
