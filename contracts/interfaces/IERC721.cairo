%lang starknet

from starkware.cairo.common.uint256 import Uint256

## @title ERC721 Interface
## @description An interface for the ERC721 standard.
## @description Adapted from OpenZeppelin's Cairo Contracts: https://github.com/OpenZeppelin/cairo-contracts
## @author andreas <andreas@nascent.xyz>

@contract_interface
namespace IERC721:

    #############################################
    ##                ACCESSORS                ##
    #############################################

    func name() -> (name: felt):
    end

    func symbol() -> (symbol: felt):
    end

    func total_supply() -> (total_supply: Uint256):
    end

    func owner_of(token_id: felt) -> (owner: felt):
    end

    func balance_of(owner: felt) -> (balance: Uint256):
    end

    func get_approved(token_id: Uint256) -> (spender: felt):
    end

    func is_approved_for_all(owner: felt, operator: felt) -> (approved: felt):
    end

    #############################################
    ##                 MUTATORS                ##
    #############################################

    func transfer(recipient: felt, token_id: Uint256):
    end

    func transfer_from(
            sender: felt,
            recipient: felt,
            token_id: Uint256
        ):
    end

    func set_approval_for_all(operator: felt, approved: felt):
    end

    func approve(spender: felt, token_id: Uint256):
    end
end