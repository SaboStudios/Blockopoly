use starknet::{ContractAddress, contract_address_const};

#[derive(Serde, Copy, Drop, Introspect, PartialEq)]
#[dojo::model]
pub struct TradeCounter {
    #[key]
    pub id: felt252,
    pub current_val: u256,
}

#[derive(Clone, Drop, Serde)]
#[dojo::model]
pub struct TradeOfferDetails {
    #[key]
    pub id: u256,
    pub from: ContractAddress,
    pub to: ContractAddress,
    pub game_id: u256,
    pub offered_property_ids: Array<u8>,
    pub requested_property_ids: Array<u8>,
    pub cash_offer: u256,
    pub cash_request: u256,
    pub trade_type: TradeOffer,
    pub status: TradeStatus,
    pub is_countered: bool,
    pub approve_counter: bool,
}
#[derive(Copy, Drop, Serde)]
#[dojo::model]
pub struct Property {
    #[key]
    pub id: u8,
    #[key]
    pub game_id: u256,
    pub name: felt252,
    pub owner: ContractAddress,
    pub property_type: PropertyType,
    pub cost_of_property: u256,
    pub property_level: u8,
    pub rent_site_only: u256,
    pub rent_one_house: u256,
    pub rent_two_houses: u256,
    pub rent_three_houses: u256,
    pub rent_four_houses: u256,
    pub cost_of_house: u256,
    pub rent_hotel: u256,
    pub is_mortgaged: bool,
    pub group_id: u8,
    pub for_sale: bool,
    pub development: u8,
}
#[derive(Serde, Copy, Drop, Introspect, PartialEq, Debug)]
pub enum PropertyType {
    Go,
    Chance,
    CommunityChest,
    Jail,
    Utility,
    RailRoad,
    Tax,
    FreeParking,
    Property,
    VisitingJail,
}

#[derive(Serde, Copy, Drop, Introspect, PartialEq, Debug)]
pub enum TradeOffer {
    PropertyForProperty,
    PropertyForCash,
    CashForProperty,
    CashPlusPropertyForProperty,
    PropertyForCashPlusProperty,
    CashForChanceJailCard,
    CashForCommunityJailCard,
    CommunityJailCardForCash,
    ChanceJailCardForCash,
}

#[derive(Serde, Copy, Drop, Introspect, PartialEq, Debug)]
pub enum TradeStatus {
    Accepted,
    Rejected,
    Pending,
    Countered,
}


#[derive(Drop, Copy, Serde)]
#[dojo::model]
pub struct PropertyToId {
    #[key]
    pub name: felt252,
    pub id: u8,
}

#[derive(Drop, Copy, Serde)]
#[dojo::model]
pub struct IdToProperty {
    #[key]
    pub id: u8,
    pub name: felt252,
}

pub trait PropertyTrait {
    fn new(
        id: u8,
        game_id: u256,
        name: felt252,
        cost: u256,
        property_type: PropertyType,
        rent_site_only: u256,
        rent_one_house: u256,
        rent_two_houses: u256,
        rent_three_houses: u256,
        rent_four_houses: u256,
        cost_of_house: u256,
        rent_hotel: u256,
        group_id: u8,
        owner: ContractAddress,
    ) -> Property;
    fn get_rent_amount(
        self: @Property, owner_railroads: u8, owner_utilities: u8, dice_rolled: u256,
    ) -> u256;
    fn calculate_utility_rent(self: @Property, no_of_utilities: u8, dice_rolled: u256) -> u256;
    fn calculate_railway_rent(self: @Property, no_of_railways: u8) -> u256;
    fn mortgage(ref self: Property, owner: ContractAddress);
    fn lift_mortgage(ref self: Property, owner: ContractAddress);
    fn upgrade_property(ref self: Property, player: ContractAddress, upgrade_level: u8) -> bool;
    fn downgrade_property(ref self: Property, player: ContractAddress, downgrade_level: u8) -> bool;
    fn change_game_property_ownership(
        ref self: Property, new_owner: ContractAddress, owner: ContractAddress,
    ) -> bool;
}


impl PropertyImpl of PropertyTrait {
    fn new(
        id: u8,
        game_id: u256,
        name: felt252,
        cost: u256,
        property_type: PropertyType,
        rent_site_only: u256,
        rent_one_house: u256,
        rent_two_houses: u256,
        rent_three_houses: u256,
        rent_four_houses: u256,
        cost_of_house: u256,
        rent_hotel: u256,
        group_id: u8,
        owner: ContractAddress,
    ) -> Property {
        Property {
            id,
            game_id,
            name,
            owner: owner,
            property_type,
            cost_of_property: cost,
            property_level: 0,
            rent_site_only: rent_site_only,
            rent_one_house: rent_one_house,
            rent_two_houses: rent_two_houses,
            rent_three_houses: rent_three_houses,
            rent_four_houses: rent_four_houses,
            rent_hotel: rent_hotel,
            cost_of_house,
            is_mortgaged: false,
            group_id,
            for_sale: true,
            development: 0,
        }
    }
    fn get_rent_amount(
        self: @Property, owner_railroads: u8, owner_utilities: u8, dice_rolled: u256,
    ) -> u256 {
        if *self.is_mortgaged {
            return 0;
        }

        match *self.property_type {
            PropertyType::Property => {
                match *self.development {
                    0 => *self.rent_site_only,
                    1 => *self.rent_one_house,
                    2 => *self.rent_two_houses,
                    3 => *self.rent_three_houses,
                    4 => *self.rent_four_houses,
                    5 => *self.rent_hotel,
                    _ => *self.rent_site_only,
                }
            },
            PropertyType::RailRoad => {
                match owner_railroads {
                    0 => 0,
                    1 => 25,
                    2 => 50,
                    3 => 100,
                    4 => 200,
                    _ => 0,
                }
            },
            PropertyType::Utility => {
                match owner_utilities {
                    0 => 0,
                    1 => 4 * dice_rolled,
                    2 => 10 * dice_rolled,
                    _ => 0,
                }
            },
            _ => 0,
        }
    }


    fn calculate_utility_rent(self: @Property, no_of_utilities: u8, dice_rolled: u256) -> u256 {
        match no_of_utilities {
            0 => 0,
            1 => 4 * dice_rolled,
            2 => 10 * dice_rolled,
            _ => 0,
        }
    }
    fn calculate_railway_rent(self: @Property, no_of_railways: u8) -> u256 {
        match no_of_railways {
            0 => 0,
            1 => 25,
            2 => 50,
            3 => 100,
            4 => 200,
            _ => 0,
        }
    }


    fn mortgage(ref self: Property, owner: ContractAddress) {
        self.is_mortgaged = true;
    }

    fn lift_mortgage(ref self: Property, owner: ContractAddress) {
        self.is_mortgaged = false;
    }

    fn upgrade_property(ref self: Property, player: ContractAddress, upgrade_level: u8) -> bool {
        // deals with the property level mostly after many checks
        true
    }

    fn downgrade_property(
        ref self: Property, player: ContractAddress, downgrade_level: u8,
    ) -> bool {
        // deals with the property level mostly after many checks
        true
    }

    fn change_game_property_ownership(
        ref self: Property, new_owner: ContractAddress, owner: ContractAddress,
    ) -> bool {
        // deals with the field owner after many checks
        true
    }
}
