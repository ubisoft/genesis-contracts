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

import {GenesisUpgradeable} from "src/abstracts/GenesisUpgradeable.sol";
import {IGenesisChampion} from "src/interfaces/IGenesisChampion.sol";
import {IGenesisChampionFactory} from "src/interfaces/IGenesisChampionFactory.sol";
import {IGenesisMinter} from "src/interfaces/IGenesisMinter.sol";
import {Errors} from "src/librairies/Errors.sol";
import {MintData} from "src/types/MintDataV2.sol";
import {SupplyConfig} from "src/types/SupplyConfig.sol";

/**
 * @title GenesisMinterV2
 *
 * @notice GenesisMinterV2 is a UUPS proxy implementing supply mechanisms and claim for GenesisChampion tokens
 * @dev This V2 is just an example for upgrade tests
 */
contract GenesisMinterV2 is IGenesisMinter, GenesisUpgradeable {

    // =============================================================
    //                   EVENTS
    // =============================================================

    /// @notice emitted after a successful `claimWithSignature`
    event Claim(address indexed collection, bytes32 indexed nonce, uint256 amount);

    /// @notice emitted after changing the factory address
    event GenesisFactoryUpdate(address oldFactory, address newFactory);

    // =============================================================
    //                   MODIFIERS
    // =============================================================

    modifier validRequestParams(MintData calldata request) {
        // Cannot mint zero tokens
        if (request.amount == 0) revert Errors.InvalidMintAmount();
        // Collection address is address(0)
        if (request.collection == address(0)) revert Errors.ZeroAddress();
        // Collection was deployed by factory
        uint256 index = factory.deployedVersions(request.collection);
        if (index == 0) revert Errors.CollectionUnknown(request.collection);
        _;
    }

    // =============================================================
    //                   CONSTANTS
    // =============================================================

    /// @notice Minter role used for AccessControl
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");

    // =============================================================
    //                   MAPPINGS
    // =============================================================

    /// @notice Supply associated to the initial claim for each collection
    mapping(address => SupplyConfig) public supply;

    // =============================================================
    //                   VARIABLES
    // =============================================================

    /// @notice GenesisChampionFactory contract instance
    IGenesisChampionFactory public factory;

    /// @notice Variable added for upgrade test with gaps
    address public newFactoryContract;

    /// @notice Storage gap for future upgrades
    uint256[47] __gap;

    // =============================================================
    //                   UUPS
    // =============================================================

    function initialize(address factory_, address minter_)
        external
        initializer
    {
        // Initialize upgradeable contracts
        __Ownable_init(_msgSender());
        __AccessControl_init();
        __UUPSUpgradeable_init();
        // Grant DEFAULT_ADMIN_ROLE to owner()
        _grantRole(DEFAULT_ADMIN_ROLE, _msgSender());
        // Grant MINTER_ROLE to minter_
        _grantRole(MINTER_ROLE, minter_);
        // Instantiate the factory and crafter
        require(factory_ != address(0));
        factory = IGenesisChampionFactory(factory_);
    }

    // =============================================================
    //                   PUBLIC
    // =============================================================

    /**
     * @inheritdoc IGenesisMinter
     */
    function claim(MintData calldata request)
        external
        validRequestParams(request)
        onlyRole(MINTER_ROLE)
        returns (uint256 firstId, uint256 lastId)
    {
        // Tokens are still available for mint
        uint256 currentSupply;
        if (request.holder) currentSupply = supply[request.collection].sHolder;
        else currentSupply = supply[request.collection].sPublic;
        if (currentSupply == 0) revert Errors.MaxSupplyReached();

        // Get user allocation
        uint256 allocation = request.amount;
        if (allocation > currentSupply) allocation = currentSupply;

        // Decrement the supply
        request.holder
            ? supply[request.collection].sHolder -= allocation
            : supply[request.collection].sPublic -= allocation;

        // Mint the tokens
        (firstId, lastId) = _mint(request.collection, request.to, allocation);
        emit Claim(request.collection, request.nonce, allocation);
    }

    /**
     * @inheritdoc IGenesisMinter
     */
    function registerSupply(address collection, uint256 holderSupply, uint256 publicSupply) external onlyOwner {
        if (supply[collection].init) revert Errors.SupplyUnregistered(collection);
        supply[collection].sHolder = holderSupply;
        supply[collection].sPublic = publicSupply;
        supply[collection].init = true;
    }

    /**
     * @inheritdoc IGenesisMinter
     */
    function mint(address collection, address to, uint256 amount)
        external
        onlyRole(MINTER_ROLE)
        returns (uint256 firstId, uint256 lastId)
    {
        return _mint(collection, to, amount);
    }

    /**
     * @inheritdoc IGenesisMinter
     */
    function updateFactory(address newFactory) external onlyOwner {
        address currentFactory = address(factory);
        factory = IGenesisChampionFactory(newFactory);
        emit GenesisFactoryUpdate(currentFactory, newFactory);
    }

    /**
     * @inheritdoc GenesisUpgradeable
     */
    function version() external pure override returns (uint256) {
        return 2;
    }

    // =============================================================
    //                   INTERNAL
    // =============================================================

    function _mint(address collection, address to, uint256 amount) internal returns (uint256 firstId, uint256 lastId) {
        IGenesisChampion champion = IGenesisChampion(collection);
        (firstId, lastId) = champion.mint(to, amount);
    }

}
