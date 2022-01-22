import pytest
import asyncio
from starkware.starknet.testing.starknet import Starknet
from utils import Signer, uint, str_to_felt

owner_signer = Signer(123456789987654321)
friend_signer = Signer(69420)


@pytest.fixture(scope='module')
def event_loop():
    return asyncio.new_event_loop()


async def ownable_factory():
    starknet = await Starknet.empty()
    owner = await starknet.deploy(
        "contracts/utils/Account.cairo",
        constructor_calldata=[owner_signer.public_key]
    )

    friend = await starknet.deploy(
        "contracts/utils/Account.cairo",
        constructor_calldata=[friend_signer.public_key]
    )

    erc721 = await starknet.deploy(
        "tests/mocks/MockNERC721.cairo",
        constructor_calldata=[
            str_to_felt("Test Contract"),
            str_to_felt("TEST"),
            str_to_felt("ipfs://"),
            str_to_felt("hashkek")
        ]
    )
    return starknet, erc721, owner, friend


@pytest.mark.asyncio
async def test_constructor():
    _, erc721, _, _ = await ownable_factory()
    expected_name = await erc721.name().call()
    assert expected_name.result.name == str_to_felt("Test Contract")
    expected_symbol = await erc721.symbol().call()
    assert expected_symbol.result.symbol == str_to_felt("TEST")
    expected_token_uri = await erc721.token_uri(0).call()
    assert expected_token_uri.result.token_uri.prefix == str_to_felt("ipfs://")
    assert expected_token_uri.result.token_uri.suffix == str_to_felt("hashkek")
    assert expected_token_uri.result.token_uri.token_id == 0


@pytest.mark.asyncio
async def test_mint():
    _, erc721, owner, _ = await ownable_factory()
    await erc721.mint(owner.contract_address, 0).invoke()
    expected_owner = await erc721.owner_of(0).call()
    assert expected_owner.result.owner == owner.contract_address
    expected_balance = await erc721.balance_of(owner.contract_address).call()
    assert expected_balance.result.balance == 1

@pytest.mark.asyncio
async def test_burn():
    _, erc721, owner, _ = await ownable_factory()
    await erc721.mint(owner.contract_address, 0).invoke()
    await owner_signer.send_transaction(owner, erc721.contract_address, 'burn', [0])
    expected_owner = await erc721.owner_of(0).call()
    assert expected_owner.result.owner == 0
    expected_balance = await erc721.balance_of(owner.contract_address).call()
    assert expected_balance.result.balance == 0

@pytest.mark.asyncio
async def test_approve():
    _, erc721, owner, friend = await ownable_factory()
    await erc721.mint(owner.contract_address, 0).invoke()
    await owner_signer.send_transaction(owner, erc721.contract_address, 'approve', [friend.contract_address, 0])
    expected_spender = await erc721.get_approved(0).call()
    assert expected_spender.result.spender == friend.contract_address

@pytest.mark.asyncio
async def test_approve_burn():
    _, erc721, owner, friend = await ownable_factory()
    await erc721.mint(owner.contract_address, 0).invoke()
    await owner_signer.send_transaction(owner, erc721.contract_address, 'approve', [friend.contract_address, 0])
    await owner_signer.send_transaction(owner, erc721.contract_address, 'burn', [0])
    expected_spender = await erc721.get_approved(0).call()
    assert expected_spender.result.spender == 0

@pytest.mark.asyncio
async def test_approve_all():
    _, erc721, owner, friend = await ownable_factory()
    await owner_signer.send_transaction(owner, erc721.contract_address, 'set_approval_for_all', [friend.contract_address, 1])
    expected_approval = await erc721.is_approved_for_all(owner.contract_address, friend.contract_address,).call()
    assert expected_approval.result.approved == 1

@pytest.mark.asyncio
async def test_transfer_from():
    _, erc721, owner, friend = await ownable_factory()
    await erc721.mint(owner.contract_address, 0).invoke()
    await owner_signer.send_transaction(owner, erc721.contract_address, 'approve', [friend.contract_address, 0])
    await friend_signer.send_transaction(friend, erc721.contract_address, 'transfer_from', [owner.contract_address, 666, 0])

    expected_approval = await erc721.get_approved(0).call()
    assert expected_approval.result.spender == 0
    expected_owner = await erc721.owner_of(0).call()
    assert expected_owner.result.owner == 666
    expected_balance_from = await erc721.balance_of(owner.contract_address).call()
    assert expected_balance_from.result.balance == 0
    expected_balance_to = await erc721.balance_of(666).call()
    assert expected_balance_to.result.balance == 1

