// SPDX-License-Identifier: MIT
use starknet::ContractAddress;

#[starknet::interface]
pub trait IBlockopoly<ContractState> {
    fn init(ref self: ContractState, owner: ContractAddress);
    fn mint(ref self: ContractState, recipient: ContractAddress, amount: u256);
    fn get_balance(ref self: ContractState, address: ContractAddress) -> u256;
    fn transferFrom(
        ref self: ContractState, sender: ContractAddress, recipient: ContractAddress, amount: u256,
    ) -> bool;
    fn get_symbol(ref self: ContractState) -> ByteArray;
    fn get_name(ref self: ContractState) -> ByteArray;
    fn get_allowance(
        ref self: ContractState, owner: ContractAddress, spender: ContractAddress,
    ) -> u256;
    fn approve_user(ref self: ContractState, spender: ContractAddress, amount: u256);
}
