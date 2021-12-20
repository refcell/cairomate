%lang starknet
%builtins pedersen range_check

from starkware.cairo.common.cairo_builtins import HashBuiltin

## @title Ownable
## @description A mirror of the Openzeppelin Ownable pattern
## @description Adapted from OpenZeppelin's Cairo Contracts: https://github.com/OpenZeppelin/cairo-contracts
## @author Alucard <github.com/a5f9t4>

#############################################
##                STORAGE                  ##
#############################################

## The contract owner ##
@storage_var
func OWNER() -> (owner : felt):
end

#############################################
##              CONSTRUCTOR                ##
#############################################

## Sets the contract owner as the `owner` parameter ##
@constructor
func constructor{
    syscall_ptr: felt*,
    pedersen_ptr: HashBuiltin*,
    range_check_ptr
}(
    owner: felt
):
    OWNER.write(owner)
    return ()
end

#############################################
##              OWNABLE LOGIC              ##
#############################################

@external
func get_owner{
    syscall_ptr: felt*,
    pedersen_ptr: HashBuiltin*,
    range_check_ptr
}() -> (owner: felt):
    let (owner) = OWNER.read()
    return (owner=owner)
end

@external
func transfer_ownership{
    syscall_ptr: felt*,
    pedersen_ptr: HashBuiltin*,
    range_check_ptr
}(new_owner: felt) -> (new_owner: felt):
    OWNER.write(new_owner)
    return (new_owner=new_owner)
end