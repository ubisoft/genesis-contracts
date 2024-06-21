// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.24;

import {AuthenticatedRelay_Base_Test} from "../AuthenticatedRelay.t.sol";
import {AuthenticatedRelay, RelayData} from "authenticated-relay/AuthenticatedRelay.sol";
import {Options, Upgrades} from "openzeppelin-foundry-upgrades/Upgrades.sol";
import {AccessControl} from "openzeppelinV4/access/AccessControl.sol";
import {GenesisChampion} from "src/GenesisChampion.sol";
import {GenesisChampionArgs, GenesisChampionFactory} from "src/GenesisChampionFactory.sol";
import {GenesisCrafter} from "src/GenesisCrafter.sol";
import {GenesisMinter} from "src/GenesisMinter.sol";
import {Errors} from "src/librairies/Errors.sol";
import {CraftData} from "src/types/CraftData.sol";
import {MintData as MintDataV2} from "src/types/MintDataV2.sol";
import {Events} from "test/utils/Events.sol";

/**
 * @dev AuthenticatedRelay_Claim_Test holds all tests related to the claim of GenesisChampion NFT through GenesisMinter
 */
contract AuthenticatedRelay_Claim_Test is AuthenticatedRelay_Base_Test {

    function setUp() public virtual override {
        AuthenticatedRelay_Base_Test.setUp();

        vm.startPrank(owner);

        // Disable checks on Proxy Upgrades so we don't need to use --ffi
        Options memory opts;
        opts.unsafeSkipAllChecks = false;

        // Deploy GenesisCrafter proxy and implementation
        address _proxyCrafter = Upgrades.deployUUPSProxy(
            "GenesisCrafter.sol", abi.encodeCall(GenesisCrafter.initialize, (address(factory), address(relay), vault)), opts
        );
        crafterImpl = GenesisCrafter(_proxyCrafter);
        vm.label({account: _proxyCrafter, newLabel: "GenesisCrafterProxy"});

        // Deploy GenesisMinter proxy and implementation
        address _proxyMinter = Upgrades.deployUUPSProxy(
            "GenesisMinter.sol", abi.encodeCall(GenesisMinter.initialize, (address(factory), address(relay))), opts
        );
        minterImpl = GenesisMinter(_proxyMinter);
        vm.label({account: _proxyMinter, newLabel: "GenesisMinterProxy"});

        // Deploy GenesisChampion
        GenesisChampionArgs memory args = GenesisChampionArgs({
            name: "GenesisChampion",
            symbol: "GEN",
            baseURI: "ipfs://Qmbcg4ykX7dTYMdRkfM4yJ8ovHBfqpDuk3GiEjdTKr1uw9/",
            owner: owner,
            minter: address(minterImpl),
            crafter: address(crafterImpl),
            vault: vault,
            endpointL0: endpoints[eid1],
            defaultMaxCraftCount: GENESIS_CHAMP_DEFAULT_MAX_CRAFT_COUNT
        });
        (address deployment,) = factory.deploy(args);
        champion = GenesisChampion(deployment);
        vm.label({account: deployment, newLabel: "GenesisChampion"});

        vm.warp(block.timestamp);

        vm.stopPrank();
    }

    /**
     * @dev mint two tokens to a recipient before testing the craft process
     */
    modifier mintBeforeCraft(address to) {
        bytes memory mintData = abi.encodeWithSelector(GenesisMinter.mint.selector, address(champion), to, 2);
        bytes32 nonce = bytes32(abi.encodePacked("mint-before"));
        RelayData memory data = RelayData({
            nonce: nonce,
            to: address(minterImpl),
            validityStart: block.timestamp,
            validityEnd: block.timestamp + 1 days,
            chainId: block.chainid,
            callData: mintData
        });
        bytes memory sig = get_relay_data_sig(minterPrivateKey, data);
        bytes memory result = relay.relay(data, sig);
        (uint256 first, uint256 last) = abi.decode(result, (uint256, uint256));
        assertEq(champion.balanceOf(to), 2);
        assertEq(first, 1);
        assertEq(last, first + 1);
        _;
    }

    /**
     * @dev register a default SupplyConfig in GenesisMinter before executing the test
     */
    modifier registerSupplyBeforeClaim() {
        vm.prank(owner);
        minterImpl.registerSupply(
            address(champion), GENESIS_CHAMP_INITIAL_HOLDER_SUPPLY, GENESIS_CHAMP_INITIAL_PUBLIC_SUPPLY
        );
        _;
    }

    // =============================================================
    //                   MINT TESTS
    // =============================================================

    /**
     * @dev a user can use the AuthenticatedRelay contract with a back-end generated authorization to call the `claim``
     * method on GenesisMinter and mint multiple NFTs from a GenesisChampion contract using the holder supply
     */
    function test_craft() public mintBeforeCraft(bob) {
        // Send tx as `to`
        vm.startPrank(bob);

        // User owns 2 Champions
        uint256[] memory tokensBefore = champion.tokensOfOwner(bob);
        assertEq(tokensBefore.length, 2);

        // Form the CraftData request
        bytes32 nonce = bytes32(abi.encodePacked("craft-", bob));
        CraftData memory craftData = CraftData({
            to: bob,
            nonce: nonce,
            collection_a: address(champion),
            collection_b: address(champion),
            parent_a: tokensBefore[0],
            parent_b: tokensBefore[1],
            payment_value: 0,
            payment_type: address(0),
            payer: address(0), expected_cc_a: 1,
            expected_cc_b: 1,
            lockPeriod: 1 hours
        });
        bytes memory callData = abi.encodeWithSelector(GenesisCrafter.craft.selector, craftData);
        RelayData memory data = RelayData({
            nonce: nonce,
            to: address(crafterImpl),
            validityStart: block.timestamp,
            validityEnd: block.timestamp + 1 days,
            chainId: block.chainid,
            callData: callData
        });
        bytes memory sig = get_relay_data_sig(minterPrivateKey, data);

        vm.expectEmit(true, false, false, true);
        emit AuthenticatedRelay.SignatureUsed(nonce, false);

        vm.expectEmit();
        emit Events.Transfer(address(0), bob, 3);

        uint256 _now = block.timestamp;
        uint256 _newLock = _now + 1 hours;

        vm.expectEmit(true, true, true, true);
        emit GenesisCrafter.Craft(
            address(champion),
            nonce,
            3,
            address(champion),
            address(champion),
            tokensBefore[0],
            tokensBefore[1]
        );
        relay.relay(data, sig);

        // User now owns 3 Champions
        uint256[] memory tokensAfter = champion.tokensOfOwner(bob);
        assertEq(tokensAfter.length, 3);

        utils_assert_craft_counters(address(champion), tokensAfter[0], 1, 8, _newLock, true);
        utils_assert_craft_counters(address(champion), tokensAfter[1], 1, 8, _newLock, true);
        utils_assert_craft_counters(address(champion), tokensAfter[2], 0, 7, 0, true);

        vm.stopPrank();
    }

    /**
     * @dev relay will revert with `AlreadyUsed` if the user tries to craft a second time with the same nonce
     */
    function test_craft_RevertWhen_nonce_already_used() public mintBeforeCraft(bob) {
        // Send tx as `to`
        vm.startPrank(bob);

        // User owns 2 Champions
        uint256[] memory tokensBefore = champion.tokensOfOwner(bob);
        assertEq(tokensBefore.length, 2);

        // Form the CraftData request
        bytes32 nonce = bytes32(abi.encodePacked("craft-", bob));
        CraftData memory craftData = CraftData({
            to: bob,
            nonce: nonce,
            collection_a: address(champion),
            collection_b: address(champion),
            parent_a: tokensBefore[0],
            parent_b: tokensBefore[1],
            payment_value: 0,
            payment_type: address(0),
            payer: address(0), expected_cc_a: 1,
            expected_cc_b: 1,
            lockPeriod: 1 hours
        });
        bytes memory callData = abi.encodeWithSelector(GenesisCrafter.craft.selector, craftData);
        RelayData memory data = RelayData({
            nonce: nonce,
            to: address(crafterImpl),
            validityStart: block.timestamp,
            validityEnd: block.timestamp + 1 days,
            chainId: block.chainid,
            callData: callData
        });
        bytes memory sig = get_relay_data_sig(minterPrivateKey, data);

        uint256 _now = block.timestamp;
        uint256 _newLock = _now + 1 hours;

        vm.expectEmit(true, false, false, true);
        emit AuthenticatedRelay.SignatureUsed(nonce, false);

        vm.expectEmit();
        emit Events.Transfer(address(0), bob, 3);

        vm.expectEmit(true, true, true, true);
        emit GenesisCrafter.Craft(
            address(champion),
            nonce,
            3,
            address(champion),
            address(champion),
            tokensBefore[0],
            tokensBefore[1]
        );
        relay.relay(data, sig);

        // User now owns 3 Champions
        uint256[] memory tokensAfter = champion.tokensOfOwner(bob);
        assertEq(tokensAfter.length, 3);

        utils_assert_craft_counters(address(champion), tokensAfter[0], 1, 8, _newLock, true);
        utils_assert_craft_counters(address(champion), tokensAfter[1], 1, 8, _newLock, true);
        utils_assert_craft_counters(address(champion), tokensAfter[2], 0, 7, 0, true);

        // Will revert on the second call
        vm.expectRevert(AuthenticatedRelay.AlreadyUsed.selector);
        relay.relay(data, sig);

        vm.stopPrank();
    }

}
