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

/**
 * @title IGenesisCrafterRule
 *
 * @notice Interface for the GenesisCrafterRule contract, implementing specific crafting rules for individual tokens
 */
interface IGenesisCrafterRule {

    /**
     * @notice validate the crafting of a new champion based on its parents
     * @param collection contract address of the GenesisChampion parent
     * @param id tokenID of the parent
     */
    function validateCraft(address collection, uint256 id) external view returns (uint256);

    /**
     * @notice set the maximum craft count for an individual token
     * @param collection contract address of the GenesisChampion parent
     * @param id tokenID of the parent
     * @param val new maxCraftCount
     */
    function setMaxCraftCount(address collection, uint256 id, uint256 val) external;
}
