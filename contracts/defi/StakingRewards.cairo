%lang starknet

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


## @title Staking Rewards
## @description A stripped down implementation of Synthetix StakingRewards.sol
## @description Adapted from https://solidity-by-example.org/defi/staking-rewards/
## @author andreas <andreas@nascent.xyz>

#############################################
##                 STORAGE                 ##
#############################################

@storage_var
func STAKING_TOKEN() -> (token: felt):
end

@storage_var
func REWARD_TOKEN() -> (token: felt):
end

@storage_var
func REWARD_RATE() -> (rate: Uint256):
end

@storage_var
func LAST_UPDATE_TIME() -> (time: Uint256):
end

@storage_var
func REWARD_PER_TOKEN_STORED() -> (reward: Uint256):
end

@storage_var
func USER_REWARD_PER_TOKEN_PAID(user: felt) -> (reward: Uint256):
end

@storage_var
func REWARDS(user: felt) -> (reward: Uint256):
end

@storage_var
func TOTAL_SUPPLY() -> (total_supply: Uint256):
end

@storage_var
func BALANCES(user: felt) -> (balance: Uint256):
end

#############################################
##               CONSTRUCTOR               ##
#############################################

@constructor
func constructor{
    syscall_ptr: felt*,
    pedersen_ptr: HashBuiltin*,
    range_check_ptr
}(
    staking_token: felt,
    reward_token: felt
):
    STAKING_TOKEN.write(staking_token)
    REWARD_TOKEN.write(reward_token)
    return ()
end

#############################################
##                ACCESSORS                ##
#############################################

@view
func rewardToken{
    syscall_ptr: felt*,
    pedersen_ptr: HashBuiltin*,
    range_check_ptr
}() -> (token: felt):
    let (_token) = REWARD_TOKEN.read()
    return (token=_token)
end

@view
func stakingToken{
    syscall_ptr: felt*,
    pedersen_ptr: HashBuiltin*,
    range_check_ptr
}() -> (token: felt):
    let (_token) = STAKING_TOKEN.read()
    return (token=_token)
end

@view
func rewardRate{
    syscall_ptr: felt*,
    pedersen_ptr: HashBuiltin*,
    range_check_ptr
}() -> (rate: Uint256):
    let (_rate) = REWARD_RATE.read()
    return (rate=_rate)
end

@view
func lastUpdateTime{
    syscall_ptr: felt*,
    pedersen_ptr: HashBuiltin*,
    range_check_ptr
}() -> (time: Uint256):
    let (_time) = LAST_UPDATE_TIME.read()
    return (time=_time)
end

@view
func rewardPerTokenStored{
    syscall_ptr: felt*,
    pedersen_ptr: HashBuiltin*,
    range_check_ptr
}() -> (reward: Uint256):
    let (_reward) = REWARD_PER_TOKEN_STORED.read()
    return (reward=_reward)
end

@view
func userRewardPerTokenPaid{
    syscall_ptr: felt*,
    pedersen_ptr: HashBuiltin*,
    range_check_ptr
}(
    user: felt
) -> (reward: Uint256):
    let (_reward) = USER_REWARD_PER_TOKEN_PAID.read(user)
    return (reward=_reward)
end

@view
func rewards{
    syscall_ptr: felt*,
    pedersen_ptr: HashBuiltin*,
    range_check_ptr
}(
    user: felt
) -> (reward: Uint256):
    let (_reward) = REWARDS.read(user)
    return (reward=_reward)
end

## MAIN VIEW FUNCTIONS ##

@view
func rewardPerToken{
    syscall_ptr: felt*,
    pedersen_ptr: HashBuiltin*,
    range_check_ptr
}() -> (reward: Uint256):
    alloc_locals
    let (local _total_supply) = TOTAL_SUPPLY.read()
    let (is_zero) = uint256_signed_nn_le(_total_supply, Uint256(0, 0))
    if is_zero == 1:
        return (reward=Uint256(0, 0))
    end

    let (_reward) = rewardPerTokenStored()
    # TODO: get current block timestamp

    # formula:
    # rewardPerTokenStored + (((block.timestamp - lastUpdateTime) * rewardRate * 1e18) / _totalSupply);
    return (reward=_reward)
end

@view
func earned{
    syscall_ptr: felt*,
    pedersen_ptr: HashBuiltin*,
    range_check_ptr
}(
    user: felt
) -> (amoun: Uint256):
    alloc_locals
    let (local balance) = BALANCES.read(user)
    let (local user_reward) = USER_REWARD_PER_TOKEN_PAID.read(user)
    let (local accumulated_rewards) = REWARDS.read(user)
    let (reward_per_token) = rewardPerToken()

    # Original formula:
    # (
    #   (_balances[account] * (rewardPerToken() - userRewardPerTokenPaid[account]))
    #   / 1e18
    # ) + rewards[account]

    let (local rel_reward: Uint256) = uint256_sub(reward_per_token, user_reward)
    let (local rel_balance: Uint256, _: Uint256) = uint256_mul(balance, rel_reward)
    let (local amount: Uint256, _: Uint256) = uint256_add(rel_balance, accumulated_rewards)
    return (amount)
