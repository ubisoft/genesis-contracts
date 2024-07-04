// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.24;

import {GenesisChampion_Base_Test} from "./GenesisChampion.t.sol";
import {MessagingFee} from "@layerzerolabs/lz-evm-oapp-v2/contracts/oapp/OApp.sol";

import {MessagingReceipt} from "@layerzerolabs/lz-evm-oapp-v2/contracts/oapp/OAppSender.sol";
import {OptionsBuilder} from "@layerzerolabs/lz-evm-oapp-v2/contracts/oapp/libs/OptionsBuilder.sol";
import {Packet} from "@layerzerolabs/lz-evm-protocol-v2/contracts/interfaces/ISendLib.sol";
import {ExecutorOptions} from "@layerzerolabs/lz-evm-protocol-v2/contracts/messagelib/libs/ExecutorOptions.sol";
import {IERC721Errors} from "@openzeppelin/contracts/interfaces/draft-IERC6093.sol";
import {ERC721} from "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import {IERC721} from "@openzeppelin/contracts/token/ERC721/IERC721.sol";

import {SafeCast} from "@openzeppelin/contracts/utils/math/SafeCast.sol";
import {AccessControl} from "openzeppelinV4/access/AccessControl.sol";
import {IAccessControl} from "openzeppelinV4/access/IAccessControl.sol";
import {Strings} from "openzeppelinV4/utils/Strings.sol";
import {GenesisChampion} from "src/GenesisChampion.sol";
import {GenesisChampionBridged} from "src/GenesisChampionBridged.sol";
import {Errors} from "src/librairies/Errors.sol";
import {GenesisChampionArgs} from "src/types/GenesisChampionArgs.sol";
import {BaseTest} from "test/Base.t.sol";

contract GenesisChampion_Bridge_Test is GenesisChampion_Base_Test {

    using SafeCast for uint256;
    using OptionsBuilder for bytes;

    uint256 internal amount = 5;
    GenesisChampionBridged internal champion2;

    function setUp() public virtual override {
        GenesisChampion_Base_Test.setUp();

        vm.startPrank(owner);
        // Deploy a second GenesisChampion contract (should be another chain)
        champion2 = new GenesisChampionBridged(
            "GenesisChampion", "CMP", "ipfs://Qmbcg4ykX7dTYMdRkfM4yJ8ovHBfqpDuk3GiEjdTKr1uw9/", endpoints[eid2], owner
        );
        champion.setPeer(champion2.endpoint().eid(), addressToBytes32(address(champion2)));
        champion2.setPeer(champion.endpoint().eid(), addressToBytes32(address(champion)));
        vm.stopPrank();
    }

    modifier mintBefore() {
        vm.startPrank(minter);
        address to = bob;
        vm.deal(bob, 1 ether);

        // to should not own any token prior to the mint
        uint256 beforeBalance = champion.balanceOf(to);
        assertEq(beforeBalance, 0);

        // mint `amout` for `to`
        (uint256 firstId, uint256 lastId) = champion.mint(to, amount);
        assertEq(firstId + (amount - 1), lastId);

        // balance was updated by `amount`
        uint256 balance = champion.balanceOf(to);
        assertEq(balance, amount);
        uint256[] memory tokens = champion.tokensOfOwner(to);
        assertEq(tokens.length, amount);

        // Total supply should match the amount of tokens minted
        assertEq(champion.totalSupply(), amount);
        vm.stopPrank();
        _;
    }

    function test_send_l0() public mintBefore {
        vm.startPrank(bob);

        // Tokens are not bridged
        uint256[] memory tokens = champion.tokensOfOwner(bob);
        assertEq(tokens.length, amount);

        uint256 targetToken = 3;

        // Generates 1 lzReceive execution option via the OptionsBuilder library.
        // STEP 0: Estimating message gas fees via the quote function.
        bytes memory opts = OptionsBuilder.newOptions().addExecutorLzReceiveOption(150000, 0);
        MessagingFee memory fee = champion.quote(eid2, bob, targetToken, opts, false);

        // STEP 1: Bridge NFT via the _lzSend() method.
        vm.expectEmit();
        emit IERC721.Transfer(bob, address(champion), targetToken);
        MessagingReceipt memory receipt = champion.send{value: fee.nativeFee}(eid2, bob, targetToken, opts);

        // GenesisChampion now owns the token
        assertEq(champion.ownerOf(targetToken), address(champion));

        // Asserting that the receiving GenesisChampionBridged OApp has NOT had data manipulated.
        vm.expectRevert(abi.encodeWithSelector(IERC721Errors.ERC721NonexistentToken.selector, targetToken));
        champion2.ownerOf(targetToken);

        // STEP 2 & 3: Deliver packet to GenesisChampionBridged manually.
        verifyPackets(eid2, addressToBytes32(address(champion2)));

        // User received its nft
        assertEq(champion2.ownerOf(targetToken), bob);
        vm.stopPrank();

        // Intermediate: try to steal the token from another wallet
        address thief = vm.addr(0xABCDEF);
        vm.deal(thief, 1 ether);

        bytes memory opts2 = OptionsBuilder.newOptions().addExecutorLzReceiveOption(150000, 0);
        MessagingFee memory fee2 = champion2.quote(eid1, thief, targetToken, opts2, false);

        vm.prank(thief);
        vm.expectRevert(abi.encodeWithSelector(IERC721Errors.ERC721InvalidSender.selector, thief));
        champion2.send{value: fee2.nativeFee}(eid1, thief, targetToken, opts2);

        // STEP 4: Bridge back
        vm.startPrank(bob);
        bytes memory opts3 = OptionsBuilder.newOptions().addExecutorLzReceiveOption(150000, 0);
        MessagingFee memory fee3 = champion2.quote(eid1, bob, targetToken, opts3, false);
        vm.expectEmit();
        emit IERC721.Transfer(bob, address(0), targetToken);
        MessagingReceipt memory receipt2 = champion2.send{value: fee3.nativeFee}(eid1, bob, targetToken, opts3);

        // Token is burnt
        vm.expectRevert(abi.encodeWithSelector(IERC721Errors.ERC721NonexistentToken.selector, targetToken));
        champion2.ownerOf(targetToken);

        // Fulfill the request
        verifyPackets(eid1, addressToBytes32(address(champion)));

        // Contract doesn't own the token anymore
        assertEq(champion.ownerOf(targetToken), bob);

        vm.stopPrank();
    }

}
