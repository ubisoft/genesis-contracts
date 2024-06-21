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
 * @notice MintData holds the data required to a minting request in GenesisChampion
 * @param collection address of the GenesisChampion contract
 * @param to address of the user receiving the token(s)
 * @param amount total number of tokens to mint if available
 * @param holder specifies the mint type
 * @param nonce for single use claim
 */
struct MintData {
    address collection;
    address to;
    uint256 amount;
    bool holder;
    bytes32 nonce;
}
