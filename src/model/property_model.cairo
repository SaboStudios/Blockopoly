use starknet::{ContractAddress, contract_address_const};

#[derive(Copy, Drop, Serde)]
#[dojo::model]
pub struct Property {
    #[key]
    pub id: u8,
    pub name: felt252,
    pub owner: ContractAddress,
    pub cost_of_property: u256,
    pub rent_site_only: u256,
    pub rent_one_house: u256,
    pub rent_two_houses: u256,
    pub rent_three_houses: u256,
    pub rent_four_houses: u256,
    pub cost_of_house: u256,
    pub rent_hotel: u256,
    pub is_mortgaged: bool,
    pub group_id: u8,
}

pub trait PropertyTrait {
    fn new(
        id: u8,
        name: felt252,
        cost: u256,
        rent_site_only: u256,
        rent_one_house: u256,
        rent_two_houses: u256,
        rent_three_houses: u256,
        rent_four_houses: u256,
        cost_of_house: u256,
        rent_hotel: u256,
        group_id: u8,
    ) -> Property;
    fn set_owner(property: Property, new_owner: ContractAddress);
    fn get_rent_amount(property: Property, houses: u8, hotel: bool) -> u256;
    fn mortgage(property: Property);
    fn lift_mortgage(property: Property);
}

impl PropertyImpl of PropertyTrait {
    fn new(
        id: u8,
        name: felt252,
        cost: u256,
        rent_site_only: u256,
        rent_one_house: u256,
        rent_two_houses: u256,
        rent_three_houses: u256,
        rent_four_houses: u256,
        cost_of_house: u256,
        rent_hotel: u256,
        group_id: u8,
    ) -> Property {
        let zero_address: ContractAddress = contract_address_const::<0>();
        Property {
            id,
            name,
            owner: zero_address,
            cost_of_property: cost,
            rent_site_only: rent_site_only,
            rent_one_house: rent_one_house,
            rent_two_houses: rent_two_houses,
            rent_three_houses: rent_three_houses,
            rent_four_houses: rent_four_houses,
            rent_hotel: rent_hotel,
            cost_of_house,
            is_mortgaged: false,
            group_id,
        }
    }

    fn set_owner(mut property: Property, new_owner: ContractAddress) {
        property.owner = new_owner;
    }

    fn get_rent_amount(mut property: Property, houses: u8, hotel: bool) -> u256 {
        if property.is_mortgaged {
            return 0;
        }
        if hotel {
            return property.rent_hotel;
        }
        match houses {
            0 => property.rent_site_only,
            1 => property.rent_one_house,
            2 => property.rent_two_houses,
            3 => property.rent_three_houses,
            4 => property.rent_four_houses,
            _ => property.rent_site_only // default fallback
        }
    }

    fn mortgage(mut property: Property) {
        property.is_mortgaged = true;
    }

    fn lift_mortgage(mut property: Property) {
        property.is_mortgaged = false;
    }
}
