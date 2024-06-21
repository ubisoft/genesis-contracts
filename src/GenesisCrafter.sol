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

import {IERC20Errors} from "@openzeppelin/contracts/interfaces/draft-IERC6093.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {GenesisUpgradeable} from "src/abstracts/GenesisUpgradeable.sol";
import {IGenesisChampion} from "src/interfaces/IGenesisChampion.sol";
import {IGenesisChampionFactory} from "src/interfaces/IGenesisChampionFactory.sol";
import {IGenesisCrafter} from "src/interfaces/IGenesisCrafter.sol";
import {IGenesisCrafterRule} from "src/interfaces/IGenesisCrafterRule.sol";
import {Errors} from "src/librairies/Errors.sol";
import {CraftCounter} from "src/types/CraftCounter.sol";
import {CraftData} from "src/types/CraftData.sol";

/**
 * @title GenesisCrafter
 *
 * @notice GenesisCrafter is a UUPS proxy implementing crafting mechanisms & rules for all GenesisChampion tokens
 */
contract GenesisCrafter is IGenesisCrafter, GenesisUpgradeable {

    // =============================================================
    //                   EVENTS
    // =============================================================

    /// @notice emitted after a successful crafting
    event Craft(
        address indexed childCollection,
        bytes32 indexed craftNonce,
        uint256 indexed childId,
        address collectionA,
        address collectionB,
        uint256 parentA,
        uint256 parentB
    );

    /// @notice emitted when vault has changed
    event VaultUpdate(address vault);

    /// @notice emitted when individual crafter rule is set
    event SetCrafterRule(address crafterRule, address collection, uint256 id);

    /// @notice emitted when craft fees are paid
    event CraftFees(address vault, address indexed currency, uint256 amount, address from);

    // =============================================================
    //                   MODIFIERS
    // =============================================================

    /// @dev CraftData parameters validation before crafting
    modifier validRequestParams(CraftData calldata request) {
        // Recipient is address(0)
        if (request.to == address(0)) revert Errors.ZeroAddress();
        // payment_value is address(0) (soft currency) but value was passed
        if (request.payment_type == address(0) && request.payment_value > 0) revert Errors.WantSoftGotToken();
        // Parents must be two different entities
        if (request.parent_a == request.parent_b && request.collection_a == request.collection_b) {
            revert Errors.CraftWithSameParents(request.collection_a, request.parent_a);
        }
        _;
    }

    /// @dev verify the craft counts for parent A/B match the new craft counts computed by back-end
    modifier craftCounterEqualsAsExpected(CraftData calldata request) {
        _;
        if (craftCounters[request.collection_a][request.parent_a].craftCount != request.expected_cc_a) {
            revert Errors.UnexpectedCraftCount(request.collection_a, request.parent_a);
        }
        if (craftCounters[request.collection_b][request.parent_b].craftCount != request.expected_cc_b) {
            revert Errors.UnexpectedCraftCount(request.collection_b, request.parent_b);
        }
    }

    // =============================================================
    //                   CONSTANTS
    // =============================================================

    /// @notice Minter role used for AccessControl
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");

    // =============================================================
    //                   MAPPINGS
    // =============================================================

    /**
     * @notice Crafting Rules define the number of craft counts a Champion can use
     * These rules are applied in {_validateCraftConditions} for all Champions
     * Collection-wide or token-specifc crafting rules can be applied using this `craftRule` mapping
     * Collection-wide policies are defined in `craftRule[collection][0]` as ID 0 can never be minted
     * Token-specific policies are defined in `craftRule[collection][id]`
     * Token-specific policies take precedence over Collection-wide policies;
     */
    mapping(address => mapping(uint256 => address)) public craftRule;

    /// @notice craftCounters holds the CraftData of all Champions from any deployed GenesisChampion contract
    mapping(address => mapping(uint256 => CraftCounter)) public craftCounters;

    // =============================================================
    //                   VARIABLES
    // =============================================================

    /// @notice GenesisChampionFactory contract instance
    IGenesisChampionFactory factory;

    /// @notice wallet receiving crafting fees
    address public vault;

    // =============================================================
    //                   UUPS
    // =============================================================

    function initialize(address factory_, address crafter_, address vault_) external initializer {
        // Initialize upgradeable contracts
        __Ownable_init(_msgSender());
        __AccessControl_init();
        __UUPSUpgradeable_init();
        // Grant DEFAULT_ADMIN_ROLE to owner()
        _grantRole(DEFAULT_ADMIN_ROLE, _msgSender());
        // Grant MINTER_ROLE to crafter_
        _grantRole(MINTER_ROLE, crafter_);
        // Instantiate the factory
        factory = IGenesisChampionFactory(factory_);
        // Setup the vault;
        vault = vault_;
    }

    // =============================================================
    //                   EXTERNAL
    // =============================================================

    /**
     * @inheritdoc IGenesisCrafter
     */
    function craft(CraftData calldata request)
        external
        validRequestParams(request)
        onlyRole(MINTER_ROLE)
        craftCounterEqualsAsExpected(request)
    {
        (uint256 newMaxCraftCount, address refParentAddress) = _determineBestParent(
            request.collection_a, request.parent_a, request.collection_b, request.parent_b, request.to
        );

        // Determine the payment type used and process payment if needed
        if (request.payment_type != address(0)) {
            _processCraftFee(request.payment_type, request.payment_value, request.to, request.payer);
        }

        // Consume craftCounter for each parent
        craftCounters[request.collection_a][request.parent_a].craftCount++;
        craftCounters[request.collection_b][request.parent_b].craftCount++;

        // Update the lock period
        if (request.lockPeriod > 0) {
            craftCounters[request.collection_a][request.parent_a].lockedUntil = block.timestamp + request.lockPeriod;
            craftCounters[request.collection_b][request.parent_b].lockedUntil = block.timestamp + request.lockPeriod;
        }

        // Mint a new champion and initialize its craftCounter
        (uint256 tokenId,) = IGenesisChampion(refParentAddress).mint(request.to, 1);
        craftCounters[refParentAddress][tokenId].maxCraftCount = newMaxCraftCount;
        craftCounters[refParentAddress][tokenId].initialized = true;
        emit Craft(
            refParentAddress,
            request.nonce,
            tokenId,
            request.collection_a,
            request.collection_b,
            request.parent_a,
            request.parent_b
        );
    }

    /**
     * @inheritdoc IGenesisCrafter
     */
    function setCrafterRule(address crafterRule, address collection, uint256 id) external onlyOwner {
        craftRule[collection][id] = crafterRule;
        emit SetCrafterRule(crafterRule, collection, id);
    }

    /**
     * @inheritdoc IGenesisCrafter
     */
    function viewMaxCraftCount(address collection, uint256 id) external returns (uint256) {
        if (craftCounters[collection][id].initialized == false) {
            return IGenesisChampion(collection).defaultMaxCraftCount();
        }
        return craftCounters[collection][id].maxCraftCount;
    }

    /**
     * @inheritdoc GenesisUpgradeable
     */
    function version() external pure override returns (uint256) {
        return 1;
    }

    /**
     * @inheritdoc IGenesisCrafter
     */
    function updateVault(address newVault) external onlyOwner {
        vault = newVault;
        emit VaultUpdate(vault);
    }

    // =============================================================
    //                   INTERNAL
    // =============================================================

    /**
     * @notice _determineBestParent verifies which parent is the oldest
     * @param collection_a address of collection_a
     * @param parent_a tokenId of parent_a
     * @param collection_b address of collection_b
     * @param parent_b tokenId of parent_b
     * @param to user receiving the token
     */
    function _determineBestParent(
        address collection_a,
        uint256 parent_a,
        address collection_b,
        uint256 parent_b,
        address to
    ) internal returns (uint256, address) {
        // parent_a can craft
        (uint256 versionA, uint256 maxCraftCountA) = _validateCraftConditions(collection_a, parent_a, to);
        // parent_b can craft
        (uint256 versionB, uint256 maxCraftCountB) = _validateCraftConditions(collection_b, parent_b, to);

        // Collection to mint from is determined by the oldest deployed contract
        // or biggest max craft count if both parents belong to the same contract
        address refParentAddress;
        uint256 refMaxCraftCount;
        if (collection_a == collection_b) {
            // Craft from the same collection, use maxCraftCount{A|B} to determine oldest parent
            refParentAddress = collection_a;
            refMaxCraftCount = maxCraftCountB > maxCraftCountA ? maxCraftCountB : maxCraftCountA;
        } else {
            // Craft from two different collections, use version{A|B} to determine oldest collection and maxCraftCount
            refParentAddress = versionB < versionA ? collection_b : collection_a;
            refMaxCraftCount = versionB < versionA ? maxCraftCountB : maxCraftCountA;
        }
        // maxCraftCount for the new Champion comes from the oldest parent's maxCraftCount - 1
        // if a CrafterRule is set, refMaxCraftCount can eventually be 0 so we need to catch the underflow
        // refMaxCraftCount can never be 0, else will revert
        uint256 newMaxCraftCount = refMaxCraftCount - 1;
        return (newMaxCraftCount, refParentAddress);
    }

    /**
     * @notice _validateCraftConditions verifies the current craftCount, maxCraftCount and lockPeriod for a specific _collection and _id
     * and checks if special crafting rules should apply at a collection-wide or token-specific level
     * @dev returns (uint256 deploymentIndex, uint256 maxCraftCount)
     * @param collection address of the parent token
     * @param id of the parent token
     * @param owner_ of the token
     */
    function _validateCraftConditions(address collection, uint256 id, address owner_)
        internal
        returns (uint256, uint256)
    {
        // Collections was deployed by the factory
        uint256 index = factory.deployedVersions(collection);
        if (index == 0) revert Errors.CollectionUnknown(collection);

        // Verify ownership
        IGenesisChampion champ = IGenesisChampion(collection);
        if (champ.ownerOf(id) != owner_) revert Errors.CallerNotOwner(collection, id);

        // Initialize the parent during its first craft
        _initializeChampionIfRequired(collection, id);
        uint256 maxCraftCount = craftCounters[collection][id].maxCraftCount;

        // Craft can be locked for a certain period of time if specified in the lastest craft request
        if (block.timestamp < craftCounters[collection][id].lockedUntil) revert Errors.ParentCraftLock();

        // Enforce collection-wide or token-specific crafting rules, if applicable
        // type(uint256).max means no override
        uint256 specialMaxCraftCount = type(uint256).max;
        address rule = craftRule[collection][id];
        uint256 ruleId = id;
        // Apply collection-wide rule if no individual rule is specified
        if (rule == address(0)) {
            rule = craftRule[collection][0];
            ruleId = 0;
        }
        if (rule != address(0)) {
            IGenesisCrafterRule ruleImpl = IGenesisCrafterRule(rule);
            specialMaxCraftCount = ruleImpl.validateCraft(collection, ruleId);
            // check craftCount, specialMaxCraftCount overrides maxCraftCount if applicable
            if (
                specialMaxCraftCount != type(uint256).max
                    && craftCounters[collection][id].craftCount >= specialMaxCraftCount
            ) revert Errors.MaxCraftCount(collection, id, specialMaxCraftCount);
        }

        // specialMaxCraftCount doesn't apply, use the registered craftCounters for [collection][id]
        if (specialMaxCraftCount == type(uint256).max && craftCounters[collection][id].craftCount >= maxCraftCount) {
            revert Errors.MaxCraftCount(collection, id, maxCraftCount);
        }
        // return maxCraftCount, we don't want to craft champions with a maxCraftCount based on an external rule
        return (index, maxCraftCount);
    }

    /**
     * @notice determine what currency is used to pay crafting fees and process the payment
     * @dev emits `CraftFee(address, address, uint256, address)` on success, except for soft currency crafts
     * @param currencyAddress address of the payment token
     * @param value craft fee to pay
     * @param crafter address of the user sending the craft request
     * @param payer if applicable, address paying for the operation
     */
    function _processCraftFee(address currencyAddress, uint256 value, address crafter, address payer) internal {
        if (payer != address(0)) _processERC20Payment(payer, currencyAddress, value);
        else _processERC20Payment(crafter, currencyAddress, value);
    }

    /**
     * @notice Pay craft fees with `ERC20.transferFrom` on behalf of the user
     * @dev requires the user's approval
     * @param payer address of the crafter
     * @param token address of the ERC20 used as currency
     * @param value amount to transfer
     */
    function _processERC20Payment(address payer, address token, uint256 value) internal {
        IERC20 erc20 = IERC20(token);
        bool success = erc20.transferFrom(payer, vault, value);
        if (!success) revert Errors.TransferCraftFees(token, value, vault);
        emit CraftFees(vault, token, value, payer);
    }

    /**
     * @dev initialize a champion with its max craft count
     * @param collection address of the champion's contract
     * @param id of the champion
     */
    function _initializeChampionIfRequired(address collection, uint256 id) internal {
        if (!craftCounters[collection][id].initialized) {
            craftCounters[collection][id].initialized = true;
            craftCounters[collection][id].maxCraftCount = IGenesisChampion(collection).defaultMaxCraftCount();
        }
    }

}
