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
 * @notice Constructor args required for the deployment of GenesisChampion
 * @param name of the contract
 * @param symbol of the contract
 * @param baseURI for metadatas
 * @param owner of the contract
 * @param minter address of the GenesisMinter contract
 * @param crafter address of the GenesisCrafter contract
 * @param vault address of the royalties vault
 * @param endpointL0 address of the LayerZero V2 endpoint used
 * @param defaultMaxCraftCount maximum craft count charges a Champion can use by default
 */
struct GenesisChampionArgs {
    string name;
    string symbol;
    string baseURI;
    address owner;
    address minter;
    address crafter;
    address vault;
    address endpointL0;
    uint256 defaultMaxCraftCount;
}
