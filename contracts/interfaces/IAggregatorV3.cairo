%lang starknet

from starkware.cairo.common.uint256 import Uint256

## @title AggregatorV3 Interface
## @description An interface for Chainlink V3 aggregator.
## @description Adapted from https://solidity-by-example.org/defi/chainlink-price-oracle/
## @author Alucard <github.com/a5f9t4>

@contract_interface
namespace IAggregatorV3:
    func latestRoundData() -> (
        roundId: Uint256, # This should be a uint80
        answer: Uint256,
        startedAt: Uint256,
        updatedAt: Uint256,
        answeredInRound: Uint256 # This should be a uint80
    ):
    end
end