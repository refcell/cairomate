import pytest
import asyncio
from starkware.starknet.testing.starknet import Starknet
from utils import Signer, assert_invoked_revert, assert_revert, uint, uint_add, str_to_felt, MAX_UINT256

signer = Signer(123456789987654321)
friend_signer = Signer(69420)

@pytest.fixture(scope='module')
def event_loop():
    return asyncio.new_event_loop()

# @pytest.fixture(scope='module')
async def erc20_factory():
    starknet = await Starknet.empty()
    owner = await starknet.deploy(
        "contracts/utils/Account.cairo",
        constructor_calldata=[signer.public_key]
    )

    friend = await starknet.deploy(
        "contracts/utils/Account.cairo",
        constructor_calldata=[friend_signer.public_key]
    )

    erc20 = await starknet.deploy(
        "contracts/mocks/MockERC20.cairo",
        constructor_calldata=[
            str_to_felt("Test Contract"),
            str_to_felt("TEST"),
            18,
            *uint(1000),
            owner.contract_address
        ]
    )
    return starknet, erc20, owner, friend

@pytest.mark.asyncio
async def test_constructor():
    _, erc20, _, _ = await erc20_factory()
    expected_name = await erc20.name().call()
    assert expected_name.result.name == str_to_felt("Test Contract")
    expected_symbol = await erc20.symbol().call()
    assert expected_symbol.result.symbol == str_to_felt("TEST")
    expected_decimals = await erc20.decimals().call()
    assert expected_decimals.result.decimals == 18
    expected_total_supply = await erc20.total_supply().call()
    assert expected_total_supply.result.total_supply == uint(1000)

#############################################
##     Validate Additional Mock Logic      ##
#############################################

@pytest.mark.asyncio
async def test_mint():
    _, erc20, owner, friend = await erc20_factory()
    amount = uint(69420)
    await erc20.mint(owner.contract_address, amount).invoke(caller_address=owner.contract_address)
    await erc20.mint(friend.contract_address, amount).invoke(caller_address=owner.contract_address)
    expected_balance = await erc20.balance_of(owner.contract_address).call()
    assert expected_balance.result.balance == amount
    expected_balance = await erc20.balance_of(friend.contract_address).call()
    assert expected_balance.result.balance == amount

@pytest.mark.asyncio
async def test_owner():
    _, erc20, owner, _ = await erc20_factory()
    expected_owner = await erc20.owner().call()
    assert expected_owner.result.owner == owner.contract_address

#############################################
##              ERC20 Tests                ##
#############################################

###############
## approve() ##
###############

@pytest.mark.asyncio
async def test_approve_from_caller():
    _, erc20, owner, friend = await erc20_factory()
    mint_amount = uint(1000)
    approved_amount = uint(500)
    # Mint tokens
    await erc20.mint(owner.contract_address, mint_amount).invoke(caller_address=owner.contract_address)
    # Then approve
    await erc20.approve(friend.contract_address, approved_amount).invoke(caller_address=owner.contract_address)
    # Check if the user is approved
    executed_info = await erc20.allowance(owner.contract_address, friend.contract_address).call()
    assert executed_info.result.allowance == approved_amount

@pytest.mark.asyncio
async def test_approve_none_minted():
    _, erc20, owner, friend = await erc20_factory()
    amount = uint(69420)
    await erc20.approve(friend.contract_address, amount).invoke(owner.contract_address)
    # Check if the user is approved
    executed_info = await erc20.allowance(owner.contract_address, friend.contract_address).call()
    assert executed_info.result.allowance == amount
    executed_info = await erc20.allowance(friend.contract_address, owner.contract_address).call()
    assert executed_info.result.allowance == uint(0)

@pytest.mark.asyncio
async def test_fail_approve_zero_spender():
    _, erc20, owner, _ = await erc20_factory()
    amount = uint(69420)
    await erc20.mint(owner.contract_address, amount).invoke(caller_address=owner.contract_address)
    await assert_invoked_revert(erc20.approve(0, amount), owner.contract_address)

##########################
## increase_allowance() ##
##########################

@pytest.mark.asyncio
async def test_increase_allowance():
    _, erc20, owner, friend = await erc20_factory()
    half = uint(500)
    amount = uint(1000)
    # Approve the user to spend the tokens
    await erc20.approve(friend.contract_address, half).invoke(caller_address=owner.contract_address)
    # Check if the user is approved to spend
    executed_info = await erc20.allowance(owner.contract_address, friend.contract_address).call()
    assert executed_info.result.allowance == half
    executed_info = await erc20.allowance(friend.contract_address, owner.contract_address).call()
    assert executed_info.result.allowance == uint(0)
    # Increase Allowance
    executed = await erc20.increase_allowance(friend.contract_address, half).invoke(caller_address=owner.contract_address)
    assert executed.result.success == 1
    # Check increased allowance
    executed_info = await erc20.allowance(owner.contract_address, friend.contract_address).call()
    assert executed_info.result.allowance == amount
    executed_info = await erc20.allowance(friend.contract_address, owner.contract_address).call()
    assert executed_info.result.allowance == uint(0)

@pytest.mark.asyncio
async def test_fail_increase_allowance_overflow():
    _, erc20, owner, friend = await erc20_factory()
    amount = MAX_UINT256
    # overflow_amount adds (1, 0) to (2**128 - 1, 2**128 - 1)
    overflow_amount = uint(1)
    # Mint
    await erc20.mint(owner.contract_address, amount).invoke(caller_address=owner.contract_address)
    # Approve
    await erc20.approve(friend.contract_address, amount).invoke(caller_address=owner.contract_address)
    # Overflow
    await assert_invoked_revert(erc20.increase_allowance(friend.contract_address, amount), owner.contract_address)


@pytest.mark.asyncio
async def test_increase_allowance_zero_spender():
    _, erc20, owner, _ = await erc20_factory()
    await assert_invoked_revert(erc20.increase_allowance(0, uint(1)), owner.contract_address)

##########################
## decrease_allowance() ##
##########################

@pytest.mark.asyncio
async def test_decrease_allowance():
    _, erc20, owner, friend = await erc20_factory()
    amount = uint(1000)
    # Approve the user to spend the tokens
    await erc20.approve(friend.contract_address, uint(500)).invoke(caller_address=owner.contract_address)
    # Check if the user is approved to spend
    executed_info = await erc20.allowance(owner.contract_address, friend.contract_address).call()
    assert executed_info.result.allowance == uint(500)
    executed_info = await erc20.allowance(friend.contract_address, owner.contract_address).call()
    assert executed_info.result.allowance == uint(0)
    # Increase Allowance
    executed = await erc20.decrease_allowance(friend.contract_address, uint(500)).invoke(caller_address=owner.contract_address)
    assert executed.result.success == 1
    # Check increased allowance
    executed_info = await erc20.allowance(owner.contract_address, friend.contract_address).call()
    assert executed_info.result.allowance == uint(0)

@pytest.mark.asyncio
async def test_fail_decrease_allowance_underflow():
    _, erc20, owner, friend = await erc20_factory()
    ## Overflows - will try to subtract 1 from 0
    await assert_invoked_revert(erc20.decrease_allowance(friend.contract_address, uint(1)), owner.contract_address)


@pytest.mark.asyncio
async def test_fail_decrease_allowance_zero_spender():
    _, erc20, owner, _ = await erc20_factory()
    await assert_invoked_revert(erc20.decrease_allowance(0, uint(0)), owner.contract_address)

################
## transfer() ##
################

#####################
## transfer_from() ##
#####################
