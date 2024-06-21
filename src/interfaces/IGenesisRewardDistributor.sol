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

import {RewardClaim} from "src/types/RewardClaim.sol";
import {SeasonReward} from "src/types/SeasonReward.sol";

/**
 * @title IGenesisRewardDistributor
 *
 * @notice Interface for the GenesisRewardDistributor contract
 */
interface IGenesisRewardDistributor {

    /**
     * @notice allows a user to claim rewards from the current season
     * @dev must be called by AuthenticatedRelay providing an authorization signature
     * @param request RewardClaim describing the reward allocated to a user
     */
    function claim(RewardClaim memory request) external;

    /**
     * @notice allows the contract admin to create a configuration for the upcoming SeasonReward
     * @param season season for which we distribute seasons
     * @param newSeasonReward configuration of the rewards
     */
    function allocate(uint256 season, SeasonReward calldata newSeasonReward) external;

}
