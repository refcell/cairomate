%lang starknet
%builtins pedersen range_check ecdsa bitwise

from starkware.cairo.common.cairo_builtins import HashBuiltin, SignatureBuiltin, BitwiseBuiltin
from starkware.starknet.common.syscalls import get_caller_address
from starkware.cairo.common.math import assert_not_zero
from starkware.cairo.common.bitwise import bitwise_or
from starkware.cairo.common.uint256 import Uint256, uint256_sub, uint256_add
from starkware.cairo.common.alloc import alloc

const ERC721_TOKEN_RECEIVER_SELECTOR = 0x150b7a02

@contract_interface
namespace ERC721_TOKEN_RECEIVER:
    func on_erc721_received(
        operator: felt,
        to: felt,
        token_id: Uint256,
        data_len: felt,
        data: felt*
    ) -> (selector: felt):
    end
end
## @title ERC721
## @description A minimalistic implementation of ERC721 Token Standard.
## @dev Uses the common uint256 type for compatibility with the base evm.
## @description Adapted from OpenZeppelin's Cairo Contracts: https://github.com/OpenZeppelin/cairo-contracts
## @author velleity <github.com/a5f9t4> exp.table <github.com/exp-table>

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
func _total_supply() -> (_total_supply: Uint256):
end

@storage_var
func _owners(token_id: Uint256) -> (owner: felt):
end

@storage_var
func _balances(owner: felt) -> (balance: Uint256):
end

@storage_var
func _token_approvals(token_id: Uint256) -> (approved: felt):
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
    token_id: Uint256
):
    let (caller) = get_caller_address()

    let (owner) = _owners.read(token_id)
    if caller == owner:
        tempvar caller_is_owner = 1
    else:
        tempvar caller_is_owner = 0
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
    token_id: Uint256
):
    let (sender) = get_caller_address()
    let (owner) = _owners.read(token_id)
    assert sender = owner
    assert_not_zero(recipient)

    let (owner_balance) = _balances.read(sender)
    let (new_owner_balance: Uint256) = uint256_sub(owner_balance, Uint256(1,0))

    let (recipient_balance) = _balances.read(recipient)
    let (new_recipient_balance, _: Uint256) = uint256_add(recipient_balance, Uint256(1,0))

    _balances.write(sender, new_owner_balance)
    _balances.write(recipient, new_recipient_balance)

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
    token_id: Uint256
):
    let (caller) = get_caller_address()
    let (owner) = _owners.read(token_id)

    assert sender = owner # wrong sender

    assert_not_zero(recipient)

    if caller == owner:
        tempvar caller_is_owner = 1
    else:
        tempvar caller_is_owner = 0
    end

    let (approved_spender) = _token_approvals.read(token_id)
    
    if approved_spender == caller:
        tempvar is_approved = 1
    else:
        tempvar is_approved = 0
    end

    let (is_approved_for_all) = _is_approved_for_all.read(owner, caller)
    let (can_transfer1) = bitwise_or(caller_is_owner, is_approved)
    let (can_transfer) = bitwise_or(can_transfer1, is_approved_for_all)
    assert can_transfer = 1

    let (owner_balance) = _balances.read(sender)
    let (new_owner_balance: Uint256) = uint256_sub(owner_balance, Uint256(1,0))

    let (recipient_balance) = _balances.read(recipient)
    let (new_recipient_balance, _: Uint256) = uint256_add(recipient_balance, Uint256(1,0))

    _balances.write(sender, new_owner_balance)
    _balances.write(recipient, new_recipient_balance)

    _owners.write(token_id, recipient)

    _token_approvals.write(token_id, 0)

    return ()
end

func safe_transfer_from{
    syscall_ptr: felt*,
    pedersen_ptr: HashBuiltin*,
    bitwise_ptr : BitwiseBuiltin*,
    range_check_ptr
}(
    sender: felt,
    recipient: felt,
    token_id: Uint256
):
    alloc_locals
    let (caller) = get_caller_address()
    transfer_from(sender, recipient, token_id)
    let (local empty_array: felt*) = alloc()
    let (selector) = ERC721_TOKEN_RECEIVER.on_erc721_received(
        contract_address=recipient,
        operator=caller,
        to=sender,
        token_id=token_id,
        data_len=0,
        data=empty_array)
    assert selector = ERC721_TOKEN_RECEIVER_SELECTOR
    return ()
end

# WARNING! Breaks with EIP-721 because OVERLOADING is NOT supported in starknet!
func safe_transfer_from_with_data{
    syscall_ptr: felt*,
    pedersen_ptr: HashBuiltin*,
    bitwise_ptr : BitwiseBuiltin*,
    range_check_ptr
}(
    sender: felt,
    recipient: felt,
    token_id: Uint256,
    data_len: felt,
    data: felt*
):
    alloc_locals
    let (caller) = get_caller_address()
    transfer_from(sender, recipient, token_id)
    let (selector) = ERC721_TOKEN_RECEIVER.on_erc721_received(
        contract_address=recipient,
        operator=caller,
        to=sender,
        token_id=token_id,
        data_len=data_len,
        data=data)
    assert selector = ERC721_TOKEN_RECEIVER_SELECTOR
    return ()
