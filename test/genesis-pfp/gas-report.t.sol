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
 * @dev GasReport_Test holds all tests used to generate gas reports
 */
contract GasReport_Test is GenesisPFP_Base_Test {
    using stdStorage for StdStorage;

    function setUp() public virtual override {
        GenesisPFP_Base_Test.setUp();
    }

    /**
     * @dev This test is used to benchmark the minting gas cost for reserve mint
     * @dev cmd: forge test --mt "reserve_gas_report" --gas-report
     */
    function test_mint_reserve_gas_report() public {
        vm.startPrank(reserveWallet);
        require(genesis.remainingSupply() == 9999);
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
            assertEq(genesis.balanceOf(reserveWallet), 200);

            // Simulate transfers for gas report
            for (uint256 i = 1; i <= 200; i+=2) {
                genesis.transferFrom(reserveWallet, vm.addr(i), i);
                genesis.safeTransferFrom(reserveWallet, vm.addr(i + 1), i + 1);
            }
        }
        vm.stopPrank();
    }

    /**
     * @dev This test is used to benchmark the minting gas cost and transfer costs for individuals mints
     * @dev cmd: forge test --mt "mint_transfer_gas_report" --gas-report
     */
    function test_mint_transfer_gas_report() public {
        uint256 i = 1;
        vm.startPrank(vm.addr(i));

        while (genesis.remainingSupply() > 0) {
            bool lastMint = (genesis.remainingSupply() == 1);
            address _minter = vm.addr(i);
            changePrank(_minter);

            bytes32 nonce = bytes32(keccak256(abi.encode(_minter)));
            MintData memory data = MintData({
                to: _minter,
                validity_start: block.timestamp,
                validity_end: 1 days,
                chain_id: block.chainid,
                mint_amount: 2,
                user_nonce: nonce
            });
            bytes memory sig = get_mint_data_sig(minterPrivateKey, data);

            // Mint and trigger a transfer with each transfer method for benchmarking purpose
            genesis.mintWithSignature(data, sig);
            genesis.balanceOf(_minter);

            if (lastMint) {
                genesis.transferFrom(_minter, vm.addr(i + 0xFFFFA), i);
                i++;
            } else {
                genesis.safeTransferFrom(_minter, vm.addr(i + 1 + 0xFFFFA), i + 1);
                genesis.transferFrom(_minter, vm.addr(i + 0xFFFFA), i);
                i += 2;
            }
        }
    }
}