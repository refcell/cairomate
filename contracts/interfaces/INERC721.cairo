%lang starknet

from starkware.cairo.common.uint256 import Uint256

## @title N-ERC721 Interface
## @description An interface for N-ERC721, an entirely felt-based ERC721 Implementation.
## @description Adapted from OpenZeppelin's Cairo Contracts: https://github.com/OpenZeppelin/cairo-contracts
## @author velleity <github.com/a5f9t4>

@contract_interface
namespace IERC721:
    func name() -> (name: felt):
    end

    func symbol() -> (symbol: felt):
    end

    func total_supply() -> (total_supply: Uint256):
    end

    func balance_of(account: felt) -> (balance: Uint256):
    end

    func allowance(owner: felt, spender: felt) -> (allowance: Uint256):
    end

    func transfer(recipient: felt, amount: Uint256) -> (success: felt):
    end

    func transfer_from(
            sender: felt,
            recipient: felt,
            amount: Uint256
        ) -> (success: felt):
    end

    func approve(spender: felt, amount: Uint256) -> (success: felt):
    end
end