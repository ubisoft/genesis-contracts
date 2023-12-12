// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.18;

import {AccessControl} from "openzeppelin/access/AccessControl.sol";
import {BaseTest} from "test/Base.t.sol";
import {Events} from "test/utils/Events.sol";
import {Errors} from "src/librairies/Errors.sol";
import {GenesisPFP} from "src/GenesisPFP.sol";
import {GenesisPFP_Base_Test} from "./GenesisPFP.t.sol";
import {MintData} from "src/types/MintData.sol";
import {Strings} from "openzeppelin/utils/Strings.sol";
import {console2} from "forge-std/Test.sol";

/**
 * @dev MetadataVrf_Test holds all tests related to the metadatas
 */
contract MetadataVrf_Test is GenesisPFP_Base_Test {
    using Strings for uint256;

    function setUp() public virtual override {
        GenesisPFP_Base_Test.setUp();

        vm.startPrank(owner);
    }

    /**
     * @dev test [set|get] for baseURI
     * @dev getter should return "" when CID is empty
     * @dev getter should return baseURI when set
     * @dev setter should revert when caller is not the contract owner
     * @dev setter should revert when called a second time to override current CID
     */
    function test_metadata_cid() public {
        // Should return ""
        string memory _cid = "ipfs://baybfeitestcid";
        assertEq(genesis.baseURI(), "");

        // Should revert when caller isn't contract owner
        changePrank(bob);
        vm.expectRevert("Ownable: caller is not the owner");
        genesis.setBaseURI(_cid);

        // Should not revert when called by the owner
        changePrank(owner);
        genesis.setBaseURI(_cid);
        assertEq(genesis.baseURI(), _cid);

        // Should revert when called after a first initialization
        vm.expectRevert(Errors.BaseURIAlreadyInitialized.selector);
        genesis.setBaseURI(_cid);
    }

    /**
     * @dev test the request of a random chainlink seed
     * @dev getter [chainlinkRequestID|chainlinkSeed] should be 0 before requesting VRF
     * @dev and greather than 0 after sending VRF request
     * @dev requestChainlinkVRF should revert if caller is not contract owner
     * @dev requestChainlinkVRF should revert if contract has no LINK tokens
     */
    function test_request_chainlink_vrf() public {
        // chainlinkRequestID and chainlinkSeed should not be initialized
        assertEq(genesis.chainlinkRequestID(), 0);
        assertEq(genesis.chainlinkSeed(), 0);

        // Requesting a chainlink number should revert without being contract owner
        // @param _callbackGasLimit 150k units of gas should be more than enough for 1 random number
        // @param _requestConfirmations 1 block confirmation during unit tests but
        // we should use 6 or more on mainnet for potential reorgs
        changePrank(bob);
        vm.expectRevert("Ownable: caller is not the owner");
        genesis.requestChainlinkVRF(150_000, 1);

        // Should revert if Genesis contract doesn't own Link tokens
        changePrank(owner);
        vm.expectRevert();
        genesis.requestChainlinkVRF(150_000, 1);

        // Fund the Genesis contract with LINK tokens and request a random number
        changePrank(linkDeployer);
        linkToken.transfer(address(genesis), 10e18);

        // Request VRF
        changePrank(owner);
        genesis.requestChainlinkVRF(150_000, 1);
        assertGt(genesis.chainlinkRequestID(), 0);
        assertEq(genesis.chainlinkSeed(), 0);

        // Mock the VRF request fulfillment
        changePrank(linkDeployer);
        coordinator.fulfillRandomWords(1, address(wrapper));
        assertGt(genesis.chainlinkRequestID(), 0);
        assertGt(genesis.chainlinkSeed(), 0);
    }

    /**
     * @dev test withdrawRemainingLink to withraw all Link tokens from the contract
     * @dev withdrawRemainingLink should revert if contract has no LINK tokens
     */
    function test_withdraw_remaining_link() public {
        // check owner has no Link token
        uint256 ownerBalance = linkToken.balanceOf(owner);
        assertEq(ownerBalance, 0);

        // Should revert if Genesis contract doesn't own Link tokens
        changePrank(owner);
        vm.expectRevert(Errors.EmptyLinkBalance.selector);
        genesis.withdrawRemainingLink(owner);

        // Fund the Genesis contract with 10 LINK tokens and request a random number
        changePrank(linkDeployer);
        linkToken.transfer(address(genesis), 10 * 10 ** 18);

        // Should revert if caller isn't owner
        changePrank(bob);
        vm.expectRevert("Ownable: caller is not the owner");
        genesis.withdrawRemainingLink(bob);

        // Request VRF
        changePrank(owner);
        genesis.requestChainlinkVRF(150_000, 1);
        assertGt(genesis.chainlinkRequestID(), 0);
        assertEq(genesis.chainlinkSeed(), 0);

        // Fulfill mock VRF
        changePrank(linkDeployer);
        coordinator.fulfillRandomWords(1, address(wrapper));
        assertGt(genesis.chainlinkRequestID(), 0);
        assertGt(genesis.chainlinkSeed(), 0);

        // Genesis contract still has LINK tokens
        uint256 contractBalance = linkToken.balanceOf(address(genesis));
        assertLt(contractBalance, 10 * 10 ** 18);
        assertGt(contractBalance, 0);

        // Should not revert
        changePrank(owner);
        genesis.withdrawRemainingLink(owner);

        // Owner now has the LINK token in its wallet
        ownerBalance = linkToken.balanceOf(owner);
        assertEq(ownerBalance, contractBalance);

        // Contract has no LINK tokens
        contractBalance = linkToken.balanceOf(address(genesis));
        assertEq(contractBalance, 0);
    }

    /**
     * @dev test the return of tokenURI and _baseURI
     * @dev should fail if tokenId does not exist
     * @dev should return "" when CID is empty
     * @dev should return the default tokenURI when reveal was not done
     * @dev should return a correct tokenURI when reveal is done
     */
    function test_loop_reveal() public {
        changePrank(bob);
        require(bytes(genesis.baseURI()).length == 0);

        // expected _cid and _uri after calling `setBaseURI`
        string memory _baseURI = "ipfs://baybfeitestcid/";

        // `tokenURI` should revert on non existent token
        vm.expectRevert(Errors.ERC721UriNonExistent.selector);
        genesis.tokenURI(1);

        // Mint all tokens
        {
            uint256 token_count = 0;
            uint256 i = 1;
            while (genesis.remainingSupply() > 0) {
                bool lastMint = genesis.remainingSupply() == 1;
                address user = vm.addr(0xFF + i);
                bytes32 nonce = bytes32(keccak256(abi.encode(user)));
                MintData memory data = MintData({
                    to: user,
                    validity_start: block.timestamp,
                    validity_end: (block.timestamp + 10 days),
                    chain_id: block.chainid,
                    mint_amount: MINT_MAX_PUBLIC,
                    user_nonce: nonce
                });
                bytes memory sig = get_mint_data_sig(minterPrivateKey, data);
                genesis.mintWithSignature(data, sig);
                uint256 balance = genesis.balanceOf(user);
                if (lastMint) {
                    assertEq(balance, 1);
                } else {
                    assertEq(balance, 2);
                }
                token_count += balance;
                // tokenURI(1) should return an empty string
                string memory uri = genesis.tokenURI(i);
                assertEq(uri, "");
                i++;
            }
            assertEq(token_count, GENESIS_PFP_INITIAL_REMAINING_SUPPLY);
        }

        // call setBaseURI
        changePrank(owner);
        genesis.setBaseURI(_baseURI);
        assertEq(genesis.baseURI(), _baseURI);

        // tokenURI should return the default fallback URI
        {
            for (uint256 i = 1; i < 9999; i++) {
                string memory uri = genesis.tokenURI(i);
                assertEq(uri, string(abi.encodePacked(_baseURI, "default.json")));
            }
        }

        // chainlinkSeed and chainlinkRequestId should equal 0 before reveal is triggered
        require(genesis.chainlinkSeed() == 0);
        require(genesis.chainlinkRequestID() == 0);

        // Fund the Genesis contract with LINK
        changePrank(linkDeployer);
        linkToken.transfer(address(genesis), 1000000000000000000);

        // tokenURI should return the correct URI after reveal
        changePrank(owner);
        genesis.requestChainlinkVRF(150_000, 1);
        coordinator.fulfillRandomWords(1, address(wrapper));

        // chainlinkSeed, chainlinkRequestId and metadataIds should be initialized
        assertGt(genesis.chainlinkRequestID(), 0);
        assertGt(genesis.chainlinkSeed(), 0);

        // Check the chainlink seed allows to compute the correct
        uint256 seed = genesis.chainlinkSeed();
        // metadata id will start at an offset computed from the seed between 1 and 9999
        // we need to check the offset resets to 1 instead of overlaping to 10000
        uint256 offset_start = 0;
        bool offset_reset = false;
        {
            for (uint256 i = 1; i <= 9999; i++) {
                // Testting the tokenURI return
                // Compute the current metadata_id based on the seed
                uint256 expected_metadata_id = ((i + seed) % 9999) + 1;

                // Register the metadata offset once at the beginning
                if (offset_start == 0) {
                    offset_start = expected_metadata_id;
                }
                // metadata_id should be bound between 1 and 9999
                assert(expected_metadata_id > 0 && expected_metadata_id < 10000);
                // Compute the full URI based on the computed metadata_id
                string memory expected_metadata_uri =
                    string(abi.encodePacked(_baseURI, expected_metadata_id.toString(), ".json"));

                // Call tokenURI with current token ID and verify it matches the computed tokenURI
                string memory actual_metadata_uri = genesis.tokenURI(i);
                assertEq(expected_metadata_uri, actual_metadata_uri);

                // after offset reset, tokenURI should point to 1.json
                if (offset_reset) {
                    assertEq(expected_metadata_id, 1);
                    string memory offset_reset_uri = string(abi.encodePacked(_baseURI, "1.json"));
                    assertEq(offset_reset_uri, actual_metadata_uri);
                    // unset `offset_reset` so we don't trigger it again
                    offset_reset = false;
                }
                // Verify if offset resets when metadata id reaches 9999
                if (expected_metadata_id == 9999) {
                    offset_reset = true;
                }
                if (i == 9999) {
                    assertEq(expected_metadata_id, (offset_start - 1));
                }
            }
        }
    }

    // =============================================================
    //                   RevertWhen
    // =============================================================

    /**
     * @dev setMetadatCID should revert when caller is not the contract owner
     * @dev revert with `Ownable: caller is no the owner`
     */
    function test_RevertWhen_OwnableCallerIsNotOwner() public {
        // Should revert when caller isn't contract owner
        changePrank(bob);
        vm.expectRevert("Ownable: caller is not the owner");
        genesis.setBaseURI("test_cid");
    }

    /**
     * @dev setMetadatCID should revert when it's already been set once
     */
    function test_RevertWhen_BaseURIAlreadyInitialized() public {
        changePrank(owner);
        // Should revert when caller isn't contract owner
        genesis.setBaseURI("test_cid");
        assertEq(genesis.baseURI(), "test_cid");

        // Should revert when called after a first initialization
        vm.expectRevert(Errors.BaseURIAlreadyInitialized.selector);
        genesis.setBaseURI("other_cid");
    }

    /**
     * @dev `requestChainlinkVRF` should revert `RequestAlreadyInitialized` when called twice
     */
    function test_RevertWhen_RequestAlreadyInitialized() public {
        changePrank(owner);

        // Should not be initialized
        assertEq(genesis.chainlinkRequestID(), 0);
        assertEq(genesis.chainlinkSeed(), 0);

        // Fund the Genesis contract with LINK tokens and request a random number
        changePrank(linkDeployer);
        linkToken.transfer(address(genesis), 1000000000000000000);

        // Request VRF a first time
        changePrank(owner);
        genesis.requestChainlinkVRF(150_000, 1);
        assertGt(genesis.chainlinkRequestID(), 0);
        assertEq(genesis.chainlinkSeed(), 0);

        // Mock the VRF request fulfillment
        changePrank(linkDeployer);
        coordinator.fulfillRandomWords(1, address(wrapper));
        assertGt(genesis.chainlinkRequestID(), 0);
        assertGt(genesis.chainlinkSeed(), 0);

        // Request VRF a second time
        changePrank(owner);
        vm.expectRevert(Errors.RequestAlreadyInitialized.selector);
        genesis.requestChainlinkVRF(150_000, 1);
    }
}
