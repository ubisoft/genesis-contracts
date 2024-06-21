// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.24;

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

    string internal constant GENESIS_CHAMP_NAME = "Genesis Champion";

    string internal constant GENESIS_CHAMP_SYMBOL = "CHAMP";

    string internal constant GENESIS_CHAMP_VERSION = "1";

    uint256 internal constant GENESIS_CHAMP_INITIAL_PUBLIC_SUPPLY = 49_000;

    uint256 internal constant GENESIS_CHAMP_INITIAL_HOLDER_SUPPLY = 50_000;

    uint256 internal constant GENESIS_CHAMP_RESERVE_MINT = 1_000;

    uint256 internal constant GENESIS_CHAMP_CLAIM_HOLDERS = 5;

    uint256 internal constant GENESIS_CHAMP_CLAIM_PARTNERS = 4;

    uint256 internal constant GENESIS_CHAMP_CLAIM_PUBLIC = 3;

    uint8 internal constant GENESIS_CHAMP_DEFAULT_MAX_CRAFT_COUNT = 8;

    address internal constant LAYERZERO_HOMEVERSE_ENDPOINT = 0x1a44076050125825900e736c501f859c50fE728c;

    uint256 internal constant LAYERZERO_HOMEVERSE_EID = 30265;

}
