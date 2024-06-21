// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.24;

// Forge STD
import "forge-std/Test.sol";

// OpenZeppelin V4
import {Strings} from "openzeppelinV4/utils/Strings.sol";

// OpenZeppelin V5
import {ERC1967Proxy} from "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";

// Chainlink
import {MockLinkToken} from "chainlink/v0.8/mocks/MockLinkToken.sol";
import {VRFCoordinatorV2Mock} from "chainlink/v0.8/mocks/VRFCoordinatorV2Mock.sol";
import {MockV3Aggregator} from "chainlink/v0.8/tests/MockV3Aggregator.sol";
import {VRFV2Wrapper} from "chainlink/v0.8/vrf/VRFV2Wrapper.sol";

// LayerZero Devtools
import {TestHelperOz5} from "@layerzerolabs/test-devtools-evm-foundry/contracts/TestHelperOz5.sol";
import {EndpointV2Mock as EndpointV2} from
    "@layerzerolabs/test-devtools-evm-foundry/contracts/mocks/EndpointV2Mock.sol";

// AuthenticatedRelay
import {AuthenticatedRelay, RelayData} from "authenticated-relay/AuthenticatedRelay.sol";

// Genesis
import {GenesisChampion} from "src/GenesisChampion.sol";
import {GenesisChampionFactory} from "src/GenesisChampionFactory.sol";
import {GenesisCrafter} from "src/GenesisCrafter.sol";
import {GenesisMinter} from "src/GenesisMinter.sol";
import {GenesisPFP} from "src/GenesisPFP.sol";
import {GenesisRewardDistributor} from "src/GenesisRewardDistributor.sol";

// Genesis Interfaces
import {IGenesisChampion} from "src/interfaces/IGenesisChampion.sol";
import {IGenesisChampionFactory} from "src/interfaces/IGenesisChampionFactory.sol";
import {IGenesisMinter} from "src/interfaces/IGenesisMinter.sol";
import {IGenesisPFP} from "src/interfaces/IGenesisPFP.sol";

// Genesis Types
import {CraftData} from "src/types/CraftData.sol";
import {MintData} from "src/types/MintData.sol";
import {MintData as MintDataV2} from "src/types/MintDataV2.sol";

// Genesis Librairies
import {Errors} from "src/librairies/Errors.sol";

// Genesis Utils
import {Constants} from "test/utils/Constants.sol";
import {Events} from "test/utils/Events.sol";

