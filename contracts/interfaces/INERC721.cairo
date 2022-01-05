%lang starknet

from starkware.cairo.common.uint256 import Uint256

## @title N-ERC721 Interface
## @description An interface for ERC721 using only felts.
## @description Adapted from OpenZeppelin's Cairo Contracts: https://github.com/OpenZeppelin/cairo-contracts
## @author velleity <github.com/a5f9t4>

@contract_interface
namespace IERC721:

    #############################################
    ##                ACCESSORS                ##
    #############################################

    func name() -> (name: felt):
    end

    func symbol() -> (symbol: felt):
    end

    func total_supply() -> (total_supply: felt):
    end

    func owner_of(token_id: felt) -> (owner: felt):
    end

    func balance_of(owner: felt) -> (balance: felt):
    end

    func get_approved(token_id: felt) -> (spender: felt):
    end

    func is_approved_for_all(owner: felt, operator: felt) -> (approved: felt):
    end

    #############################################
    ##                 MUTATORS                ##
    #############################################

    func transfer(recipient: felt, token_id: felt):
    end

    func transfer_from(
            sender: felt,
            recipient: felt,
            token_id: felt
        ):
    end

    func set_approval_for_all(operator: felt, approved: felt):
    end

    func approve(spender: felt, token_id: felt):
    end
end