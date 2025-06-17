// use starknet::ContractAddress;
// use dojo_starter::interfaces::IBlockopolyNFT::IBlockopolyNFT;

// #[starknet::contract]
// pub mod BlockopolyNFT {
//     use starknet::ContractAddress;
//     use openzeppelin::introspection::src5::SRC5Component;
//     use openzeppelin::token::erc721::{ERC721Component, ERC721HooksEmptyImpl};
//     use super::IBlockopolyNFT;

//     component!(path: ERC721Component, storage: erc721, event: ERC721Event);
//     component!(path: SRC5Component, storage: src5, event: SRC5Event);

//     #[storage]
//     struct Storage {
//         #[substorage(v0)]
//         erc721: ERC721Component::Storage,
//         #[substorage(v0)]
//         src5: SRC5Component::Storage,
//     }

//     #[event]
//     #[derive(Drop, starknet::Event)]
//     enum Event {
//         #[flat]
//         ERC721Event: ERC721Component::Event,
//         #[flat]
//         SRC5Event: SRC5Component::Event,
//     }

//     #[constructor]
//     fn constructor(
//         ref self: ContractState, base_uri: ByteArray, name_: ByteArray, symbol: ByteArray,
//     ) {
//         self.erc721.initializer(name_, symbol, base_uri);
//     }

//     #[abi(embed_v0)]
//     impl ERC721Impl = ERC721Component::ERC721MixinImpl<ContractState>;

//     impl ERC721InternalImpl = ERC721Component::InternalImpl<ContractState>;

//     #[abi(embed_v0)]
//     impl BlockopolyNFTImpl of IBlockopolyNFT<ContractState> {
//         fn mint(ref self: ContractState, recipient: ContractAddress, token_id: u256) {
//             self.erc721.mint(recipient, token_id);
//         }
//     }
// }