/// @notice Base test contract holding common deployments, private keys and users
abstract contract BaseTest is Test, Events, Constants, TestHelperOz5 {

    using Strings for uint256;

    // Authenticated Relay
    AuthenticatedRelay public relay;

    // Genesis
    GenesisPFP public genesis;
    GenesisChampion public champion;
    GenesisChampionFactory factory;
    GenesisCrafter crafterImpl;
    GenesisMinter minterImpl;
    GenesisRewardDistributor rewarder;

    // Chainlink
    VRFCoordinatorV2Mock internal coordinator;
    MockV3Aggregator internal linkEthFeed;
    MockLinkToken internal linkToken;
    VRFV2Wrapper internal wrapper;

    // Private keys
    uint256 internal ownerPrivateKey;
    uint256 internal minterPrivateKey;
    uint256 internal crafterPrivateKey;
    uint256 internal vaultPrivateKey;
    uint256 internal externalDeployerPrivateKey;
    uint256 internal bobPrivateKey;
    uint256 internal reservePrivateKey;
    uint256 internal privateKey;

    // Addresses
    address internal owner;
    address internal minter;
    address internal crafter;
    address internal vault;
    address internal externalDeployer;
    address internal bob;
    address internal reserveWallet;
    address internal privateWallet;
    address internal layerZeroDeployer;

    // LayerZero endpoints
    uint16 internal eid1 = 1;
    uint16 internal eid2 = 2;

    function setUp() public virtual override (TestHelperOz5) {
        // Update the timestamp so it's not 0
        vm.warp(1719227853);
        // Initialize the private keys (default mnemonic from anvil from #0 to #7)
        ownerPrivateKey = 0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80;
        minterPrivateKey = 0x59c6995e998f97a5a0044966f0945389dc9e86dae88c7a8412f4603b6b78690d;
        vaultPrivateKey = 0x7c852118294e51e653712a81e05800f419141751be58f605c371e15141b007a6;
        bobPrivateKey = 0x47e179ec197488593b187f80a00eb0da91f1b9d0b13f8733639f19c30a34926a;
        reservePrivateKey = 0x8b3a350cf5c34c9194ca85829a2df0ec3153be0318b5e2d3348e872092edffba;
        privateKey = 0x92db14e403b83dfe3df233f83dfa3a0d7096f21ca9b0d6d6b8d88b2b4ec1564e;
        externalDeployerPrivateKey = 0x4bbbf85ce3377467afe5d46f804f221813b2bb87f24d81f60f1fcdbf7cbf4356;

        // Initialize the wallets associated with previous private keys
        owner = vm.addr(ownerPrivateKey);
        minter = vm.addr(minterPrivateKey);
        vault = vm.addr(vaultPrivateKey);
        bob = vm.addr(bobPrivateKey);
        reserveWallet = vm.addr(reservePrivateKey);
        privateWallet = vm.addr(privateKey);
        externalDeployer = vm.addr(externalDeployerPrivateKey);
        layerZeroDeployer = vm.addr(1); // Hardcoded in TestHelperOz5

        // All RPC calls will be sent from `externalDeployer` until `stopPrank` is called
        vm.startPrank(externalDeployer);

        // Deploy the Chainlink contracts
        // https://docs.chain.link/vrf/v2/direct-funding/examples/test-locally
        // Deploy the VRFCoordinatorV2Mock. This contract is a mock of the VRFCoordinatorV2 contract.
        coordinator = new VRFCoordinatorV2Mock(100000000000000000, 1000000000);

        // Deploy the MockV3Aggregator contract.
        linkEthFeed = new MockV3Aggregator(18, 3000000000000000);

        // Deploy the LinkToken contract.
        linkToken = new MockLinkToken();

        // Deploy the VRFV2Wrapper contract.
        wrapper = new VRFV2Wrapper(address(linkToken), address(linkEthFeed), address(coordinator));

        // Call the VRFV2Wrapper setConfig function to set wrapper specific parameters.
        // uint32 _wrapperGasOverhead,
        // uint32 _coordinatorGasOverhead,
        // uint8 _wrapperPremiumPercentage,
        // bytes32 _keyHash,
        // uint8 _maxNumWords
        wrapper.setConfig(60000, 52000, 10, 0xd89b2bf150e3b9e13446986e571fb9cab24b13cea0a43ea20a6049a85cc807cc, 10);

        // Fund the VRFv2Wrapper subscription.
        // @param _subid = 1
        // @param _amount = 10 LINK
        coordinator.fundSubscription(1, 10000000000000000000);

        vm.stopPrank();

        // Deploy LayerZero endpoints
        setUpEndpoints(2, LibraryType.UltraLightNode);

        // Label the address so they are logged using a name instead of their address
        vm.label({account: owner, newLabel: "OwnerOperator"});
        vm.label({account: minter, newLabel: "MinterOperator"});
        vm.label({account: address(wrapper), newLabel: "Chainlink VRFV2Wrapper"});
    }

    /**
     * @dev sign any minting authorization with any private key for MintData (GenesisPFP)
     * @param private_key used to sign the EIP712 typed digest
     * @param data MintData request
     */
    function get_mint_data_sig(uint256 private_key, MintData memory data) public view returns (bytes memory) {
        bytes32 digest = genesis.hashTypedDataV4(data);
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(private_key, digest);
        return abi.encodePacked(r, s, v);
    }

    function get_relay_data_sig(uint256 private_key, RelayData memory data) public view returns (bytes memory) {
        bytes32 digest = relay.hashTypedDataV4(data);
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(private_key, digest);
        return abi.encodePacked(r, s, v);
    }

    // Craft Counters for idsBefore[0] and idsBefore[1] were never initialized before craft
    function utils_assert_craft_counters(
        address collection,
        uint256 id,
        uint256 expectedCraftCount,
        uint256 expectedMaxCraftCount,
        uint256 expectedLock,
        bool expectedInit
    ) internal {
        (uint256 newCraftCount, uint256 newMaxCraftCount, uint256 newLockedUntil, bool newInit) =
            crafterImpl.craftCounters(collection, id);
        assertEq(newCraftCount, expectedCraftCount, "utils newCraftCount");
        assertEq(newMaxCraftCount, expectedMaxCraftCount, "utils newMaxCraftCount");
        assertEq(newLockedUntil, expectedLock, "utils lock");
        assertEq(newInit, expectedInit, "utils init");
    }

    /**
     * @dev convert a bytes32 to address
     * @param b data to convert
     */
    function bytes32ToAddress(bytes32 b) internal pure returns (address) {
        return address(uint160(uint256(b)));
    }

}
