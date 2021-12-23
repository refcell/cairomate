%lang starknet
%builtins pedersen range_check

from starkware.starknet.common.syscalls import get_caller_address
from starkware.cairo.common.cairo_builtins import HashBuiltin
from starkware.cairo.common.hash import hash2
from starkware.cairo.common.math import assert_le, assert_nn_le, unsigned_div_rem, assert_not_zero
from starkware.starknet.common.syscalls import storage_read, storage_write
from starkware.cairo.common.uint256 import (
    Uint256, uint256_add, uint256_sub, uint256_le, uint256_lt, uint256_check
)

## @title Lending Pool Core
## @description Refactored Core Logic for the Lending Pool
## @description Adapted from Aave's Lending Pool https://github.com/aave/aave-protocol
## @author Alucard <github.com/a5f9t4>

#############################################
##               MODIFIERS                 ##
#############################################

## Ensures that the caller is the Lending Pool ##
func onlyLendingPool{
    syscall_ptr: felt*,
    pedersen_ptr: HashBuiltin*,
    range_check_ptr
}(
    reserve: felt
):
    alloc_locals
    let (local caller) = get_caller_address()
    let (pool: felt) = LENDING_POOL.read()
    assert pool = caller

    return ()
end

#############################################
##                 STORAGE                 ##
#############################################

struct RESERVE_DATA:

end

@storage_var
func LENDING_POOL() -> (pool: felt):
end

@storage_var
func RESERVES(reserve: felt) -> (reserveData: felt):
end

#############################################
##               POOL LOGIC                ##
#############################################

func getReserveATokenAddress{
    syscall_ptr: felt*,
    pedersen_ptr: HashBuiltin*,
    range_check_ptr
}(
    reserve: felt
):
    let (reserveData: RESERVE_DATA) = RESERVES.read(reserve)
    return (reserveData.aTokenAddress)
end