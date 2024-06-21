// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.24;

import {GenesisMinter_Base_Test} from "./GenesisMinter.t.sol";
import {IAccessControl} from "@openzeppelin/contracts/access/IAccessControl.sol";
import {GenesisChampion} from "src/GenesisChampion.sol";
import {GenesisChampionFactory} from "src/GenesisChampionFactory.sol";
import {Errors} from "src/librairies/Errors.sol";
import {GenesisChampionArgs} from "src/types/GenesisChampionArgs.sol";
import {MintData} from "src/types/MintDataV2.sol";
import {Events} from "test/utils/Events.sol";

/**
 * @dev GenesisMinter_Mint_Test holds all tests related to minting from a MINTER_ROLE wallet
 */
contract GenesisMinter_Mint_Test is GenesisMinter_Base_Test {

    function setUp() public virtual override {
        GenesisMinter_Base_Test.setUp();
    }

    // =============================================================
    //                   MINT TESTS
    // =============================================================

    /**
     * @dev caller with MINTER_ROLE can call `mint`
     */
    function test_mint() public {
        vm.startPrank(minter);

        // caller can mint on all deployments registered by the factory
        for (uint256 i = 0; i < deployments.length - 1; i++) {
            GenesisChampion impl = GenesisChampion(deployments[i]);
            // to should have an empty balance before mint
            assertEq(impl.balanceOf(reserveWallet), 0);

            // Mint arbitrary amount of tokens
            minterImpl.mint(address(impl), reserveWallet, GENESIS_CHAMP_RESERVE_MINT);

            // `to` should own `amount` tokens in its balance after mint
            assertEq(impl.balanceOf(reserveWallet), GENESIS_CHAMP_RESERVE_MINT);
        }
    }

    /**
     * @dev caller without MINTER_ROLE cannot call `mint`
     */
    function test_mint_RevertWhen_AccessControlUnauthorizedAccount() public {
        vm.startPrank(bob);

        // caller can mint on all deployments registered by the factory
        for (uint256 i = 0; i < deployments.length - 1; i++) {
            GenesisChampion impl = GenesisChampion(deployments[i]);
            // to should have an empty balance before mint
            assertEq(impl.balanceOf(bob), 0);

            // Mint arbitrary amount of tokens
            vm.expectRevert(
                abi.encodeWithSelector(
                    IAccessControl.AccessControlUnauthorizedAccount.selector, bob, minterImpl.MINTER_ROLE()
                )
            );
            minterImpl.mint(address(impl), bob, GENESIS_CHAMP_CLAIM_PUBLIC);

            // `to` should own `amount` tokens in its balance after mint
            assertEq(impl.balanceOf(bob), 0);
        }
        vm.stopPrank();
    }

}
