// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.24;

import {GenesisChampionFactory} from "src/GenesisChampionFactory.sol";
import {BaseTest} from "test/Base.t.sol";

/**
 * @dev GenesisChampionFactory_Base_Test holds all basic tests for the `GenesisChampionFactory` contract
 */
contract GenesisChampionFactory_Base_Test is BaseTest {

    function setUp() public virtual override {
        BaseTest.setUp();

        // Deploy the Genesis contract
        vm.prank(owner);
        factory = new GenesisChampionFactory(owner);

        vm.label({account: address(factory), newLabel: "GenesisChampionFactory"});
    }

}
