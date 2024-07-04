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

import {AccessControl} from "openzeppelinV4/access/AccessControl.sol";
import {IERC721} from "openzeppelinV4/token/ERC721/IERC721.sol";
import {ERC2981} from "openzeppelinV4/token/common/ERC2981.sol";
import {ERC721Psi} from "src/ERC721Psi/ERC721Psi.sol";
import {ERC721PsiAddressData} from "src/ERC721Psi/extension/ERC721PsiAddressData.sol";
import {ERC721PsiBurnable} from "src/ERC721Psi/extension/ERC721PsiBurnable.sol";
import {IGenesisBase} from "src/interfaces/IGenesisBase.sol";
import {Errors} from "src/librairies/Errors.sol";

/**
 * @title GenesisBaseV2
 *
 * @dev GenesisBaseV2 implements ERC721Psi as a base for GenesisChampion
 * for GenesisChampion
 */
abstract contract GenesisBaseV2 is IGenesisBase, ERC721PsiAddressData, ERC721PsiBurnable, ERC2981, AccessControl {

    // =============================================================
    //                   EVENTS
    // =============================================================

    /// @notice UpdateDefaultRoyalty is emitted when calling `updateDefaultRoyalty`
    event UpdateDefaultRoyalty(address receiver, uint96 feeNumerator);

    // =============================================================
    //                   CONSTANTS
    // =============================================================

    /// @notice Minter role used for AccessControl
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");

    // =============================================================
    //                   VARIABLES
    // =============================================================

    /// @notice baseURI for computing tokenURI
    string public baseURI;

    // =============================================================
    //                   EXTERNAL
    // =============================================================

    /**
     * @inheritdoc IGenesisBase
     */
    function setBaseURI(string calldata baseURI_) external override onlyRole(DEFAULT_ADMIN_ROLE) {
        if (bytes(baseURI).length > 0) revert Errors.BaseURIAlreadyInitialized();
        baseURI = baseURI_;
    }

    /**
     * @inheritdoc IGenesisBase
     */
    function updateDefaultRoyalty(address receiver, uint96 feeNumerator) external onlyRole(DEFAULT_ADMIN_ROLE) {
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

    function _afterTokenTransfers(address from, address to, uint256 startTokenId, uint256 quantity)
        internal
        virtual
        override(ERC721Psi, ERC721PsiAddressData)
    {
        return ERC721PsiAddressData._afterTokenTransfers(from, to, startTokenId, quantity);
    }

    function _exists(uint256 tokenId) internal view override(ERC721Psi, ERC721PsiBurnable) virtual returns (bool){
        return ERC721PsiBurnable._exists(tokenId);
    }

    function balanceOf(address owner) public view virtual override(ERC721Psi, ERC721PsiAddressData) returns (uint256) {
        return ERC721PsiAddressData.balanceOf(owner);
    }

    function totalSupply() public view virtual override(ERC721Psi, ERC721PsiBurnable) returns (uint256) {
        return ERC721PsiBurnable.totalSupply();
    }

}
