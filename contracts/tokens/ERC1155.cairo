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

## @title ERC1155
## @description A minimalistic implementation of ERC1155 Token Standard.
## @description Adheres to the ERC1155 Token Standard: https://eips.ethereum.org/EIPS/eip-1155
## @author Alucard <github.com/a5f9t4>

#############################################
##                METADATA                 ##
#############################################


#############################################
##               CONSTRUCTOR               ##
#############################################

@constructor
func constructor{
    syscall_ptr: felt*,
    pedersen_ptr: HashBuiltin*,
    range_check_ptr
}(
    name: felt,
    symbol: felt,
    decimals: felt, # 18
    totalSupply: Uint256,
):
    NAME.write(name)
    SYMBOL.write(symbol)
    DECIMALS.write(decimals)
    TOTAL_SUPPLY.write(totalSupply)
    return ()
end

#############################################
##             ERC-165 SUPPORT             ##
#############################################

@external
func supportsInterface{
    syscall_ptr: felt*,
    pedersen_ptr: HashBuiltin*,
    range_check_ptr
}(
    interfaceID: felt # This should be a `bytes4`
) -> (
    supported: felt # Either 0 (false) or 1 (true)
):
    # Check ERC165 Interface Support
    if interfaceID == 0xd9b67a26:
        return (1)
    end

    # ERC165 Interface Support - 0x01ffc9a7
    # This doesn't need to be checked since it is XORed with the above interfaceID

    # return super.supportsInterface(_interfaceID);
    return (0)
end