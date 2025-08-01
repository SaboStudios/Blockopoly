use blockopoly::model::property_model::{
    IdToProperty, Property, PropertyToId, PropertyTrait, PropertyType, TradeCounter, TradeOffer,
    TradeOfferDetails, TradeStatus,
};
use blockopoly::model::player_model::{AddressToUsername, IsRegistered, Player, PlayerTrait, UsernameToAddress};
use starknet::ContractAddress;
// define the interface
#[starknet::interface]
pub trait ITrade<T> {
    // 🔄 TradeSystem - All trade & negotiation logic
    fn offer_trade(
        ref self: T,
        game_id: u256,
        to: ContractAddress,
        offered_property_ids: Array<u8>,
        requested_property_ids: Array<u8>,
        cash_offer: u256,
        cash_request: u256,
        trade_type: TradeOffer,
    ) -> u256;
    fn accept_trade(ref self: T, trade_id: u256, game_id: u256) -> bool;
    fn reject_trade(ref self: T, trade_id: u256, game_id: u256) -> bool;
    fn counter_trade(
        ref self: T,
        game_id: u256,
        original_offer_id: u256,
        offered_property_ids: Array<u8>,
        requested_property_ids: Array<u8>,
        cash_offer: u256,
        cash_request: u256,
        trade_type: TradeOffer,
    ) -> u256;
    fn approve_counter_trade(ref self: T, trade_id: u256) -> bool;
    fn get_trade(self: @T, trade_id: u256) -> TradeOfferDetails;
    fn create_trade_id(ref self: T) -> u256;
}

// dojo decorator
#[dojo::contract]
pub mod trade {
    use blockopoly::model::game_model::{
        Game, GameBalance, GameCounter, GameStatus, GameTrait, GameType, IGameBalance,
    };
    use blockopoly::model::game_player_model::{GamePlayer, GamePlayerTrait, PlayerSymbol};
    use dojo::event::EventStorage;
    use dojo::model::ModelStorage;
    use starknet::{
        ContractAddress, contract_address_const, get_block_timestamp, get_caller_address,
    };
    use super::{
        AddressToUsername, ITrade, IdToProperty, IsRegistered, Player, PlayerTrait, Property,
        PropertyToId, PropertyTrait, PropertyType, TradeCounter, TradeOffer, TradeOfferDetails,
        TradeStatus, UsernameToAddress,
    };


    #[derive(Copy, Drop, Serde)]
    #[dojo::event]
    pub struct PlayerCreated {
        #[key]
        pub username: felt252,
        #[key]
        pub player: ContractAddress,
        pub timestamp: u64,
    }

    #[abi(embed_v0)]
    impl TradeImpl of ITrade<ContractState> {
        fn offer_trade(
            ref self: ContractState,
            game_id: u256,
            to: ContractAddress,
            offered_property_ids: Array<u8>,
            requested_property_ids: Array<u8>,
            cash_offer: u256,
            cash_request: u256,
            trade_type: TradeOffer,
        ) -> u256 {
            let caller = get_caller_address();

            let mut world = self.world_default();
            let mut game: Game = world.read_model(game_id);

            assert!(game.next_player == caller, "Not your turn");
            assert!(game.status == GameStatus::Ongoing, "Game is not ongoing");

            let id = self.create_trade_id();

            // Validate inputs here (as you do)
            let mut offer: TradeOfferDetails = world.read_model(id);
            // Create the offer struct

            offer.id = id;
            offer.from = caller;
            offer.to = to;
            offer.game_id = game_id;
            offer.offered_property_ids = offered_property_ids;
            offer.requested_property_ids = requested_property_ids;
            offer.cash_offer = cash_offer;
            offer.cash_request = cash_request;
            offer.trade_type = trade_type;
            offer.status = TradeStatus::Pending;

            world.write_model(@offer);

            id
        }

