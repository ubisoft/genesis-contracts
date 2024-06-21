// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.24;

import {AuthenticatedRelay_Base_Test} from "../AuthenticatedRelay.t.sol";
import {AccessControl} from "@openzeppelin/contracts/access/AccessControl.sol";
import {AuthenticatedRelay, RelayData} from "authenticated-relay/AuthenticatedRelay.sol";
import {IERC721} from "openzeppelinV4/token/ERC721/IERC721.sol";
import {GenesisChampion} from "src/GenesisChampion.sol";
import {GenesisRewardDistributor, RewardType} from "src/GenesisRewardDistributor.sol";
import {Errors} from "src/librairies/Errors.sol";
import {GenesisChampionArgs} from "src/types/GenesisChampionArgs.sol";
import {RewardClaim} from "src/types/RewardClaim.sol";
import {SeasonReward} from "src/types/SeasonReward.sol";
import {Events} from "test/utils/Events.sol";

contract GenesisRewardDistributor_Allocate_Test is AuthenticatedRelay_Base_Test {

    uint256 internal claimStart;
    uint256 internal claimEnd;
    uint256 internal supply;

    function setUp() public virtual override {
        AuthenticatedRelay_Base_Test.setUp();

        // Deploy GenesisRewardDistributor
        vm.prank(owner);
        rewarder = new GenesisRewardDistributor(address(relay));
        vm.label({account: address(rewarder), newLabel: "GenesisRewardDistributor"});

        vm.prank(owner);
        // Create a Champion collection as reward
        (address newChampion, uint256 index) = factory.deploy(
            GenesisChampionArgs({
                name: "GenesisChampion",
                symbol: "GEN",
                baseURI: "ipfs://Qmbcg4ykX7dTYMdRkfM4yJ8ovHBfqpDuk3GiEjdTKr1uw9/default.json",
                owner: owner,
                minter: address(rewarder),
                crafter: address(0),
                vault: vault,
                endpointL0: endpoints[eid1],
                defaultMaxCraftCount: GENESIS_CHAMP_DEFAULT_MAX_CRAFT_COUNT
            })
        );
        champion = GenesisChampion(newChampion);

        // Change timestamp
        vm.warp(1718212400);
    }

    /**
     * @dev test the correct creation of season rewards as contract owner
     */
    function test_allocate_and_claim() external {
        // Setup a SeasonReward
        claimStart = block.timestamp + 5 minutes;
        claimEnd = block.timestamp + 5 days;
        supply = 500;
        // Setup a SeasonReward
        SeasonReward memory reward = SeasonReward({
            collection: address(champion),
            rewardType: uint8(RewardType.ERC721),
            supply: supply,
            tokenId: 0,
            claimStart: claimStart,
            claimEnd: claimEnd
        });
        vm.prank(owner);
        vm.expectEmit();
        emit GenesisRewardDistributor.NewSeasonReward(1);
        rewarder.allocate(1, reward);
        (
            address curCollection,
            uint8 curRewardType,
            uint256 curSupply,
            uint256 curTokenId,
            uint256 curClaimStart,
            uint256 curClaimEnd
        ) = rewarder.rewards(1);
        assertEq(curCollection, address(champion));
        assertEq(curRewardType, uint8(RewardType.ERC721));
        assertEq(curSupply, supply);
        assertEq(curTokenId, 0);
        assertEq(curClaimStart, claimStart);
        assertEq(curClaimEnd, claimEnd);

        // Generate a Claim from a user wallet
        bytes32 userNonce = keccak256("claim-bob-1");
        RewardClaim memory rc = RewardClaim({season: 1, to: bob, amount: 2, nonce: userNonce});
        bytes memory claimCalldata = abi.encodeWithSelector(GenesisRewardDistributor.claim.selector, rc);

        // Warp before claim end
        vm.warp(claimStart + 12 hours);

        RelayData memory data = RelayData({
            nonce: userNonce,
            to: address(rewarder),
            validityStart: claimStart,
            validityEnd: claimEnd,
            chainId: block.chainid,
            callData: claimCalldata
        });

        bytes memory sig = get_relay_data_sig(minterPrivateKey, data);
        vm.expectEmit(true, false, false, true);
        emit AuthenticatedRelay.SignatureUsed(userNonce, false);
        // 2 tokens minted
        vm.expectEmit();
        emit IERC721.Transfer(address(0), bob, 1);
        vm.expectEmit();
        emit IERC721.Transfer(address(0), bob, 2);
        // ClaimReward event)
        vm.expectEmit();
        emit GenesisRewardDistributor.ClaimReward(userNonce, bob);

        vm.prank(bob);
        relay.relay(data, sig);

        // Supply decreased
        (,, uint256 newSupply,,,) = rewarder.rewards(1);
        assertEq(newSupply, supply - 2);
        // User balance increased
        assertEq(champion.balanceOf(bob), 2);
    }

}
