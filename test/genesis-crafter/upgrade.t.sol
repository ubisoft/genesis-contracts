// SPDX-License-Identifier: APACHE-2.0
pragma solidity ^0.8.24;

import {GenesisCrafter_Base_Test} from "./GenesisCrafter.t.sol";
import {VmSafe} from "forge-std/Vm.sol";
import {UUPSUpgradeable} from "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import {Options, Upgrades} from "openzeppelin-foundry-upgrades/Upgrades.sol";
import {GenesisChampionFactory} from "src/GenesisChampionFactory.sol";
import {GenesisCrafter} from "src/GenesisCrafter.sol";
import {GenesisCrafterV2} from "test/genesis-crafter/GenesisCrafterV2.sol";
import {BaseTest} from "test/Base.t.sol";
import {Events} from "test/utils/Events.sol";

contract GenesisCrafter_Upgrade_Test is GenesisCrafter_Base_Test {

    function setUp() public virtual override {
        GenesisCrafter_Base_Test.setUp();
    }

    /**
     * @dev test the deployment of GenesisCrafter proxy v1 and ugprade to v2
     */
    function test_upgrade() external {
        vm.startPrank(owner);
        // Record the deployment logs
        vm.recordLogs();

        // Deploy the initial proxy and v1 implementation
        Options memory opts1;
        opts1.unsafeSkipAllChecks = false;
        address proxy = Upgrades.deployUUPSProxy(
            "GenesisCrafter.sol",
            abi.encodeCall(GenesisCrafter.initialize, (address(factory), minter, vault)),
            opts1
        );
        // Retrieve the logs
        VmSafe.Log[] memory entries1 = vm.getRecordedLogs();
        assertEq(entries1.length, 6);

        // Verify current implementation's configuration
        GenesisCrafter crafterImpl_V1 = GenesisCrafter(proxy);
        assertEq(crafterImpl_V1.version(), 1);
        assertTrue(crafterImpl_V1.hasRole(crafterImpl_V1.MINTER_ROLE(), minter));
        assertTrue(crafterImpl_V1.hasRole(crafterImpl_V1.DEFAULT_ADMIN_ROLE(), owner));
        assertEq(crafterImpl_V1.owner(), owner);

        // Check for event Upgraded({implementation: address(GenesisCrafter)})
        // Verify the implementation address for GenesisCrafter matches the address stored in ERC1967Proxy implementation slot
        address crafterImpl_V1_address = utils_load_implementation_slot(proxy);
        assertEq(entries1[1].topics.length, 2);
        assertEq(entries1[1].topics[0], Events.Upgraded.selector);
        assertEq(bytes32ToAddress(entries1[1].topics[1]), crafterImpl_V1_address);

        VmSafe.Log[] memory entries2 = vm.getRecordedLogs();

        // Upgrade to V2
        Options memory opts2;
        // Reference the previous contract implementation
        opts2.referenceContract = "GenesisCrafter.sol";
        opts2.unsafeSkipAllChecks = false;
        Upgrades.upgradeProxy(proxy, "GenesisCrafterV2.sol", "", opts2);
        // Retrieve logs after proxy upgrade
        entries2 = vm.getRecordedLogs();
        assertEq(entries2.length, 2);

        // Check for event Upgraded({implementation: address(GenesisCrafter)})
        // Verify the implementation address for GenesisCrafter matches the address stored in ERC1967Proxy implementation slot
        address crafterImplementation_V2_address = utils_load_implementation_slot(proxy);
        assert(crafterImpl_V1_address != crafterImplementation_V2_address);

        // emit Upgraded({implementation: address(GenesisCrafter)});
        assertEq(entries2[1].topics.length, 2);
        assertEq(entries2[1].topics[0], Events.Upgraded.selector);
        assertEq(bytes32ToAddress(entries2[1].topics[1]), crafterImplementation_V2_address);

        // Verify the new implementation's configuration
        GenesisCrafterV2 crafterImpl_V2 = GenesisCrafterV2(proxy);
        // Nothing implemented in V2 except version()
        assertEq(crafterImpl_V2.version(), 2);

        vm.stopPrank();
    }

    /**
     * @dev DEFAULT_ADMIN can renounce its admin role
     */
    function test_RevertWhen_upgrade_after_renounce_ownership() public {
        vm.startPrank(owner);

        // Deploy the initial proxy and v1 implementation
        Options memory opts1;
        opts1.unsafeSkipAllChecks = false;
        address proxy = Upgrades.deployUUPSProxy(
            "GenesisCrafter.sol",
            abi.encodeCall(GenesisCrafter.initialize, (address(factory), minter, vault)),
            opts1
        );
        GenesisCrafter crafterImpl_V1 = GenesisCrafter(proxy);

        // Owner controls ADMIN_ROLE
        assertEq(crafterImpl_V1.owner(), owner);

        // Owner can renounce the ownership of the contract
        vm.expectEmit();
        emit Events.OwnershipTransferred(address(owner), address(0));
        crafterImpl_V1.renounceOwnership();
        assertEq(crafterImpl_V1.owner(), address(0));

        // Upgrade to V2 should revert
        vm.expectRevert();
        UUPSUpgradeable(proxy).upgradeToAndCall(address(0), "");

        vm.stopPrank();
    }

    function utils_load_implementation_slot(address proxy) internal view returns (address) {
        // Retrieve the implementation address of GenesisCrafter using its storage slot as defined in ERC1967ProxyUpgrade.sol
        bytes32 _crafterStorageImpl =
            vm.load(proxy, bytes32(0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc));
        return bytes32ToAddress(_crafterStorageImpl);
    }

}
