// SPDX-License-Identifier: APACHE-2.0
pragma solidity 0.8.24;

//  **     **  **       **                    ****   **
// /**    /** /**      //                    /**/   /**
// /**    /** /**       **  ******  ******  ****** ******
// /**    /** /******  /** **////  **////**///**/ ///**/
// /**    /** /**///** /**//***** /**   /**  /**    /**
// /**    /** /**  /** /** /////**/**   /**  /**    /**
// //*******  /******  /** ****** //******   /**    //**
// ///////    /////    // //////   //////    //      //

import {AccessControl} from "@openzeppelin/contracts/access/AccessControl.sol";
import {IERC1155} from "forge-std/interfaces/IERC1155.sol";
import {IERC20} from "forge-std/interfaces/IERC20.sol";
import {IERC721} from "forge-std/interfaces/IERC721.sol";
import {IGenesisRewardDistributor} from "src/interfaces/IGenesisRewardDistributor.sol";
import {Errors} from "src/librairies/Errors.sol";
import {RewardClaim} from "src/types/RewardClaim.sol";
import {SeasonReward} from "src/types/SeasonReward.sol";

enum RewardType {
    ERC20,
    ERC721,
    ERC1155
}

interface IERC20MintableReward {

    function mint(address to, uint256 amount) external;

}

interface IERC721MintableReward {

    function mint(address to, uint256 tokenId) external;

}

interface IERC1155MintableReward {

    function mint(address to, uint256 tokenId, uint256 amount, bytes calldata data) external;

}

/**
 * @title GenesisRewardDistributor
 *
 * @notice handles the allocation and claiming of rewards after a game season
 */
contract GenesisRewardDistributor is IGenesisRewardDistributor, AccessControl {

    /// @notice NewSeasonReward is emitted when a new SeasonReward is set
    event NewSeasonReward(uint256 season);

    /// @notice ClaimReward is emitted when a user claims its SeasonReward
    event ClaimReward(bytes32 nonce, address to);

    // =============================================================
    //                   MODIFIERS
    // =============================================================

    modifier validSeasonConfig(uint256 season, SeasonReward calldata newSeason) {
        // Season already exists
        if (rewards[season].claimStart != 0) revert Errors.SeasonAlreadyExist();
        // Claiming phase must be created ahead of time
        if (block.timestamp >= newSeason.claimStart) revert Errors.RewardsClaimStart();
        // Claiming end must be after claimStart
        if (newSeason.claimStart > newSeason.claimEnd) revert Errors.RewardsClaimEnd();
        // Rewards must be greater than 0
        if (newSeason.supply == 0) revert Errors.ZeroSupply();
        // Reward collectio cnanot be address(0)
        if (newSeason.collection == address(0)) revert Errors.ZeroAddress();
        _;
    }

    // =============================================================
    //                   CONSTANTS
    // =============================================================

    bytes32 constant MINTER_ROLE = keccak256("MINTER_ROLE");

    // =============================================================
    //                   VARIABLES
    // =============================================================

    /// @notice rewards is the supply configuration for a specific period
    mapping(uint256 season => SeasonReward rewardConfig) public rewards;

    // =============================================================
    //                   CONSTRUCTOR
    // =============================================================

    constructor(address _minter) {
        // Default admin
        _grantRole(DEFAULT_ADMIN_ROLE, _msgSender());
        // MINTER_ROLE can allocate rewards for a season
        _grantRole(MINTER_ROLE, _minter);
    }

    // =============================================================
    //                   EXTERNAL
    // =============================================================

    /**
     * @inheritdoc IGenesisRewardDistributor
     */
    function allocate(uint256 season, SeasonReward calldata newSeasonReward)
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
        validSeasonConfig(season, newSeasonReward)
    {
        rewards[season] = newSeasonReward;
        emit NewSeasonReward(season);
    }

    /**
     * @inheritdoc IGenesisRewardDistributor
     */
    function claim(RewardClaim memory request) external onlyRole(MINTER_ROLE) {
        uint256 season = request.season;
        SeasonReward storage currentSeason = rewards[season];
        // Season must exist
        if (currentSeason.collection == address(0) && currentSeason.claimStart == 0 && currentSeason.supply == 0) {
            revert Errors.SeasonUnknown();
        }
        // Claim is still opened
        if (block.timestamp < currentSeason.claimStart || block.timestamp > currentSeason.claimEnd) {
            revert Errors.ClaimingPeriodClosed();
        }

        // Revert if all rewards were claimed for the current season
        uint256 claimable = currentSeason.supply;
        if (claimable == 0) revert Errors.MaxSupplyReached();

        // Get the user allocation
        uint256 allocation = request.amount;
        if (allocation > claimable) allocation = claimable;

        // Decrease the season allocation
        currentSeason.supply -= allocation;

        // Mint the reward following its type
        if (currentSeason.rewardType == uint8(RewardType.ERC20)) {
            IERC20MintableReward(currentSeason.collection).mint(request.to, request.amount);
        } else if (currentSeason.rewardType == uint8(RewardType.ERC721)) {
            IERC721MintableReward(currentSeason.collection).mint(request.to, request.amount);
        } else {
            IERC1155MintableReward(currentSeason.collection).mint(request.to, currentSeason.tokenId, request.amount, "");
        }
        emit ClaimReward(request.nonce, request.to);
    }

}