        fn reject_trade(ref self: ContractState, trade_id: u256, game_id: u256) -> bool {
            let mut world = self.world_default();
            let caller = get_caller_address();

            let mut offer: TradeOfferDetails = world.read_model(trade_id);
            assert!(caller == offer.to, "Only recipient can reject trade");
            offer.status = TradeStatus::Rejected;

            world.write_model(@offer);

            true
        }

        fn counter_trade(
            ref self: ContractState,
            game_id: u256,
            original_offer_id: u256,
            offered_property_ids: Array<u8>,
            requested_property_ids: Array<u8>,
            cash_offer: u256,
            cash_request: u256,
            trade_type: TradeOffer,
        ) -> u256 {
            let caller = get_caller_address();

            let mut world = self.world_default();
            let mut game: Game = world.read_model(game_id);

            assert!(game.status == GameStatus::Ongoing, "Game is not ongoing");

            let mut original_offer: TradeOfferDetails = world.read_model(original_offer_id);

            // Ensure the caller is the recipient of the original offer
            assert!(
                original_offer.to == caller, "Only the receiver of the original trade can counter",
            );

            original_offer.id = original_offer.id;
            original_offer.game_id = game_id;
            original_offer.offered_property_ids = offered_property_ids;
            original_offer.requested_property_ids = requested_property_ids;
            original_offer.cash_offer = cash_offer;
            original_offer.cash_request = cash_request;
            original_offer.trade_type = trade_type;
            original_offer.status = TradeStatus::Countered;
            original_offer.is_countered = true;

            world.write_model(@original_offer);

            original_offer.id
        }

        fn approve_counter_trade(ref self: ContractState, trade_id: u256) -> bool {
            let mut world = self.world_default();
            let caller = get_caller_address();

            let mut offer: TradeOfferDetails = world.read_model(trade_id);
            assert!(caller == offer.from, "Only the initiator can approve the counter trade");
            assert!(offer.status == TradeStatus::Countered, "Trade is not pending");

            // Process the trade
            offer.status = TradeStatus::Pending;
            offer.is_countered = false;
            offer.approve_counter = true;

            true
        }

        fn get_trade(self: @ContractState, trade_id: u256) -> TradeOfferDetails {
            let world = self.world_default();
            let trade: TradeOfferDetails = world.read_model(trade_id);
            trade
        }