end

@external
func mint{
    syscall_ptr: felt*,
    pedersen_ptr: HashBuiltin*,
    bitwise_ptr : BitwiseBuiltin*,
    range_check_ptr
}(
    recipient: felt,
    token_id: Uint256
):
    _mint(recipient, token_id)
    return ()
end

@external
func safe_mint{
    syscall_ptr: felt*,
    pedersen_ptr: HashBuiltin*,
    bitwise_ptr : BitwiseBuiltin*,
    range_check_ptr
}(
    recipient: felt,
    token_id: Uint256
):
    _safe_mint(recipient, token_id)
    return ()
end

@external
func safe_mint_with_data{
    syscall_ptr: felt*,
    pedersen_ptr: HashBuiltin*,
    bitwise_ptr : BitwiseBuiltin*,
    range_check_ptr
}(
    recipient: felt,
    token_id: Uint256,
    data_len: felt,
    data: felt*
):
    _safe_mint_with_data(recipient, token_id, data_len, data)
    return ()
end

@external
func burn{
    syscall_ptr: felt*,
    pedersen_ptr: HashBuiltin*,
    bitwise_ptr : BitwiseBuiltin*,
    range_check_ptr
}(
    token_id: Uint256
):
    _burn(token_id)
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
    token_id: Uint256
):
    assert_not_zero(recipient) #invalid recipient
    let (token_owner) = _owners.read(token_id)
    assert token_owner = 0 #already minted

    let (current_balance) = _balances.read(owner=recipient)
    let (new_balance, _: Uint256) = uint256_add(current_balance, Uint256(1,0))
    _balances.write(recipient, new_balance)

    let (current_supply) = _total_supply.read()
    let (new_supply, _: Uint256) = uint256_add(current_supply, Uint256(1,0))
    _total_supply.write(new_supply)

    _owners.write(token_id, recipient)

    return ()
end

func _safe_mint{
    syscall_ptr: felt*,
    pedersen_ptr: HashBuiltin*,
    bitwise_ptr : BitwiseBuiltin*,
    range_check_ptr
}(
    recipient: felt,
    token_id: Uint256
):
    alloc_locals
    let (caller) = get_caller_address()
    _mint(recipient, token_id)
    let (local empty_array: felt*) = alloc()
    let (selector) = ERC721_TOKEN_RECEIVER.on_erc721_received(
        contract_address=recipient,
        operator=caller,
        to=0,
        token_id=token_id,
        data_len=0,
        data=empty_array)
    assert selector = ERC721_TOKEN_RECEIVER_SELECTOR
    return ()
end

func _safe_mint_with_data{
    syscall_ptr: felt*,
    pedersen_ptr: HashBuiltin*,
    bitwise_ptr : BitwiseBuiltin*,
    range_check_ptr
}(
    recipient: felt,
    token_id: Uint256,
    data_len: felt,
    data: felt*
):
    alloc_locals
    let (caller) = get_caller_address()
    _mint(recipient, token_id)
    let (local empty_array: felt*) = alloc()
    let (selector) = ERC721_TOKEN_RECEIVER.on_erc721_received(
        contract_address=recipient,
        operator=caller,
        to=0,
        token_id=token_id,
        data_len=data_len,
        data=data)
    assert selector = ERC721_TOKEN_RECEIVER_SELECTOR
    return ()
end

func _burn{
    syscall_ptr: felt*,
    pedersen_ptr: HashBuiltin*,
    range_check_ptr
}(
    token_id: Uint256
):
    let (owner) = _owners.read(token_id)
    assert_not_zero(owner) #not minted

    let (current_balance) = _balances.read(owner)
    let (new_balance: Uint256) = uint256_sub(current_balance, Uint256(1,0))
    _balances.write(owner, new_balance)

    let (current_supply) = _total_supply.read()
    let (new_supply: Uint256) = uint256_sub(current_supply, Uint256(1,0))
    _total_supply.write(new_supply)

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
}() -> (total_supply: Uint256):
    let (total_supply: Uint256) = _total_supply.read()
    return (total_supply)
end

@view
func owner_of{
    syscall_ptr: felt*,
    pedersen_ptr: HashBuiltin*,
    range_check_ptr
}(token_id: Uint256) -> (owner: felt):
    let (owner) = _owners.read(token_id)
    return (owner)
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
func get_approved{
    syscall_ptr: felt*,
    pedersen_ptr: HashBuiltin*,
    range_check_ptr
}(token_id: Uint256) -> (spender: felt):
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