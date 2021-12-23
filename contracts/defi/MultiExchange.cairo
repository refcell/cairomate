%lang starknet
%builtins pedersen range_check

from starkware.starknet.common.syscalls import get_caller_address, get_contract_address
from starkware.cairo.common.cairo_builtins import HashBuiltin
from starkware.cairo.common.hash import hash2
from starkware.cairo.common.math import assert_le, assert_nn_le, unsigned_div_rem, assert_not_zero
from starkware.starknet.common.syscalls import storage_read, storage_write
from starkware.cairo.common.uint256 import (
    Uint256, uint256_add, uint256_sub, uint256_le, uint256_lt, uint256_check, uint256_signed_nn_le, uint256_mul
)

## Local Imports ##
from contracts.interfaces.IERC20 import IERC20


## @title MultiExchange
## @description A permissionless, multi-token exchange implemented using erc1155.
## @description Adapted from https://github.com/z0r0z/Helios
## @author Alucard <github.com/a5f9t4>

#############################################
##                 STORAGE                 ##
#############################################

struct Pair:
    member token0: felt
    member token1: felt
    member swapStrategy: felt
    member fee: felt # Uint256 ?
end

@storage_var
func PAIRS(id: felt) -> (pair: Pair):
end

# Equivalent to totalSupply
@storage_var
func PAIR_COUNT() -> (count: felt):
end

@storage_var
func INITIALIZED() -> (res: felt):
end

@storage_var
func ERC1155() -> (address: felt):
end

#############################################
##               CONSTRUCTOR               ##
#############################################

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

@constructor
func constructor{
    syscall_ptr: felt*,
    pedersen_ptr: HashBuiltin*,
    range_check_ptr
}(
    erc1155: felt, # address of the deployed ERC1155 contract
    initialize: felt
):
    ERC1155.write(erc1155)
    INITIALIZED.write(initialize)
    return ()
end

#############################################
##               CORE LOGIC                ##
#############################################

@external
func createPair{
    syscall_ptr: felt*,
    pedersen_ptr: HashBuiltin*,
    range_check_ptr
}(
    _to: felt,
    _tokenA: felt,
    _tokenB: felt,
    _tokenA_amount: felt,
    _tokenB_amount: felt,
    _swap_strategy: felt,
    _fee: felt,
    _data: felt # bytes calldata data
) -> (
    id: felt, # Uint256 ?
    lp: felt # Uint256 ?
):
    alloc_locals
    # Prevent Identical Tokens
    if _tokenA == _tokenB:
        # revert
        assert 0 = 1
    end

    # Prevent Zero Swap Strategy
    assert_not_zero(_swap_strategy)

    # Swap Tokens and Amounts to prevent permutations of tokens
    # if _tokenA > _tokenB:

    # end


    # // sort tokens
    # (address token0, address token1) = tokenA < tokenB ? (tokenA, tokenB) : (tokenB, tokenA);

    # totalSupply++;
    # id = totalSupply;
    let (local pairCount) = PAIR_COUNT.read()
    local newPairCount = pairCount + 1
    PAIR_COUNT.write(newPairCount)

    # if (pairSettings[token0][token1][swapStrategy][fee] != 0) revert PairExists();

    # pairSettings[token0][token1][swapStrategy][fee] = id;

    # pairs[id] = Pair({
    #     token0: token0,
    #     token1: token1,
    #     swapStrategy: swapStrategy,
    #     fee: fee
    # });

    # // if base is address(0), assume ETH and overwrite amount
    # if (token0 == address(0)) token0amount = msg.value;

    # // strategy dictates output LP
    # lp = ISwap(swapStrategy).addLiquidity(token0amount, token1amount);
    local lp = 0

    # _mint(
    #     to,
    #     id,
    #     lp,
    #     data
    # );

    return (
        id=newPairCount,
        lp=lp
    )
end