end

#############################################
##                MUTATORS                 ##
#############################################

@view
func setRewardToken{
    syscall_ptr: felt*,
    pedersen_ptr: HashBuiltin*,
    range_check_ptr
}(
    reward_token: felt
):
    REWARD_TOKEN.write(reward_token)
    return ()
end

@view
func setStakingToken{
    syscall_ptr: felt*,
    pedersen_ptr: HashBuiltin*,
    range_check_ptr
}(
    staking_token: felt
):
    STAKING_TOKEN.write(staking_token)
    return ()
end

@view
func setRewardRate{
    syscall_ptr: felt*,
    pedersen_ptr: HashBuiltin*,
    range_check_ptr
}(
    rate: Uint256
):
    REWARD_RATE.write(rate)
    return ()
end

#############################################
##              STAKING LOGIC              ##
#############################################

## Called at the beginning of all staking functions ##
## In place of Solidity's native modifiers ##
func updateReward{
    syscall_ptr: felt*,
    pedersen_ptr: HashBuiltin*,
    range_check_ptr
}(
    address: felt
):
    alloc_locals
    let (local _reward_per_token_stored) = rewardPerToken()
    let _last_update_time = 0 # TODO: how to get `block.timestamp`?

    let (_earned) = earned(address)
    REWARDS.write(address, _earned)
    USER_REWARD_PER_TOKEN_PAID.write(address, _reward_per_token_stored)

    return ()
end

@external
func stake{
    syscall_ptr: felt*,
    pedersen_ptr: HashBuiltin*,
    range_check_ptr
}(
    amount: Uint256
):
    alloc_locals
    ## !! CALL updateReward() !! ##
    let (local caller) = get_caller_address()
    updateReward(caller)

    ## Update total supply ##
    let (intial_supply) = TOTAL_SUPPLY.read()
    let (new_supply, _: Uint256) = uint256_add(intial_supply, amount)
    let (positive_update) = uint256_le(intial_supply, new_supply)
    assert_not_zero(positive_update)
    TOTAL_SUPPLY.write(new_supply)

    ## Update balances ##
    let (initial_balance) = BALANCES.read(caller)
    let (new_balance, _: Uint256) = uint256_add(initial_balance, amount)
    let (positive_update) = uint256_le(initial_balance, new_balance)
    assert_not_zero(positive_update)
    BALANCES.write(caller, new_balance)

    ## Transfer from caller to contract ##
    let (local staking_token) = STAKING_TOKEN.read()
    let (contract_address) = get_contract_address()
    IERC20.transfer_from(
        contract_address=staking_token,
        sender=caller,
        recipient=contract_address,
        amount=amount
    )

    return ()
end

@external
func withdraw{
    syscall_ptr: felt*,
    pedersen_ptr: HashBuiltin*,
    range_check_ptr
}(
    amount: Uint256
):
    alloc_locals
    ## !! CALL updateReward() !! ##
    let (local caller) = get_caller_address()
    updateReward(caller)

    ## Update total supply ##
    let (intial_supply) = TOTAL_SUPPLY.read()
    let (new_supply, _: Uint256) = uint256_add(intial_supply, amount)
    let (negative_update) = uint256_le(new_supply, intial_supply)
    assert_not_zero(negative_update)
    TOTAL_SUPPLY.write(new_supply)

    ## Update balances ##
    let (initial_balance) = BALANCES.read(caller)
    let (new_balance, _: Uint256) = uint256_add(initial_balance, amount)
    let (negative_update) = uint256_le(new_balance, initial_balance)
    assert_not_zero(negative_update)
    BALANCES.write(caller, new_balance)

    ## Transfer from caller to contract ##
    let (local staking_token) = STAKING_TOKEN.read()
    let (contract_address) = get_contract_address()
    IERC20.transfer_from(
        contract_address=staking_token,
        sender=contract_address,
        recipient=caller,
        amount=amount
    )

    return ()
end

@external
func getReward{
    syscall_ptr: felt*,
    pedersen_ptr: HashBuiltin*,
    range_check_ptr
}():
    alloc_locals
    ## !! CALL updateReward() !! ##
    let (local caller) = get_caller_address()
    updateReward(caller)

    ## Send the reward to the caller ##
    let (local reward) = REWARDS.read(caller)
    REWARDS.write(caller, Uint256(0, 0))

    ## Transfer from caller to contract ##
    let (local reward_token) = REWARD_TOKEN.read()
    let (contract_address) = get_contract_address()
    IERC20.transfer(
        contract_address=reward_token,
        recipient=caller,
        amount=reward
    )

    return ()
end