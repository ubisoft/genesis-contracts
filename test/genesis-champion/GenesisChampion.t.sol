// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.24;

import {GenesisChampion} from "src/GenesisChampion.sol";
import {GenesisChampionArgs} from "src/types/GenesisChampionArgs.sol";
import {BaseTest} from "test/Base.t.sol";

/**
 * @dev GenesisChampion_Base_Test holds all basic tests for the `GenesisChampion` contract
 */
contract GenesisChampion_Base_Test is BaseTest {
    function setUp() public virtual override {
        // Setup the test suite with accounts
        BaseTest.setUp();

        // Deploy the Genesis contract
        vm.prank(owner);
        champion = new GenesisChampion(
            GenesisChampionArgs({
                name: GENESIS_CHAMP_NAME,
                symbol: GENESIS_CHAMP_SYMBOL,
                baseURI: "ipfs://Qmbcg4ykX7dTYMdRkfM4yJ8ovHBfqpDuk3GiEjdTKr1uw9/default.json",
                owner: owner,
                minter: minter,
                crafter: address(0),
                vault: vault,
                endpointL0: endpoints[eid1],
                defaultMaxCraftCount: GENESIS_CHAMP_DEFAULT_MAX_CRAFT_COUNT
            })
        );

        vm.label({account: address(champion), newLabel: "GenesisChampion"});
    }

}
