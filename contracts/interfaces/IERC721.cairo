%lang starknet

from starkware.cairo.common.uint256 import Uint256

## @title ERC721 Interface
## @description An interface for the ERC721 standard.
## @description Adapted from OpenZeppelin's Cairo Contracts: https://github.com/OpenZeppelin/cairo-contracts
## @author Alucard <github.com/a5f9t4>

@contract_interface
namespace IERC721:
    func name() -> (name: felt):
    end

    func symbol() -> (symbol: felt):
    end

    func baseURI() -> (base_uri: felt):
    end

    func totalSupply() -> (totalSupply: Uint256):
    end

    func balanceOf(account: felt) -> (balance: Uint256):
    end

    func allowance(owner: felt, spender: felt) -> (remaining: Uint256):
    end

    func transfer(recipient: felt, amount: Uint256) -> (success: felt):
    end

    func transferFrom(
            sender: felt,
            recipient: felt,
            amount: Uint256
        ) -> (success: felt):
    end

    func approve(spender: felt, amount: Uint256) -> (success: felt):
    end
end