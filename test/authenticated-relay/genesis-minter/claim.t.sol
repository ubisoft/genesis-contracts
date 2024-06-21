// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.24;

import {AuthenticatedRelay_Base_Test} from "../AuthenticatedRelay.t.sol";
import {AuthenticatedRelay, RelayData} from "authenticated-relay/AuthenticatedRelay.sol";
import {Options, Upgrades} from "openzeppelin-foundry-upgrades/Upgrades.sol";
import {AccessControl} from "openzeppelinV4/access/AccessControl.sol";
import {GenesisChampion} from "src/GenesisChampion.sol";
import {GenesisChampionFactory} from "src/GenesisChampionFactory.sol";
import {GenesisMinter} from "src/GenesisMinter.sol";
import {Errors} from "src/librairies/Errors.sol";
import {GenesisChampionArgs} from "src/types/GenesisChampionArgs.sol";
import {MintData as MintDataV2} from "src/types/MintDataV2.sol";
import {SupplyConfig} from "src/types/SupplyConfig.sol";
import {Events} from "test/utils/Events.sol";

/**
 * @dev AuthenticatedRelay_Claim_Test holds all tests related to the craft of GenesisChampion NFT through GenesisMinter
 */
contract AuthenticatedRelay_Claim_Test is AuthenticatedRelay_Base_Test {

    function setUp() public virtual override {
        AuthenticatedRelay_Base_Test.setUp();

        vm.startPrank(owner);

        // Disable checks on Proxy Upgrades so we don't need to use --ffi
        Options memory opts;
        opts.unsafeSkipAllChecks = false;

        // Deploy GenesisMinter proxy and implementation
        address _proxyMinter = Upgrades.deployUUPSProxy(
            "GenesisMinter.sol", abi.encodeCall(GenesisMinter.initialize, (address(factory), address(relay))), opts
        );
        minterImpl = GenesisMinter(_proxyMinter);
        vm.label({account: _proxyMinter, newLabel: "GenesisMinterProxy"});

        // Deploy GenesisChampion
        GenesisChampionArgs memory args = GenesisChampionArgs({
            name: "GenesisChampion",
            symbol: "GEN",
            baseURI: "ipfs://Qmbcg4ykX7dTYMdRkfM4yJ8ovHBfqpDuk3GiEjdTKr1uw9/",
            owner: owner,
            minter: address(minterImpl),
            crafter: address(crafterImpl),
            vault: vault,
            endpointL0: endpoints[eid1],
            defaultMaxCraftCount: GENESIS_CHAMP_DEFAULT_MAX_CRAFT_COUNT
        });
        (address deployment,) = factory.deploy(args);
        champion = GenesisChampion(deployment);
        vm.label({account: deployment, newLabel: "GenesisChampion"});

        vm.stopPrank();
    }

    /**
     * @dev register a default SupplyConfig in GenesisMinter before executing the test
     */
    modifier registerSupplyBeforeClaim() {
        vm.prank(owner);
        minterImpl.registerSupply(
            address(champion), GENESIS_CHAMP_INITIAL_HOLDER_SUPPLY, GENESIS_CHAMP_INITIAL_PUBLIC_SUPPLY
        );
        _;
    }

    // =============================================================
    //                   MINT TESTS
    // =============================================================

    /**
     * @dev a user can use the AuthenticatedRelay contract with a back-end generated authorization to call the `claim``
     * method on GenesisMinter and mint multiple NFTs from a GenesisChampion contract using the holder supply
     */
    function test_claim_holder() public registerSupplyBeforeClaim {
        // Supply is registered for address(champion)
        (uint256 sHolder, uint256 sPublic, bool init) = minterImpl.supply(address(champion));
        assertEq(sHolder, GENESIS_CHAMP_INITIAL_HOLDER_SUPPLY);
        assertEq(sPublic, GENESIS_CHAMP_INITIAL_PUBLIC_SUPPLY);
        assertEq(init, true);

        address to = bob;
        uint256 amount = GENESIS_CHAMP_CLAIM_HOLDERS;
        uint256 exptectedSupplyAfterClaim = sHolder - amount;
        bytes32 nonce = bytes32(keccak256(abi.encode(to)));

        // Send tx as `to`
        vm.startPrank(to);

        {
            // Generate a claim autorization for AuthenticatedRelay
            MintDataV2 memory mintData =
                MintDataV2({collection: address(champion), to: to, amount: amount, nonce: nonce, holder: true});
            bytes memory callData = abi.encodeWithSelector(GenesisMinter.claim.selector, mintData);
            RelayData memory data = RelayData({
                nonce: nonce,
                to: address(minterImpl),
                validityStart: block.timestamp,
                validityEnd: block.timestamp + 1 days,
                chainId: block.chainid,
                callData: callData
            });
            bytes memory sig = get_relay_data_sig(minterPrivateKey, data);

            vm.expectEmit(true, false, false, true);
            emit AuthenticatedRelay.SignatureUsed(nonce, false);
            vm.expectEmit(true, true, true, true);
            emit GenesisMinter.Claim(address(champion), nonce, amount);

            bytes memory result = relay.relay(data, sig);
            (uint256 firstId, uint256 lastId) = abi.decode(result, (uint256, uint256));

            // get all tokens owned by address and verify they were minted in the range [firstId;lastId]
            uint256[] memory tokens = champion.tokensOfOwner(to);
            assertEq(tokens.length, amount);
            assertEq(tokens[0], firstId);
            assertEq(tokens[tokens.length - 1], lastId);
        }

        // to's balance equals the requested `amount`
        uint256 balance = champion.balanceOf(to);
        assertEq(balance, amount);

        // claimable supply decreased by `amount`
        (uint256 newSupplyHolder, uint256 newSupplyPublic,) = minterImpl.supply(address(champion));
        assertEq(newSupplyHolder, exptectedSupplyAfterClaim);
        assertEq(newSupplyPublic, sPublic);

        vm.stopPrank();
    }

    /**
     * @dev claim the whole holder supply in one transaction
     */
    function test_claim_all_holder() public registerSupplyBeforeClaim {
        // Supply is registered for address(champion)
        (uint256 sHolder, uint256 sPublic, bool init) = minterImpl.supply(address(champion));
        assertEq(sHolder, GENESIS_CHAMP_INITIAL_HOLDER_SUPPLY);
        assertEq(sPublic, GENESIS_CHAMP_INITIAL_PUBLIC_SUPPLY);
        assertEq(init, true);

        address to = reserveWallet;
        uint256 amount = GENESIS_CHAMP_INITIAL_HOLDER_SUPPLY;
        bytes32 nonce = bytes32(keccak256(abi.encode(to)));

        // Send tx as `to`
        vm.startPrank(to);

        {
            // Generate a claim autorization for AuthenticatedRelay
            MintDataV2 memory mintData =
                MintDataV2({collection: address(champion), to: to, amount: amount, nonce: nonce, holder: true});
            bytes memory callData = abi.encodeWithSelector(GenesisMinter.claim.selector, mintData);
            RelayData memory data = RelayData({
                nonce: nonce,
                to: address(minterImpl),
                validityStart: block.timestamp,
                validityEnd: block.timestamp + 1 days,
                chainId: block.chainid,
                callData: callData
            });
            bytes memory sig = get_relay_data_sig(minterPrivateKey, data);

            vm.expectEmit(true, false, false, true);
            emit AuthenticatedRelay.SignatureUsed(nonce, false);
            vm.expectEmit(true, true, true, true);
            emit GenesisMinter.Claim(address(champion), nonce, amount);

            bytes memory result = relay.relay(data, sig);
            (uint256 firstId, uint256 lastId) = abi.decode(result, (uint256, uint256));

            // get all tokens owned by address and verify they were minted in the range [firstId;lastId]
            uint256[] memory tokens = champion.tokensOfOwner(to);
            assertEq(tokens.length, amount);
            assertEq(tokens[0], firstId);
            assertEq(tokens[tokens.length - 1], lastId);
        }
        // to's balance equals the requested `amount`
        uint256 balance = champion.balanceOf(to);
        assertEq(balance, amount);
        // claimable supply decreased by `amount`
        (uint256 newSupplyHolder, uint256 newSupplyPublic,) = minterImpl.supply(address(champion));
        assertEq(newSupplyHolder, 0);
        assertEq(newSupplyPublic, sPublic);

        vm.stopPrank();
    }

    /**
     * @dev a user can use the AuthenticatedRelay contract with a back-end generated authorization to call the `claim``
     * method on GenesisMinter and mint multiple NFTs from a GenesisChampion contract using the public supply
     */
    function test_claim_public() public registerSupplyBeforeClaim {
        // Supply is registered for address(champion)
        (uint256 sHolder, uint256 sPublic, bool init) = minterImpl.supply(address(champion));
        assertEq(sHolder, GENESIS_CHAMP_INITIAL_HOLDER_SUPPLY);
        assertEq(sPublic, GENESIS_CHAMP_INITIAL_PUBLIC_SUPPLY);
        assertEq(init, true);

        address to = bob;
        uint256 amount = GENESIS_CHAMP_CLAIM_PUBLIC;
        uint256 exptectedSupplyAfterClaim = sPublic - amount;
        bytes32 nonce = bytes32(keccak256(abi.encode(to)));

        // Send tx as `to`
        vm.startPrank(to);

        // Generate a claim autorization for AuthenticatedRelay
        {
            MintDataV2 memory mintData =
                MintDataV2({collection: address(champion), to: to, amount: amount, nonce: nonce, holder: false});
            bytes memory callData = abi.encodeWithSelector(GenesisMinter.claim.selector, mintData);
            RelayData memory data = RelayData({
                nonce: nonce,
                to: address(minterImpl),
                validityStart: block.timestamp,
                validityEnd: block.timestamp + 1 days,
                chainId: block.chainid,
                callData: callData
            });
            bytes memory sig = get_relay_data_sig(minterPrivateKey, data);
            vm.expectEmit(true, false, false, true);
            emit AuthenticatedRelay.SignatureUsed(nonce, false);
            vm.expectEmit(true, true, true, true);
            emit GenesisMinter.Claim(address(champion), nonce, amount);

            bytes memory result = relay.relay(data, sig);
            (uint256 firstId, uint256 lastId) = abi.decode(result, (uint256, uint256));
            // get all tokens owned by address and verify they were minted in the range [firstId;lastId]
            uint256[] memory tokens = champion.tokensOfOwner(to);
            assertEq(tokens.length, amount);
            assertEq(tokens[0], firstId);
            assertEq(tokens[tokens.length - 1], lastId);
        }

        // to's balance equals the requested `amount`
        uint256 balance = champion.balanceOf(to);
        assertEq(balance, amount);

        // claimable supply decreased by `amount`
        (uint256 newSupplyHolder, uint256 newSupplyPublic,) = minterImpl.supply(address(champion));
        assertEq(newSupplyHolder, sHolder);
        assertEq(newSupplyPublic, exptectedSupplyAfterClaim);

        vm.stopPrank();
    }

    /**
     * @dev a user can use the AuthenticatedRelay contract with a back-end generated authorization to call the `claim``
     * method on GenesisMinter and mint multiple NFTs from a GenesisChampion contract using the public supply
     */
    function test_claim_all_public() public registerSupplyBeforeClaim {
        // Supply is registered for address(champion)
        (uint256 sHolder, uint256 sPublic, bool init) = minterImpl.supply(address(champion));
        assertEq(sHolder, GENESIS_CHAMP_INITIAL_HOLDER_SUPPLY);
        assertEq(sPublic, GENESIS_CHAMP_INITIAL_PUBLIC_SUPPLY);
        assertEq(init, true);

        address to = reserveWallet;
        uint256 amount = GENESIS_CHAMP_INITIAL_PUBLIC_SUPPLY;
        uint256 exptectedSupplyAfterClaim = sPublic - amount;
        bytes32 nonce = bytes32(keccak256(abi.encode(to)));

        // Send tx as `to`
        vm.startPrank(to);

        {
            // Generate a claim autorization for AuthenticatedRelay
            MintDataV2 memory mintData =
                MintDataV2({collection: address(champion), to: to, amount: amount, nonce: nonce, holder: false});
            bytes memory callData = abi.encodeWithSelector(GenesisMinter.claim.selector, mintData);
            RelayData memory data = RelayData({
                nonce: nonce,
                to: address(minterImpl),
                validityStart: block.timestamp,
                validityEnd: block.timestamp + 1 days,
                chainId: block.chainid,
                callData: callData
            });
            bytes memory sig = get_relay_data_sig(minterPrivateKey, data);

            vm.expectEmit(true, false, false, true);
            emit AuthenticatedRelay.SignatureUsed(nonce, false);
            vm.expectEmit(true, true, true, true);
            emit GenesisMinter.Claim(address(champion), nonce, amount);

            bytes memory result = relay.relay(data, sig);
            (uint256 firstId, uint256 lastId) = abi.decode(result, (uint256, uint256));

            // get all tokens owned by address and verify they were minted in the range [firstId;lastId]
            uint256[] memory tokens = champion.tokensOfOwner(to);
            assertEq(tokens.length, amount);
            assertEq(tokens[0], firstId);
            assertEq(tokens[tokens.length - 1], lastId);
        }

        // to's balance equals the requested `amount`
        uint256 balance = champion.balanceOf(to);
        assertEq(balance, amount);

        // claimable supply decreased by `amount`
        (uint256 newSupplyHolder, uint256 newSupplyPublic,) = minterImpl.supply(address(champion));
        assertEq(newSupplyHolder, sHolder);
        assertEq(newSupplyPublic, exptectedSupplyAfterClaim);

        vm.stopPrank();
    }

    // // =============================================================
    // //                   REVERT TESTS
    // // =============================================================

    /**
     * @dev `relay` should revert when using a nonce twice
     */
    function test_RevertWhen_nonce_already_used() public registerSupplyBeforeClaim {
        (uint256 sHolder, uint256 sPublic, bool init) = minterImpl.supply(address(champion));
        assertEq(sHolder, GENESIS_CHAMP_INITIAL_HOLDER_SUPPLY);
        assertEq(sPublic, GENESIS_CHAMP_INITIAL_PUBLIC_SUPPLY);
        assertEq(init, true);

        address to = bob;
        uint256 amount = GENESIS_CHAMP_CLAIM_HOLDERS;
        uint256 exptectedSupplyAfterClaim = sHolder - amount;
        bytes32 nonce = bytes32(keccak256(abi.encode(to)));
        vm.startPrank(to);

        MintDataV2 memory mintData =
            MintDataV2({collection: address(champion), to: to, amount: amount, nonce: nonce, holder: true});
        bytes memory callData = abi.encodeWithSelector(GenesisMinter.claim.selector, mintData);
        RelayData memory data = RelayData({
            nonce: nonce,
            to: address(minterImpl),
            validityStart: block.timestamp,
            validityEnd: block.timestamp + 1 days,
            chainId: block.chainid,
            callData: callData
        });
        bytes memory sig = get_relay_data_sig(minterPrivateKey, data);

        vm.expectEmit(true, false, false, true);
        emit AuthenticatedRelay.SignatureUsed(nonce, false);
        vm.expectEmit(true, true, true, true);
        emit GenesisMinter.Claim(address(champion), nonce, amount);

        // Relay the tx
        relay.relay(data, sig);
        uint256 balance = champion.balanceOf(to);
        assertEq(balance, amount);

        // claimable supply decreased by `amount`
        (uint256 newSupplyHolder, uint256 newSupplyPublic,) = minterImpl.supply(address(champion));
        assertEq(newSupplyHolder, exptectedSupplyAfterClaim);
        assertEq(newSupplyPublic, sPublic);

        // Use the nonce a second time, will revert
        vm.expectRevert(AuthenticatedRelay.AlreadyUsed.selector);
        relay.relay(data, sig);

        vm.stopPrank();
    }

    /**
     * @dev `relayh` should revert with Unauthorized if signature wasn't signed by an authorized minter
     */
    function test_RevertWhen_unauthorized() public registerSupplyBeforeClaim {
        address to = bob;
        uint256 amount = GENESIS_CHAMP_CLAIM_HOLDERS;
        bytes32 nonce = bytes32(keccak256(abi.encode(to)));

        vm.startPrank(to);

        MintDataV2 memory mintData =
            MintDataV2({collection: address(champion), to: to, amount: amount, nonce: nonce, holder: true});
        bytes memory callData = abi.encodeWithSelector(GenesisMinter.claim.selector, mintData);
        RelayData memory data = RelayData({
            nonce: nonce,
            to: address(minterImpl),
            validityStart: block.timestamp,
            validityEnd: block.timestamp + 1 days,
            chainId: block.chainid,
            callData: callData
        });
        bytes memory sig = get_relay_data_sig(bobPrivateKey, data);

        vm.expectRevert(AuthenticatedRelay.Unauthorized.selector);
        relay.relay(data, sig);

        vm.stopPrank();
    }

    /**
     * @dev `relay` should revert with CallFailed if the SupplyConfig was not set in
     * GenesisMinter for the GenesisChampion target
     */
    function test_RevertWhen_unregistered_supply() public {
        address to = bob;
        uint256 amount = GENESIS_CHAMP_CLAIM_HOLDERS;
        bytes32 nonce = bytes32(keccak256(abi.encode(to)));

        vm.startPrank(to);

        MintDataV2 memory mintData =
            MintDataV2({collection: address(champion), to: to, amount: amount, nonce: nonce, holder: true});
        bytes memory callData = abi.encodeWithSelector(GenesisMinter.claim.selector, mintData);
        RelayData memory data = RelayData({
            nonce: nonce,
            to: address(minterImpl),
            validityStart: block.timestamp,
            validityEnd: block.timestamp + 1 days,
            chainId: block.chainid,
            callData: callData
        });
        bytes memory sig = get_relay_data_sig(minterPrivateKey, data);

        vm.expectRevert(AuthenticatedRelay.CallFailed.selector);
        relay.relay(data, sig);

        vm.stopPrank();
    }

    /**
     * @dev `relay` should revert with InvalidSignature if the signature is broadcasted before `validityStart` begins
     */
    function test_RevertWhen_claim_validity_start() public {
        address to = bob;
        uint256 amount = GENESIS_CHAMP_CLAIM_HOLDERS;
        bytes32 nonce = bytes32(keccak256(abi.encode(to)));

        vm.startPrank(to);

        MintDataV2 memory mintData =
            MintDataV2({collection: address(champion), to: to, amount: amount, nonce: nonce, holder: true});
        bytes memory callData = abi.encodeWithSelector(GenesisMinter.claim.selector, mintData);
        RelayData memory data = RelayData({
            nonce: nonce,
            to: address(minterImpl),
            validityStart: block.timestamp + 1 days,
            validityEnd: 2 days,
            chainId: block.chainid,
            callData: callData
        });
        bytes memory sig = get_relay_data_sig(bobPrivateKey, data);

        vm.expectRevert(AuthenticatedRelay.InvalidSignature.selector);
        relay.relay(data, sig);

        vm.stopPrank();
    }

    /**
     * @dev `relay` should revert with InvalidSignature if the signature is broadcasted before `validityStart` begins
     */
    function test_RevertWhen_claim_validity_end() public {
        address to = bob;
        uint256 amount = GENESIS_CHAMP_CLAIM_HOLDERS;
        bytes32 nonce = bytes32(keccak256(abi.encode(to)));

        vm.startPrank(to);

        MintDataV2 memory mintData =
            MintDataV2({collection: address(champion), to: to, amount: amount, nonce: nonce, holder: true});
        bytes memory callData = abi.encodeWithSelector(GenesisMinter.claim.selector, mintData);
        RelayData memory data = RelayData({
            nonce: nonce,
            to: address(minterImpl),
            validityStart: block.timestamp,
            validityEnd: block.timestamp + 1 days,
            chainId: block.chainid,
            callData: callData
        });
        bytes memory sig = get_relay_data_sig(bobPrivateKey, data);

        // Fast forward 5 days
        vm.warp(5 days);
        vm.expectRevert(AuthenticatedRelay.InvalidSignature.selector);
        relay.relay(data, sig);

        vm.stopPrank();
    }

    /**
     * @dev `relay` should revert with InvalidSignature if the signature was signed for another chainid
     */
    function test_RevertWhen_invalid_chain_id() public {
        address to = bob;
        uint256 amount = GENESIS_CHAMP_CLAIM_HOLDERS;
        bytes32 nonce = bytes32(keccak256(abi.encode(to)));

        // Send tx as `to`
        vm.startPrank(to);

        // Generate a claim autorization for AuthenticatedRelay
        MintDataV2 memory mintData =
            MintDataV2({collection: address(champion), to: to, amount: amount, nonce: nonce, holder: true});
        bytes memory callData = abi.encodeWithSelector(GenesisMinter.claim.selector, mintData);
        RelayData memory data = RelayData({
            nonce: nonce,
            to: address(minterImpl),
            validityStart: block.timestamp,
            validityEnd: block.timestamp + 1 days,
            chainId: block.chainid,
            callData: callData
        });
        bytes memory sig = get_relay_data_sig(minterPrivateKey, data);

        // Change network
        vm.chainId(1337);
        vm.expectRevert(AuthenticatedRelay.InvalidSignature.selector);
        relay.relay(data, sig);

        vm.stopPrank();
    }

}
