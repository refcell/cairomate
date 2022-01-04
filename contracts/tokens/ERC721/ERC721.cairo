%lang starknet
%builtins pedersen range_check ecdsa bitwise

from starkware.cairo.common.cairo_builtins import HashBuiltin, SignatureBuiltin, BitwiseBuiltin
from starkware.starknet.common.syscalls import get_caller_address
from starkware.cairo.common.math import assert_not_zero
from starkware.cairo.common.bitwise import bitwise_or
from starkware.cairo.common.uint256 import Uint256, uint256_sub, uint256_add

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
func _totalSupply() -> (totalSupply: Uint256):
end

@storage_var
func _owners(tokenId: Uint256) -> (owner: felt):
end

@storage_var
func _balances(owner: felt) -> (balance: Uint256):
end

@storage_var
func _tokenApprovals(tokenId: Uint256) -> (approved: felt):
end

@storage_var
func _isApprovedForAll(owner: felt, spender: felt) -> (approved: felt):
end

#############################################
##             EIP 2612 STORE              ##
#############################################

## TODO: EIP-2612

# bytes32 public constant PERMIT_TYPEHASH =
#     keccak256("Permit(address spender,uint256 tokenId,uint256 nonce,uint256 deadline)");
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
    tokenId: Uint256
):
    let (caller) = get_caller_address()

    let (owner) = _owners.read(tokenId)
    tempvar callerIsOwner = 0 #false by default
    if caller == owner:
        callerIsOwner = 1
    end
    let (approved) = _isApprovedForAll.read(owner, caller)
    let (canApprove) = bitwise_or(callerIsOwner, approved)
    assert canApprove = 1

    _tokenApprovals.write(tokenId, spender)
    return ()
end

@external
func setApprovalForAll{
    syscall_ptr: felt*,
    pedersen_ptr: HashBuiltin*,
    range_check_ptr
}(
    operator: felt,
    approved: felt
):
    let (caller) = get_caller_address()
    _isApprovedForAll.write(caller, operator, approved)
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
    tokenId: Uint256
):
    let (sender) = get_caller_address()
    let (owner) = _owners.read(tokenId)
    assert sender = owner
    assert_not_zero(recipient)

    let (ownerBalance) = _balances.read(sender)
    let (newOwnerBalance: Uint256) = uint256_sub(ownerBalance, Uint256(0,1))

    let (recipientBalance) = _balances.read(recipient)
    let (newRecipientBalance, _: Uint256) = uint256_add(recipientBalance, Uint256(0,1))

    _balances.write(sender, newOwnerBalance)
    _balances.write(recipient, newRecipientBalance)

    _owners.write(tokenId, recipient)

    _tokenApprovals.write(tokenId, 0)

    return ()
end

@external
func transferFrom{
    syscall_ptr: felt*,
    pedersen_ptr: HashBuiltin*,
    bitwise_ptr : BitwiseBuiltin*,
    range_check_ptr
}(
    sender: felt,
    recipient: felt,
    tokenId: Uint256
):
    let (caller) = get_caller_address()
    let (owner) = _owners.read(tokenId)

    assert sender = owner # wrong sender

    assert_not_zero(recipient)

    tempvar isCallerOwner = 0
    if owner == caller:
        isCallerOwner = 1
    end
    let (approvedSpender) = _tokenApprovals.read(tokenId)
    tempvar isApproved = 0
    if approvedSpender == caller:
        isApproved = 1
    end
    let (isApprovedForAll) = _isApprovedForAll.read(owner, caller)
    let (canTransfer1) = bitwise_or(isCallerOwner, isApproved)
    let (canTransfer) = bitwise_or(canTransfer1, isApprovedForAll)
    assert canTransfer = 1

    let (ownerBalance) = _balances.read(sender)
    let (newOwnerBalance: Uint256) = uint256_sub(ownerBalance, Uint256(0,1))

    let (recipientBalance) = _balances.read(recipient)
    let (newRecipientBalance, _: Uint256) = uint256_add(recipientBalance, Uint256(0,1))

    _balances.write(sender, newOwnerBalance)
    _balances.write(recipient, newRecipientBalance)

    _owners.write(tokenId, recipient)

    _tokenApprovals.write(tokenId, 0)

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
    tokenId: Uint256
):
    assert_not_zero(recipient) #invalid recipient
    let (tokenOwner) = _owners.read(tokenId)
    assert tokenOwner = 0 #already minted

    let (currentBalance) = _balances.read(owner=recipient)
    let (newBalance, _: Uint256) = uint256_add(currentBalance, Uint256(0,1))
    _balances.write(recipient, newBalance)

    let (currentSupply) = _totalSupply.read()
    let (newSupply, _: Uint256) = uint256_add(currentSupply, Uint256(0,1))
    _totalSupply.write(newSupply)

    _owners.write(tokenId, recipient)

    return ()
end

func _burn{
    syscall_ptr: felt*,
    pedersen_ptr: HashBuiltin*,
    range_check_ptr
}(
    tokenId: Uint256
):
    let (owner) = _owners.read(tokenId)
    assert_not_zero(owner) #not minted

    let (currentBalance) = _balances.read(owner)
    let (newBalance: Uint256) = uint256_sub(currentBalance, Uint256(0,1))
    _balances.write(owner, newBalance)

    let (currentSupply) = _totalSupply.read()
    let (newSupply: Uint256) = uint256_sub(currentSupply, Uint256(0,1))
    _totalSupply.write(newSupply)

    _owners.write(tokenId, 0)
    _tokenApprovals.write(tokenId, 0)

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
func totalSupply{
    syscall_ptr: felt*,
    pedersen_ptr: HashBuiltin*,
    range_check_ptr
}() -> (totalSupply: Uint256):
    let (totalSupply: Uint256) = _totalSupply.read()
    return (totalSupply)
end

@view
func ownerOf{
    syscall_ptr: felt*,
    pedersen_ptr: HashBuiltin*,
    range_check_ptr
}(tokenId: Uint256) -> (owner: felt):
    let (owner) = _owners.read(tokenId)
    return (owner)
end


@view
func balanceOf{
    syscall_ptr: felt*,
    pedersen_ptr: HashBuiltin*,
    range_check_ptr
}(owner: felt) -> (balance: Uint256):
    let (balance: Uint256) = _balances.read(owner)
    return (balance)
end

@view
func getApproved{
    syscall_ptr: felt*,
    pedersen_ptr: HashBuiltin*,
    range_check_ptr
}(tokenId: Uint256) -> (spender: felt):
    let (spender) = _tokenApprovals.read(tokenId)
    return (spender)
end

@view
func isApprovedForAll{
    syscall_ptr: felt*,
    pedersen_ptr: HashBuiltin*,
    range_check_ptr
}(owner: felt, operator: felt) -> (approved: felt):
    let (approved) = _isApprovedForAll.read(owner, operator)
    return (approved)
end