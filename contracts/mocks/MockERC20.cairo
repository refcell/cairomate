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

## @title Mock ERC20
## @description Practical implementation of an ERC20 token.
## @author velleity <github.com/a5f9t4>


#############################################
##                OWNABLE                  ##
#############################################

@storage_var
func _owner() -> (owner: felt):
end

## CONSTRUCTOR
@constructor
func constructor{
    syscall_ptr: felt*,
    pedersen_ptr: HashBuiltin*,
    range_check_ptr
}(
    name: felt,
    symbol: felt,
    decimals: felt, # 18
    total_supply: Uint256,
    owner: felt,
):
    _name.write(name)
    _symbol.write(symbol)
    _decimals.write(decimals)
    _total_supply.write(total_supply)
    _owner.write(owner)
    return ()
end

## Mint
@external
func mint{
    syscall_ptr: felt*,
    pedersen_ptr: HashBuiltin*,
    range_check_ptr
}(receiver: felt, amount: Uint256):
    let (caller) = get_caller_address()
    let (owner) = _owner.read()
    assert caller = owner
    let (previous_receiver_balance) = _balances.read(receiver)
    let (new_receiver_balance, _: Uint256) = uint256_add(previous_receiver_balance, amount)
    _balances.write(receiver, new_receiver_balance)
    return ()
end


# ERC20 Implementation Below
#############################################
#############################################
#############################################


#############################################
##                METADATA                 ##
#############################################

@storage_var
func _name() -> (name: felt):
end

@storage_var
func _symbol() -> (symbol: felt):
end

@storage_var
func _decimals() -> (decimals: felt):
end

#############################################
##               ERC20 STORE               ##
#############################################

@storage_var
func _total_supply() -> (total_supply: Uint256):
end

@storage_var
func _balances(owner: felt) -> (balance: Uint256):
end

@storage_var
func _allowances(owner: felt, spender: felt) -> (allowance: Uint256):
end

#############################################
##             EIP 2612 STORE              ##
#############################################

## TODO: EIP-2612

#     bytes32 public constant PERMIT_TYPEHASH =
#         keccak256("Permit(address owner,address spender,uint256 value,uint256 nonce,uint256 deadline)");
#     uint256 internal immutable INITIAL_CHAIN_ID;
#     bytes32 internal immutable INITIAL_DOMAIN_SEPARATOR;
#     mapping(address => uint256) public nonces;

#############################################
##               CONSTRUCTOR               ##
#############################################

# @constructor
# func constructor{
#     syscall_ptr: felt*,
#     pedersen_ptr: HashBuiltin*,
#     range_check_ptr
# }(
#     name: felt,
#     symbol: felt,
#     decimals: felt, # 18
#     total_supply: Uint256,
# ):
#     _name.write(name)
#     _symbol.write(symbol)
#     _decimals.write(decimals)
#     _total_supply.write(total_supply)
#     return ()
# end

#############################################
##               ERC20 LOGIC               ##
#############################################

@external
func approve{
    syscall_ptr: felt*,
    pedersen_ptr: HashBuiltin*,
    range_check_ptr
}(
    spender: felt,
    amount: Uint256
) -> (success: felt):
    ## Manually fetch the caller address ##
    let (caller) = get_caller_address()

    ## CHECKS ##
    assert_not_zero(caller)
    assert_not_zero(spender)
    uint256_check(amount)

    ## EFFECTS ##
    _allowances.write(caller, spender, amount)

    ## NO INTERACTIONS ##

    return (1) # Starknet's `true`
end

@external
func increase_allowance{
    syscall_ptr: felt*,
    pedersen_ptr: HashBuiltin*,
    range_check_ptr
}(
    spender: felt,
    amount: Uint256
) -> (success: felt):
    alloc_locals
    uint256_check(amount)
    let (local caller) = get_caller_address()
    let (local current_allowance: Uint256) = _allowances.read(caller, spender)

    ## Check allowance overflow ##
    let (local new_allowance: Uint256, is_overflow) = uint256_add(current_allowance, amount)
    assert (is_overflow) = 0

    assert_not_zero(caller)
    assert_not_zero(spender)
    uint256_check(amount)
    _allowances.write(caller, spender, amount)

    return (1) # Starknet's `true`
end

