// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.24;

//  **     **  **       **                    ****   **
// /**    /** /**      //                    /**/   /**
// /**    /** /**       **  ******  ******  ****** ******
// /**    /** /******  /** **////  **////**///**/ ///**/
// /**    /** /**///** /**//***** /**   /**  /**    /**
// /**    /** /**  /** /** /////**/**   /**  /**    /**
// //*******  /******  /** ****** //******   /**    //**
// ///////    /////    // //////   //////    //      //

/**
 * @title Errors
 *
 * @notice Library contains all the custom errors used to revert in Genesis contracts
 */
library Errors {

    /**
     * @notice user has already minted
     */
    error AlreadyMinted();

    /**
     * @notice signature is invalid
     */
    error InvalidSignature();

    /**
     * @notice signature is being used too early
     */
    error SignatureValidityStart();

    /**
     * @notice signature isn't valid anymore
     */
    error SignatureValidityEnd();

    /**
     * @notice signature was created for another chain_id
     */
    error WrongChainID();

    /**
     * @notice baseURI was already set once
     */
    error BaseURIAlreadyInitialized();

    /**
     * @notice token does not exist
     */
    error ERC721UriNonExistent();

    /**
     * @notice MintData.mint_amount cannot be 0
     */
    error InvalidMintAmount();

    /**
     * @notice the token maximum supply is reached
     */
    error MaxSupplyReached();

    /**
     * Chainlink VRF request was already called
     */
    error RequestAlreadyInitialized();

    /**
     * GenesisPFP contract does not own any Link tokens
     */
    error EmptyLinkBalance();

    /**
     * The caller account is not authorized to perform an operation.
     */
    error OwnableUnauthorizedAccount(address account);

    /**
     * Champion used all its craft
     */
    error MaxCraftCount(address collection, uint256 tokenId, uint256 maxCraftCount);

    /**
     * Zero address was passed in function parameter
     */
    error ZeroAddress();

    /**
     * @dev The `account` is missing a role.
     */
    error AccessControlUnauthorizedAccount(address account, bytes32 neededRole);

    /**
     * @dev Parents are the same
     */
    error CraftWithSameParents(address collection, uint256 parentA);

    /**
     * @dev User does not own the token
     */
    error CallerNotOwner(address collection, uint256 parent);

    /**
     * @dev Collection wasn't deployed by the factory
     */
    error CollectionUnknown(address collection);

    /**
     * @dev Payment value `given` was provided in currency `token` doesn't match the required amount `want`
     * @dev token is address(0) in case of OAS or soft currency
     */
    error PaymentValue(address token, uint256 given, uint256 want);

    /**
     * @dev Transfering amount{`value`} of (OAS|ERC20){`token`} to address `vault` failed
     */
    error TransferCraftFees(address token, uint256 value, address vault);

    /**
     * @dev Craft with soft currency but payment value was passed
     */
    error WantSoftGotToken();

    /**
     * @dev Minter supply is already set for the collection
     */
    error SupplyUnregistered(address collection);

    /**
     * @dev Checks the Champion's craft count after executing the craft
     */
    error UnexpectedCraftCount(address collection, uint256 id);
    
    /**
     * @dev Duplicate season setup
     */
    error SeasonAlreadyExist();

    /**
     * @dev Season doesn't exist
     */
    error SeasonUnknown();

    /**
     * @dev Claiming period for the current season is closed
     */
    error ClaimingPeriodClosed();

    /**
     * @dev Craft capacities are locked for a certain time for a Champion
     */
    error ParentCraftLock();

    /**
     * @dev SeasonReward.supply cannot be 0
     */
    error ZeroSupply();

    /**
     * @dev Wrong SeasonReward.claimStart parameter
     */
    error RewardsClaimStart();

    /**
     * @dev Wrong SeasonReward.claimStart parameter
     */
    error RewardsClaimEnd();

    /**
     * @dev Token is already bridged
     */
    error LockedToken(uint256 id);
}
