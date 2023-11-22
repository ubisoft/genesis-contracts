// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.18;

/**
 * @notice MintData holds the data required to a minting request
 * @param to address of the user receiving the token(s)
 * @param validity_start timestamp for signature's start of validity
 * @param validity_end timestamp for signature's end of validity
 * @param chain_id for replay attack protection
 * @param mint_amount total number of tokens to mint if available
 * @param user_nonce generated by Genesis' backend
 */
struct MintData {
    address to;
    uint256 validity_start;
    uint256 validity_end;
    uint256 chain_id;
    uint256 mint_amount;
    bytes32 user_nonce;
}
