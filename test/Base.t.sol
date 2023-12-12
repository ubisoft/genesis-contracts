// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.18;

// Forge STD
import "forge-std/Test.sol";

// Utils
import {Constants} from "test/utils/Constants.sol";
import {Events} from "test/utils/Events.sol";

// Genesis
import {GenesisPFP} from "src/GenesisPFP.sol";
import {IGenesisPFP} from "src/interfaces/IGenesisPFP.sol";
import {Errors} from "src/librairies/Errors.sol";
import {MintData} from "src/types/MintData.sol";

// OpenZeppelin
import {Strings} from "openzeppelin/utils/Strings.sol";

// Chainlink mocks
import {VRFCoordinatorV2Mock} from "chainlink/v0.8/mocks/VRFCoordinatorV2Mock.sol";
import {MockV3Aggregator} from "chainlink/v0.8/tests/MockV3Aggregator.sol";
import {MockLinkToken} from "chainlink/v0.8/mocks/MockLinkToken.sol";
import {VRFV2Wrapper} from "chainlink/v0.8/vrf/VRFV2Wrapper.sol";

/// @notice Base test contract holding common deployments, private keys and users
abstract contract BaseTest is Test, Events, Constants {
    using Strings for uint256;

    // Genesis
    GenesisPFP public genesis;

    // Chainlink Mock
    VRFCoordinatorV2Mock internal coordinator;
    MockV3Aggregator internal linkEthFeed;
    MockLinkToken internal linkToken;
    VRFV2Wrapper internal wrapper;

    // Private keys
    uint256 internal ownerPrivateKey;
    uint256 internal minterPrivateKey;
    uint256 internal vaultPrivateKey;
    uint256 internal linkDeployerPrivateKey;
    uint256 internal bobPrivateKey;
    uint256 internal reservePrivateKey;
    uint256 internal privateKey;

    // Addresses
    address internal owner;
    address internal minter;
    address internal vault;
    address internal linkDeployer;
    address internal bob;
    address internal reserveWallet;
    address internal privateWallet;

    function setUp() public virtual {
        // Initialize the private keys used
        ownerPrivateKey = 0xFFFA11CE;
        minterPrivateKey = 0xFFF1111;
        vaultPrivateKey = 0xFFF1112;
        bobPrivateKey = 0xFFFB0B;
        reservePrivateKey = 0xFFFD1D;
        privateKey = 0xFFFDE7;
        linkDeployerPrivateKey = 0xFFF7144;

        // Initialize the wallets associated with previous private keys
        owner = vm.addr(ownerPrivateKey);
        minter = vm.addr(minterPrivateKey);
        vault = vm.addr(vaultPrivateKey);
        bob = vm.addr(bobPrivateKey);
        reserveWallet = vm.addr(reservePrivateKey);
        privateWallet = vm.addr(privateKey);
        linkDeployer = vm.addr(linkDeployerPrivateKey);

        // All RPC calls will be sent from `linkDeployer` until `changePrank` or `stopPrank` is called
        vm.startPrank(linkDeployer);

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

        // Label the address so they are logged using a name instead of their address
        vm.label({account: owner, newLabel: "GenesisPFP Admin"});
        vm.label({account: minter, newLabel: "GenesisPFP Minter"});
        vm.label({account: address(wrapper), newLabel: "Chainlink VRFV2Wrapper"});
    }

    /**
     * @dev sign any minting authorization with any private key
     * @param private_key used to sign the EIP712 typed digest
     * @param data MintData request
     */
    function get_mint_data_sig(uint256 private_key, MintData memory data) public view returns (bytes memory) {
        bytes32 digest = genesis.hashTypedDataV4(data);
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(private_key, digest);
        return abi.encodePacked(r, s, v);
    }
}
