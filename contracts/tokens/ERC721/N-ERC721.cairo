%lang starknet
%builtins pedersen range_check ecdsa bitwise

from starkware.cairo.common.cairo_builtins import HashBuiltin, SignatureBuiltin, BitwiseBuiltin
from starkware.starknet.common.syscalls import get_caller_address
from starkware.cairo.common.math import assert_not_zero
from starkware.cairo.common.bitwise import bitwise_or

## @title N-ERC721
## @description A minimalistic implementation of ERC721 Token Standard using only felts.
## @description Adapted from Solmate: https://github.com/Rari-Capital/solmate/blob/main/src/tokens/ERC721.sol
## @authors velleity <github.com/a5f9t4> exp.table <github.com/exp-table>

#############################################
##                METADATA                 ##
#############################################

@storage_var
func _name() -> (name: felt):
end

@storage_var
func _symbol() -> (symbol: felt):
end

#############################################
##                 STORAGE                 ##
#############################################

@storage_var
func _total_supply() -> (total_supply: felt):
end

@storage_var
func _owners(token_id: felt) -> (owner: felt):
end

@storage_var
func _balances(owner: felt) -> (balance: felt):
end

@storage_var
func _token_approvals(token_id: felt) -> (res: felt):
end

@storage_var
func _is_approved_for_all(owner: felt, spender: felt) -> (approved: felt):
end

#############################################
##             EIP 2612 STORE              ##
#############################################

## TODO: EIP-2612

# bytes32 public constant PERMIT_TYPEHASH =
#     keccak256("Permit(address spender,uint256 token_id,uint256 nonce,uint256 deadline)");
# bytes32 public constant PERMIT_ALL_TYPEHASH =
#     keccak256("Permit(address owner,address spender,uint256 nonce,uint256 deadline)");
# uint256 internal immutable INITIAL_CHAIN_ID;
# bytes32 internal immutable INITIAL_DOMAIN_SEPARATOR;
# mapping(uint256 => uint256) public nonces;
# mapping(address => uint256) public noncesForAll;


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
    symbol: felt
):
    _name.write(name)
    _symbol.write(symbol)

    return()
end

#############################################
##              ERC721 LOGIC               ##
#############################################

@external
func approve{
    syscall_ptr: felt*,
    pedersen_ptr: HashBuiltin*,
    bitwise_ptr: BitwiseBuiltin*,
    range_check_ptr
}(
    spender: felt,
    token_id: felt
):
    let (caller) = get_caller_address()

    let (owner) = _owners.read(token_id)
    tempvar caller_is_owner = 0 #false by default
    if caller == owner:
        caller_is_owner = 1
    end
    let (approved) = _is_approved_for_all.read(owner, caller)
    let (can_approve) = bitwise_or(caller_is_owner, approved)
    assert can_approve = 1

    _token_approvals.write(token_id, spender)
    return ()
end

@external
func set_approval_for_all{
    syscall_ptr: felt*,
    pedersen_ptr: HashBuiltin*,
    range_check_ptr
}(
    operator: felt,
    approved: felt
):
    let (caller) = get_caller_address()
    _is_approved_for_all.write(caller, operator, approved)
    return ()
end

@external
func transfer{
    syscall_ptr: felt*,
    pedersen_ptr: HashBuiltin*,
    bitwise_ptr : BitwiseBuiltin*,
    range_check_ptr
}(
    recipient: felt,
    token_id: felt
):
    let (sender) = get_caller_address()
    let (owner) = _owners.read(token_id)
    assert sender = owner
    assert_not_zero(recipient)

    let (owner_balance) = _balances.read(sender)
    let (recipient_balance) = _balances.read(recipient)

    _balances.write(sender, owner_balance - 1)
    _balances.write(recipient, recipient_balance + 1)

    _owners.write(token_id, recipient)

    _token_approvals.write(token_id, 0)

    return ()
end

@external
func transfer_from{
    syscall_ptr: felt*,
    pedersen_ptr: HashBuiltin*,
    bitwise_ptr : BitwiseBuiltin*,
    range_check_ptr
}(
    sender: felt,
    recipient: felt,
    token_id: felt
):
    let (caller) = get_caller_address()
    let (owner) = _owners.read(token_id)

    assert sender = owner # wrong sender

    assert_not_zero(recipient)

    tempvar is_caller_owner = 0
    if owner == caller:
        is_caller_owner = 1
    end
    let (approved_spender) = _token_approvals.read(token_id)
    tempvar is_approved = 0
    if approved_spender == caller:
        is_approved = 1
    end
    let (is_approved_for_all) = _is_approved_for_all.read(owner, caller)
    let (can_transfer1) = bitwise_or(is_caller_owner, is_approved)
    let (can_transfer) = bitwise_or(can_transfer1, is_approved_for_all)
    assert can_transfer = 1

    let (owner_balance) = _balances.read(sender)
    let (recipient_balance) = _balances.read(recipient)

    _balances.write(sender, owner_balance - 1)
    _balances.write(recipient, recipient_balance + 1)

    _owners.write(token_id, recipient)

    _token_approvals.write(token_id, 0)

    return ()
end

#############################################
##             INTERNAL LOGIC              ##
#############################################

func _mint{
    syscall_ptr: felt*,
    pedersen_ptr: HashBuiltin*,
    range_check_ptr
}(
    recipient: felt,
    token_id: felt
):
    assert_not_zero(recipient) #invalid recipient
    let (token_owner) = _owners.read(token_id)
    assert token_owner = 0 #already minted

    let (current_balance) = _balances.read(recipient)
    _balances.write(recipient, current_balance + 1)

    let (current_supply) = _total_supply.read()
    _total_supply.write(current_supply + 1)

    _owners.write(token_id, recipient)

    return ()
end

func _burn{
    syscall_ptr: felt*,
    pedersen_ptr: HashBuiltin*,
    range_check_ptr
}(
    token_id: felt
):
    let (owner) = _owners.read(token_id)
    assert_not_zero(owner) #not minted

    let (current_owner_balance) = _balances.read(owner)
    _balances.write(owner, current_owner_balance - 1)

    let (current_supply) = _total_supply.read()
    _total_supply.write(current_supply - 1)

    _owners.write(token_id, 0)
    _token_approvals.write(token_id, 0)

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
}() -> (total_supply: felt):
    let (total_supply) = _total_supply.read()
    return (total_supply)
end

@view
func owner_of{
    syscall_ptr: felt*,
    pedersen_ptr: HashBuiltin*,
    range_check_ptr
}(token_id: felt) -> (owner: felt):
    let (owner) = _owners.read(token_id)
    return (owner)
end

@view
func balance_of{
    syscall_ptr: felt*,
    pedersen_ptr: HashBuiltin*,
    range_check_ptr
}(owner: felt) -> (balance: felt):
    let (balance: felt) = _balances.read(owner)
    return (balance)
end

@view
func get_approved{
    syscall_ptr: felt*,
    pedersen_ptr: HashBuiltin*,
    range_check_ptr
}(token_id: felt) -> (spender: felt):
    let (spender) = _token_approvals.read(token_id)
    return (spender)
end

@view
func is_approved_for_all{
    syscall_ptr: felt*,
    pedersen_ptr: HashBuiltin*,
    range_check_ptr
}(owner: felt, operator: felt) -> (approved: felt):
    let (approved) = _is_approved_for_all.read(owner, operator)
    return (approved)
end