@external
func decrease_allowance{
    syscall_ptr: felt*,
    pedersen_ptr: HashBuiltin*,
    range_check_ptr
}(
    spender: felt,
    amount: Uint256
) -> (success: felt):
    alloc_locals
    uint256_check(amount)
    let (local caller) = get_caller_address()
    let (local current_allowance: Uint256) = _allowances.read(caller, spender)
    let (local new_allowance: Uint256) = uint256_sub(current_allowance, amount)

    ## Validate allowance decrease ##
    let (enough_allowance) = uint256_lt(new_allowance, current_allowance)
    assert_not_zero(enough_allowance)

    assert_not_zero(caller)
    assert_not_zero(spender)
    uint256_check(amount)
    _allowances.write(caller, spender, amount)

    return (1) # Starknet's `true`
end


@external
func transfer{
    syscall_ptr: felt*,
    pedersen_ptr: HashBuiltin*,
    range_check_ptr
}(
    recipient: felt,
    amount: Uint256
) -> (success: felt):
    let (sender) = get_caller_address()
    _transfer(sender, recipient, amount)

    return (1) # Starknet's `true`
end

@external
func transfer_from{
    syscall_ptr: felt*,
    pedersen_ptr: HashBuiltin*,
    range_check_ptr
}(
    sender: felt,
    recipient: felt,
    amount: Uint256
) -> (success: felt):
    alloc_locals
    let (local caller) = get_caller_address()
    let (local caller_allowance: Uint256) = _allowances.read(owner=sender, spender=caller)

    ## Validate allowance decrease ##
    let (enough_allowance) = uint256_le(amount, caller_allowance)
    assert_not_zero(enough_allowance)

    _transfer(sender, recipient, amount)

    # subtract allowance
    let (new_allowance: Uint256) = uint256_sub(caller_allowance, amount)
    _allowances.write(sender, caller, new_allowance)

    return (1) # Starknet's `true`
end

## INTERNAL TRANSFER LOGIC ##
func _transfer{
    syscall_ptr: felt*,
    pedersen_ptr: HashBuiltin*,
    range_check_ptr
}(
    sender: felt,
    recipient: felt,
    amount: Uint256
):
    alloc_locals

    ## CHECKS ##
    assert_not_zero(sender)
    assert_not_zero(recipient)
    uint256_check(amount)

    let (local sender_balance: Uint256) = _balances.read(owner=sender)
    let (enough_balance) = uint256_le(amount, sender_balance)
    assert_not_zero(enough_balance)

    ## EFFECTS ##
    ## Subtract from sender ##
    let (new_sender_balance: Uint256) = uint256_sub(sender_balance, amount)
    _balances.write(sender, new_sender_balance)

    ## Add to recipient ##
    let (recipient_balance: Uint256) = _balances.read(owner=recipient)
    let (new_recipient_balance, _: Uint256) = uint256_add(recipient_balance, amount)
    _balances.write(recipient, new_recipient_balance)

    ## NO INTERACTIONS ##

    return ()
end

#############################################
##                ACCESSORS                ##
#############################################

@view
func name{
    syscall_ptr: felt*,
    pedersen_ptr: HashBuiltin*,
    range_check_ptr
}() -> (name: felt):
    let (name) = _name.read()
    return (name)
end

@view
func symbol{
    syscall_ptr: felt*,
    pedersen_ptr: HashBuiltin*,
    range_check_ptr
}() -> (symbol: felt):
    let (symbol) = _symbol.read()
    return (symbol)
end

@view
func total_supply{
    syscall_ptr: felt*,
    pedersen_ptr: HashBuiltin*,
    range_check_ptr
}() -> (total_supply: Uint256):
    let (total_supply: Uint256) = _total_supply.read()
    return (total_supply)
end

@view
func decimals{
    syscall_ptr: felt*,
    pedersen_ptr: HashBuiltin*,
    range_check_ptr
}() -> (decimals: felt):
    let (decimals) = _decimals.read()
    return (decimals)
end

@view
func balance_of{
    syscall_ptr: felt*,
    pedersen_ptr: HashBuiltin*,
    range_check_ptr
}(owner: felt) -> (balance: Uint256):
    let (balance: Uint256) = _balances.read(owner)
    return (balance)
end

@view
func allowance{
    syscall_ptr: felt*,
    pedersen_ptr: HashBuiltin*,
    range_check_ptr
}(
    owner: felt,
    spender: felt
) -> (allowance: Uint256):
    let (allowance: Uint256) = _allowances.read(owner=owner, spender=spender)
    return (allowance)
end
