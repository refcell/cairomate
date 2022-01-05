import pytest
import asyncio
from starkware.starknet.testing.starknet import Starknet
from utils import Signer, uint, uint_add, str_to_felt, MAX_UINT256

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
    return starknet, erc20, owner

@pytest.mark.asyncio
async def test_constructor(ownable_factory):
    _, erc20, _ = ownable_factory
    expected_name = await erc20.name().call()
    assert expected_name.result.name == str_to_felt("Test Contract")
    expected_symbol = await erc20.symbol().call()
    assert expected_symbol.result.symbol == str_to_felt("TEST")
    expected_decimals = await erc20.decimals().call()
    assert expected_decimals.result.decimals == 18
    expected_total_supply = await erc20.total_supply().call()
    assert expected_total_supply.result.total_supply == uint(1000)

@pytest.mark.asyncio
async def test_approve_from_caller(ownable_factory):
    _, erc20, owner = ownable_factory
    user = 123
    amount = uint(1000)
    # First mint the owner tokens
    await signer.send_transaction(owner, erc20.contract_address, 'mint', [owner.contract_address, *amount])
    # Approve the user to spend the tokens
    await signer.send_transaction(owner, erc20.contract_address, 'approve', [user, *amount])
    # Check if the user is approved
    executed_info = await erc20.allowance(owner.contract_address, user).call()
    assert executed_info.result.allowance == amount


@pytest.mark.asyncio
async def test_increase_allowance(ownable_factory):
    _, erc20, owner = ownable_factory
    user = 123
    amount = uint(1000)
    # First mint the owner tokens
    await signer.send_transaction(owner, erc20.contract_address, 'mint', [owner.contract_address, *amount])
    # Approve the user to spend the tokens
    await signer.send_transaction(owner, erc20.contract_address, 'approve', [user, *amount])
    # Check if the user is approved to spend
    executed_info = await erc20.allowance(owner.contract_address, user).call()
    assert executed_info.result.allowance == amount
    # Increase Allowance
    executed = await signer.send_transaction(owner, erc20.contract_address, 'increase_allowance', [user, *amount])
    assert executed.result.response == [1]
    # Check increased allowance
    executed_info = await erc20.allowance(owner.contract_address, user).call()
    increased_allowance = uint_add(amount, amount)
    assert executed_info.result.allowance == increased_allowance

@pytest.mark.asyncio
async def test_decrease_allowance(ownable_factory):
    _, erc20, owner = ownable_factory
    user = 123
    amount = uint(1000)
    # First mint the owner tokens
    await signer.send_transaction(owner, erc20.contract_address, 'mint', [owner.contract_address, *amount])
    # Approve the user to spend the tokens
    await signer.send_transaction(owner, erc20.contract_address, 'approve', [user, *amount])
    # Check if the user is approved to spend
    executed_info = await erc20.allowance(owner.contract_address, user).call()
    assert executed_info.result.allowance == amount
    # Increase Allowance
    executed = await signer.send_transaction(owner, erc20.contract_address, 'decrease_allowance', [user, *amount])
    assert executed.result.response == [1]
    # Check increased allowance
    executed_info = await erc20.allowance(owner.contract_address, user).call()
    assert executed_info.result.allowance == uint(0)
