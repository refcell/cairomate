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

    erc20 = await starknet.deploy(
        "contracts/tokens/ERC20.cairo",
        constructor_calldata=[
          str_to_felt("Test Contract"),
          str_to_felt("TEST"),
          18,
          *uint(1000)
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
    expected_totalSupply = await erc20.totalSupply().call()
    assert expected_totalSupply.result.totalSupply == uint(1000)
