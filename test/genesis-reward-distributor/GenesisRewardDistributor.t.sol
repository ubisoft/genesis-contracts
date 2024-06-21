// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.24;

import {GenesisRewardDistributor} from "src/GenesisRewardDistributor.sol";
import {BaseTest} from "test/Base.t.sol";

/**
 * @dev GenesisRewardDistributor_Base_Test holds all base test setup for the GenesisRewardDistributor contract
 */
contract GenesisRewardDistributor_Base_Test is BaseTest {

    function setUp() public virtual override {
        // Setup the test suite with accounts
        BaseTest.setUp();

        // Deploy the Genesis contract
        vm.prank(owner);
        rewarder = new GenesisRewardDistributor(minter);

        vm.label({account: address(rewarder), newLabel: "GenesisRewardDistributor"});
    }

}
