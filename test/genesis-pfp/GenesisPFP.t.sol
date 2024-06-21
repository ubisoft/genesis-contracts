// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.24;

import {GenesisPFP} from "src/GenesisPFP.sol";
import {BaseTest} from "test/Base.t.sol";

/**
 * @dev GenesisPFP_Base_Test holds all basic tests for the `GenesisPFP` contract
 */
contract GenesisPFP_Base_Test is BaseTest {

    function setUp() public virtual override {
        // Setup the test suite with accounts and Chainlink contracts
        BaseTest.setUp();

        // Deploy the Genesis contract
        vm.prank(owner);
        genesis = new GenesisPFP(
            GENESIS_PFP_NAME,
            GENESIS_PFP_SYMBOL,
            GENESIS_PFP_VERSION,
            address(minter),
            address(vault),
            address(linkToken),
            address(wrapper)
        );

        vm.label({account: address(genesis), newLabel: "GenesisPFP"});
    }

}
