import pytest
import asyncio
from starkware.starknet.testing.starknet import Starknet
from utils import Signer, uint, str_to_felt, MAX_UINT256

signer = Signer(123456789987654321)


@pytest.fixture(scope='module')
def event_loop():
    return asyncio.new_event_loop()


@pytest.fixture(scope='module')
async def ownable_factory():
    starknet = await Starknet.empty()
    owner = await starknet.deploy(
        "contracts/utils/Account.cairo",
        constructor_calldata=[signer.public_key]
    )

    staking_rewards = await starknet.deploy(
        "contracts/defi/StakingRewards.cairo",
        constructor_calldata=[
            1,
            2
        ]
    )
    return starknet, staking_rewards, owner


@pytest.mark.asyncio
async def test_constructor(ownable_factory):
    _, staking_rewards, _ = ownable_factory
    exp_staking_token = await staking_rewards.stakingToken().call()
    assert exp_staking_token.result.token == 1
    exp_reward_token = await staking_rewards.rewardToken().call()
    assert exp_reward_token.result.token == 2


@pytest.mark.asyncio
async def test_set_staking_token(ownable_factory):
    _, staking_rewards, owner = ownable_factory
    new_staking_token = 3
    await signer.send_transaction(owner, staking_rewards.contract_address, 'setStakingToken', [new_staking_token])
    executed_info = await staking_rewards.stakingToken().call()
    assert executed_info.result.token == new_staking_token


@pytest.mark.asyncio
async def test_set_reward_token(ownable_factory):
    _, staking_rewards, owner = ownable_factory
    new_reward_token = 3
    await signer.send_transaction(owner, staking_rewards.contract_address, 'setRewardToken', [new_reward_token])
    executed_info = await staking_rewards.rewardToken().call()
    assert executed_info.result.token == new_reward_token


@pytest.mark.asyncio
async def test_set_reward_rate(ownable_factory):
    _, staking_rewards, owner = ownable_factory
    initial_rate = await staking_rewards.rewardRate().call()
    assert initial_rate.result.rate == uint(0)
    new_rate = uint(3)
    await signer.send_transaction(owner, staking_rewards.contract_address, 'setRewardRate', [*new_rate])
    updated_rate = await staking_rewards.rewardRate().call()
    assert updated_rate.result.rate == new_rate
