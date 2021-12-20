%lang starknet
%builtins pedersen range_check ecdsa

from starkware.cairo.common.cairo_builtins import HashBuiltin, SignatureBuiltin
from starkware.starknet.common.syscalls import get_caller_address
from starkware.cairo.common.math import assert_nn_le, assert_not_zero
from starkware.cairo.common.uint256 import Uint256, uint256_le, uint256_sub, uint256_add

## @title ERC721
## @description A minimalistic implementation of ERC721 Token Standard.
## @description Adapted from OpenZeppelin's Cairo Contracts: https://github.com/OpenZeppelin/cairo-contracts
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
func BASE_URI() -> (BASE_URI: felt):
end

#############################################
##                 STORAGE                 ##
#############################################

@storage_var
func TOTAL_SUPPLY() -> (TOTAL_SUPPLY: Uint256):
end

@storage_var
func OWNER(token_id: felt) -> (res: felt):
end

@storage_var
func BALANCES(owner: felt) -> (res: Uint256):
end

@storage_var
func TOKEN_APPROVALS(token_id: felt) -> (res: felt):
end

@storage_var
func ALLOWANCE(owner: felt, spender: felt) -> (REMAINING: Uint256):
end

@storage_var
func INITIALIZED() -> (res: felt):
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
    symbol: felt,
    base_uri: felt,
    totalSupply: Uint256
):
    NAME.write(name)
    SYMBOL.write(symbol)
    BASE_URI.write(base_uri)
    TOTAL_SUPPLY.write(totalSupply)

    ## Mint the total supply of tokens to the creator ##
    let (caller) = get_caller_address()
    _mint(caller, totalSupply)

    return()
end

@external
func initialize{
    syscall_ptr: felt*,
    pedersen_ptr: HashBuiltin*,
    range_check_ptr
}():
    let (_initialized) = INITIALIZED.read()
    assert _initialized = 0
    INITIALIZED.write(1)
    return ()
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
    alloc_locals
    let (_owner) = OWNER.read(token_id)
    let (local res) = TOKEN_APPROVALS.read(token_id)
    let (caller) = get_caller_address()

    if caller == _owner:
        return ()
    end

    if _owner == to:
        assert 1 = 0
    end

    assert res = caller

    TOKEN_APPROVALS.write(token_id, to)
    return ()
end

@external
func transfer{
    syscall_ptr: felt*,
    pedersen_ptr: HashBuiltin*,
    range_check_ptr
}(
    recipient: felt,
    amount: Uint256
):
    let (sender) = get_caller_address()
    _transfer(sender, recipient, amount)
    return ()
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
):
    alloc_locals
    let (local caller) = get_caller_address()
    let (local caller_allowance) = ALLOWANCE.read(owner=sender, spender=caller)

    let (enough_allowance) = uint256_le(amount, caller_allowance)
    assert_not_zero(enough_allowance)

    _transfer(sender, recipient, amount)

    # subtract allowance
    let (new_allowance: Uint256) = uint256_sub(caller_allowance, amount)
    ALLOWANCE.write(sender, caller, new_allowance)
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
    alloc_locals
    let (local res) = TOKEN_APPROVALS.read(token_id)
    let (caller) = get_caller_address()
    let (_owner) = OWNER.read(token_id)

    if caller == _owner:
        return ()
    end

    assert res = caller
    return ()
end

func _mint{
    syscall_ptr: felt*,
    pedersen_ptr: HashBuiltin*,
    range_check_ptr
}(
    recipient: felt,
    amount: Uint256
):
    let (res) = BALANCES.read(owner=recipient)
    let (new_balance, _: Uint256) = uint256_add(res, amount)
    BALANCES.write(recipient, new_balance)

    let (supply) = TOTAL_SUPPLY.read()
    let (new_supply, _: Uint256) = uint256_add(supply, amount)
    TOTAL_SUPPLY.write(new_supply)
    return ()
end

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
    let (local sender_balance) = BALANCES.read(owner=sender)

    let (enough_balance) = uint256_le(amount, sender_balance)
    assert_not_zero(enough_balance)

    let (new_sender_balance: Uint256) = uint256_sub(sender_balance, amount)
    BALANCES.write(sender, new_sender_balance)

    ## Add to recipient ##
    let (recipient_balance: Uint256) = BALANCES.read(recipient)
    let (new_recipient_balance, _: Uint256) = uint256_add(recipient_balance, amount)
    BALANCES.write(recipient, new_recipient_balance)

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
    let (_name) = NAME.read()
    return (name=_name)
end

@view
func symbol{
    syscall_ptr: felt*,
    pedersen_ptr: HashBuiltin*,
    range_check_ptr
}() -> (symbol: felt):
    let (_symbol) = SYMBOL.read()
    return (symbol=_symbol)
end

@view
func totalSupply{
    syscall_ptr: felt*,
    pedersen_ptr: HashBuiltin*,
    range_check_ptr
}() -> (totalSupply: Uint256):
    let (_total_supply: Uint256) = TOTAL_SUPPLY.read()
    return (totalSupply=_total_supply)
end

@view
func ownerOf{
    syscall_ptr: felt*,
    pedersen_ptr: HashBuiltin*,
    range_check_ptr
}(token_id: felt) -> (res: felt):
    let (res) = OWNER.read(token_id=token_id)
    return (res)
end


@view
func balanceOf{
    syscall_ptr: felt*,
    pedersen_ptr: HashBuiltin*,
    range_check_ptr
}(account: felt) -> (balance: Uint256):
    let (_balance: Uint256) = BALANCES.read(owner=account)
    return (balance=_balance)
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

@view
func getApproved{
    syscall_ptr: felt*,
    pedersen_ptr: HashBuiltin*,
    range_check_ptr
}(
    token_id: felt
) -> (res: felt):
    let (res) = TOKEN_APPROVALS.read(token_id=token_id)
    return (res)
end
