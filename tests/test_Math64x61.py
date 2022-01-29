import pytest
import asyncio
import math
from starkware.starknet.testing.starknet import Starknet
from utils import Signer, felt_to_64x61, PRIME, is_fp_close

signer = Signer(123456789987654321)
friend_signer = Signer(69420)

@pytest.fixture(scope='module')
def event_loop():
    return asyncio.new_event_loop()

@pytest.fixture(scope='module')
async def math64x61_factory():
    starknet = await Starknet.empty()
    math = await starknet.deploy(
        "contracts/utils/math_64x61.cairo",
    )
    return starknet, math

@pytest.mark.asyncio
async def test_multiplication(math64x61_factory):
    (_, fp_math ) =  math64x61_factory
    x = pow(2, 8)
    y = pow(2, 8)

    res = await fp_math.mul_fp(felt_to_64x61(x), felt_to_64x61(y)).invoke()

    assert res.result[0] == felt_to_64x61(x * y)

@pytest.mark.asyncio
async def test_division(math64x61_factory):
    (_, fp_math ) =  math64x61_factory
    x = pow(2, 32)
    y = pow(2, 32)

    res = await fp_math.div_fp(x, y).invoke()

    assert res.result[0] == felt_to_64x61(x / y)


@pytest.mark.asyncio
async def test_pow(math64x61_factory):
    (_, fp_math ) =  math64x61_factory

    xs = [ 4, 4, 4, 1024, 2 ** 16 - 1 , 4 , 64, -10, -10, -10 ]
    ys = [ 0, 1, 2, 3, 3 , -2, -3, 1, 2, 3 ]

    for i in range(len(xs)):
        x = xs[i]
        y = ys[i]

        res = await fp_math.pow_fp(felt_to_64x61(x), y).invoke()
        target = felt_to_64x61(pow(x, y))
        if target < 0:
            assert res.result[0] - PRIME == target
        else:
            assert res.result[0]  == target

@pytest.mark.asyncio
async def test_sqrt(math64x61_factory):
    (_, fp_math ) =  math64x61_factory

    xs = [ 1, 64, 2 ** 32, 7.21 ** 2 ]

    for x in xs:
        res = await fp_math.sqrt_fp(int(felt_to_64x61(x))).invoke()
        target = felt_to_64x61(math.sqrt(x))
        assert is_fp_close(res.result[0],target)

@pytest.mark.asyncio
async def test_binary_exp(math64x61_factory):
    (_, fp_math ) =  math64x61_factory

    xs = [ 0, 1, 3, 5.5, -1, -5.5 ]

    for x in xs:
        res = await fp_math.exp2_fp(int(felt_to_64x61(x))).invoke()
        target = felt_to_64x61(pow(2, x))
        assert is_fp_close(res.result[0],target)

@pytest.mark.asyncio
async def test_binary_log(math64x61_factory):
    (_, fp_math ) =  math64x61_factory

    xs = [ 0.5, 0.75, 1, 2, 5, 72.11 ]

    for x in xs:
        res = await fp_math.log2_fp(int(felt_to_64x61(x))).invoke()
        target = felt_to_64x61(math.log2(x))
        if target < 0:
            assert is_fp_close(res.result[0]- PRIME,target)
        else:
            assert is_fp_close(res.result[0],target)

@pytest.mark.asyncio
async def test_natural_log(math64x61_factory):
    (_, fp_math ) =  math64x61_factory

    xs = [ 0.5, 1, math.e, 5, 72.11 ]

    for x in xs:
        res = await fp_math.ln_fp(int(felt_to_64x61(x))).invoke()
        target = felt_to_64x61(math.log(x))
        if target < 0:
            assert is_fp_close(res.result[0]- PRIME,target)
        else:
            assert is_fp_close(res.result[0],target)

@pytest.mark.asyncio
async def test_log_10(math64x61_factory):
    (_, fp_math ) =  math64x61_factory

    xs = [ 0.5, 1, 2, 10, 72.11 ]

    for x in xs:
        res = await fp_math.log10_fp(int(felt_to_64x61(x))).invoke()
        target = felt_to_64x61(math.log(x, 10))
        if target < 0:
            assert is_fp_close(res.result[0]- PRIME,target)
        else:
            assert is_fp_close(res.result[0],target)