%lang starknet
%builtins pedersen range_check

from starkware.cairo.common.cairo_builtins import HashBuiltin
from starkware.starknet.common.syscalls import (
    get_contract_address)

## @title Context
## @description A mirror of the Openzeppelin Context pattern.
## @description Adapted from OpenZeppelin's Cairo Contracts: https://github.com/OpenZeppelin/cairo-contracts
## @description https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/utils/Context.sol
## @description sry @t11s know ur not a fan
## @author Alucard <github.com/a5f9t4>

## Returns the caller ##
@external
func _msgSender{
    syscall_ptr: felt*,
    pedersen_ptr: HashBuiltin*,
    range_check_ptr
}() -> (sender: felt):
    let (sender) = get_contract_address()
    return (sender=sender)
end