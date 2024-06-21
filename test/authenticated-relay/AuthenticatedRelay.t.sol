// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.24;

import {AuthenticatedRelay} from "authenticated-relay/AuthenticatedRelay.sol";
import {GenesisChampionFactory} from "src/GenesisChampionFactory.sol";
import {BaseTest} from "test/Base.t.sol";

/**
 * @dev AuthenticatedRelay_Base_Test holds all basic tests for the `AuthenticatedRelay` contract
 */
contract AuthenticatedRelay_Base_Test is BaseTest {

    function setUp() public virtual override {
        // Setup the test suite with accounts and contracts
        BaseTest.setUp();

        vm.startPrank(owner);

        // Deploy Authenticated Relay
        relay = new AuthenticatedRelay("AuthenticatedRelay", "1", owner, minter);
        vm.label({account: address(relay), newLabel: "AuthenticatedRelay"});

        // Deploy Factory and Champion
        factory = new GenesisChampionFactory(owner);
        vm.label({account: address(factory), newLabel: "GenesisChampionFactory"});

        vm.stopPrank();
    }

}
