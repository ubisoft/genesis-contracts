// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.24;

import {IAccessControl} from "@openzeppelin/contracts/access/IAccessControl.sol";
import {VmSafe} from "forge-std/Vm.sol";
import {Options, Upgrades} from "openzeppelin-foundry-upgrades/Upgrades.sol";
import {AccessControl} from "openzeppelinV4/access/AccessControl.sol";
import {Strings} from "openzeppelinV4/utils/Strings.sol";
import {GenesisChampionFactory} from "src/GenesisChampionFactory.sol";
import {GenesisCrafter} from "src/GenesisCrafter.sol";
import {BaseTest} from "test/Base.t.sol";
import {Events} from "test/utils/Events.sol";

contract GenesisCrafter_Constructor_Test is BaseTest {

    // OpenZeppelin Upgrades options
    Options internal opts;

    function setUp() public virtual override {
        BaseTest.setUp();
        factory = new GenesisChampionFactory(owner);
        opts.unsafeSkipAllChecks = false;
    }

    /**
     * @dev test the correct contract creation of GenesisCrafter and setup of AccessControl roles
     */
    function test_Constructor() external {
        vm.startPrank(owner);
        // Factory should have been deployed during the setup
        assertNotEq(address(factory), address(0));

        // Record the deployment logs
        vm.recordLogs();

        address _proxy = Upgrades.deployUUPSProxy(
            "GenesisCrafter.sol",
            abi.encodeCall(GenesisCrafter.initialize, (address(factory), minter, vault)),
            opts
        );
        crafterImpl = GenesisCrafter(_proxy);

        // Retrieve the implementation address of GenesisCrafter using its storage slot as defined in ERC1967ProxyUpgrade.sol
        bytes32 _crafterStorageImpl =
            vm.load(_proxy, bytes32(0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc));
        address _crafterStorageImplAddr = bytes32ToAddress(_crafterStorageImpl);

        // Retrieve the logs
        VmSafe.Log[] memory entries = vm.getRecordedLogs();

        // Expect 5 events: Initialized, Upgraded, OwnershipTransferred, Initialized, RoleGranted, RoleGranted
        assertEq(entries.length, 6);

        // emit Initialized(uint64.max);
        assertEq(entries[0].topics.length, 1);
        assertEq(entries[0].topics[0], Events.Initialized.selector);
        assertEq(abi.decode(entries[0].data, (uint64)), type(uint64).max);

        // emit Upgraded({implementation: address(GenesisCrafter)});
        assertEq(entries[1].topics.length, 2);
        assertEq(entries[1].topics[0], Events.Upgraded.selector);
        assertEq(bytes32ToAddress(entries[1].topics[1]), _crafterStorageImplAddr);

        // emit OwnershipTransferred({previousOwner: address(0), newOwner: owner});
        assertEq(entries[2].topics.length, 3);
        assertEq(entries[2].topics[0], Events.OwnershipTransferred.selector);
        assertEq(bytes32ToAddress(entries[2].topics[1]), address(0));
        assertEq(bytes32ToAddress(entries[2].topics[2]), owner);

        // emit RoleGranted({role: DEFAULT_ADMIN_ROLE, account: address(owner), sender: address(owner)});
        assertEq(entries[3].topics.length, 4);
        assertEq(entries[3].topics[0], Events.RoleGranted.selector);
        assertEq(entries[3].topics[1], crafterImpl.DEFAULT_ADMIN_ROLE());
        assertEq(bytes32ToAddress(entries[3].topics[2]), address(owner));
        assertEq(bytes32ToAddress(entries[3].topics[3]), address(owner));

        // emit RoleGranted({role: MINTER_ROLE, account: address(minter), sender: address(owner)});
        assertEq(entries[4].topics.length, 4);
        assertEq(entries[4].topics[0], Events.RoleGranted.selector);
        assertEq(entries[4].topics[1], crafterImpl.MINTER_ROLE());
        assertEq(bytes32ToAddress(entries[4].topics[2]), address(minter));
        assertEq(bytes32ToAddress(entries[4].topics[3]), address(owner));

        // emit Initialized(1);
        assertEq(entries[5].topics.length, 1);
        assertEq(entries[5].topics[0], Events.Initialized.selector);
        assertEq(abi.decode(entries[5].data, (uint64)), 1);

        // Conract deployer has the DEFAULT_ADMIN_ROLE
        require(crafterImpl.hasRole(DEFAULT_ADMIN_ROLE, owner));

        // Contract owner does not have the MINTER_ROLE
        require(!crafterImpl.hasRole(MINTER_ROLE, owner));

        // Minter does not have the DEFAULT_ADMIN_ROLE
        require(!crafterImpl.hasRole(DEFAULT_ADMIN_ROLE, minter));

        // Minter has the MINTER_ROLE
        require(crafterImpl.hasRole(MINTER_ROLE, minter));

        vm.stopPrank();

        // Not DEFAULT_ADMIN_ROLE user cannot revoke a role
        vm.prank(minter);
        vm.expectRevert(
            abi.encodeWithSelector(IAccessControl.AccessControlUnauthorizedAccount.selector, minter, DEFAULT_ADMIN_ROLE)
        );
        crafterImpl.revokeRole(DEFAULT_ADMIN_ROLE, owner);

        // DEFAULT_ADMIN_ROLE user can revoke a role
        vm.prank(owner);
        crafterImpl.revokeRole(MINTER_ROLE, minter);

        // DEFAULT_ADMIN_ROLE user can grant a role to another user
        vm.prank(owner);
        crafterImpl.grantRole(MINTER_ROLE, bob);
    }

}
