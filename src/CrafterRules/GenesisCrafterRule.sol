// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.8.24;

import {IGenesisChampionFactory} from "src/interfaces/IGenesisChampionFactory.sol";
import {IGenesisCrafterRule} from "src/interfaces/IGenesisCrafterRule.sol";
import {IERC721} from "openzeppelinV4/token/ERC721/IERC721.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

/**
 * @title GenesisCrafterRule
 *
 * @notice Implements specific craft rules for individual tokens, i.e. disable crafting
 */
contract GenesisCrafterRule is IGenesisCrafterRule, Ownable {

    event MaxCraftCountUpdate(address collection, uint256 id, uint256 val);

    // =============================================================
    //                   MODIFIERS
    // =============================================================

    modifier collectionExists(address collection) {
        // Collections was deployed by the factory
        require(address(factory) != address(0));
        require(factory.deployedVersions(collection) > 0);
        _;
    }

    // =============================================================
    //                   MAPPINGS
    // =============================================================

    mapping(address collection => mapping(uint256 tokenId => uint256 maxCraftCount)) private maxCraftCounts;

    // =============================================================
    //                   VARIABLES
    // =============================================================

    IGenesisChampionFactory private factory;

    // =============================================================
    //                   CONSTRUCTOR
    // =============================================================

    constructor(address owner_, address factory_) Ownable(owner_) {
        factory = IGenesisChampionFactory(factory_);
    }

    // =============================================================
    //                   EXTERNAL
    // =============================================================

    /**
     * @inheritdoc IGenesisCrafterRule
     */
    function validateCraft(address collection, uint256 id)
        public
        view
        collectionExists(collection)
        returns (uint256)
    {
        // Anything can happen here
        // i.e. consume a token to increase max craft count?
        return maxCraftCounts[collection][id];
    }

    /**
     * @inheritdoc IGenesisCrafterRule
     */
    function setMaxCraftCount(address collection, uint256 id, uint256 val) public onlyOwner collectionExists(collection) {
        maxCraftCounts[collection][id] = val;
        emit MaxCraftCountUpdate(collection, id, val);
    }

}
