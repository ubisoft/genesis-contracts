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

import {MintData} from "src/types/MintDataV2.sol";

/**
 * @title IGenesisMinter
 *
 * @notice Interface for the GenesisMinter contract, implementing minting and signature verification
 * for all GenesisChampion NFT collections deployed by the GenesisChampionFactory
 */
interface IGenesisMinter {

    /**
     * @notice allows a user to claim a token with a valid signature
     * @dev signature must be signed by an address with MINTER_ROLE
     * @dev returns minted id in range between [firstId, lastId]
     * @param request MintData object describing the mint request
     */
    function claim(MintData calldata request)
        external
        returns (uint256 firstId, uint256 lastId);

    /**
     * @notice allows a contract to arbitrarily mint many tokens
     * @dev returns a range of token IDs minted [firstId,lastId]
     * @param collection address of the target GenesisChampion contract
     * @param to recipient of the mint
     * @param amount of token to mint
     */
    function mint(address collection, address to, uint256 amount) external returns (uint256 firstId, uint256 lastId);

    /**
     * @notice updates the current factory address to `newFactory`
     * @param newFactory address of the new factory
     */
    function updateFactory(address newFactory) external;

    /**
     * @notice register a new supply configuration for a primary mint
     * @param collection address of the Champion collection
     * @param holderSupply amout of tokens available for holders mint
     * @param publicSupply amount of tokens available for public mint
     */
    function registerSupply(address collection, uint256 holderSupply, uint256 publicSupply) external;
}
