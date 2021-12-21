
%lang starknet
%builtins pedersen range_check

from starkware.cairo.common.cairo_builtins import HashBuiltin
from starkware.starknet.common.syscalls import get_caller_address

## @title Pausable
## @description A mirror of the Openzeppelin Pausable pattern
## @description Adapted from OpenZeppelin's Cairo Contracts: https://github.com/OpenZeppelin/cairo-contracts
## @author Alucard <github.com/a5f9t4>

#############################################
##                STORAGE                  ##
#############################################

@storage_var
func PAUSED() -> (paused: felt):
end

#############################################
##              CONSTRUCTOR                ##
#############################################

## Initializes paused as false or `0` ##
@constructor
func constructor{
    syscall_ptr: felt*,
    pedersen_ptr: HashBuiltin*,
    range_check_ptr
}():
    PAUSED.write(0)
    return ()
end

#############################################
##                MODIFIERS                ##
#############################################

func onlyNotPaused{
    syscall_ptr: felt*,
    pedersen_ptr: HashBuiltin*,
    range_check_ptr
}():
    let (is_paused) = PAUSED.read()
    assert is_paused = 0
    return ()
end

func onlyPaused{
    syscall_ptr: felt*,
    pedersen_ptr: HashBuiltin*,
    range_check_ptr
}():
    let (is_paused) = PAUSED.read()
    assert is_paused = 1
    return ()
end

#############################################
##             PAUSABLE LOGIC              ##
#############################################

@view
func paused{
    syscall_ptr: felt*,
    pedersen_ptr: HashBuiltin*,
    range_check_ptr
}() -> (paused: felt):
    let (paused) = PAUSED.read()
    return (paused)
end

@external
func pause{
    syscall_ptr: felt*,
    pedersen_ptr: HashBuiltin*,
    range_check_ptr
}():
    onlyNotPaused() # In place of Solidity's MODIFIERS
    PAUSED.write(1)
    return ()
end

@external
func unpause{
    syscall_ptr: felt*,
    pedersen_ptr: HashBuiltin*,
    range_check_ptr
}():
    onlyPaused() # In place of Solidity's MODIFIERS
    PAUSED.write(0)
    return ()
end