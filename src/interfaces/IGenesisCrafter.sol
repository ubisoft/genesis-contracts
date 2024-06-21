// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.8.24;

//  **     **  **       **                    ****   **
// /**    /** /**      //                    /**/   /**
// /**    /** /**       **  ******  ******  ****** ******
// /**    /** /******  /** **////  **////**///**/ ///**/
// /**    /** /**///** /**//***** /**   /**  /**    /**
// /**    /** /**  /** /** /////**/**   /**  /**    /**
// //*******  /******  /** ****** //******   /**    //**
// ///////    /////    // //////   //////    //      //

import {CraftData} from "src/types/CraftData.sol";

/**
 * @title IGenesisCrafter
 *
 * @notice Interface for the GenesisCrafter contract, a UUPS proxy implementation of the crafting mechanisms
 */
interface IGenesisCrafter {

    /**
     * @notice allows a user to craft a new champion from two parents champions
     * @param request CraftData object describing the craft request
     * @dev A new Champion can be created by crafting two parents, these parents can exist within the same
     * GenesisChampion collection or from two distinct collections.
     * - In case the parents come from the same
     * collection, the parent with the biggest maxCraftCount is used as a reference for the child's
     * maxCraftCount.
     * - If the parents come from two distinct collections, the parent from the oldest collection is used
     * as the reference, even if its maxCraftCount is lower than the other parent's
     */
    function craft(CraftData calldata request) external;

    /**
     * @notice registers the address of a specific CrafterRule contract for token `id` in `collection`
     * @param crafterRule address of the CrafterRule
     * @param collection address of the collection
     * @param id of the token
     * @dev id 0 registers a CrafterRule contract for the whole collection
     * @dev rules registered for ids greater than 0 take precedence over global rules
     */
    function setCrafterRule(address crafterRule, address collection, uint256 id) external;

    /**
     * @notice returns the maxCraftCount from a Champion, in case it wasn't initialized in `craftCounters`,
     * `viewMaxCraftCount` instantiates GenesisChampion to call `defaultMaxCraftCount`
     * @param collection address of the GenesisChampion contract
     * @param id of the token
     */
    function viewMaxCraftCount(address collection, uint256 id) external returns (uint256);

    /**
     * @notice replace the current crafting fees receiver
     * @param newVault address of the new vault wallet
     */
    function updateVault(address newVault) external;
}
