%lang starknet
%builtins pedersen range_check

from starkware.cairo.common.cairo_builtins import HashBuiltin
from starkware.starknet.common.syscalls import storage_read, storage_write
from starkware.cairo.common.uint256 import Uint256, uint256_unsigned_div_rem

## Local Imports ##
from contracts.interfaces.IAggregatorV3 import IAggregatorV3

## @title Chainlink Price Oracle
## @description A price oracle that fetches data from a Chainlink V3 Aggregator contract.
## @description Adapted from https://solidity-by-example.org/defi/chainlink-price-oracle/
## @author velleity <github.com/a5f9t4>

#############################################
##                 STORAGE                 ##
#############################################

@storage_var
func PRICE_FEED() -> (aggregator: felt):
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
    price_feed: felt # Address of the Chainlink V3 Aggregator contract
):
    PRICE_FEED.write(price_feed)
    return ()
end

#############################################
##              ORACLE LOGIC               ##
#############################################

@external
func getLatestPrice{
    syscall_ptr: felt*,
    pedersen_ptr: HashBuiltin*,
    range_check_ptr
}() -> (
    price: Uint256
):
    alloc_locals
    let (local price_feed) = PRICE_FEED.read()
    let (
        roundID: Uint256, # This should be a uint80
        price: Uint256,
        startedAt: Uint256,
        timeStamp: Uint256,
        answeredInRound: Uint256, # This should be a uint80
    ) = IAggregatorV3.latestRoundData(contract_address=price_feed)

    # Price scaled up by 10 ** 8 (ETH/USD)
    let (scaled_price: Uint256, _: Uint256) = uint256_unsigned_div_rem(price, Uint256(100000000, 0))
    return (price=scaled_price)
end