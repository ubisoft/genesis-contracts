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
 * @notice SupplyConfig holds the supplies for a collection's primary drop
 * @param sHolder supply associated to the holders' claim
 * @param sPublic supply associatged to the public claim
 * @param init specifies if the supply was initialized
 * @dev sHolder and sPublic will decrement by `MintData.amount` for each claim until reaching 0, hence the init field
 */
struct SupplyConfig {
    uint256 sHolder;
    uint256 sPublic;
    bool init;
}
