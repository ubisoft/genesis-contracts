// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.24;

import {AccessControl} from "@openzeppelin/contracts/access/AccessControl.sol";
import {GenesisRewardDistributor} from "src/GenesisRewardDistributor.sol";
import {BaseTest} from "test/Base.t.sol";
import {Events} from "test/utils/Events.sol";

contract GenesisRewardDistributor_Constructor_Test is BaseTest {

    function setUp() public virtual override {
        BaseTest.setUp();
    }

    /**
     * @dev test the correct contract creation of GenesisRewardDistributor and setup of AccessControl roles
     */
    function test_Constructor() external {
        vm.expectEmit();
        emit RoleGranted({role: DEFAULT_ADMIN_ROLE, account: owner, sender: owner});

        vm.expectEmit();
        emit RoleGranted({role: MINTER_ROLE, account: minter, sender: owner});

        vm.prank(owner);
        rewarder = new GenesisRewardDistributor(minter);

        // Contract owner does not have the MINTER_ROLE
        require(!rewarder.hasRole(MINTER_ROLE, owner));

        // Minter does not have the DEFAULT_ADMIN_ROLE
        require(!rewarder.hasRole(DEFAULT_ADMIN_ROLE, minter));
    }

}
