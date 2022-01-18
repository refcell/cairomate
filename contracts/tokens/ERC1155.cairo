%lang starknet

from starkware.starknet.common.syscalls import get_caller_address
from starkware.cairo.common.cairo_builtins import HashBuiltin
from starkware.cairo.common.hash import hash2
from starkware.cairo.common.math import assert_le, assert_nn_le, unsigned_div_rem, assert_not_zero
from starkware.starknet.common.syscalls import storage_read, storage_write
from starkware.cairo.common.uint256 import (
    Uint256, uint256_add, uint256_sub, uint256_le, uint256_lt, uint256_check
)
from starkware.cairo.common.alloc import alloc

## @title ERC1155
## @description A minimalistic implementation of ERC1155 Token Standard.
## @description Adheres to the ERC1155 Token Standard: https://eips.ethereum.org/EIPS/eip-1155
## @author andreas <andreas@nascent.xyz>

#############################################
##                METADATA                 ##
#############################################


#############################################
##                 STORAGE                 ##
#############################################

## Selector ID for ERC1155 Received Value ##
const ERC1155_RECEIVED_VALUE = 0xf23a6e61

## Selector ID for ERC1155 Batch Received Value ##
const ERC1155_BATCH_RECEIVED_VALUE = 0xbc197c81

## Selector ID for ERC1155 ##
const ERC1155 = 0xd9b67a26

## Selector ID for EIP165 Interface ##
const EIP165_INTERFACE = 0x01ffc9a7

## Balance of a user,id pair ##
@storage_var
func BALANCES(owner: felt, id: felt) -> (balance: felt):
end

## Returns 0 (false) or 1 (true) ##
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
func safeTransferFrom{
    syscall_ptr: felt*,
    pedersen_ptr: HashBuiltin*,
    range_check_ptr
}(
    _from: felt,
    _to: felt,
    _id: felt, # Uint256
    _value: felt, # Uint256
    _data: felt
):
    alloc_locals

    # Check caller is the sender
    let (local caller: felt) = get_caller_address()
    let (local approved: felt) = isApprovedForAll(_from, caller)
    if caller == _from:
    else:
        # Otherwise, the caller must be an approved operator
        assert approved = 1
    end

    # Check valid Uint256 value to prevent overflow
    # uint256_check(_value)

    # Prevent 0 Address for spam manipulation
    assert_not_zero(_to)

    # Affect Sender's balance
    let (local initial_sender_balance: felt) = BALANCES.read(_from, _id)
    let new_sender_balance = initial_sender_balance - _value
    assert_nn_le(0, new_sender_balance)
    BALANCES.write(_from, _id, new_sender_balance)

    # Affect Recipient's balance
    let (local initial_recp_balance: felt) = BALANCES.read(_to, _id)
    let new_recp_balance = initial_recp_balance + _value
    assert_nn_le(0, new_recp_balance)
    BALANCES.write(_to, _id, new_recp_balance)

    return ()
end


@external
func safeBatchTransferFrom{
    syscall_ptr: felt*,
    pedersen_ptr: HashBuiltin*,
    range_check_ptr
}(
    _from: felt,
    _to: felt,
    _ids_len: felt,
    _ids: felt*, # ?? Uint256* ??
    _values_len: felt,
    _values: felt*, # ?? Uint256* ??
    _data: felt
):
    alloc_locals

    # Check caller is the sender
    let (local caller: felt) = get_caller_address()
    let (approved: felt) = isApprovedForAll(_from, caller)
    if caller == _from:
    else:
        # Otherwise, the caller must be an approved operator
        assert approved = 1
    end

    # Prevent 0 Address for spam manipulation
    assert_not_zero(_to)

    assert _ids_len = _values_len

    # TODO: recurse

    # // Number of transfer to execute
    # uint256 nTransfer = _ids.length;

    # // Executing all transfers
    # for (uint256 i = 0; i < nTransfer; i++) {
    #   // Update storage balance of previous bin
    #   balances[_from][_ids[i]] = balances[_from][_ids[i]].sub(_amounts[i]);
    #   balances[_to][_ids[i]] = balances[_to][_ids[i]].add(_amounts[i]);
    # }

    # // Emit event
    # emit TransferBatch(msg.sender, _from, _to, _ids, _amounts);


    return ()
end

@external
func balanceOf{
    syscall_ptr: felt*,
    pedersen_ptr: HashBuiltin*,
    range_check_ptr
}(
    _owner: felt,
    _id: felt # Uint256
) -> (
    balance: felt # Uint256
):
    let (balance) = BALANCES.read(_owner, _id)
    return (balance)
end


@external
func balanceOfBatch{
    syscall_ptr: felt*,
    pedersen_ptr: HashBuiltin*,
    range_check_ptr
}(
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
    alloc_locals
    # Owners length must equal ids length
    assert _owners_len = _ids_len

    # Allocate memory for balances array
    let (local balances: felt*) = alloc()
    let (_) = _recurseBalances(
        _owners_len,
        _owners,
        _ids_len,
        _ids,
        _owners_len, #index in _ids array
        balances
    )

    # balances_len must equal _owners_len, otherwise our recursion failed
    # assert balances_len = _owners_len

    return (_owners_len, balances)
end

# Internal helper function for balanceOfBatch
func _recurseBalances{
    syscall_ptr: felt*,
    pedersen_ptr: HashBuiltin*,
    range_check_ptr
}(
    _owners_len: felt,
    _owners: felt*,
    _ids_len: felt,
    _ids: felt*,
    _index: felt,
    _balances: felt*
) -> (
    success: felt
):
    alloc_locals
    if _index == 0:
        return (1)
    else:
        let (val) = BALANCES.read(_owners[_index], _ids[_index])
        assert [_balances + _index] = val
        return _recurseBalances(
            _owners_len,
            _owners,
            _ids_len,
            _ids,
            _index - 1,
            _balances
        )
    end
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
    alloc_locals
    let (local approved: felt) = OPERATORS.read(_owner, _operator)
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
    if interfaceID == ERC1155:
        return (1)
    end

    # ERC165 Interface Support - 0x01ffc9a7
    # This doesn't need to be checked since it is XORed with the above interfaceID

    # return super.supportsInterface(_interfaceID);
    return (0)
end