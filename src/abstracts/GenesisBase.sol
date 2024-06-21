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

import {AccessControl} from "openzeppelinV4/access/AccessControl.sol";

import {IAccessControl} from "openzeppelinV4/access/IAccessControl.sol";

import {Ownable} from "openzeppelinV4/access/Ownable.sol";
import {IERC721} from "openzeppelinV4/token/ERC721/IERC721.sol";
import {IERC721Metadata} from "openzeppelinV4/token/ERC721/extensions/IERC721Metadata.sol";
import {ERC2981} from "openzeppelinV4/token/common/ERC2981.sol";
import {EIP712} from "openzeppelinV4/utils/cryptography/EIP712.sol";
import {ERC721Psi} from "src/ERC721Psi/ERC721Psi.sol";
import {ERC721PsiAddressData} from "src/ERC721Psi/extension/ERC721PsiAddressData.sol";

import {IGenesisBase} from "src/interfaces/IGenesisBase.sol";
import {Errors} from "src/librairies/Errors.sol";
import {MintData} from "src/types/MintData.sol";

/**
 * @title GenesisBase
 *
 * @dev GenesisBase implements ERC721Psi as a base for GenesisPFP
 */
abstract contract GenesisBase is IGenesisBase, ERC721PsiAddressData, ERC2981, EIP712, Ownable, AccessControl {

    // =============================================================
    //                   EVENTS
    // =============================================================

    /// @notice UpdateDefaultRoyalty is emitted when calling `updateDefaultRoyalty`
    event UpdateDefaultRoyalty(address receiver, uint96 feeNumerator);

    // =============================================================
    //                   VARIABLES
    // =============================================================

    /// @notice baseURI for computing tokenURI
    string public baseURI;

    // =============================================================
    //                   MAPPINGS
    // =============================================================

    /// @notice Mapping for an address to a bool
    /// @notice Tracks if a user minted its tokens
    mapping(bytes32 => bool) public minted;

    // =============================================================
    //                   EXTERNAL
    // =============================================================

    /**
     * @inheritdoc IGenesisBase
     */
    function setBaseURI(string calldata _uri) external override onlyOwner {
        if (bytes(baseURI).length > 0) revert Errors.BaseURIAlreadyInitialized();
        baseURI = _uri;
    }

    /**
     * @inheritdoc IGenesisBase
     */
    function updateDefaultRoyalty(address receiver, uint96 feeNumerator) external onlyOwner {
        _setDefaultRoyalty(receiver, feeNumerator);
        emit UpdateDefaultRoyalty(receiver, feeNumerator);
    }

    // =============================================================
    //                   PUBLIC
    // =============================================================

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override (ERC721Psi, ERC2981, AccessControl)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }

    // =============================================================
    //                   INTERNAL
    // =============================================================

    /**
     * @dev Base URI for computing {tokenURI}. If set, the resulting URI for each
     * token will be the concatenation of the `baseURI` and the `tokenId`. Empty
     * by default, can be overriden in child contracts.
     */
    function _baseURI() internal view override returns (string memory) {
        return baseURI;
    }

}
