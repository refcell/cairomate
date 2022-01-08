%lang starknet
%builtins pedersen range_check ecdsa
from starkware.cairo.common.cairo_builtins import HashBuiltin, SignatureBuiltin
from starkware.cairo.common.uint256 import Uint256

@view 
func on_erc721_received(
    operator: felt,
    to: felt,
    token_id: Uint256,
    data_len: felt,
    data: felt*
) -> (selector: felt):
    return (selector=0x150b7a02)
end