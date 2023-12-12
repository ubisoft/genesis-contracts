// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.18;

import {AccessControl} from "openzeppelin/access/AccessControl.sol";
import {BaseTest} from "test/Base.t.sol";
import {Events} from "test/utils/Events.sol";
import {Errors} from "src/librairies/Errors.sol";
import {GenesisPFP} from "src/GenesisPFP.sol";
import {GenesisPFP_Base_Test} from "./GenesisPFP.t.sol";
import {MintData} from "src/types/MintData.sol";

/**
 * @dev Transfer_Test holds all tests related to the transfer functions
 */
contract Transfer_Test is GenesisPFP_Base_Test {
    function setUp() public virtual override {
        GenesisPFP_Base_Test.setUp();

        vm.startPrank(bob);
    }

    /**
     * @dev test the transfer of a token from public mint
     */
    function test_transfer_one() public {
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

        genesis.mintWithSignature(data, sig);
        uint256 balance = genesis.balanceOf(bob);
        require(balance == 2);

        genesis.transferFrom(bob, vm.addr(42), 1);
        require(genesis.balanceOf(vm.addr(42)) == 1);
    }

    /**
     * @dev test the safe transfer of one token from public mint
     */
    function test_safe_transfer_one() public {
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

        genesis.mintWithSignature(data, sig);
        uint256 balance = genesis.balanceOf(bob);
        require(balance == 2);

        genesis.safeTransferFrom(bob, vm.addr(42), 1);
        require(genesis.balanceOf(vm.addr(42)) == 1);
    }

    /**
     * @dev test the transfer of many tokens from public mint
     */
    function test_transfer_many() public {
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

        genesis.mintWithSignature(data, sig);
        uint256 balance = genesis.balanceOf(bob);
        require(balance == 2);

        genesis.transferFrom(bob, vm.addr(42), 1);
        genesis.transferFrom(bob, vm.addr(42), 2);
        require(genesis.balanceOf(vm.addr(42)) == 2);
    }

    /**
     * @dev test the safe transfer of many token from public mint
     */
    function test_safe_transfer_many() public {
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
        
        genesis.mintWithSignature(data, sig);
        uint256 balance = genesis.balanceOf(bob);
        require(balance == 2);

        genesis.safeTransferFrom(bob, vm.addr(42), 1);
        genesis.safeTransferFrom(bob, vm.addr(42), 2);
        require(genesis.balanceOf(vm.addr(42)) == 2);
    }
}
