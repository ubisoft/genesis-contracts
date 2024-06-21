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
 * @param season defines a 30-days period in Genesis
 * @param to recipient of the mint
 * @param amount total amount of tokens available for mint this season
 * @param nonce back-end issued for non replayability
 */
struct RewardClaim {
    uint256 season;
    address to;
    uint256 amount;
    bytes32 nonce;
}

