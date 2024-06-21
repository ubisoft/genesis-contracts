// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.24;

import {ERC1967Proxy} from "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";
import {Options, Upgrades} from "openzeppelin-foundry-upgrades/Upgrades.sol";
import {GenesisChampion} from "src/GenesisChampion.sol";
import {GenesisChampionFactory} from "src/GenesisChampionFactory.sol";
import {GenesisCrafter} from "src/GenesisCrafter.sol";
import {GenesisMinter} from "src/GenesisMinter.sol";
import {GenesisChampionArgs} from "src/types/GenesisChampionArgs.sol";
import {BaseTest} from "test/Base.t.sol";

/**
 * @dev GenesisMinter_Base_Test holds all basic tests for the `GenesisMinter` contract
 */
contract GenesisMinter_Base_Test is BaseTest {

    // GenesisChampion contracts deployed during setup
    address[] internal deployments;

    function setUp() public virtual override {
        // Disable checks on Proxy Upgrades so we don't need to use --ffi
        Options memory opts;
        opts.unsafeSkipAllChecks = false;

        // Setup the test suite with accounts and contracts
        BaseTest.setUp();

        vm.startPrank(owner);
        // Deploy the factory
        factory = new GenesisChampionFactory(owner);

        // Deploy GenesisMinter proxy and implementation
        // https://github.com/OpenZeppelin/openzeppelin-foundry-upgrades
        address _proxyMinter = Upgrades.deployUUPSProxy(
            "GenesisMinter.sol", abi.encodeCall(GenesisMinter.initialize, (address(factory), minter))
        );
        minterImpl = GenesisMinter(_proxyMinter);
        vm.label({account: _proxyMinter, newLabel: "GenesisMinterProxy"});

        // Deploy GenesisChampion contracts
        GenesisChampionArgs memory args = GenesisChampionArgs({
            name: "GenesisChamp_1",
            symbol: "CMP_1",
            baseURI: "ipfs://Qmbcg4ykX7dTYMdRkfM4yJ8ovHBfqpDuk3GiEjdTKr1uw9/",
            owner: owner,
            minter: _proxyMinter,
            crafter: address(0),
            vault: vault,
            endpointL0: endpoints[eid1],
            defaultMaxCraftCount: GENESIS_CHAMP_DEFAULT_MAX_CRAFT_COUNT
        });
        (address deployment,) = factory.deploy(args);

        // Store the deployments
        deployments.push(deployment);
        champion = GenesisChampion(deployments[0]);
        vm.label({account: deployments[0], newLabel: "GenesisChamp_1"});

        vm.stopPrank();
    }

}
