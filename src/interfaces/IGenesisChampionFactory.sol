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

import {GenesisChampionArgs} from "src/types/GenesisChampionArgs.sol";

interface IGenesisChampionFactory {

    /**
     * @notice deploy a new GenesisChampion contract and register it in the deployedVersions array
     * @param _args constructor arguments for GenesisChampion
     */
    function deploy(GenesisChampionArgs calldata _args) external returns (address, uint256);

    /**
     * @notice return the last deployed contract
     */
    function lastDeployment() external returns (address);

    /**
     * @notice return the last deployed version
     */
    function lastVersion() external returns (uint256);

    /**
     * @notice getter for the deployedVersions mapping
     * @param collection address of the token
     */
    function deployedVersions(address collection) external view returns (uint256);
}
