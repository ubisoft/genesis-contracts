// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.18;

import {AccessControl} from "openzeppelin/access/AccessControl.sol";
import {IAccessControl} from "openzeppelin/access/IAccessControl.sol";
import {BaseTest} from "test/Base.t.sol";
import {Events} from "test/utils/Events.sol";
import {Errors} from "src/librairies/Errors.sol";
import {GenesisPFP} from "src/GenesisPFP.sol";
import {GenesisPFP_Base_Test} from "./GenesisPFP.t.sol";
import {MintData} from "src/types/MintData.sol";

/**
 * @dev Royalties_Test holds all tests related to contract royalties trough ERC2981
 */
contract Royalties_Test is GenesisPFP_Base_Test {
    function setUp() public virtual override {
        GenesisPFP_Base_Test.setUp();

        // Mint 9999 tokens before fuzz test
        vm.startPrank(reserveWallet);

        uint256 mint_amount = 9999;
        assertEq(genesis.remainingSupply(), mint_amount);
        bytes32 nonce = bytes32(keccak256(abi.encode(reserveWallet)));
        MintData memory data = MintData({
            to: reserveWallet,
            validity_start: block.timestamp,
            validity_end: 1 days,
            chain_id: block.chainid,
            mint_amount: mint_amount,
            user_nonce: nonce
        });
        bytes memory sig = get_mint_data_sig(minterPrivateKey, data);

        genesis.mintWithSignature(data, sig);
        uint256 balance = genesis.balanceOf(reserveWallet);
        assertEq(balance, mint_amount);
    }

    /**
     * @dev test royaltyInfo() to compute the royalty amount to transfer based on a salePrice and tokenId
     * @dev royaltyInfo is set globally by using _setDefaultRoyalty
     * @dev using _setTokenRoyalty would oerride the global default
     */
    function test_single_token_royalty_info() public {
        uint256 salePrice = 1 ether;
        uint256 expectedRoyaltyAmount = 0.05 ether;
        // Compute the royaltyAmount to pay to the vault at each token sale for tokenId 1 and a salePrice of 1 ether
        // royaltyInfo computes the royalty fee using a 5% royalty fee
        (address receiver, uint256 royaltyAmount) = genesis.royaltyInfo(1, salePrice);
        assertEq(receiver, address(vault));
        assertEq(royaltyAmount, expectedRoyaltyAmount);
    }

    /**
     * @dev Fuzz test royaltyInfo() to compute the royalty amount to transfer based on a salePrice and tokenId
     * @dev royaltyInfo is set globally by using _setDefaultRoyalty
     * @dev using _setTokenRoyalty would oerride the global default
     */
    function test_fuzz_token_royalty_info(uint256 tokenId, uint96 salePrice) public {
        vm.assume(tokenId > 0);
        vm.assume(tokenId < 10000);
        vm.assume(salePrice > 0.01 ether); // min 0.01 ether
        vm.assume(salePrice < 10000000 ether);

        // Compute the royaltyAmount to pay to the vault at each token sale for `tokenId` and a `salePrice`
        // royaltyInfo computes the royalty fee using a 5% royalty fee
        uint256 expectedRoyaltyAmount = (salePrice * 5) / 100;
        (address receiver, uint256 royaltyAmount) = genesis.royaltyInfo(tokenId, salePrice);
        assertEq(receiver, address(vault));
        assertEq(royaltyAmount, expectedRoyaltyAmount);
    }
}
