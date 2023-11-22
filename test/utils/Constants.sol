// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.18;

/**
 * @title Constants
 *
 * @notice Abstract contract containing all the constants used by GenesisPFP and dependencies
 */
abstract contract Constants {
    bytes32 internal constant DEFAULT_ADMIN_ROLE = 0x00;

    bytes32 internal constant MINTER_ROLE = keccak256("MINTER_ROLE");

    uint256 internal constant GENESIS_PFP_INITIAL_REMAINING_SUPPLY = 9999;

    uint256 internal constant MINT_MAX_PRIVATE = 2;

    uint256 internal constant MINT_MAX_PUBLIC = 2;

    uint256 internal constant MINT_MIN_RESERVE = 200;

    string internal constant GENESIS_PFP_NAME = "Genesis PFP";

    string internal constant GENESIS_PFP_SYMBOL = "PFP";

    string internal constant GENESIS_PFP_VERSION = "1";
}
