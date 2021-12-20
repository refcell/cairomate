%lang starknet

## @title Account Interface
## @description An interface for the Account implementation.
## @description Adapted from OpenZeppelin's Cairo Contracts: https://github.com/OpenZeppelin/cairo-contracts
## @author Alucard <github.com/a5f9t4>

@contract_interface
namespace IAccount:
    func get_nonce() -> (res : felt):
    end

    func is_valid_signature(
            hash: felt,
            signature_len: felt,
            signature: felt*
        ):
    end

    func execute(
            to: felt,
            selector: felt,
            calldata_len: felt,
            calldata: felt*,
            nonce: felt
        ) -> (response_len: felt, response: felt*):
    end
end