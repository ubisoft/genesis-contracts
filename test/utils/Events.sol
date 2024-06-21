// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.24;

/**
 * @title Events
 *
 * @notice Abstract contract containing all the events emitted by GenesisPFP and dependencies
 */
abstract contract Events {

    // =============================================================
    //                   ERC721
    // =============================================================

    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);

    // =============================================================
    //                   ERC20
    // =============================================================

    event Approval(address indexed owner, address indexed spender, uint256 value);

    // =============================================================
    //                   AccessControl
    // =============================================================

    event RoleAdminChanged(bytes32 indexed role, bytes32 indexed previousAdminRole, bytes32 indexed newAdminRole);

    event RoleGranted(bytes32 indexed role, address indexed account, address indexed sender);

    event RoleRevoked(bytes32 indexed role, address indexed account, address indexed sender);

    // =============================================================
    //                   Ownable
    // =============================================================

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    // =============================================================
    //                   GenesisChampion
    // =============================================================

    event CrafterContractUpdate(address indexed newCrafter);

    event ContractCreated(address collection, uint256 version);


    // =============================================================
    //                   UUPS
    // =============================================================

    event Initialized(uint64 version);

    event Upgraded(address indexed implementation);

    // =============================================================
    //                   GENESIS CRAFTER
    // =============================================================

    event VaultUpdate(address vault);

    event GenesisMinterUpdate(address minter);

    event Craft(
        address indexed childCollection,
        bytes32 indexed craftNonce,
        uint256 indexed childId,
        address collectionA,
        address collectionB,
        uint256 parentA,
        uint256 parentB
    );

    event SetCrafterRule(address crafterRule, address collection, uint256 id);

    // =============================================================
    //                   GENESIS MINTER
    // =============================================================

    event Claim(address indexed collection, bytes32 indexed nonce, uint256 amount);

    event GenesisCrafterUpdate(address oldCrafter, address newCrafter);

    event GenesisFactoryUpdate(address oldFactory, address newFactory);

    event CraftFees(address vault, address indexed currency, uint256 amount, address from);

    // =============================================================
    //                   GENESIS CRAFTER RULE
    // =============================================================

    event MaxCraftCountUpdate(address collection, uint256 id, uint256 val);
}
