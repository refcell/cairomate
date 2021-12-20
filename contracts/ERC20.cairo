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

## @title ERC20
## @description A minimalistic implementation of ERC20 Token Standard.
## @author Alucard <github.com/a5f9t4>

#############################################
##                METADATA                 ##
#############################################

@storage_var
func NAME() -> (NAME: felt):
end

@storage_var
func SYMBOL() -> (SYMBOL: felt):
end

@storage_var
func DECIMALS() -> (DECIMALS: felt):
end

#############################################
##               ERC20 STORE               ##
#############################################

@storage_var
func TOTAL_SUPPLY() -> (TOTAL_SUPPLY: felt):
end

@storage_var
func BALANCE_OF(address: felt) -> (BALANCE: felt):
end

@storage_var
func ALLOWANCE(owner: felt, spender: felt) -> (REMAINING: felt):
end

#############################################
##             EIP 2612 STORE              ##
#############################################

bytes32 public constant PERMIT_TYPEHASH =
        keccak256("Permit(address owner,address spender,uint256 value,uint256 nonce,uint256 deadline)");

    uint256 internal immutable INITIAL_CHAIN_ID;

    bytes32 internal immutable INITIAL_DOMAIN_SEPARATOR;

    mapping(address => uint256) public nonces;

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
    decimals: felt,
    totalSupply: felt,
):
    name.write(name);
    symbol.write(symbol);
    decimals.write(decimals);
    totalSupply.write(totalSupply);
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
    ALLOWANCE.write(caller, spender, amount)

    ## NO INTERACTIONS ##

    return (1) # Starknet's `true`
end

@external
func increaseAllowance{
    syscall_ptr: felt*,
    pedersen_ptr: HashBuiltin*,
    range_check_ptr
}(
    spender: felt,
    amount: Uint256
) -> (success: felt):
    alloc_locals
    uint256_check(added_value)
    let (local caller) = get_caller_address()
    let (local current_allowance: Uint256) = ALLOWANCE.read(caller, spender)

    ## Check allowance overflow ##
    let (local new_allowance: Uint256, is_overflow) = uint256_add(current_allowance, added_value)
    assert (is_overflow) = 0

    assert_not_zero(caller)
    assert_not_zero(spender)
    uint256_check(amount)
    ALLOWANCE.write(caller, spender, amount)

    return (1) # Starknet's `true`
end

@external
func decreaseAllowance{
    syscall_ptr: felt*,
    pedersen_ptr: HashBuiltin*,
    range_check_ptr
}(
    spender: felt,
    subtracted_value: Uint256
) -> (success: felt):
    alloc_locals
    uint256_check(subtracted_value)
    let (local caller) = get_caller_address()
    let (local current_allowance: Uint256) = ALLOWANCE.read(caller, spender)
    let (local new_allowance: Uint256) = uint256_sub(current_allowance, subtracted_value)

    ## Validate allowance decrease ##
    let (enough_allowance) = uint256_lt(new_allowance, current_allowance)
    assert_not_zero(enough_allowance)

    assert_not_zero(caller)
    assert_not_zero(spender)
    uint256_check(amount)
    ALLOWANCE.write(caller, spender, amount)

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
func transferFrom{
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
    let (local caller_allowance: Uint256) = ALLOWANCE.read(owner=sender, spender=caller)

    ## Validate allowance decrease ##
    let (enough_allowance) = uint256_le(amount, caller_allowance)
    assert_not_zero(enough_allowance)

    _transfer(sender, recipient, amount)

    # subtract allowance
    let (new_allowance: Uint256) = uint256_sub(caller_allowance, amount)
    ALLOWANCE.write(sender, caller, new_allowance)

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

    let (local sender_balance: Uint256) = BALANCE_OF.read(account=sender)
    let (enough_balance) = uint256_le(amount, sender_balance)
    assert_not_zero(enough_balance)

    ## EFFECTS ##
    ## Subtract from sender ##
    let (new_sender_balance: Uint256) = uint256_sub(sender_balance, amount)
    BALANCE_OF.write(sender, new_sender_balance)

    ## Add to recipient ##
    let (recipient_balance: Uint256) = BALANCE_OF.read(account=recipient)
    let (new_recipient_balance, _: Uint256) = uint256_add(recipient_balance, amount)
    BALANCE_OF.write(recipient, new_recipient_balance)

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
    let (NAME) = NAME.read()
    return (name=NAME)
end

@view
func symbol{
    syscall_ptr: felt*,
    pedersen_ptr: HashBuiltin*,
    range_check_ptr
}() -> (symbol: felt):
    let (SYMBOL) = SYMBOL.read()
    return (symbol=SYMBOL)
end

@view
func totalSupply{
    syscall_ptr: felt*,
    pedersen_ptr: HashBuiltin*,
    range_check_ptr
}() -> (totalSupply: Uint256):
    let (TOTAL_SUPPLY: Uint256) = TOTAL_SUPPLY.read()
    return (totalSupply=TOTAL_SUPPLY)
end

@view
func decimals{
    syscall_ptr: felt*,
    pedersen_ptr: HashBuiltin*,
    range_check_ptr
}() -> (decimals: felt):
    let (DECIMALS) = DECIMALS.read()
    return (decimals=DECIMALS)
end

@view
func balanceOf{
    syscall_ptr: felt*,
    pedersen_ptr: HashBuiltin*,
    range_check_ptr
}(account: felt) -> (balance: Uint256):
    let (BALANCE: Uint256) = BALANCE_OF.read(account=account)
    return (balance=BALANCE)
end

@view
func allowance{
    syscall_ptr: felt*,
    pedersen_ptr: HashBuiltin*,
    range_check_ptr
}(
    owner: felt,
    spender: felt
) -> (remaining: Uint256):
    let (REMAINING: Uint256) = ALLOWANCE.read(owner=owner, spender=spender)
    return (remaining=REMAINING)
end
