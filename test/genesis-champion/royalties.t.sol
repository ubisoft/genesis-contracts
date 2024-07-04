// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.24;

import {GenesisChampion_Base_Test} from "./GenesisChampion.t.sol";
import {AccessControl} from "openzeppelinV4/access/AccessControl.sol";
import {IAccessControl} from "openzeppelinV4/access/IAccessControl.sol";
import {GenesisChampion} from "src/GenesisChampion.sol";
import {Errors} from "src/librairies/Errors.sol";

import {MintData} from "src/types/MintData.sol";
import {BaseTest} from "test/Base.t.sol";
import {Events} from "test/utils/Events.sol";

/**
 * @dev Royalties_Test holds all tests related to contract royalties trough ERC2981
 */
contract GenesisChampion_Royalties_Test is GenesisChampion_Base_Test {

    function setUp() public virtual override {
        GenesisChampion_Base_Test.setUp();
        uint256 mint_amount = 100_000;

        vm.startPrank(minter);

        // Mint 100_000 tokens before fuzz test
        assertEq(champion.totalSupply(), 0);
        champion.mint(reserveWallet, mint_amount);
        uint256 balance = champion.balanceOf(reserveWallet);
        assertEq(balance, mint_amount);
        assertEq(champion.totalSupply(), mint_amount);
    }

    /**
     * @dev test royaltyInfo() to compute the royalty amount to transfer based on a salePrice and tokenId
     * @dev royaltyInfo is set globally by using _setDefaultRoyalty
     * @dev using _setTokenRoyalty would oerride the global default
     */
    function test_get_royalty_info() public {
        uint256 salePrice = 1 ether;
        uint256 expectedRoyaltyAmount = 0.09 ether;
        // Compute the royaltyAmount to pay to the vault at each token sale for tokenId 1 and a salePrice of 1 ether
        // royaltyInfo computes the royalty fee using a 9% royalty fee
        (address receiver, uint256 royaltyAmount) = champion.royaltyInfo(1, salePrice);
        assertEq(receiver, address(vault));
        assertEq(royaltyAmount, expectedRoyaltyAmount);
    }

}
