// SPDX-License-Identifier: APACHE-2.0
pragma solidity ^0.8.24;

import {GenesisMinter_Base_Test} from "./GenesisMinter.t.sol";
import {VmSafe} from "forge-std/Vm.sol";
import {Options, Upgrades} from "openzeppelin-foundry-upgrades/Upgrades.sol";
import {GenesisChampionFactory} from "src/GenesisChampionFactory.sol";
import {GenesisMinter} from "src/GenesisMinter.sol";
import {GenesisMinterV2} from "test/genesis-minter/GenesisMinterV2.sol";
import {Events} from "test/utils/Events.sol";

contract GenesisMinter_Upgrade_Test is GenesisMinter_Base_Test {

    function setUp() public virtual override {
        GenesisMinter_Base_Test.setUp();
    }

    /**
     * @dev test the deployment of GenesisMinter proxy v1 and ugprade to v2
     */
    function test_upgrade() external {
        vm.startPrank(owner);
        // Record the deployment logs
        vm.recordLogs();

        // Deploy the initial proxy and v1 implementation
        Options memory opts1;
        opts1.unsafeSkipAllChecks = false;
        address proxy = Upgrades.deployUUPSProxy(
            "GenesisMinter.sol",
            abi.encodeCall(GenesisMinter.initialize, (address(factory), minter)),
            opts1
        );
        // Retrieve the logs
        VmSafe.Log[] memory entries1 = vm.getRecordedLogs();
        assertEq(entries1.length, 6);

        // Verify current implementation's configuration
        GenesisMinter minterImpl_V1 = GenesisMinter(proxy);
        assertEq(minterImpl_V1.version(), 1);
        assertTrue(minterImpl_V1.hasRole(minterImpl_V1.MINTER_ROLE(), minter));
        assertTrue(minterImpl_V1.hasRole(minterImpl_V1.DEFAULT_ADMIN_ROLE(), owner));
        assertEq(minterImpl_V1.owner(), owner);

        // Check for event Upgraded({implementation: address(GenesisMinter)})
        // Verify the implementation address for GenesisMinter matches the address stored in ERC1967Proxy implementation slot
        address minterImplementationV1 = utils_load_implementation_slot(proxy);
        assertEq(entries1[1].topics.length, 2);
        assertEq(entries1[1].topics[0], Events.Upgraded.selector);
        assertEq(bytes32ToAddress(entries1[1].topics[1]), minterImplementationV1);

        VmSafe.Log[] memory entries2 = vm.getRecordedLogs();

        // Upgrade to V2
        Options memory opts2;
        // Reference the previous contract implementation
        opts2.referenceContract = "GenesisMinter.sol";
        opts2.unsafeSkipAllChecks = false;
        Upgrades.upgradeProxy(proxy, "GenesisMinterV2.sol", "", opts2);
        // Retrieve logs after proxy upgrade
        entries2 = vm.getRecordedLogs();
        assertEq(entries2.length, 2);

        // Check for event Upgraded({implementation: address(GenesisMinter)})
        // Verify the implementation address for GenesisMinter matches the address stored in ERC1967Proxy implementation slot
        address minterImplementationV2address = utils_load_implementation_slot(proxy);
        assert(minterImplementationV1 != minterImplementationV2address);

        // emit Upgraded({implementation: address(GenesisMinter)});
        assertEq(entries2[1].topics.length, 2);
        assertEq(entries2[1].topics[0], Events.Upgraded.selector);
        assertEq(bytes32ToAddress(entries2[1].topics[1]), minterImplementationV2address);

        // Minter V2 only implements version()
        GenesisMinterV2 minterImpl_V2 = GenesisMinterV2(proxy);
        assertEq(minterImpl_V2.version(), 2);
        vm.stopPrank();
    }

    function utils_load_implementation_slot(address proxy) internal view returns (address) {
        // Retrieve the implementation address of GenesisMinter using its storage slot as defined in ERC1967ProxyUpgrade.sol
        bytes32 _minterStorageImpl =
            vm.load(proxy, bytes32(0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc));
        return bytes32ToAddress(_minterStorageImpl);
    }

}
