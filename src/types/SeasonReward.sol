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
 * SeasonReward configuration of rewards for a given game season
 * @param collection last deployed GenesisChampion contract before the new season starts
 * @param rewardType enum of type RewardType, can be ERC20|ERC721|ERC1155
 * @param supply quantity of tokens to distribute to players for the upcoming season
 * @param tokenId token ID in case of ERC1155 reward
 * @param claimStart date on which the season starts
 * @param claimEnd date on which season ends
 */
struct SeasonReward {
    address collection;
    uint8 rewardType;
    uint256 supply;
    uint256 tokenId;
    uint256 claimStart;
    uint256 claimEnd;
}
