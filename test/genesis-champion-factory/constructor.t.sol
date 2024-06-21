// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.24;

import {GenesisChampionFactory} from "src/GenesisChampionFactory.sol";
import {GenesisCrafter} from "src/GenesisCrafter.sol";
import {BaseTest} from "test/Base.t.sol";
import {Events} from "test/utils/Events.sol";

contract GenesisChampionFactory_Constructor_Test is BaseTest {

    function setUp() public virtual override {
        BaseTest.setUp();
    }

    /**
     * @dev test the correct contract creation of GenesisChampionFactory and setup of Ownership
     */
    function test_Constructor() external {
        vm.expectEmit();
        emit OwnershipTransferred({previousOwner: address(0), newOwner: address(owner)});

        vm.prank(owner);
        factory = new GenesisChampionFactory(owner);
    }

}
