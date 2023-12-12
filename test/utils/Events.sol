// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.18;

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
    //                   AccessControl
    // =============================================================

    event RoleAdminChanged(bytes32 indexed role, bytes32 indexed previousAdminRole, bytes32 indexed newAdminRole);

    event RoleGranted(bytes32 indexed role, address indexed account, address indexed sender);

    event RoleRevoked(bytes32 indexed role, address indexed account, address indexed sender);

    // =============================================================
    //                   Ownable
    // =============================================================

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
}
