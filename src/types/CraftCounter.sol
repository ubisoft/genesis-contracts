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
 * @notice CraftCounter is the data structure responsible for crafting mechanisms for each Champion
 * @param craftCount default 0, increments by 1 after a successful craft
 * @param maxCraftCount default 8 for Gen0 Champions, decrements by 1 for a newly crafter Champion
 * @param lockedUntil if greather than 0, parent tokens won't be able to craft for a duration of `lockedUntil`
 * @param initialized specify if the Champion token's CraftCounter data was initialized
 */
struct CraftCounter {
    uint256 craftCount;
    uint256 maxCraftCount;
    uint256 lockedUntil;
    bool initialized;
}
