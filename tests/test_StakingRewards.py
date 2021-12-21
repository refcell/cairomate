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
