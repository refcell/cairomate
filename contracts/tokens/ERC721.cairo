%lang starknet
%builtins pedersen range_check ecdsa

from starkware.cairo.common.cairo_builtins import HashBuiltin, SignatureBuiltin
from starkware.starknet.common.syscalls import get_caller_address
from starkware.cairo.common.math import assert_nn_le

## @title ERC721
## @description A minimalistic implementation of ERC721 Token Standard.
## @description Adapted from OpenZeppelin's Cairo Contracts: https://github.com/OpenZeppelin/cairo-contracts
## @author Alucard <github.com/a5f9t4>

#############################################
##                METADATA                 ##
#############################################

@storage_var
func OWNER(token_id: felt) -> (res: felt):
end

@storage_var
func BALANCES(owner: felt) -> (res: felt):
end

@storage_var
func TOKEN_APPROVALS(token_id: felt) -> (res: felt):
end

@storage_var
func OPERATOR_APPROVALS(owner: felt, operator: felt) -> (res: felt):
end

@storage_var
func INITIALIZED() -> (res: felt):
end

#############################################
##               CONSTRUCTOR               ##
#############################################

@constsructor
func constructor{
    syscall_ptr: felt*,
    pedersen_ptr: HashBuiltin*,
    range_check_ptr
}(recipient: felt):
    let (recipient) = get_caller_address()
    _mint(recipient, 1000)
    return()
end

@external
func initialize{
    syscall_ptr: felt*,
    pedersen_ptr: HashBuiltin*,
    range_check_ptr
}():
    let (_initialized) = initialized.read()
    assert _initialized = 0
    initialized.write(1)
    return ()
end

#############################################
##                ACCESSORS                ##
#############################################

@view
func balance_of{
    syscall_ptr: felt*,
    pedersen_ptr: HashBuiltin*,
    range_check_ptr
}(owner: felt) -> (res: felt):
    let (res) = BALANCES.read(owner=owner)
    return (res)
end

@view
func owner_of{
    syscall_ptr: felt*,
    pedersen_ptr: HashBuiltin*,
    range_check_ptr
}(token_id: felt) -> (res: felt):
    let (res) = OWNER.read(token_id=token_id)
    return (res)
end

@view
func get_approved{
    syscall_ptr: felt*,
    pedersen_ptr: HashBuiltin*,
    range_check_ptr
}(
    token_id: felt
) -> (res: felt):
    let (res) = TOKEN_APPROVALS.read(token_id=token_id)
    return (res)
end

#############################################
##              ERC721 LOGIC               ##
#############################################

@external
func approve{
    syscall_ptr: felt*,
    pedersen_ptr: HashBuiltin*,
    range_check_ptr
}(
    to: felt,
    token_id: felt
):
    let (_owner) = OWNER.read(token_id)

    if _owner == to:
        assert 1 = 0
    end

    _is_approved_or_owner()
    TOKEN_APPROVALS.write(token_id=token_id, to)
    return ()
end

@external
func transfer{
    syscall_ptr: felt*,
    pedersen_ptr: HashBuiltin*,
    range_check_ptr
}(
    recipient: felt,
    amount: felt
):
    let (sender) = get_caller_address()
    _transfer(sender, recipient, amount)
    return ()
end

@external
func transfer_from{
    syscall_ptr: felt*,
    pedersen_ptr: HashBuiltin*,
    range_check_ptr
}(
    sender: felt,
    recipient: felt,
    amount: felt
):
    let (caller) = get_caller_address()
    let (caller_allowance) = ALLOWANCE.read(owner=sender, spender=caller)
    assert_nn_le(amount, caller_allowance)
    _transfer(sender, recipient, amount)
    ALLOWANCE.write(sender, caller, caller_allowance - amount)
    return ()
end

#############################################
##             INTERNAL LOGIC              ##
#############################################

func _is_approved_or_owner{
    syscall_ptr: felt*,
    pedersen_ptr: HashBuiltin*,
    range_check_ptr
}(
    to: felt,
    token_id: felt
):
    let (caller) = get_caller_address()
    let (_owner) = OWNER.read(token_id)

    if caller == _owner:
        return ()
    end

    let (res) = TOKEN_APPROVALS(token_id)
    assert res = caller
end

func _mint{
    syscall_ptr: felt*,
    pedersen_ptr: HashBuiltin*,
    range_check_ptr
}(
    recipient: felt,
    amount: felt
):
    let (res) = BALANCES.read(user=recipient)
    BALANCES.write(recipient, res + amount)

    let (supply) = TOTAL_SUPPLY.read()
    TOTAL_SUPPLY.write(supply + amount)
    return ()
end

func _transfer{
    syscall_ptr: felt*,
    pedersen_ptr: HashBuiltin*,
    range_check_ptr
}(
    sender: felt,
    recipient: felt,
    amount: felt
):
    let (sender_balance) = BALANCES.read(user=sender)
    assert_nn_le(amount, sender_balance)

    BALANCES.write(sender, sender_balance - amount)

    let (res) = BALANCES.read(user=recipient)
    BALANCES.write(recipient, res + amount)
    return ()
end
