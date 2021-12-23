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

## Local Imports ##
from contracts.defi.LendingPool.LendingPoolCore import getReserveATokenAddress, getReserveIsActive, getReserveIsFreezed


## @title Lending Pool
## @description A simple lending pool contract.
## @description Adapted from Aave's Lending Pool https://github.com/aave/aave-protocol
## @author Alucard <github.com/a5f9t4>

#############################################
##               MODIFIERS                 ##
#############################################

## Ensures that the caller is the aToken contract ##
func onlyOverlyingAToken{
    syscall_ptr: felt*,
    pedersen_ptr: HashBuiltin*,
    range_check_ptr
}(
    reserve: felt
):
    alloc_locals
    let (local caller) = get_caller_address()
    let (aToken: felt) = getReserveATokenAddress(reserve)
    assert aToken = caller

    return ()
end

## Reserve must be active ##
func onlyActiveReserve{
    syscall_ptr: felt*,
    pedersen_ptr: HashBuiltin*,
    range_check_ptr
}(
    reserve: felt
):
    # absent native booleans, 0<>1 serves as false<>true
    let (isActive: felt) = getReserveIsActive(reserve)
    assert isActive = 1

    return ()
end

## Reserve must not be frozen ##
func onlyUnfreezedReserve{
    syscall_ptr: felt*,
    pedersen_ptr: HashBuiltin*,
    range_check_ptr
}(
    reserve: felt
):
    # absent native booleans, 0<>1 serves as false<>true
    let (isFrozen: felt) = getReserveIsFreezed(reserve)
    assert isFrozen = 0

    return ()
end

## Reserve must be active ##
func onlyAmountGreaterThanZero{
    syscall_ptr: felt*,
    pedersen_ptr: HashBuiltin*,
    range_check_ptr
}(
    amount: felt
):
    assert_not_zero(amount)
    return ()
end

#############################################
##                 STORAGE                 ##
#############################################

@storage_var
func INITIALIZED() -> (res: felt):
end

#############################################
##               CONSTRUCTOR               ##
#############################################

@constructor
func constructor{
    syscall_ptr: felt*,
    pedersen_ptr: HashBuiltin*,
    range_check_ptr
}():
    INITIALIZED.write(0)
    return ()
end

@external
func initialize{
    syscall_ptr: felt*,
    pedersen_ptr: HashBuiltin*,
    range_check_ptr
}():
    let (_initialized) = INITIALIZED.read()
    assert _initialized = 0
    INITIALIZED.write(1)
    return ()
end

#############################################
##               POOL LOGIC                ##
#############################################

func deposit{
    syscall_ptr: felt*,
    pedersen_ptr: HashBuiltin*,
    range_check_ptr
}(
    reserve: felt,
    amount: Uint256,
    referralCode: Uint256 # TODO: Should be Uint16
):

    return ()
end