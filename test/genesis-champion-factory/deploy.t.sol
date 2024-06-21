// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.24;

import {GenesisChampionFactory_Base_Test} from "./GenesisChampionFactory.t.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {Strings} from "@openzeppelin/contracts/utils/Strings.sol";
import {VmSafe} from "forge-std/Vm.sol";
import {GenesisChampion} from "src/GenesisChampion.sol";
import {GenesisChampionFactory} from "src/GenesisChampionFactory.sol";
import {Errors} from "src/librairies/Errors.sol";
import {GenesisChampionArgs} from "src/types/GenesisChampionArgs.sol";
import {BaseTest} from "test/Base.t.sol";
import {Events} from "test/utils/Events.sol";
import {ILayerZeroEndpointV2} from "@layerzerolabs/lz-evm-protocol-v2/contracts/interfaces/ILayerZeroEndpointV2.sol";
import { TestHelperOz5 } from "@layerzerolabs/test-devtools-evm-foundry/contracts/TestHelperOz5.sol";

/**
 * @dev GenesisChampionFactory_Deploy_Tests holds all tests used to generate gas reports
 */
contract GenesisChampionFactory_Deploy_Tests is GenesisChampionFactory_Base_Test {

    using Strings for uint256;

    function setUp() public virtual override {
        GenesisChampionFactory_Base_Test.setUp();
    }

    /**
     * @dev Test the deployment of new instances of GenesisChampion contracts with given
     * constructor arguments and its storage in the factory's `deployedVersions`
     */
    function test_deploy() public {
        uint256 NUM_DEPLOYMENTS = 5;

        // lastDeployment should return address(0) when no contract was deployed yet
        // lastVersion should return 0 when no contract was deployed yet
        address expectedLastDeployment = factory.lastDeployment();
        uint256 expectedLastVersion = factory.lastVersion();
        assertEq(expectedLastDeployment, address(0));
        assertEq(expectedLastVersion, 0);

        for (uint256 i = 1; i <= NUM_DEPLOYMENTS; i++) {
            string memory _version = i.toString();
            string memory _name = string.concat("GenesisChampions_", _version);
            string memory _symbol = string.concat("CHAMP_", _version);

            GenesisChampionArgs memory args = GenesisChampionArgs({
                name: _name,
                symbol: _symbol,
                baseURI: "ipfs://Qmbcg4ykX7dTYMdRkfM4yJ8ovHBfqpDuk3GiEjdTKr1uw9/",
                owner: owner,
                minter: minter,
                crafter: address(0),
                vault: vault,
                endpointL0: endpoints[eid1],
                defaultMaxCraftCount: GENESIS_CHAMP_DEFAULT_MAX_CRAFT_COUNT
            });

            // Record the deployment logs
            vm.recordLogs();

            // Deploy a new GenesisChampion instance using GenesisChampionFactory
            vm.prank(owner);
            (address lastDeployment, uint256 lastVersion) = factory.deploy(args);
            champion = GenesisChampion(lastDeployment);

            // lastDeployment was updated with address(champion)
            address actualLastDeployment = factory.lastDeployment();
            assertEq(actualLastDeployment, lastDeployment);
            // lastVersion was incrememented from 0 by +1 at each round
            uint256 actualLastVersion = factory.lastVersion();
            assertEq(actualLastVersion, i);
            // lastVersion isn't 0
            assertGt(actualLastVersion, 0);
            // deployedVersions mapping was updated
            uint256 mappingVersion = factory.deployedVersions(lastDeployment);
            assertEq(mappingVersion, actualLastVersion);

            // Retrieve the logs
            VmSafe.Log[] memory entries = vm.getRecordedLogs();

            // Expect 5 events: OwnershipTransferred, DelegateSet, RoleGranted, RoleGranted, ContractCreated
            assertEq(entries.length, 5);

            // emit OwnershipTransferred({previousOwner: address(0), newOwner: owner});
            assertEq(entries[0].topics[0], Events.OwnershipTransferred.selector, "error 1");
            assertEq(entries[0].topics[1], addressToBytes32(address(0)), "error 2");
            assertEq(entries[0].topics[2], addressToBytes32(owner), "error 3");
            // emit DelegateSet(owner, owner)
            assertEq(entries[1].topics[0], ILayerZeroEndpointV2.DelegateSet.selector, "error 4");
            (address _addr1, address _addr2) = abi.decode(entries[1].data, (address, address));
            assertEq(_addr1, address(champion), "error 5");
            assertEq(_addr2, owner, "error 6");
            // emit RoleGranted({role: DEFAULT_ADMIN_ROLE, account: owner, sender: address(factory)};
            assertEq(entries[2].topics[0], Events.RoleGranted.selector, "error 10");
            assertEq(entries[2].topics[1], champion.DEFAULT_ADMIN_ROLE(), "error 11");
            assertEq(entries[2].topics[2], addressToBytes32(owner), "error 12");
            assertEq(entries[2].topics[3], addressToBytes32(address(factory)), "error 13");
            // emit RoleGranted({role: MINTER_ROLE, account: minter, sender: address(factory)};
            assertEq(entries[3].topics[0], Events.RoleGranted.selector, "error 14");
            assertEq(entries[3].topics[1], champion.MINTER_ROLE(), "error 15");
            assertEq(entries[3].topics[2], addressToBytes32(minter), "error 16");
            assertEq(entries[3].topics[3], addressToBytes32(address(factory)), "error 17");
            // emit ConractCreated(address lastDeployment, uint256 lastVersion)
            assertEq(entries[4].topics[0], Events.ContractCreated.selector);
            (address eventData0, uint256 eventData1) = abi.decode(entries[4].data, (address, uint256));
            assertEq(lastDeployment, eventData0, "contract event 0");
            assertEq(lastVersion, eventData1, "contract event 1");

            // Newly deployed contract should match its initialization args
            assertEq(champion.name(), args.name);
            assertEq(champion.symbol(), args.symbol);
            assertEq(champion.owner(), owner);
            assertEq(champion.defaultMaxCraftCount(), GENESIS_CHAMP_DEFAULT_MAX_CRAFT_COUNT);
            assertTrue(champion.hasRole(champion.DEFAULT_ADMIN_ROLE(), owner));
            assertTrue(champion.hasRole(champion.MINTER_ROLE(), minter));
        }
    }

    /**
     * @dev deploy should deploy a new instance of GenesisChampion with given constructor arguments
     * and store the new implementation in `deployedVersions`
     */
    function test_fuzz_deploy(
        uint256 _deploymentVersion,
        address _minter,
        address _vault,
        uint256 _publicSupply,
        uint256 _holderSupply,
        uint256 _maxCraftCount
    ) public {
        _deploymentVersion = bound(_deploymentVersion, 1, 10);
        _publicSupply = bound(_publicSupply, 1_000, 1_000_000);
        _holderSupply = bound(_holderSupply, 1_000, 1_000_000);
        vm.assume(_maxCraftCount > 0);
        vm.assume(_minter != address(0));
        vm.assume(_vault != address(0));

        string memory _name = string.concat("GenesisChampions_", _deploymentVersion.toString());
        string memory _symbol = string.concat("CHAMP_", _deploymentVersion.toString());

        GenesisChampionArgs memory args = GenesisChampionArgs({
            name: _name,
            symbol: _symbol,
            baseURI: "ipfs://Qmbcg4ykX7dTYMdRkfM4yJ8ovHBfqpDuk3GiEjdTKr1uw9/",
            owner: owner,
            minter: _minter,
            crafter: address(0),
            vault: _vault,
            endpointL0: endpoints[eid1],
            defaultMaxCraftCount: _maxCraftCount
        });

        // Record the deployment logs
        vm.recordLogs();

        // Deploy a new GenesisChampion instance using GenesisChampionFactory
        vm.prank(owner);
        (address lastDeployment, uint256 lastVersion) = factory.deploy(args);
        champion = GenesisChampion(lastDeployment);

        // Retrieve the logs
        VmSafe.Log[] memory entries = vm.getRecordedLogs();

        // Expect 5 events: OwnershipTransferred, DelegateSet, RoleGranted, RoleGranted, ContractCreated
        assertEq(entries.length, 5);

        // emit OwnershipTransferred({previousOwner: address(0), newOwner: owner});
        assertEq(entries[0].topics[0], Events.OwnershipTransferred.selector, "error 1");
        assertEq(entries[0].topics[1], addressToBytes32(address(0)), "error 2");
        assertEq(entries[0].topics[2], addressToBytes32(address(owner)), "error 3");
        // emit DelegateSet(owner, owner)
        assertEq(entries[1].topics[0], ILayerZeroEndpointV2.DelegateSet.selector, "error 4");
        (address _addr1, address _addr2) = abi.decode(entries[1].data, (address, address));
        assertEq(_addr1, address(champion), "error 6");
        assertEq(_addr2, owner, "error 7");
        // emit RoleGranted({role: DEFAULT_ADMIN_ROLE, account: owner, sender: address(factory)});
        assertEq(entries[2].topics[0], Events.RoleGranted.selector, "error 11");
        assertEq(entries[2].topics[1], 0x00, "error 12"); // DEFAULT_ADMIN_ROLE
        assertEq(entries[2].topics[2], addressToBytes32(owner), "error 13");
        assertEq(entries[2].topics[3], addressToBytes32(address(factory)), "error 14");
        // emit RoleGranted({role: MINTER_ROLE, account: minter, sender: address(factory)});
        assertEq(entries[3].topics[0], Events.RoleGranted.selector, "error 15");
        assertEq(entries[3].topics[1], champion.MINTER_ROLE(), "error 16");
        assertEq(entries[3].topics[2], addressToBytes32(_minter), "error 17");
        assertEq(entries[3].topics[3], addressToBytes32(address(factory)), "error 18");
        // emit ConractCreated(address lastDeployment, uint256 lastVersion)
        assertEq(entries[4].topics[0], Events.ContractCreated.selector, "error 19");
        (address eventData0, uint256 eventData1) = abi.decode(entries[4].data, (address, uint256));
        assertEq(lastDeployment, eventData0, "error 20");
        assertEq(lastVersion, eventData1, "error 21");

        // Newly deployed contract should match its initialization args
        assertEq(champion.name(), args.name, "error 22");
        assertEq(champion.symbol(), args.symbol, "error 23");
        assertEq(champion.owner(), owner, "error 24");
        assertEq(champion.defaultMaxCraftCount(), _maxCraftCount, "error 25");

        // Latest deployment's address matches our local instance
        assertEq(factory.lastDeployment(), address(champion), "error 26");
    }

    /**
     * @dev deploy should revert when caller isn't the contract owner
     */
    function test_fuzz_RevertWhen_CallerIsNotOwner(uint16 _privateKey) public {
        vm.assume(_privateKey > 0);

        GenesisChampionArgs memory args = GenesisChampionArgs({
            name: "GenesisChampion_1",
            symbol: "CHAMP_1",
            baseURI: "ipfs://Qmbcg4ykX7dTYMdRkfM4yJ8ovHBfqpDuk3GiEjdTKr1uw9/",
            owner: owner,
            minter: minter,
            crafter: address(0),
            vault: vault,
            endpointL0: endpoints[eid1],
            defaultMaxCraftCount: GENESIS_CHAMP_DEFAULT_MAX_CRAFT_COUNT
        });

        address acc = vm.addr(_privateKey);

        vm.prank(acc);
        vm.expectRevert(abi.encodeWithSelector(Ownable.OwnableUnauthorizedAccount.selector, acc));
        factory.deploy(args);
    }

}
