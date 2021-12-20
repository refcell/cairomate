%lang starknet
%builtins pedersen range_check

from starkware.starknet.common.syscalls import get_caller_address, get_contract_address
from starkware.cairo.common.cairo_builtins import HashBuiltin
from starkware.cairo.common.hash import hash2
from starkware.cairo.common.math import assert_le, assert_nn_le, unsigned_div_rem, assert_not_zero
from starkware.starknet.common.syscalls import storage_read, storage_write
from starkware.cairo.common.uint256 import (
    Uint256, uint256_add, uint256_sub, uint256_le, uint256_lt, uint256_check
)

## Local Imports ##
from contracts.interfaces.IERC20 import IERC20


## @title Staking Rewards
## @description A stripped down implementation of Synthetix StakingRewards.sol
## @description Adapted from https://solidity-by-example.org/defi/staking-rewards/
## @author Alucard <github.com/a5f9t4>

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
func REWARD_RATE() -> (rate: felt):
end

@storage_var
func LAST_UPDATE_TIME() -> (time: felt):
end

@storage_var
func REWARD_PER_TOKEN_STORED() -> (reward: felt):
end

@storage_var
func USER_REWARD_PER_TOKEN_PAID(user: felt) -> (reward: felt):
end

@storage_var
func REWARDS(user: felt) -> (reward: felt):
end

@storage_var
func TOTAL_SUPPLY() -> (total_supply: felt):
end

@storage_var
func BALANCES(user: felt) -> (balance: felt):
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
}() -> (rate: felt):
    let (_rate) = REWARD_RATE.read()
    return (rate=_rate)
end

@view
func lastUpdateTime{
    syscall_ptr: felt*,
    pedersen_ptr: HashBuiltin*,
    range_check_ptr
}() -> (time: felt):
    let (_time) = LAST_UPDATE_TIME.read()
    return (time=_time)
end

@view
func rewardPerTokenStored{
    syscall_ptr: felt*,
    pedersen_ptr: HashBuiltin*,
    range_check_ptr
}() -> (reward: felt):
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
) -> (reward: felt):
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
) -> (reward: felt):
    let (_reward) = REWARDS.read(user)
    return (reward=_reward)
end

## MAIN VIEW FUNCTIONS ##

@view
func rewardPerToken{
    syscall_ptr: felt*,
    pedersen_ptr: HashBuiltin*,
    range_check_ptr
}() -> (reward: felt):
    let (_total_supply) = TOTAL_SUPPLY.read()
    if _total_supply == 0:
        return (reward=0)
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
) -> (amoun: felt):
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

    let (amount) = (balance * (reward_per_token - user_reward)) + accumulated_rewards
    return (amount)
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
    let (_reward_per_token_stored) = rewardPerToken()
    let (_last_update_time) = 0 # TODO: how to get `block.timestamp`?

    let (_earned) = earned(address)
    REWARDS.write(address, _earned)
    USER_REWARD_PER_TOKEN_PAID.write(address, _reward_per_token_stored)
end

@external
func stake{
    syscall_ptr: felt*,
    pedersen_ptr: HashBuiltin*,
    range_check_ptr
}(
    amount: felt
):
    ## !! CALL updateReward() !! ##
    let (caller) = get_caller_address()
    updateReward(caller)

    ## Update total supply ##
    let (_total_supply) = TOTAL_SUPPLY.read()
    let (new_supply) = _total_supply + amount
    assert_nn_le(_total_supply, new_supply)
    TOTAL_SUPPLY.write(_total_supply + amount)

    ## Update balances ##
    let (_balances) = BALANCES.read(caller)
    let (new_balance) = _balances + amount
    assert_nn_le(_balances, new_balance)
    BALANCES.write(caller, new_balance)

    ## Transfer from caller to contract ##
    let (staking_token) = STAKING_TOKEN.read()
    let (contract_address) = get_contract_address()
    IERC20.transferFrom(
        contract_address=staking_token,
        caller, # sender
        contract_address, # recipient
        amount # amount
    )

    return ()
end

@external
func withdraw{
    syscall_ptr: felt*,
    pedersen_ptr: HashBuiltin*,
    range_check_ptr
}(
    amount: felt
):
    ## !! CALL updateReward() !! ##
    let (caller) = get_caller_address()
    updateReward(caller)

    ## Update total supply ##
    let (_total_supply) = TOTAL_SUPPLY.read()
    let (new_supply) = _total_supply + amount
    assert_nn_le(_total_supply, new_supply)
    TOTAL_SUPPLY.write(_total_supply + amount)

    ## Update balances ##
    let (_balances) = BALANCES.read(caller)
    let (new_balance) = _balances + amount
    assert_nn_le(_balances, new_balance)
    BALANCES.write(caller, new_balance)

    ## Transfer from caller to contract ##
    let (staking_token) = STAKING_TOKEN.read()
    let (contract_address) = get_contract_address()
    IERC20.transferFrom(
        contract_address=staking_token,
        caller, # sender
        contract_address, # recipient
        amount # amount
    )

    return ()
end

function withdraw(uint _amount) external updateReward(msg.sender) {
    _totalSupply -= _amount;
    _balances[msg.sender] -= _amount;
    stakingToken.transfer(msg.sender, _amount);
}

function getReward() external updateReward(msg.sender) {
    uint reward = rewards[msg.sender];
    rewards[msg.sender] = 0;
    rewardsToken.transfer(msg.sender, reward);
}