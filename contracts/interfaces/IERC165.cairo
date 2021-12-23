%lang starknet

from starkware.cairo.common.uint256 import Uint256

## @title ERC165 Interface
## @description An interface for the ERC165 standard.
## @description Specification: https://eips.ethereum.org/EIPS/eip-165
## @author Alucard <github.com/a5f9t4>

@contract_interface
namespace IERC165:
    ## @notice Query if a contract implements an interface
    ## @param interfaceID The interface identifier, as specified in ERC-165
    ## @dev Interface identification is specified in ERC-165. This function
    ##  uses less than 30,000 gas.
    ## @return `true` if the contract implements `interfaceID` and
    ##  `interfaceID` is not 0xffffffff, `false` otherwise
    func supportsInterface(
        interfaceID: felt # This should be a bytes4
    ) -> (
        supported: felt # 0 (false) or 1 (true) - no native booleans in cairo
    ):
    end
end