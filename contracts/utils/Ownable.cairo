%lang starknet
%builtins pedersen range_check

from starkware.cairo.common.cairo_builtins import HashBuiltin

## The contract owner ##
@storage_var
func owner() -> (owner_address : felt):
end

## Sets the contract owner as the `owner_address` parameter ##
@constructor
func constructor{
        syscall_ptr : felt*, pedersen_ptr : HashBuiltin*,
        range_check_ptr}(owner_address : felt):
    owner.write(value=owner_address)
    return ()
end