%lang starknet

from starkware.starknet.common.syscalls import get_caller_address
from starkware.cairo.common.cairo_builtins import HashBuiltin
from starkware.cairo.common.hash import hash2
from starkware.cairo.common.math import assert_le, assert_nn_le, unsigned_div_rem, assert_not_zero
from starkware.starknet.common.syscalls import storage_read, storage_write
from starkware.cairo.common.uint256 import (
    Uint256, uint256_add, uint256_sub, uint256_le, uint256_lt, uint256_check
)

## @title ERC20
## @description A minimalistic implementation of ERC20 Token Standard.
## @description Adapted from OpenZeppelin's Cairo Contracts: https://github.com/OpenZeppelin/cairo-contracts
## @author andreas <andreas@nascent.xyz>

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
##                 EVENTS                  ##
#############################################

@event
func transfer(sender: felt, recipient: felt, amount: uint256):
end

@event
func approval(owner: felt, spender: felt, amount: uint256):
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
    total_supply: Uint256,
):
    _name.write(name)
    _symbol.write(symbol)
    _decimals.write(decimals)
    _total_supply.write(total_supply)
    return ()
end

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

    ## Emit the approval event ##
    approval.emit(owner=caller, spender=spender, amount=amount)

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
    uint256_check(new_allowance)
    _allowances.write(caller, spender, new_allowance)

    ## Emit the approval event ##
    approval.emit(owner=caller, spender=spender, amount=amount)

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
    uint256_check(new_allowance)
    _allowances.write(caller, spender, new_allowance)

    ## Emit the approval event ##
    approval.emit(owner=caller, spender=spender, amount=amount)

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

    ## Emit the transfer event ##
    transfer.emit(sender=sender, recipient=recipient, amount=amount)

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

    ## Emit the transfer event ##
    transfer.emit(sender=sender, recipient=recipient, amount=amount)

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
