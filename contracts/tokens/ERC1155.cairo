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
##                 STORAGE                 ##
#############################################

# Returns 0 (false) or 1 (true)
@storage_var
func OPERATORS(owner: felt, operator: felt) -> (approved: felt):
end

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
    # NAME.write(name)
    # SYMBOL.write(symbol)
    # DECIMALS.write(decimals)
    # TOTAL_SUPPLY.write(totalSupply)
    return ()
end

#############################################
##                CORE LOGIC               ##
#############################################

@external
func balanceOfBatch(
    ## @dev Array arguments are defined by `<name>_len` felt and the data
    ## @dev https://www.cairo-lang.org/docs/hello_starknet/more_features.html#array-arguments-in-calldata
    _owners_len: felt,
    _owners: felt*,
    _ids_len: felt,
    _ids: felt* # ?? Uint256* ??
) -> (
    balances_len: felt,
    balances: felt* # ?? Uint256* ??
):
end


@external
func setApprovalForAll{
    syscall_ptr: felt*,
    pedersen_ptr: HashBuiltin*,
    range_check_ptr
}(
    _operator: felt,
    _approved: felt
):
    alloc_locals
    let (local caller: felt) = get_caller_address()
    OPERATORS.write(caller, _operator, _approved)
    return ()
end

@external
func isApprovedForAll{
    syscall_ptr: felt*,
    pedersen_ptr: HashBuiltin*,
    range_check_ptr
}(
    _owner: felt,
    _operator: felt
) -> (
    approved: felt
):
    let (approved: felt) = OPERATORS.read(_owner, _operator)
    return (approved)
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