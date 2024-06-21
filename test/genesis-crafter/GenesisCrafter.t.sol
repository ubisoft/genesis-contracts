// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.24;

import {GenesisChampionFactory_Base_Test} from "../genesis-champion-factory/GenesisChampionFactory.t.sol";
import {ERC1967Proxy} from "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";
import {Options, Upgrades} from "openzeppelin-foundry-upgrades/Upgrades.sol";
import {GenesisChampionFactory} from "src/GenesisChampionFactory.sol";
import {GenesisCrafter} from "src/GenesisCrafter.sol";
import {GenesisMinter} from "src/GenesisMinter.sol";
import {GenesisChampionArgs} from "src/types/GenesisChampionArgs.sol";
import {BaseTest} from "test/Base.t.sol";
import {Events} from "test/utils/Events.sol";

/**
 * @dev GenesisCrafter_Base_Test holds all basic tests for the `GenesisCrafter` contract
 */
contract GenesisCrafter_Base_Test is BaseTest {

    uint8 internal constant NUM_DEPLOYMENTS = 2;
    address[] internal deployments;

    function setUp() public virtual override {
        // Setup the test suite with accounts and deploy the factory
        BaseTest.setUp();

        // Disable checks on Proxy Upgrades so we don't need to use --ffi
        Options memory opts;
        opts.unsafeSkipAllChecks = false;

        vm.startPrank(owner);
        // Deploy the factory
        factory = new GenesisChampionFactory(owner);

        // Deploy GenesisCrafter proxy and implementation
        address _proxyCrafter = Upgrades.deployUUPSProxy(
            "GenesisCrafter.sol",
            abi.encodeCall(GenesisCrafter.initialize, (address(factory), minter, vault)),
            opts
        );
        crafterImpl = GenesisCrafter(_proxyCrafter);
        vm.label({account: _proxyCrafter, newLabel: "GenesisCrafterProxy"});

        // Deploy GenesisMinter proxy and implementation
        address _proxyMinter = Upgrades.deployUUPSProxy(
            "GenesisMinter.sol",
            abi.encodeCall(GenesisMinter.initialize, (address(factory), minter)),
            opts
        );
        minterImpl = GenesisMinter(_proxyMinter);
        vm.label({account: _proxyMinter, newLabel: "GenesisMinterProxy"});

        // Grant MINTER_ROLE to GenesisCrafter on GenesisMinter, otherwise mint wont work
        vm.expectEmit();
        emit Events.RoleGranted(minterImpl.MINTER_ROLE(), _proxyCrafter, owner);
        minterImpl.grantRole(minterImpl.MINTER_ROLE(), _proxyCrafter);

        // Deploy some GenesisChampion contracts
        // Deploy N new instances of GenesisChampion using the factory
        for (uint256 i = 0; i < NUM_DEPLOYMENTS; i++) {
            GenesisChampionArgs memory args = GenesisChampionArgs({
                name: string(abi.encodePacked("GenesisChamp_", i)),
                symbol: string(abi.encodePacked("CMP_", i)),
                baseURI: "ipfs://Qmbcg4ykX7dTYMdRkfM4yJ8ovHBfqpDuk3GiEjdTKr1uw9/",
                owner: owner,
                minter: address(minterImpl),
                crafter: address(crafterImpl),
                vault: address(vault),
                endpointL0: endpoints[eid1],
                defaultMaxCraftCount: GENESIS_CHAMP_DEFAULT_MAX_CRAFT_COUNT
            });
            (address _impl,) = factory.deploy(args);
            deployments.push(_impl);
        }

        vm.stopPrank();
    }

}
