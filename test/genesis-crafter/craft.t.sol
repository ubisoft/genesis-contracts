// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.24;

import {GenesisCrafter_Base_Test} from "./GenesisCrafter.t.sol";
import {IAccessControl} from "@openzeppelin/contracts/access/IAccessControl.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {VmSafe} from "forge-std/Vm.sol";
import {MockERC20} from "forge-std/mocks/MockERC20.sol";
import {AccessControl} from "openzeppelinV4/access/AccessControl.sol";
import {GenesisCrafterRule} from "src/CrafterRules/GenesisCrafterRule.sol";
import {GenesisChampion} from "src/GenesisChampion.sol";
import {GenesisChampionFactory} from "src/GenesisChampionFactory.sol";
import {Errors} from "src/librairies/Errors.sol";
import {CraftData} from "src/types/CraftData.sol";
import {BaseTest} from "test/Base.t.sol";
import {Events} from "test/utils/Events.sol";

/**
 * @dev GenesisCrafter_Craft_Test holds all tests related to crafting
 */
contract GenesisCrafter_Craft_Test is GenesisCrafter_Base_Test {

    uint16 internal constant NUM_USERS = 2;
    uint16 internal constant PUBLIC_ALLOC = 2;

    address[] internal users;
    uint256[] internal usersPk;

    GenesisChampion internal gen0;
    GenesisChampion internal gen1;
    Token_ERC20 internal token;

    modifier prank(address caller) {
        vm.startPrank(caller);
        _;
        vm.stopPrank();
    }

    function get_default_max_craft_count(address collection) internal view returns (uint256) {
        GenesisChampion impl = GenesisChampion(collection);
        return impl.defaultMaxCraftCount();
    }

    function get_new_locked_until(uint256 lockTime) internal view returns (uint256, uint256) {
        uint256 _now = block.timestamp;
        uint256 _newLock = _now + lockTime;
        return (_now, _newLock);
    }

    function setUp() public virtual override {
        GenesisCrafter_Base_Test.setUp();

        // Change the current timetamp
        vm.warp(1712130000);

        // Setup users
        for (uint256 i = 0; i < NUM_USERS; i++) {
            uint256 pk = 0xFFFFFF + i;
            usersPk.push(pk);
            users.push(vm.addr(pk));
        }

        // 2 versions should be deployed
        assertEq(deployments.length, NUM_DEPLOYMENTS);

        // Mint 3 tokens for all users
        vm.startPrank(minter);
        for (uint256 i = 0; i < deployments.length; i++) {
            for (uint256 j = 0; j < NUM_USERS; j++) {
                minterImpl.mint(deployments[i], users[j], PUBLIC_ALLOC);
                assertEq(GenesisChampion(deployments[i]).balanceOf(users[j]), PUBLIC_ALLOC);
            }
        }
        vm.stopPrank();

        // Gen 0 contract
        gen0 = GenesisChampion(deployments[0]);
        vm.label({account: address(gen0), newLabel: "Gen0 Champion"});
        // Gen 1 contract
        gen1 = GenesisChampion(deployments[1]);
        vm.label({account: address(gen1), newLabel: "Gen1 Champion"});

        // MockERC20
        vm.startPrank(owner);
        token = new Token_ERC20("WrappedOAS", "wOAS", 18);
        token.mint(owner, 1e18);
        vm.stopPrank();
    }

    /// @dev User with MINTER_ROLE can craft a new Champion with parents from same collection
    function test_craft() public prank(minter) {
        address to = users[0];
        bytes32 nonce = bytes32(abi.encodePacked("craft-parent"));

        // gen0 balance before craft is `PUBLIC_ALLOC`
        uint256[] memory idsGen0 = gen0.tokensOfOwner(to);
        assertEq(idsGen0.length, PUBLIC_ALLOC);
        uint256 nextId = gen0.totalSupply() + 1;

        CraftData memory request = CraftData({
            to: to,
            nonce: nonce,
            collection_a: address(gen0),
            collection_b: address(gen0),
            parent_a: idsGen0[0],
            parent_b: idsGen0[1],
            payment_value: 0,
            payment_type: address(0),
            payer: address(0),
            expected_cc_a: 1,
            expected_cc_b: 1,
            lockPeriod: 1 hours
        });

        (,uint256 _newLock) = get_new_locked_until(1 hours);

        vm.expectEmit();
        emit Events.Transfer(address(0), to, nextId);
        vm.expectEmit();
        emit Events.Craft(address(gen0), nonce, nextId, address(gen0), address(gen0), idsGen0[0], idsGen0[1]);
        crafterImpl.craft(request);

        // Craft counters increased
        utils_assert_craft_counters(address(gen0), idsGen0[0], 1, 8, _newLock, true);
        utils_assert_craft_counters(address(gen0), idsGen0[1], 1, 8, _newLock, true);

        // Balance increased by one
        assertEq(gen0.balanceOf(to), idsGen0.length + 1);
        idsGen0 = gen0.tokensOfOwner(to);
        assertEq(idsGen0[2], nextId);

        // Craft counter for child is initialized with parent's (maxCraftCount - 1)
        utils_assert_craft_counters(address(gen0), idsGen0[2], 0, 7, 0, true);
    }

    /// @dev User without MINTER_ROLE cannot craft
    function test_craft_RevertWhen_caller_lacks_minter_role() public prank(users[0]) {
        address to = users[0];
        bytes32 nonce = bytes32(abi.encodePacked("craft"));

        // gen0 balance before craft is `PUBLIC_ALLOC`
        uint256[] memory idsGen0 = gen0.tokensOfOwner(to);
        assertEq(idsGen0.length, PUBLIC_ALLOC);
        uint256 nextId = gen0.totalSupply() + 1;

        CraftData memory request = CraftData({
            to: to,
            nonce: nonce,
            collection_a: address(gen0),
            collection_b: address(gen0),
            parent_a: idsGen0[0],
            parent_b: idsGen0[1],
            payment_value: 0,
            payment_type: address(0),
            payer: address(0),
            expected_cc_a: 0,
            expected_cc_b: 0,
            lockPeriod: 1 hours
        });

        vm.expectRevert(
            abi.encodeWithSelector(IAccessControl.AccessControlUnauthorizedAccount.selector, users[0], MINTER_ROLE)
        );
        crafterImpl.craft(request);

        // Craft counters didn't change
        utils_assert_craft_counters(address(gen0), idsGen0[0], 0, 0, 0, false);
        utils_assert_craft_counters(address(gen0), idsGen0[1], 0, 0, 0, false);
    }

    /// @dev should revert when crafting with two same parents
    function test_craft_RevertWhen_not_validRequestParams_same_parents() public prank(users[0]) {
        address to = users[0];
        // balance before craft is `PUBLIC_ALLOC`
        uint256[] memory ids = gen0.tokensOfOwner(to);
        assertEq(ids.length, PUBLIC_ALLOC);

        CraftData memory request = CraftData({
            to: to,
            nonce: bytes32(abi.encodePacked("craft-user-", to)),
            collection_a: address(gen0),
            collection_b: address(gen0),
            parent_a: ids[0],
            parent_b: ids[0],
            payment_value: 0,
            payment_type: address(0),
            payer: address(0),
            expected_cc_a: 8,
            expected_cc_b: 8,
            lockPeriod: 1 hours
        });

        vm.expectRevert(abi.encodeWithSelector(Errors.CraftWithSameParents.selector, address(gen0), ids[0]));
        crafterImpl.craft(request);

        // Craft counters didn't change
        utils_assert_craft_counters(address(gen0), ids[0], 0, 0, 0, false);
        utils_assert_craft_counters(address(gen0), ids[1], 0, 0, 0, false);

        // Balance after didn't change
        assertEq(gen0.balanceOf(to), ids.length);
    }

    /// @dev should revert is user crafts with someone else's champion
    function test_craft_RevertWhen_not_owner_of() public prank(minter) {
        // Try crafting with a champion not owned by users[0]
        address to = users[0];

        // User 0's tokens
        uint256[] memory ids0 = gen0.tokensOfOwner(to);
        assertEq(ids0.length, PUBLIC_ALLOC);

        // User 1's tokens
        uint256[] memory ids1 = gen0.tokensOfOwner(users[1]);
        assertEq(ids1.length, PUBLIC_ALLOC);

        CraftData memory request = CraftData({
            to: to,
            nonce: bytes32(abi.encodePacked("craft-user-", to)),
            collection_a: address(gen0),
            collection_b: address(gen0),
            parent_a: ids0[0],
            parent_b: ids1[0],
            payment_value: 0,
            payment_type: address(0),
            payer: address(0),
            expected_cc_a: 0,
            expected_cc_b: 0,
            lockPeriod: 1 hours
        });

        vm.expectRevert(abi.encodeWithSelector(Errors.CallerNotOwner.selector, address(gen0), ids1[0]));
        crafterImpl.craft(request);

        // Craft counters didn't change
        utils_assert_craft_counters(address(gen0), ids0[0], 0, 0, 0, false);
        utils_assert_craft_counters(address(gen0), ids1[0], 0, 0, 0, false);

        // Balance after didn't change
        assertEq(gen0.balanceOf(to), ids0.length);
    }

    /// @notice should revert when maxCraftCount for a parent is reached
    function test_craft_RevertWhen_max_craft_count() public prank(minter) {
        address to = users[0];

        // balance before craft is `PUBLIC_ALLOC`
        uint256[] memory idsBefore = gen0.tokensOfOwner(to);
        assertEq(idsBefore.length, PUBLIC_ALLOC, "should be 2");

        // Craft counters should not be initialized
        utils_assert_craft_counters(address(gen0), idsBefore[0], 0, 0, 0, false);
        utils_assert_craft_counters(address(gen0), idsBefore[1], 0, 0, 0, false);

        uint256[] memory idsLockedUntil = new uint256[](9);
        // Craft until we reach maxCraftCount
        for (uint256 i = 1; i < 9; i++) {
            bytes32 nonce_ = bytes32(i);
            uint256 nextId = gen0.totalSupply() + 1;
            CraftData memory request = CraftData({
                to: to,
                nonce: nonce_,
                collection_a: address(gen0),
                collection_b: address(gen0),
                parent_a: idsBefore[0],
                parent_b: idsBefore[1],
                payment_value: 0,
                payment_type: address(0),
                payer: address(0),
                expected_cc_a: i,
                expected_cc_b: i,
                lockPeriod: 1 hours
            });
    
            (uint256 _now,uint256 _newLock) = get_new_locked_until(1 hours);
            idsLockedUntil[0] = _newLock;
            idsLockedUntil[1] = _newLock;

            vm.expectEmit();
            emit Events.Transfer(address(0), to, nextId);
            vm.expectEmit();
            emit Events.Craft(address(gen0), nonce_, nextId, address(gen0), address(gen0), idsBefore[0], idsBefore[1]);
            crafterImpl.craft(request);

            // balance incremented by 1
            uint256[] memory ids = gen0.tokensOfOwner(to);
            assertEq(ids.length, idsBefore.length + i);
            assertEq(ids[ids.length - 1], nextId);

            // Craft counter were updated
            utils_assert_craft_counters(
                address(gen0), idsBefore[0], i, get_default_max_craft_count(address(gen0)), idsLockedUntil[0], true
            );
            utils_assert_craft_counters(
                address(gen0), idsBefore[1], i, get_default_max_craft_count(address(gen0)), idsLockedUntil[1], true
            );
            vm.warp(_now + 62 minutes);
            assertGt(block.timestamp, _newLock, "new timestmap not greather than _newLock");
        }

        uint256[] memory newIds = gen0.tokensOfOwner(to);
        assertEq(newIds.length, 10); // 2 initial tokens + 8 from crafting
        utils_assert_craft_counters(address(gen0), newIds[0], 8, get_default_max_craft_count(address(gen0)), idsLockedUntil[0], true);
        utils_assert_craft_counters(address(gen0), newIds[1], 8, get_default_max_craft_count(address(gen0)), idsLockedUntil[1], true);

        // Crafting with parentA will revert
        {
            bytes32 nonce_ = bytes32("will-revert-1");
            CraftData memory request = CraftData({
                to: to,
                nonce: nonce_,
                collection_a: address(gen0),
                collection_b: address(gen0),
                parent_a: newIds[0],
                parent_b: newIds[2],
                payment_value: 0,
                payment_type: address(0),
                payer: address(0),
                expected_cc_a: 8,
                expected_cc_b: 8,
                lockPeriod: 1 hours
            });

            vm.expectRevert(
                abi.encodeWithSelector(
                    Errors.MaxCraftCount.selector, address(gen0), newIds[0], get_default_max_craft_count(address(gen0))
                )
            );
            crafterImpl.craft(request);
        }

        // Crafting with parentB will revert
        {
            bytes32 nonce_ = bytes32("will-revert-2");
            CraftData memory request = CraftData({
                to: to,
                nonce: nonce_,
                collection_a: address(gen0),
                collection_b: address(gen0),
                parent_a: newIds[1],
                parent_b: newIds[2],
                payment_value: 0,
                payment_type: address(0),
                payer: address(0),
                expected_cc_a: 8,
                expected_cc_b: 8,
                lockPeriod: 1 hours
            });

            vm.expectRevert(
                abi.encodeWithSelector(
                    Errors.MaxCraftCount.selector, address(gen0), newIds[1], get_default_max_craft_count(address(gen0))
                )
            );
            crafterImpl.craft(request);
        }
    }

    /// @notice should revert when a special CrafterRule has been set (i.e. disable crafting on an individual token)
    function test_craft_with_craft_rules() public {
        // Deploy a specific CrafterRule contract that restricts ids[0] to craft
        vm.startPrank(owner);
        vm.expectEmit();
        emit OwnershipTransferred({previousOwner: address(0), newOwner: address(owner)});
        GenesisCrafterRule rules = new GenesisCrafterRule(owner, address(factory));

        // balance before craft is `PUBLIC_ALLOC`
        address to = users[1];
        uint256[] memory idsBefore = gen0.tokensOfOwner(to);
        assertEq(idsBefore.length, PUBLIC_ALLOC, "should be 2");

        // Setup a global craft rule
        {
            vm.recordLogs();
            rules.setMaxCraftCount(address(gen0), 0, 0);
            crafterImpl.setCrafterRule(address(rules), address(gen0), 0);
            vm.stopPrank();

            // Retrieve the logs
            VmSafe.Log[] memory entries = vm.getRecordedLogs();
            assertEq(entries.length, 2, "more than 2 entries");

            // emit MaxCraftCountUpdate(address(gen0), 0, 0);
            {
                assertEq(entries[0].topics.length, 1, "topics 0 length");
                assertEq(entries[0].topics[0], Events.MaxCraftCountUpdate.selector, "topics 0 selector");
                (address championAddress, uint256 tokenId, uint256 maxCraftCount) =
                    abi.decode(entries[0].data, (address, uint256, uint256));
                assertEq(championAddress, address(gen0), "championAddress");
                assertEq(tokenId, 0, "token 0");
                assertEq(maxCraftCount, 0, "maxCraftCount");
            }
            // emit Events.setCrafterRule(address(rules), address(gen0), 0);
            {
                assertEq(entries[1].topics.length, 1, "topics 1 length");
                assertEq(entries[1].topics[0], Events.SetCrafterRule.selector, "topics 1 selector");
                (address rulesAddress, address championAddress, uint256 tokenId) =
                    abi.decode(entries[1].data, (address, address, uint256));
                assertEq(rulesAddress, address(rules), "rulesAddress");
                assertEq(championAddress, address(gen0), "championAddress");
                assertEq(tokenId, 0, "tokenId");
            }

            // Craft counters should not be initialized
            utils_assert_craft_counters(address(gen0), idsBefore[0], 0, 0, 0, false);
            utils_assert_craft_counters(address(gen0), idsBefore[1], 0, 0, 0, false);

            // Will revert
            bytes32 nonce = bytes32(abi.encode(to));
            CraftData memory request = CraftData({
                to: to,
                nonce: nonce,
                collection_a: address(gen0),
                collection_b: address(gen0),
                parent_a: idsBefore[0],
                parent_b: idsBefore[1],
                payment_value: 0,
                payment_type: address(0),
                payer: address(0),
                expected_cc_a: 0,
                expected_cc_b: 0,
                lockPeriod: 1 hours
            });
            vm.prank(minter);
            vm.expectRevert(abi.encodeWithSelector(Errors.MaxCraftCount.selector, address(gen0), idsBefore[0], 0));
            crafterImpl.craft(request);
        }

        // Setup an individual craft rule
        {
            vm.recordLogs();

            vm.startPrank(owner);
            rules.setMaxCraftCount(address(gen0), idsBefore[0], 0);
            crafterImpl.setCrafterRule(address(rules), address(gen0), idsBefore[0]);
            vm.stopPrank();

            // Retrieve the logs
            VmSafe.Log[] memory entries = vm.getRecordedLogs();
            assertEq(entries.length, 2, "more than 2 entries");

            // emit MaxCraftCountUpdate(address(gen0), 1, 0);
            {
                assertEq(entries[0].topics.length, 1, "topics 0 length");
                assertEq(entries[0].topics[0], Events.MaxCraftCountUpdate.selector, "topics 0 selector");
                (address championAddress, uint256 tokenId, uint256 maxCraftCount) =
                    abi.decode(entries[0].data, (address, uint256, uint256));
                assertEq(championAddress, address(gen0), "championAddress");
                assertEq(tokenId, 3, "token 1");
                assertEq(maxCraftCount, 0, "maxCraftCount");
            }
            // emit Events.setCrafterRule(address(rules), address(gen0), 0);
            {
                assertEq(entries[1].topics.length, 1, "topics 1 length");
                assertEq(entries[1].topics[0], Events.SetCrafterRule.selector, "topics 1 selector");
                (address rulesAddress, address championAddress, uint256 tokenId) =
                    abi.decode(entries[1].data, (address, address, uint256));
                assertEq(rulesAddress, address(rules), "rulesAddress");
                assertEq(championAddress, address(gen0), "championAddress");
                assertEq(tokenId, 3, "tokenId");
            }

            // Craft counters should not be initialized
            utils_assert_craft_counters(address(gen0), idsBefore[0], 0, 0, 0, false);
            utils_assert_craft_counters(address(gen0), idsBefore[1], 0, 0, 0, false);

            // Will revert
            bytes32 nonce = bytes32(abi.encode(to));
            CraftData memory request = CraftData({
                to: to,
                nonce: nonce,
                collection_a: address(gen0),
                collection_b: address(gen0),
                parent_a: idsBefore[0],
                parent_b: idsBefore[1],
                payment_value: 0,
                payment_type: address(0),
                payer: address(0),
                expected_cc_a: 0,
                expected_cc_b: 0,
                lockPeriod: 1 hours
            });
            vm.prank(minter);
            vm.expectRevert(abi.encodeWithSelector(Errors.MaxCraftCount.selector, address(gen0), idsBefore[0], 0));
            crafterImpl.craft(request);
        }

        // Remove the global rule and override the rule for token 1
        vm.startPrank(owner);

        vm.expectEmit();
        emit Events.MaxCraftCountUpdate(address(gen0), idsBefore[0], 10);
        rules.setMaxCraftCount(address(gen0), idsBefore[0], 10);

        vm.expectEmit();
        emit Events.SetCrafterRule(address(0), address(gen0), 0);
        crafterImpl.setCrafterRule(address(0), address(gen0), 0);

        vm.stopPrank();

        uint256[] memory idsLockedUntil = new uint256[](13);
        // Craft until we reach maxCraftCount
        for (uint256 i = 1; i <= 10; i++) {
            bytes32 nonce_ = bytes32(i);
            uint256 nextId = gen0.totalSupply() + 1;
            CraftData memory request = CraftData({
                to: to,
                nonce: nonce_,
                collection_a: address(gen0),
                collection_b: address(gen0),
                parent_a: idsBefore[0],
                parent_b: idsBefore[0] + i,
                payment_value: 0,
                payment_type: address(0),
                payer: address(0),
                expected_cc_a: i,
                expected_cc_b: 1,
                lockPeriod: 1 hours
            });

            (uint256 current,uint256 _newLock) = get_new_locked_until(1 hours);
            vm.expectEmit();
            emit Events.Transfer(address(0), to, nextId);
            vm.expectEmit();
            emit Events.Craft(
                address(gen0), nonce_, nextId, address(gen0), address(gen0), idsBefore[0], idsBefore[0] + i
            );
            vm.prank(minter);
            crafterImpl.craft(request);

            idsLockedUntil[0] = _newLock;
            idsLockedUntil[i] = _newLock;

            vm.warp(current + 62 minutes);

            // balance incremented by 1
            uint256[] memory ids = gen0.tokensOfOwner(to);
            assertEq(ids.length, idsBefore.length + i);
            assertEq(ids[ids.length - 1], nextId);

            // Craft counter were updated
            utils_assert_craft_counters(
                address(gen0), idsBefore[0], i, get_default_max_craft_count(address(gen0)), idsLockedUntil[0], true
            );
            // Newly crafted children have their maxCraftCount decreased by one from the oldest parent
            if (i == 1) {
                // idsBefore[1] is gen0 with DEFAULT_MAX_CRAFT_COUNT
                utils_assert_craft_counters(
                    address(gen0), idsBefore[0] + i, 1, get_default_max_craft_count(address(gen0)), idsLockedUntil[i], true
                );
            } else {
                // any token with i > 1 is gen0 with DEFAULT_MAX_CRAFT_COUNT - 1
                // since they were crafted from idsBefore[0] and idsBefore[1]
                utils_assert_craft_counters(
                    address(gen0), idsBefore[0] + i, 1, get_default_max_craft_count(address(gen0)) - 1, idsLockedUntil[i], true
                );
            }
        }

        uint256[] memory newIds = gen0.tokensOfOwner(to);
        assertEq(newIds.length, 12, "12 tokens"); // 2 initial tokens + 10 from crafting
        utils_assert_craft_counters(address(gen0), newIds[0], 10, get_default_max_craft_count(address(gen0)), idsLockedUntil[0], true);
    }

    /// @dev User can craft a new Champion with parents from different collection
    /// @dev child will be minted in the oldest parent's contract
    /// @dev child will have parent's maxCraftCount + 1
    function test_craft_parent_with_older_collection_parent_a() public prank(minter) {
        address to = users[0];
        bytes32 nonce = bytes32(abi.encodePacked("craft-parent-a-older"));

        // gen0 balance before craft is `PUBLIC_ALLOC`
        uint256[] memory idsGen0 = gen0.tokensOfOwner(to);
        assertEq(idsGen0.length, PUBLIC_ALLOC);
        uint256 nextId = gen0.totalSupply() + 1;

        // gen1 balance before craft is `PUBLIC_ALLOC`
        uint256[] memory idsGen1 = gen1.tokensOfOwner(to);
        assertEq(idsGen1.length, PUBLIC_ALLOC);

        CraftData memory request = CraftData({
            to: to,
            nonce: nonce,
            collection_a: address(gen0),
            collection_b: address(gen1),
            parent_a: idsGen0[0],
            parent_b: idsGen1[0],
            payment_value: 0,
            payment_type: address(0),
            payer: address(0),
            expected_cc_a: 1,
            expected_cc_b: 1,
            lockPeriod: 1 hours
        });

        (,uint256 _newLock) = get_new_locked_until(1 hours);

        // child will be minted in older generation (gen0)
        vm.expectEmit();
        emit Events.Transfer(address(0), to, nextId);
        vm.expectEmit();
        emit Events.Craft(address(gen0), nonce, nextId, address(gen0), address(gen1), idsGen0[0], idsGen1[0]);
        crafterImpl.craft(request);

        // Craft counters increased
        utils_assert_craft_counters(address(gen0), idsGen0[0], 1, 8, _newLock, true);
        utils_assert_craft_counters(address(gen1), idsGen1[0], 1, 8, _newLock, true);

        // Balance increased by one
        assertEq(gen0.balanceOf(to), idsGen0.length + 1);
        idsGen0 = gen0.tokensOfOwner(to);
        assertEq(idsGen0[2], nextId);

        // Craft counter for child is initialized with parent's (maxCraftCount - 1)
        utils_assert_craft_counters(address(gen0), idsGen0[2], 0, 7, 0, true);
    }

    /// @dev User didn't approve the crafter proxy for ERC20 transferFrom
    function test_craft_RevertWhen_no_erc20_approval_or_not_enough_balance() public {
        address to = users[0];
        bytes32 nonce = bytes32(abi.encodePacked("craft-erc20"));

        // Check the prior erc20 balance
        assertEq(token.balanceOf(to), 0, "users has more than 0 tokens");

        // gen0 balance before craft is `PUBLIC_ALLOC`
        uint256[] memory ids = gen0.tokensOfOwner(to);
        assertEq(ids.length, PUBLIC_ALLOC);
        uint256 nextId = gen0.totalSupply() + 1;

        CraftData memory request = CraftData({
            to: to,
            nonce: nonce,
            collection_a: address(gen0),
            collection_b: address(gen0),
            parent_a: ids[0],
            parent_b: ids[1],
            payment_value: 1e18, // 1 TestUSD
            payment_type: address(token), // TestUSD address,
            payer: address(0),
            expected_cc_a: 1,
            expected_cc_b: 1,
            lockPeriod: 1 hours
        });

        // User has no tokens, will revert
        vm.expectRevert();
        vm.prank(minter);
        crafterImpl.craft(request);
        // Vault didn't receive fees
        assertEq(token.balanceOf(vault), 0);

        // Give some TestUSD to users[0]
        deal(address(token), to, 1e18);
        // User balance change
        assertEq(token.balanceOf(to), 1e18, "users has 0 tokens");
        // User has funds but didn't approve, will revert
        vm.expectRevert();
        vm.prank(minter);
        crafterImpl.craft(request);

        // GenesisCrafter can spend 1 TestUSD from users[0]
        vm.expectEmit();
        emit Events.Approval(to, address(crafterImpl), 1e18);
        vm.prank(to);
        token.approve(address(crafterImpl), 1e18);

        (,uint256 _newLock) = get_new_locked_until(1 hours);
        // Retry with the correct amount
        vm.expectEmit();
        emit IERC20.Transfer(to, vault, 1e18);
        vm.expectEmit();
        emit Events.CraftFees(vault, address(token), 1e18, to);
        vm.expectEmit();
        emit Events.Transfer(address(0), to, nextId);
        vm.expectEmit();
        emit Events.Craft(address(gen0), nonce, nextId, address(gen0), address(gen0), ids[0], ids[1]);
        vm.prank(minter);
        crafterImpl.craft(request);

        // User balance changed
        assertEq(token.balanceOf(to), 0);
        // Vault received fees
        assertEq(token.balanceOf(vault), 1e18);

        // Craft counters increased
        utils_assert_craft_counters(address(gen0), ids[0], 1, 8, _newLock, true);
        utils_assert_craft_counters(address(gen0), ids[1], 1, 8, _newLock, true);
        assertEq(gen0.balanceOf(to), ids.length + 1);
    }

    function test_craft_RevertWhen_no_erc20_approval_payer() public {
        address payer = users[0];
        vm.label(payer, "Payer");
        address to = users[1];
        vm.label(to, "Buyer");
        bytes32 nonce = bytes32(abi.encodePacked("craft-erc20-with-payer"));

        // Give some TestUSD to payer
        deal(address(token), payer, 1e18);

        // Check the prior erc20 balance
        assertGt(token.balanceOf(payer), 0, "users has no tokens");
        assertEq(token.balanceOf(to), 0, "users has more than 0 tokens");

        // gen0 balance before craft is `PUBLIC_ALLOC`
        uint256[] memory ids = gen0.tokensOfOwner(to);
        assertEq(ids.length, PUBLIC_ALLOC);
        uint256 nextId = gen0.totalSupply() + 1;

        CraftData memory request = CraftData({
            to: to,
            nonce: nonce,
            collection_a: address(gen0),
            collection_b: address(gen0),
            parent_a: ids[0],
            parent_b: ids[1],
            payment_value: 1e18, // 1 TestUSD
            payment_type: address(token), // TestUSD address,
            payer: payer,
            expected_cc_a: 1,
            expected_cc_b: 1,
            lockPeriod: 1 hours
        });

        // Payer has funds but didn't approve, will revert
        vm.expectRevert();
        vm.prank(minter);
        crafterImpl.craft(request);

        // GenesisCrafter can spend 1 TestUSD from payer
        vm.expectEmit();
        emit Events.Approval(payer, address(crafterImpl), 1e18);
        vm.prank(payer);
        token.approve(address(crafterImpl), 1e18);

        (,uint256 _newLock) = get_new_locked_until(1 hours);
        // Retry with the correct amount
        vm.expectEmit();
        emit IERC20.Transfer(payer, vault, 1e18);
        vm.expectEmit();
        emit Events.CraftFees(vault, address(token), 1e18, payer);
        vm.expectEmit();
        emit Events.Transfer(address(0), to, nextId);
        vm.expectEmit();
        emit Events.Craft(address(gen0), nonce, nextId, address(gen0), address(gen0), ids[0], ids[1]);
        vm.prank(minter);
        crafterImpl.craft(request);

        // User balance changed
        assertEq(token.balanceOf(to), 0);
        // Vault received fees
        assertEq(token.balanceOf(vault), 1e18);

        // Craft counters increased
        utils_assert_craft_counters(address(gen0), ids[0], 1, 8, _newLock, true);
        utils_assert_craft_counters(address(gen0), ids[1], 1, 8, _newLock, true);
        assertEq(gen0.balanceOf(to), ids.length + 1);
    }

}

/**
 * @title Token_ERC20
 *
 * @dev Used for testing purpose
 */
contract Token_ERC20 is MockERC20 {

    constructor(string memory name_, string memory symbol_, uint8 decimals_) {
        initialize(name_, symbol_, decimals_);
    }

    function mint(address to, uint256 value) public virtual {
        _mint(to, value);
    }

}
