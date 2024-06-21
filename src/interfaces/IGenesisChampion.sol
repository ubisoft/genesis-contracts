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

import {IGenesisBase} from "./IGenesisBase.sol";
import {IERC721} from "openzeppelinV4/token/ERC721/IERC721.sol";

/**
 * @title IGenesisChampion
 *
 * @notice Interface for the GenesisChampion contract, implementing minting and signature verification
 */
interface IGenesisChampion is IGenesisBase, IERC721 {

    /**
     * @notice mint allows an authorized MINTER_ROLE address to mint any amount of tokens for a recipient
     * @dev returns the first and last ID of tokens minted
     * @param to address of the recipient
     * @param amount of tokens to mint
     */
    function mint(address to, uint256 amount) external returns (uint256, uint256);

    /**
     * @notice defaultMaxCraftCount for each gen0 Champion
     */
    function defaultMaxCraftCount() external returns (uint256);
}