@pytest.mark.asyncio
async def test_transfer_from_self():
    _, erc721, owner, _ = await ownable_factory()
    await erc721.mint(owner.contract_address, 0).invoke()
    await owner_signer.send_transaction(owner, erc721.contract_address, 'transfer_from', [owner.contract_address, 666, 0])

    expected_approval = await erc721.get_approved(0).call()
    assert expected_approval.result.spender == 0
    expected_owner = await erc721.owner_of(0).call()
    assert expected_owner.result.owner == 666
    expected_balance_from = await erc721.balance_of(owner.contract_address).call()
    assert expected_balance_from.result.balance == 0
    expected_balance_to = await erc721.balance_of(666).call()
    assert expected_balance_to.result.balance == 1

@pytest.mark.asyncio
async def test_transfer_from_approve_all():
    _, erc721, owner, friend = await ownable_factory()
    await erc721.mint(owner.contract_address, 0).invoke()
    await owner_signer.send_transaction(owner, erc721.contract_address, 'set_approval_for_all', [friend.contract_address, 1])
    await friend_signer.send_transaction(friend, erc721.contract_address, 'transfer_from', [owner.contract_address, 666, 0])

    expected_approval = await erc721.get_approved(0).call()
    assert expected_approval.result.spender == 0
    expected_owner = await erc721.owner_of(0).call()
    assert expected_owner.result.owner == 666
    expected_balance_from = await erc721.balance_of(owner.contract_address).call()
    assert expected_balance_from.result.balance == 0
    expected_balance_to = await erc721.balance_of(666).call()
    assert expected_balance_to.result.balance == 1

@pytest.mark.asyncio
async def test_fail_mint_to_zero():
    _, erc721, owner, _ = await ownable_factory()
    with pytest.raises(Exception):
        await erc721.mint(0, 0).invoke()

@pytest.mark.asyncio
async def test_fail_double_mint():
    _, erc721, owner, _ = await ownable_factory()
    await erc721.mint(owner.contract_address, 0).invoke()
    with pytest.raises(Exception):
        await erc721.mint(owner.contract_address, 0).invoke()

@pytest.mark.asyncio
async def test_fail_burn_unminted():
    _, erc721, owner, _ = await ownable_factory()
    with pytest.raises(Exception):
        await owner_signer.send_transaction(owner, erc721.contract_address, 'burn', [0])

@pytest.mark.asyncio
async def test_fail_double_burn():
    _, erc721, owner, _ = await ownable_factory()
    await erc721.mint(owner.contract_address, 0).invoke()
    await owner_signer.send_transaction(owner, erc721.contract_address, 'burn', [0])
    with pytest.raises(Exception):
        await owner_signer.send_transaction(owner, erc721.contract_address, 'burn', [0])

@pytest.mark.asyncio
async def test_fail_approve_unminted():
    _, erc721, owner, friend = await ownable_factory()
    with pytest.raises(Exception):
        await owner_signer.send_transaction(owner, erc721.contract_address, 'approve', [friend.contract_address, 0])

@pytest.mark.asyncio
async def test_fail_approve_unauthorized():
    _, erc721, owner, friend = await ownable_factory()
    await erc721.mint(owner.contract_address, 0).invoke()
    with pytest.raises(Exception):
        await friend_signer.send_transaction(friend, erc721.contract_address, 'approve', [666, 0])

@pytest.mark.asyncio
async def test_fail_transfer_from_unowned():
    _, erc721, owner, friend = await ownable_factory()
    with pytest.raises(Exception):
        await owner_signer.send_transaction(owner, erc721.contract_address, 'transfer_from', [69, 420, 0])

@pytest.mark.asyncio
async def test_fail_transfer_from_wrong_from():
    _, erc721, owner, friend = await ownable_factory()
    await erc721.mint(owner.contract_address, 0).invoke()
    with pytest.raises(Exception):
        await friend_signer.send_transaction(friend, erc721.contract_address, 'transfer_from', [69, 420, 0])

@pytest.mark.asyncio
async def test_fail_transfer_from_to_zero():
    _, erc721, owner, friend = await ownable_factory()
    await erc721.mint(owner.contract_address, 0).invoke()
    with pytest.raises(Exception):
        await owner_signer.send_transaction(owner, erc721.contract_address, 'transfer_from', [owner.contract_address, 0, 0])
    
@pytest.mark.asyncio
async def test_fail_transfer_from_not_owner():
    _, erc721, owner, friend = await ownable_factory()
    await erc721.mint(owner.contract_address, 0).invoke()
    with pytest.raises(Exception):
        await friend_signer.send_transaction(friend, erc721.contract_address, 'transfer_from', [owner.contract_address, 666, 0])