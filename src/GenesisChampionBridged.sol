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

import {MessagingFee, OApp, Origin} from "@layerzerolabs/lz-evm-oapp-v2/contracts/oapp/OApp.sol";
import {MessagingReceipt} from "@layerzerolabs/lz-evm-oapp-v2/contracts/oapp/OAppSender.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {ERC721} from "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import {IERC721Errors} from "@openzeppelin/contracts/interfaces/draft-IERC6093.sol";


/**
 * @title GenesisChampionBridged
 *  
 * @notice Simple ERC721 representation of GenesisChampion tokens after bridging them through Layer Zero
 * This implementation does not implemment any crafting mechanism.
 * 
 * @dev When bridging from Homeverse mainnet, the source token is locked within GenesisChampion.
 * The exact ID number gets minted on the destination chain as a GenesisChampionBridged.
 * 
 * @dev metadataCID should match GenesisChampion's baseURI on Homeverse mainnet
 */
contract GenesisChampionBridged is ERC721, OApp {

    string private metadataCID;

    constructor(string memory _name, string memory _symbol, string memory _metadataCID, address _endpoint, address _delegate)
        ERC721(_name, _symbol)
        OApp(_endpoint, _delegate)
        Ownable(_delegate)
    {
        metadataCID = _metadataCID;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return metadataCID;
    }

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
        if (_ownerOf(_id) != msg.sender) revert IERC721Errors.ERC721InvalidSender(msg.sender);
        _burn(_id);
        bytes memory _payload = abi.encode(_dstTo, _id);
        receipt = _lzSend(_dstEid, _payload, _options, MessagingFee(msg.value, 0), payable(msg.sender));
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
        Origin calldata, /*_origin*/
        bytes32, /*_guid*/
        bytes calldata payload,
        address, /*_executor*/
        bytes calldata /*_extraData*/
    ) internal override {
        (address to, uint256 id) = abi.decode(payload, (address, uint256));
        require(_ownerOf(id) == address(0), "token already exists");
        _safeMint(to, id);
    }

}
