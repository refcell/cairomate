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