        fn accept_trade(ref self: ContractState, trade_id: u256, game_id: u256) -> bool {
            let mut world = self.world_default();
            let caller = get_caller_address();

            let mut offer: TradeOfferDetails = world.read_model(trade_id);
            assert!(caller == offer.to, "Only recipient can accept trade");

            // Load offer

            let mut initiator: GamePlayer = world.read_model((offer.from, offer.game_id));
            let mut receiver: GamePlayer = world.read_model((offer.to, offer.game_id));

            if offer.trade_type == TradeOffer::PropertyForCash {
                // Transfer properties from initiator to receiver
                let mut i = 0;
                while i < offer.offered_property_ids.len() {
                    let prop_id = *offer.offered_property_ids[i];
                    let mut property: Property = world.read_model((prop_id, game_id));

                    // Manual transfer of ownership
                    assert!(
                        property.owner == initiator.address, "Initiator does not own this property",
                    );
                    property.owner = receiver.address;

                    // Create a new array excluding the property being traded
                    let mut new_properties_owned: Array<u8> = ArrayTrait::new();
                    let mut j = 0;

                    while j < initiator.properties_owned.len() {
                        let owned_prop_id = *initiator.properties_owned[j];
                        if owned_prop_id != prop_id {
                            new_properties_owned.append(owned_prop_id);
                        }
                        j += 1;
                    };

                    // Assign back the new array
                    initiator.properties_owned = new_properties_owned;

                    // Now add the property to the receiver
                    receiver.properties_owned.append(prop_id);
                    match property.group_id {
                        0 => {},
                        1 => receiver.no_section1 += 1,
                        2 => receiver.no_section2 += 1,
                        3 => receiver.no_section3 += 1,
                        4 => receiver.no_section4 += 1,
                        5 => receiver.no_section5 += 1,
                        6 => receiver.no_section6 += 1,
                        7 => receiver.no_section7 += 1,
                        8 => receiver.no_section8 += 1,
                        _ => {},
                    }
                    match property.group_id {
                        0 => {},
                        1 => initiator.no_section1 -= 1,
                        2 => initiator.no_section2 -= 1,
                        3 => initiator.no_section3 -= 1,
                        4 => initiator.no_section4 -= 1,
                        5 => initiator.no_section5 -= 1,
                        6 => initiator.no_section6 -= 1,
                        7 => initiator.no_section7 -= 1,
                        8 => initiator.no_section8 -= 1,
                        _ => {},
                    }

                    // Save updated property
                    world.write_model(@property);

                    i += 1;
                };

                // Transfer cash from receiver to initiator
                assert!(receiver.balance >= offer.cash_request, "Receiver has insufficient cash");
                receiver.balance -= offer.cash_request;
                initiator.balance += offer.cash_request;

                // Persist updated players
                world.write_model(@initiator);
                world.write_model(@receiver);
            } else if offer.trade_type == TradeOffer::PropertyForProperty {
                // Transfer offered properties from initiator to receiver
                let mut i = 0;
                while i < offer.offered_property_ids.len() {
                    let prop_id = *offer.offered_property_ids[i];
                    let mut property: Property = world.read_model((prop_id, game_id));

                    // Ensure the initiator owns it
                    assert!(
                        property.owner == initiator.address, "Initiator does not own this property",
                    );
                    property.owner = receiver.address;

                    // Remove from initiator properties_owned
                    let mut new_properties_owned: Array<u8> = ArrayTrait::new();
                    let mut k = 0;
                    while k < initiator.properties_owned.len() {
                        let owned_prop_id = *initiator.properties_owned[k];
                        if owned_prop_id != prop_id {
                            new_properties_owned.append(owned_prop_id);
                        }
                        k += 1;
                    };
                    initiator.properties_owned = new_properties_owned;

                    // Add to receiver properties_owned
                    receiver.properties_owned.append(prop_id);

                    // Update section counters
                    match property.group_id {
                        0 => {},
                        1 => {
                            receiver.no_section1 += 1;
                            initiator.no_section1 -= 1;
                        },
                        2 => {
                            receiver.no_section2 += 1;
                            initiator.no_section2 -= 1;
                        },
                        3 => {
                            receiver.no_section3 += 1;
                            initiator.no_section3 -= 1;
                        },
                        4 => {
                            receiver.no_section4 += 1;
                            initiator.no_section4 -= 1;
                        },
                        5 => {
                            receiver.no_section5 += 1;
                            initiator.no_section5 -= 1;
                        },
                        6 => {
                            receiver.no_section6 += 1;
                            initiator.no_section6 -= 1;
                        },
                        7 => {
                            receiver.no_section7 += 1;
                            initiator.no_section7 -= 1;
                        },
                        8 => {
                            receiver.no_section8 += 1;
                            initiator.no_section8 -= 1;
                        },
                        _ => {},
                    }

                    // Write updated property
                    world.write_model(@property);

                    i += 1;
                };

                // Transfer requested properties from receiver to initiator
                let mut j = 0;
                while j < offer.requested_property_ids.len() {
                    let prop_id = *offer.requested_property_ids[j];
                    let mut property: Property = world.read_model((prop_id, game_id));

                    // Ensure the receiver owns it
                    assert!(
                        property.owner == receiver.address, "Receiver does not own this property",
                    );
                    property.owner = initiator.address;

                    // Remove from receiver properties_owned
                    let mut new_properties_owned: Array<u8> = ArrayTrait::new();
                    let mut l = 0;
                    while l < receiver.properties_owned.len() {
                        let owned_prop_id = *receiver.properties_owned[l];
                        if owned_prop_id != prop_id {
                            new_properties_owned.append(owned_prop_id);
                        }
                        l += 1;
                    };
                    receiver.properties_owned = new_properties_owned;

                    // Add to initiator properties_owned
                    initiator.properties_owned.append(prop_id);

                    // Update section counters
                    match property.group_id {
                        0 => {},
                        1 => {
                            initiator.no_section1 += 1;
                            receiver.no_section1 -= 1;
                        },
                        2 => {
                            initiator.no_section2 += 1;
                            receiver.no_section2 -= 1;
                        },
                        3 => {
                            initiator.no_section3 += 1;
                            receiver.no_section3 -= 1;
                        },
                        4 => {
                            initiator.no_section4 += 1;
                            receiver.no_section4 -= 1;
                        },
                        5 => {
                            initiator.no_section5 += 1;
                            receiver.no_section5 -= 1;
                        },
                        6 => {
                            initiator.no_section6 += 1;
                            receiver.no_section6 -= 1;
                        },
                        7 => {
                            initiator.no_section7 += 1;
                            receiver.no_section7 -= 1;
                        },
                        8 => {
                            initiator.no_section8 += 1;
                            receiver.no_section8 -= 1;
                        },
                        _ => {},
                    }

                    // Write updated property
                    world.write_model(@property);

                    j += 1;
                };

                // Write updated players
                world.write_model(@initiator);
                world.write_model(@receiver);
            } else if offer.trade_type == TradeOffer::CashForProperty {
                // Transfer cash from initiator to receiver
                assert!(initiator.balance >= offer.cash_offer, "Initiator has insufficient cash");
                initiator.balance -= offer.cash_offer;
                receiver.balance += offer.cash_offer;

                // Transfer requested properties from receiver to initiator
                let mut j = 0;
                while j < offer.requested_property_ids.len() {
                    let prop_id = *offer.requested_property_ids[j];
                    let mut property: Property = world.read_model((prop_id, game_id));

                    // Ensure the receiver owns it
                    assert!(
                        property.owner == receiver.address, "Receiver does not own this property",
                    );
                    property.owner = initiator.address;

                    // Remove from receiver properties_owned
                    let mut new_properties_owned: Array<u8> = ArrayTrait::new();
                    let mut l = 0;
                    while l < receiver.properties_owned.len() {
                        let owned_prop_id = *receiver.properties_owned[l];
                        if owned_prop_id != prop_id {
                            new_properties_owned.append(owned_prop_id);
                        }
                        l += 1;
                    };
                    receiver.properties_owned = new_properties_owned;

                    // Add to initiator properties_owned
                    initiator.properties_owned.append(prop_id);

                    // Update section counters
                    match property.group_id {
                        0 => {},
                        1 => {
                            initiator.no_section1 += 1;
                            receiver.no_section1 -= 1;
                        },
                        2 => {
                            initiator.no_section2 += 1;
                            receiver.no_section2 -= 1;
                        },
                        3 => {
                            initiator.no_section3 += 1;
                            receiver.no_section3 -= 1;
                        },
                        4 => {
                            initiator.no_section4 += 1;
                            receiver.no_section4 -= 1;
                        },
                        5 => {
                            initiator.no_section5 += 1;
                            receiver.no_section5 -= 1;
                        },
                        6 => {
                            initiator.no_section6 += 1;
                            receiver.no_section6 -= 1;
                        },
                        7 => {
                            initiator.no_section7 += 1;
                            receiver.no_section7 -= 1;
                        },
                        8 => {
                            initiator.no_section8 += 1;
                            receiver.no_section8 -= 1;
                        },
                        _ => {},
                    }

                    // Write updated property
                    world.write_model(@property);

                    j += 1;
                };

                // Write updated players
                world.write_model(@initiator);
                world.write_model(@receiver);
            } else if offer.trade_type == TradeOffer::CashPlusPropertyForProperty {
                // Transfer offered properties from initiator to receiver
                let mut i = 0;
                while i < offer.offered_property_ids.len() {
                    let prop_id = *offer.offered_property_ids[i];
                    let mut property: Property = world.read_model((prop_id, game_id));

                    // Ensure the initiator owns it
                    assert!(
                        property.owner == initiator.address, "Initiator does not own this property",
                    );
                    property.owner = receiver.address;

                    // Remove from initiator properties_owned
                    let mut new_properties_owned: Array<u8> = ArrayTrait::new();
                    let mut k = 0;
                    while k < initiator.properties_owned.len() {
                        let owned_prop_id = *initiator.properties_owned[k];
                        if owned_prop_id != prop_id {
                            new_properties_owned.append(owned_prop_id);
                        }
                        k += 1;
                    };
                    initiator.properties_owned = new_properties_owned;

                    // Add to receiver properties_owned
                    receiver.properties_owned.append(prop_id);

                    // Update section counters
                    match property.group_id {
                        0 => {},
                        1 => {
                            receiver.no_section1 += 1;
                            initiator.no_section1 -= 1;
                        },
                        2 => {
                            receiver.no_section2 += 1;
                            initiator.no_section2 -= 1;
                        },
                        3 => {
                            receiver.no_section3 += 1;
                            initiator.no_section3 -= 1;
                        },
                        4 => {
                            receiver.no_section4 += 1;
                            initiator.no_section4 -= 1;
                        },
                        5 => {
                            receiver.no_section5 += 1;
                            initiator.no_section5 -= 1;
                        },
                        6 => {
                            receiver.no_section6 += 1;
                            initiator.no_section6 -= 1;
                        },
                        7 => {
                            receiver.no_section7 += 1;
                            initiator.no_section7 -= 1;
                        },
                        8 => {
                            receiver.no_section8 += 1;
                            initiator.no_section8 -= 1;
                        },
                        _ => {},
                    }

                    // Write updated property
                    world.write_model(@property);

                    i += 1;
                };

                // Transfer cash from initiator to receiver
                assert!(initiator.balance >= offer.cash_offer, "Initiator has insufficient cash");
                initiator.balance -= offer.cash_offer;
                receiver.balance += offer.cash_offer;

                // Transfer requested properties from receiver to initiator
                let mut j = 0;
                while j < offer.requested_property_ids.len() {
                    let prop_id = *offer.requested_property_ids[j];
                    let mut property: Property = world.read_model((prop_id, game_id));

                    // Ensure the receiver owns it
                    assert!(
                        property.owner == receiver.address, "Receiver does not own this property",
                    );
                    property.owner = initiator.address;

                    // Remove from receiver properties_owned
                    let mut new_properties_owned: Array<u8> = ArrayTrait::new();
                    let mut l = 0;
                    while l < receiver.properties_owned.len() {
                        let owned_prop_id = *receiver.properties_owned[l];
                        if owned_prop_id != prop_id {
                            new_properties_owned.append(owned_prop_id);
                        }
                        l += 1;
                    };
                    receiver.properties_owned = new_properties_owned;

                    // Add to initiator properties_owned
                    initiator.properties_owned.append(prop_id);

                    // Update section counters
                    match property.group_id {
                        0 => {},
                        1 => {
                            initiator.no_section1 += 1;
                            receiver.no_section1 -= 1;
                        },
                        2 => {
                            initiator.no_section2 += 1;
                            receiver.no_section2 -= 1;
                        },
                        3 => {
                            initiator.no_section3 += 1;
                            receiver.no_section3 -= 1;
                        },
                        4 => {
                            initiator.no_section4 += 1;
                            receiver.no_section4 -= 1;
                        },
                        5 => {
                            initiator.no_section5 += 1;
                            receiver.no_section5 -= 1;
                        },
                        6 => {
                            initiator.no_section6 += 1;
                            receiver.no_section6 -= 1;
                        },
                        7 => {
                            initiator.no_section7 += 1;
                            receiver.no_section7 -= 1;
                        },
                        8 => {
                            initiator.no_section8 += 1;
                            receiver.no_section8 -= 1;
                        },
                        _ => {},
                    }

                    // Write updated property
                    world.write_model(@property);

                    j += 1;
                };

                // Write updated players
                world.write_model(@initiator);
                world.write_model(@receiver);
            } else if offer.trade_type == TradeOffer::PropertyForCashPlusProperty {
                // Transfer offered properties from initiator to receiver
                let mut i = 0;
                while i < offer.offered_property_ids.len() {
                    let prop_id = *offer.offered_property_ids[i];
                    let mut property: Property = world.read_model((prop_id, game_id));

                    // Ensure the initiator owns it
                    assert!(
                        property.owner == initiator.address, "Initiator does not own this property",
                    );
                    property.owner = receiver.address;

                    // Remove from initiator properties_owned
                    let mut new_properties_owned: Array<u8> = ArrayTrait::new();
                    let mut k = 0;
                    while k < initiator.properties_owned.len() {
                        let owned_prop_id = *initiator.properties_owned[k];
                        if owned_prop_id != prop_id {
                            new_properties_owned.append(owned_prop_id);
                        }
                        k += 1;
                    };
                    initiator.properties_owned = new_properties_owned;

                    // Add to receiver properties_owned
                    receiver.properties_owned.append(prop_id);

                    // Update section counters
                    match property.group_id {
                        0 => {},
                        1 => {
                            receiver.no_section1 += 1;
                            initiator.no_section1 -= 1;
                        },
                        2 => {
                            receiver.no_section2 += 1;
                            initiator.no_section2 -= 1;
                        },
                        3 => {
                            receiver.no_section3 += 1;
                            initiator.no_section3 -= 1;
                        },
                        4 => {
                            receiver.no_section4 += 1;
                            initiator.no_section4 -= 1;
                        },
                        5 => {
                            receiver.no_section5 += 1;
                            initiator.no_section5 -= 1;
                        },
                        6 => {
                            receiver.no_section6 += 1;
                            initiator.no_section6 -= 1;
                        },
                        7 => {
                            receiver.no_section7 += 1;
                            initiator.no_section7 -= 1;
                        },
                        8 => {
                            receiver.no_section8 += 1;
                            initiator.no_section8 -= 1;
                        },
                        _ => {},
                    }

                    // Write updated property
                    world.write_model(@property);

                    i += 1;
                };

                // Transfer cash from receiver to initiator
                assert!(receiver.balance >= offer.cash_request, "Receiver has insufficient cash");
                receiver.balance -= offer.cash_request;
                initiator.balance += offer.cash_request;

                // Transfer requested properties from receiver to initiator
                let mut j = 0;
                while j < offer.requested_property_ids.len() {
                    let prop_id = *offer.requested_property_ids[j];
                    let mut property: Property = world.read_model((prop_id, game_id));

                    // Ensure the receiver owns it
                    assert!(
                        property.owner == receiver.address, "Receiver does not own this property",
                    );
                    property.owner = initiator.address;

                    // Remove from receiver properties_owned
                    let mut new_properties_owned: Array<u8> = ArrayTrait::new();
                    let mut l = 0;
                    while l < receiver.properties_owned.len() {
                        let owned_prop_id = *receiver.properties_owned[l];
                        if owned_prop_id != prop_id {
                            new_properties_owned.append(owned_prop_id);
                        }
                        l += 1;
                    };
                    receiver.properties_owned = new_properties_owned;

                    // Add to initiator properties_owned
                    initiator.properties_owned.append(prop_id);

                    // Update section counters
                    match property.group_id {
                        0 => {},
                        1 => {
                            initiator.no_section1 += 1;
                            receiver.no_section1 -= 1;
                        },
                        2 => {
                            initiator.no_section2 += 1;
                            receiver.no_section2 -= 1;
                        },
                        3 => {
                            initiator.no_section3 += 1;
                            receiver.no_section3 -= 1;
                        },
                        4 => {
                            initiator.no_section4 += 1;
                            receiver.no_section4 -= 1;
                        },
                        5 => {
                            initiator.no_section5 += 1;
                            receiver.no_section5 -= 1;
                        },
                        6 => {
                            initiator.no_section6 += 1;
                            receiver.no_section6 -= 1;
                        },
                        7 => {
                            initiator.no_section7 += 1;
                            receiver.no_section7 -= 1;
                        },
                        8 => {
                            initiator.no_section8 += 1;
                            receiver.no_section8 -= 1;
                        },
                        _ => {},
                    }

                    // Write updated property
                    world.write_model(@property);

                    j += 1;
                };

                // Write updated players
                world.write_model(@initiator);
                world.write_model(@receiver);
            } else if offer.trade_type == TradeOffer::CashForChanceJailCard {
                // Initiator pays cash to receiver for receiver's chance jail card
                assert!(initiator.balance >= offer.cash_offer, "Initiator has insufficient cash");
                assert!(receiver.chance_jail_card, "Receiver does not have a chance jail card");
                assert!(!initiator.chance_jail_card, "Initiator already owns a chance jail card");

                // Transfer cash
                initiator.balance -= offer.cash_offer;
                receiver.balance += offer.cash_offer;

                // Transfer the card
                receiver.chance_jail_card = false;
                initiator.chance_jail_card = true;

                // Write back players
                world.write_model(@initiator);
                world.write_model(@receiver);
            } else if offer.trade_type == TradeOffer::CommunityJailCardForCash {
                // Initiator pays cash to receiver for receiver's community jail card
                assert!(initiator.balance >= offer.cash_offer, "Initiator has insufficient cash");
                assert!(receiver.comm_free_card, "Receiver does not have a community jail card");
                assert!(!initiator.comm_free_card, "Initiator already owns a community jail card");

                // Transfer cash
                initiator.balance -= offer.cash_offer;
                receiver.balance += offer.cash_offer;

                // Transfer the card
                receiver.comm_free_card = false;
                initiator.comm_free_card = true;

                // Write back players
                world.write_model(@initiator);
                world.write_model(@receiver);
            } else if offer.trade_type == TradeOffer::CashForCommunityJailCard {
                // Receiver pays cash to initiator for initiator's community jail card
                assert!(receiver.balance >= offer.cash_request, "Receiver has insufficient cash");
                assert!(initiator.comm_free_card, "Initiator does not have a community jail card");
                assert!(!receiver.comm_free_card, "Receiver already owns a community jail card");

                // Transfer cash
                receiver.balance -= offer.cash_request;
                initiator.balance += offer.cash_request;

                // Transfer the card
                initiator.comm_free_card = false;
                receiver.comm_free_card = true;

                // Write back players
                world.write_model(@initiator);
                world.write_model(@receiver);
            } else if offer.trade_type == TradeOffer::ChanceJailCardForCash {
                // Receiver pays cash to initiator for initiator's chance jail card
                assert!(receiver.balance >= offer.cash_request, "Receiver has insufficient cash");
                assert!(initiator.chance_jail_card, "Initiator does not have a chance jail card");
                assert!(!receiver.chance_jail_card, "Receiver already owns a chance jail card");

                // Transfer cash
                receiver.balance -= offer.cash_request;
                initiator.balance += offer.cash_request;

                // Transfer the card
                initiator.chance_jail_card = false;
                receiver.chance_jail_card = true;

                // Write back players
                world.write_model(@initiator);
                world.write_model(@receiver);
            }

            offer.status = TradeStatus::Accepted;

            // Save updated player and property data
            world.write_model(@initiator);
            world.write_model(@receiver);
            world.write_model(@offer);

            true
        }

             fn create_trade_id(ref self: ContractState) -> u256 {
            let mut world = self.world_default();
            let mut trade_counter: TradeCounter = world.read_model('v0');
            let new_val = trade_counter.current_val + 1;
            trade_counter.current_val = new_val;
            world.write_model(@trade_counter);
            new_val
        }
    }

    #[generate_trait]
    impl InternalImpl of InternalTrait {
        /// Use the default namespace "dojo_starter". This function is handy since the ByteArray
        /// can't be const.
        fn world_default(self: @ContractState) -> dojo::world::WorldStorage {
            self.world(@"blockopoly")
        }

   
    }
}

