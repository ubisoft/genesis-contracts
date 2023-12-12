// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.18;

import {AccessControl} from "openzeppelin/access/AccessControl.sol";
import {BaseTest} from "test/Base.t.sol";
import {Events} from "test/utils/Events.sol";
import {Errors} from "src/librairies/Errors.sol";
import {GenesisPFP} from "src/GenesisPFP.sol";
import {GenesisPFP_Base_Test} from "./GenesisPFP.t.sol";
import {MintData} from "src/types/MintData.sol";
import {StdStorage, stdStorage} from "forge-std/Test.sol";

/**
 * @dev MintWithSignature_Test holds all tests related to the `mintWithSignature` function
 */
contract MintWithSignature_Test is GenesisPFP_Base_Test {
    using stdStorage for StdStorage;

    function setUp() public virtual override {
        GenesisPFP_Base_Test.setUp();
    }

    // =============================================================
    //                   MINT TESTS
    // =============================================================

    /**
     * @dev test mint with all phases included (RESERVE, PRIVATE, PUBLIC)
     * @dev phases are decided by the backend, not declard within the contract
     * @dev phases should be executed in the following order:
     * @dev Phase [RESERVE] -> our backend will mint 200 tokens for the reserve at launch
     * @dev     in case public mint does not sell out, our backend can mint the remaining tokens
     * @dev Phase [PRIVATE] and phase [PUBLIC] are executed with a slight delay for PUBLIC minters
     * @dev     [PRIVATE] minters can mint 2 tokens in advance
     * @dev     [PUBLIC] minters can mint 2 tokens
     */
    function test_mint_all() public {
        uint256 token_count = 0;
        uint256 wallet_index = 1;

        vm.startPrank(reserveWallet);
        // Phase [RESERVE]: mint 200 reserve tokens to `reserveWallet`
        {
            assertEq(genesis.remainingSupply(), 9999);
            bytes32 nonce = bytes32(keccak256(abi.encode(reserveWallet)));
            MintData memory data = MintData({
                to: reserveWallet,
                validity_start: block.timestamp,
                validity_end: 1 days,
                chain_id: block.chainid,
                mint_amount: MINT_MIN_RESERVE,
                user_nonce: nonce
            });
            bytes memory sig = get_mint_data_sig(minterPrivateKey, data);

            genesis.mintWithSignature(data, sig);
            uint256 balance = genesis.balanceOf(reserveWallet);
            token_count += balance;
            assertEq(balance, 200);
            assertEq(genesis.remainingSupply(), 9799);

            // Tokens can be transfered after reserve mint
            for (uint256 i = 1; i <= balance; i++) {
                genesis.transferFrom(reserveWallet, vm.addr(0xdead), i);
            }
        }
        // Phase [PRIVATE]: mint from 300 wallets (600 tokens)
        {
            uint256 mint_count = 0;
            uint256 expected_mint_count = 600;
            assertEq(genesis.remainingSupply(), 9799);
            while (genesis.remainingSupply() > 9199) {
                address dest = vm.addr(wallet_index);
                changePrank(dest);
                bytes32 nonce = bytes32(keccak256(abi.encode(dest)));
                MintData memory data = MintData({
                    to: dest,
                    validity_start: block.timestamp,
                    validity_end: (block.timestamp + 10 days),
                    chain_id: block.chainid,
                    mint_amount: MINT_MAX_PRIVATE,
                    user_nonce: nonce
                });
                bytes memory sig = get_mint_data_sig(minterPrivateKey, data);

                genesis.mintWithSignature(data, sig);
                uint256 balance = genesis.balanceOf(dest);
                assertEq(balance, MINT_MAX_PRIVATE);

                // Increment counters
                token_count += balance;
                mint_count += balance;
                wallet_index += 1;

                // Test the transfer
                genesis.transferFrom(dest, vm.addr(0xdead), (token_count - 1));
                genesis.transferFrom(dest, vm.addr(0xdead), (token_count));
            }
            assertEq(mint_count, expected_mint_count);
            assertEq(genesis.remainingSupply(), 9199);
        }
        // Phase [PUBLIC]: partially mint the supply with 4500 wallets, leave 199 tokens
        {
            uint256 mint_count = 0;
            uint256 expected_mint_count = 9000;
            assertEq(genesis.remainingSupply(), 9199);
            while (genesis.remainingSupply() > 199) {
                address dest = vm.addr(wallet_index);
                changePrank(dest);
                bytes32 nonce = bytes32(keccak256(abi.encode(dest)));
                MintData memory data = MintData({
                    to: dest,
                    validity_start: block.timestamp,
                    validity_end: (block.timestamp + 10 days),
                    chain_id: block.chainid,
                    mint_amount: MINT_MAX_PUBLIC,
                    user_nonce: nonce
                });
                bytes memory sig = get_mint_data_sig(minterPrivateKey, data);

                genesis.mintWithSignature(data, sig);
                uint256 balance = genesis.balanceOf(dest);
                assertEq(balance, 2);

                // Increment counters
                token_count += balance;
                mint_count += balance;
                wallet_index += 1;

                // Tokens can be transfered after public mint
                genesis.transferFrom(dest, vm.addr(0xdead), (token_count - 1));
                genesis.transferFrom(dest, vm.addr(0xdead), (token_count));
            }
            assertEq(mint_count, expected_mint_count);
            assertEq(genesis.remainingSupply(), 199);
            token_count += mint_count;
        }
        assertEq(genesis.remainingSupply(), 199);
        // Phase [RESERVE]: if there are unminted tokens after the public window, mint the remaining for the reserve
        {
            changePrank(reserveWallet);
            assertEq(genesis.remainingSupply(), 199);
            bytes32 nonce = bytes32(keccak256(abi.encodePacked(reserveWallet, "_bis")));
            MintData memory data = MintData({
                to: reserveWallet,
                validity_start: block.timestamp,
                validity_end: 1 days,
                chain_id: block.chainid,
                mint_amount: 199,
                user_nonce: nonce
            });
            bytes memory sig = get_mint_data_sig(minterPrivateKey, data);

            genesis.mintWithSignature(data, sig);
            uint256 balance = genesis.balanceOf(reserveWallet);
            token_count += balance;
            // We already transfered the first batch of reserve tokens
            assertEq(balance, 199);
        }
        assertEq(genesis.remainingSupply(), 0);
        // A user send its tx with gas too low/forgot to hit send but the supply is now empty
        {
            address dest = vm.addr(0xc1053d);
            changePrank(dest);
            bytes32 nonce = bytes32(keccak256(abi.encode(dest)));
            MintData memory data = MintData({
                to: dest,
                validity_start: block.timestamp,
                validity_end: 1 days,
                chain_id: block.chainid,
                mint_amount: MINT_MAX_PUBLIC,
                user_nonce: nonce
            });
            bytes memory sig = get_mint_data_sig(minterPrivateKey, data);

            vm.expectRevert(Errors.MaxSupplyReached.selector);
            genesis.mintWithSignature(data, sig);
        }
    }

    // =============================================================
    //                   REVERT TESTS
    // =============================================================

    /**
     * @dev test the mint of reserve tokens twice by `reserveWallet`
     * @dev should revert in the second call with AlreadyMinted if same nonce is used
     * @dev should not revert in the third call if the nonce is updated
     */
    function test_RevertWhen_mint_reserve_twice() public {
        vm.startPrank(reserveWallet);
        // Should not revert when using a valid nonce
        assertEq(genesis.remainingSupply(), 9999);
        {
            bytes32 nonce = bytes32(keccak256(abi.encode(reserveWallet)));
            MintData memory data = MintData({
                to: reserveWallet,
                validity_start: block.timestamp,
                validity_end: 1 days,
                chain_id: block.chainid,
                mint_amount: MINT_MIN_RESERVE,
                user_nonce: nonce
            });
            bytes memory sig = get_mint_data_sig(minterPrivateKey, data);

            genesis.mintWithSignature(data, sig);
            uint256 balance = genesis.balanceOf(reserveWallet);
            assertEq(balance, MINT_MIN_RESERVE);
        }
        // Should revert when using the same nonce after succesful mint
        {
            bytes32 nonce = bytes32(keccak256(abi.encode(reserveWallet)));
            MintData memory data = MintData({
                to: reserveWallet,
                validity_start: block.timestamp,
                validity_end: 1 days,
                chain_id: block.chainid,
                mint_amount: MINT_MIN_RESERVE,
                user_nonce: nonce
            });
            bytes memory sig = get_mint_data_sig(minterPrivateKey, data);

            vm.expectRevert(Errors.AlreadyMinted.selector);
            genesis.mintWithSignature(data, sig);
            uint256 balance = genesis.balanceOf(reserveWallet);
            assertEq(balance, MINT_MIN_RESERVE);
        }
        // Should not revert when using a new valid nonce
        {
            bytes32 nonce = bytes32(keccak256(abi.encodePacked(reserveWallet, "_bis")));
            MintData memory data = MintData({
                to: reserveWallet,
                validity_start: block.timestamp,
                validity_end: 1 days,
                chain_id: block.chainid,
                mint_amount: 9799,
                user_nonce: nonce
            });
            bytes memory sig = get_mint_data_sig(minterPrivateKey, data);

            genesis.mintWithSignature(data, sig);
            uint256 balance = genesis.balanceOf(reserveWallet);
            assertEq(balance, 9999);
        }
        assertEq(genesis.remainingSupply(), 0);
        vm.stopPrank();
    }

    /**
     * @dev test the revert of invalid signatures when a user
     * @dev without MINTER_ROLE signs the mint request
     * @dev should revert with InvalidSignature
     */
    function test_RevertWhen_invalid_signature() public {
        bytes32 nonce = bytes32(keccak256(abi.encode(bob)));
        MintData memory data = MintData({
            to: bob,
            validity_start: block.timestamp,
            validity_end: 1 days,
            chain_id: block.chainid,
            mint_amount: MINT_MAX_PUBLIC,
            user_nonce: nonce
        });
        // Random user cannot sign a mint authorization
        {
            bytes memory sig = get_mint_data_sig(bobPrivateKey, data);

            vm.expectRevert(Errors.InvalidSignature.selector);
            vm.prank(bob);
            genesis.mintWithSignature(data, sig);
        }
        // Contract owner cannot sign a mint authorization
        {
            bytes memory sig = get_mint_data_sig(ownerPrivateKey, data);

            vm.expectRevert(Errors.InvalidSignature.selector);
            vm.prank(bob);
            genesis.mintWithSignature(data, sig);
        }
    }

    /**
     * @dev test the revert when signature.validity_start < block.timestamp
     * @dev should revert with SignatureValidityStart
     */
    function test_RevertWhen_mint_validity_start() public {
        vm.warp(100);
        bytes32 nonce = bytes32(keccak256(abi.encode(bob)));
        MintData memory data = MintData({
            to: bob,
            validity_start: 200,
            validity_end: 500,
            chain_id: block.chainid,
            mint_amount: MINT_MAX_PUBLIC,
            user_nonce: nonce
        });
        bytes memory sig = get_mint_data_sig(minterPrivateKey, data);

        vm.expectRevert(Errors.SignatureValidityStart.selector);
        vm.prank(bob);
        genesis.mintWithSignature(data, sig);

        vm.warp(201);
        vm.prank(bob);
        genesis.mintWithSignature(data, sig);
    }

    /**
     * @dev test the revert when signature.validity_end > block.timestamp
     * @dev should revert with SignatureValidityEnd
     */
    function test_RevertWhen_mint_validity_end() public {
        bytes32 nonce = bytes32(keccak256(abi.encode(bob)));
        MintData memory data = MintData({
            to: bob,
            validity_start: block.timestamp,
            validity_end: 5 minutes,
            chain_id: block.chainid,
            mint_amount: MINT_MAX_PUBLIC,
            user_nonce: nonce
        });
        bytes memory sig = get_mint_data_sig(minterPrivateKey, data);

        vm.warp(1 days);
        vm.prank(bob);
        vm.expectRevert(Errors.SignatureValidityEnd.selector);
        genesis.mintWithSignature(data, sig);
    }

    /**
     * @dev test the revert of invalid signatures with wrong chainId
     * @dev should revert with WrongChainID
     */
    function test_RevertWhen_invalid_sig_chain_id() public {
        bytes32 nonce = bytes32(keccak256(abi.encode(bob)));
        MintData memory data = MintData({
            to: bob,
            validity_start: block.timestamp,
            validity_end: 1 days,
            chain_id: block.chainid,
            mint_amount: MINT_MAX_PUBLIC,
            user_nonce: nonce
        });
        bytes memory sig = get_mint_data_sig(minterPrivateKey, data);

        vm.prank(bob);
        genesis.mintWithSignature(data, sig);

        // Change network
        vm.chainId(1337);
        vm.prank(bob);
        vm.expectRevert(Errors.WrongChainID.selector);
        genesis.mintWithSignature(data, sig);
    }

    /**
     * @dev test the revert of corrupt signature
     * @dev should revert with InvalidSignature
     */
    function test_RevertWhen_corrupt_sig() public {
        bytes32 nonce = bytes32(keccak256(abi.encode(bob)));
        MintData memory data = MintData({
            to: bob,
            validity_start: block.timestamp,
            validity_end: 1 days,
            chain_id: block.chainid,
            mint_amount: MINT_MAX_PUBLIC,
            user_nonce: nonce
        });
        bytes memory sig = get_mint_data_sig(bobPrivateKey, data);

        // Corrupting `v` parameter from the signatures
        vm.prank(bob);
        vm.expectRevert(Errors.InvalidSignature.selector);
        genesis.mintWithSignature(data, sig);
    }

    /**
     * @dev test the revert of a mint when a user gets authorization for all mint types
     * @dev cannot happen unless our backend/signer infrastructure is compromised
     * @dev should revert with AlreadyMinted after any first mint
     */
    function test_RevertWhen_user_has_all_authorizations() public {
        bytes32 nonce = bytes32(keccak256(abi.encode(bob)));
        {
            MintData memory data = MintData({
                to: bob,
                validity_start: block.timestamp,
                validity_end: 1 days,
                chain_id: block.chainid,
                mint_amount: MINT_MAX_PUBLIC,
                user_nonce: nonce
            });
            bytes memory sig = get_mint_data_sig(minterPrivateKey, data);

            vm.prank(bob);
            genesis.mintWithSignature(data, sig);
            assertEq(genesis.balanceOf(bob), 2);
        }
        {
            MintData memory data = MintData({
                to: bob,
                validity_start: block.timestamp,
                validity_end: 1 days,
                chain_id: block.chainid,
                mint_amount: MINT_MAX_PRIVATE,
                user_nonce: nonce
            });
            bytes memory sig = get_mint_data_sig(minterPrivateKey, data);

            vm.expectRevert(Errors.AlreadyMinted.selector);
            vm.prank(bob);
            genesis.mintWithSignature(data, sig);
        }
        {
            MintData memory data = MintData({
                to: bob,
                validity_start: block.timestamp,
                validity_end: 1 days,
                chain_id: block.chainid,
                mint_amount: MINT_MIN_RESERVE,
                user_nonce: nonce
            });
            bytes memory sig = get_mint_data_sig(minterPrivateKey, data);

            vm.prank(bob);
            vm.expectRevert(Errors.AlreadyMinted.selector);
            genesis.mintWithSignature(data, sig);
        }
    }

    /**
     * @dev test the revert when the destination address is zero
     * @dev should revert with "ERC721Psi: transfer to the zero address"
     */
    function test_RevertWhen_mint_zero_address() public {
        bytes32 nonce = bytes32(keccak256(abi.encode("0x0")));
        MintData memory data = MintData({
            to: address(0),
            validity_start: block.timestamp,
            validity_end: 1 days,
            chain_id: block.chainid,
            mint_amount: 3,
            user_nonce: nonce
        });
        bytes memory sig = get_mint_data_sig(minterPrivateKey, data);

        // Can't send from 0x0 but MintData.to can
        vm.prank(bob);
        vm.expectRevert("ERC721Psi: mint to the zero address");
        genesis.mintWithSignature(data, sig);
    }
}
