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

import {GenesisBaseV2} from "./abstracts/GenesisBaseV2.sol";
import {IGenesisChampion} from "./interfaces/IGenesisChampion.sol";
import {Errors} from "./librairies/Errors.sol";
import {MessagingFee, OApp, Origin} from "@layerzerolabs/lz-evm-oapp-v2/contracts/oapp/OApp.sol";
import {MessagingReceipt} from "@layerzerolabs/lz-evm-oapp-v2/contracts/oapp/OAppSender.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {Context as ContextV5} from "@openzeppelin/contracts/utils/Context.sol";
import {Context as ContextV4} from "openzeppelinV4/utils/Context.sol";
import {Strings} from "openzeppelinV4/utils/Strings.sol";
import {ERC721Psi} from "src/ERC721Psi/ERC721Psi.sol";
import {ERC721PsiAddressData} from "src/ERC721Psi/extension/ERC721PsiAddressData.sol";
import {GenesisChampionArgs as ConstructorArgs} from "src/types/GenesisChampionArgs.sol";

contract GenesisChampion is GenesisBaseV2, IGenesisChampion, OApp {

    using Strings for uint256;

    /// @notice LzSend is emitted when a token is bridged to another chain
    event LzSend(address to, uint256 id, uint32 toEid);

    /// @notice LzReceive is emitted when a token is bridged from another chain
    event LzReceive(address to, uint256 id, uint32 fromEid);

    // =============================================================
    //                   VARIABLES
    // =============================================================

    /// @inheritdoc IGenesisChampion
    uint256 public immutable defaultMaxCraftCount;

    // =============================================================
    //                   CONSTRUCTOR
    // =============================================================

    /**
     * @dev Initializes the contract
     * @param args GenesisChampion constructor arguments
     */
    constructor(ConstructorArgs memory args)
        ERC721Psi(args.name, args.symbol)
        OApp(args.endpointL0, args.owner)
        Ownable(args.owner)
    {
        // Setup owner and DEFAULT_ADMIN_ROLE
        _setupRole(DEFAULT_ADMIN_ROLE, args.owner);
        // Setup MINTER_ROLE
        if (args.minter != address(0)) _grantRole(MINTER_ROLE, args.minter);
        if (args.crafter != address(0)) _grantRole(MINTER_ROLE, args.crafter);
        // Set royalties to a default 5% using ERC2981
        _setDefaultRoyalty(args.vault, 500);
        // Set baseURI, or call setBaseURI() later if empty arg
        baseURI = args.baseURI;
        // Set the default maximum craft count
        defaultMaxCraftCount = args.defaultMaxCraftCount;
    }

    // =============================================================
    //                   PUBLIC
    // =============================================================

    /**
     * @inheritdoc IGenesisChampion
     */
    function mint(address to, uint256 amount) external onlyRole(MINTER_ROLE) returns (uint256, uint256) {
        uint256 startNextTokenId = _nextTokenId();
        _safeMint(to, amount);
        return (startNextTokenId, _nextTokenId() - 1);
    }

    // =============================================================
    //                   ERC721
    // =============================================================

    /**
     * @inheritdoc ERC721Psi
     */
    function _startTokenId() internal pure override returns (uint256) {
        return 1;
    }

    /**
     * @dev See {IERC721Metadata-tokenURI}.
     */
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        if (!_exists(tokenId)) revert Errors.ERC721UriNonExistent();

        return string(abi.encodePacked(_baseURI(), tokenId.toString(), ".json"));
    }

    // =============================================================
    //                   LAYER ZERO
    // =============================================================

    /**
     * @notice Sends a token from the source chain to a destination chain.
     * @param _dstEid The endpoint ID of the destination chain.
     * @param _dstTo The receiver of the token
     * @param _id The ID of the token
     * @param _options Additional options for message execution.
     * @dev Encodes the message as bytes and sends it using the `_lzSend` internal function.
     * @return receipt A `MessagingReceipt` struct containing details of the message sent.
     */
    function send(uint32 _dstEid, address _dstTo, uint256 _id, bytes calldata _options)
        external
        payable
        returns (MessagingReceipt memory receipt)
    {
        transferFrom(_dstTo, address(this), _id);
        bytes memory _payload = abi.encode(_dstTo, _id);
        receipt = _lzSend(_dstEid, _payload, _options, MessagingFee(msg.value, 0), payable(msg.sender));
        emit LzSend(_dstTo, _id, _dstEid);
    }
    
    /**
     * @notice Quotes the gas needed to pay for the full omnichain transaction in native gas or ZRO token.
     * @param _dstEid Destination chain's endpoint ID.
     * @param _dstTo The receiver of the token
     * @param _id The ID of the token
     * @param _options Message execution options (e.g., for sending gas to destination).
     * @param _payInLzToken Whether to return fee in ZRO token.
     * @return fee A `MessagingFee` struct containing the calculated gas fee in either the native token or ZRO token.
     */
    function quote(uint32 _dstEid, address _dstTo, uint256 _id, bytes memory _options, bool _payInLzToken)
        public
        view
        returns (MessagingFee memory fee)
    {
        bytes memory payload = abi.encode(_dstTo, _id);
        fee = _quote(_dstEid, payload, _options, _payInLzToken);
    }

    /**
     * @dev Internal function override to handle incoming messages from another chain.
     * @dev _origin A struct containing information about the message sender.
     * @dev _guid A unique global packet identifier for the message.
     * @param payload The encoded message payload being received.
     *
     * @dev The following params are unused in the current implementation of the OApp.
     * @dev _executor The address of the Executor responsible for processing the message.
     * @dev _extraData Arbitrary data appended by the Executor to the message.
     *
     * Decodes the received payload and processes it as per the business logic defined in the function.
     */
    function _lzReceive(
        Origin calldata _origin,
        bytes32, /*_guid*/
        bytes calldata payload,
        address, /*_executor*/
        bytes calldata /*_extraData*/
    ) internal override {
        (address to, uint256 id) = abi.decode(payload, (address, uint256));
        require(ownerOf(id) == address(this), "contract doesn't own the token");
        _transfer(address(this), to, id);
        emit LzReceive(to, id, _origin.srcEid);
    }

    // =============================================================
    //                   CONTEXT
    // =============================================================

    function _msgSender() internal view virtual override (ContextV5, ContextV4) returns (address) {
        return ContextV5._msgSender();
    }

    function _msgData() internal view virtual override (ContextV5, ContextV4) returns (bytes calldata) {
        return ContextV5._msgData();
    }

}
