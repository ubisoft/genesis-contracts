// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.24;

import {GenesisRewardDistributor_Base_Test} from "./GenesisRewardDistributor.t.sol";
import {AccessControl} from "@openzeppelin/contracts/access/AccessControl.sol";
import {IERC721} from "openzeppelinV4/token/ERC721/IERC721.sol";
import {GenesisChampion} from "src/GenesisChampion.sol";
import {GenesisRewardDistributor, RewardType} from "src/GenesisRewardDistributor.sol";
import {Errors} from "src/librairies/Errors.sol";
import {GenesisChampionArgs} from "src/types/GenesisChampionArgs.sol";
import {RewardClaim} from "src/types/RewardClaim.sol";
import {SeasonReward} from "src/types/SeasonReward.sol";
import {Events} from "test/utils/Events.sol";

contract GenesisRewardDistributor_Allocate_Test is GenesisRewardDistributor_Base_Test {

    function setUp() public virtual override {
        GenesisRewardDistributor_Base_Test.setUp();

        // Change timestamp
        vm.warp(1718212400);

        // Create a Champion collection as reward
        champion = new GenesisChampion(
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
    }

    modifier prankAs(address pranker) {
        vm.startPrank(pranker);
        _;
        vm.stopPrank();
    }

    /**
     * @dev test the correct creation of season rewards as contract owner
     */
    function test_allocate_and_claim() external {
        // Setup SeasonReward
        uint256 nSeason = 1;
        uint256 expectedClaimStart = block.timestamp + 5 minutes;
        uint256 expectedClaimEnd = block.timestamp + 5 days;
        uint256 expectedSupply = 500;

        // User owns 0 tokens before claiming
        assertEq(champion.balanceOf(minter), 0);

        {
            SeasonReward memory reward = SeasonReward({
                collection: address(champion),
                rewardType: uint8(RewardType.ERC721),
                supply: expectedSupply,
                tokenId: 0,
                claimStart: expectedClaimStart,
                claimEnd: expectedClaimEnd
            });

            vm.prank(owner);
            vm.expectEmit();
            emit GenesisRewardDistributor.NewSeasonReward(nSeason);
            rewarder.allocate(nSeason, reward);
        }
        {
            // Retrieved SeasonReward matches the one registered previously
            (address _col, uint8 _rt, uint256 _s, uint256 _ti, uint256 _cs, uint256 _ce) = rewarder.rewards(nSeason);
            assertEq(_col, address(champion));
            assertEq(_rt, uint8(RewardType.ERC721));
            assertEq(_s, expectedSupply);
            assertEq(_ti, 0);
            assertEq(_cs, expectedClaimStart);
            assertEq(_ce, expectedClaimEnd);
        }
        // Claim from a MINTER_ROLE wallet
        bytes32 userNonce = keccak256("claim-from-minter");
        uint256 expectedAmount = 3;
        RewardClaim memory rc = RewardClaim({season: nSeason, to: minter, amount: expectedAmount, nonce: userNonce});

        // Cannot claim before the claimin period opens
        vm.startPrank(minter);
        vm.expectRevert(Errors.ClaimingPeriodClosed.selector);
        rewarder.claim(rc);

        // Warp before claim end
        vm.warp(expectedClaimEnd - 12 hours);

        // 3 tokens minted
        vm.expectEmit();
        emit IERC721.Transfer(address(0), minter, 1);
        vm.expectEmit();
        emit IERC721.Transfer(address(0), minter, 2);
        vm.expectEmit();
        emit IERC721.Transfer(address(0), minter, 3);
        // ClaimReward event
        vm.expectEmit();
        emit GenesisRewardDistributor.ClaimReward(userNonce, minter);
        rewarder.claim(rc);
        vm.stopPrank();

        // Supply decreased
        (,, uint256 newSupply,,,) = rewarder.rewards(nSeason);
        assertEq(newSupply, expectedSupply - expectedAmount);
        // User balance increased
        assertEq(champion.balanceOf(minter), expectedAmount);
    }

    /**
     * @dev test the correct creation of season rewards as contract owner
     */
    function test_RevertWhen_validSeasonConfig() external {
        // Setup SeasonReward
        uint256 nSeason = 1;
        uint256 expectedClaimStart = block.timestamp + 1 minutes;
        uint256 expectedClaimEnd = block.timestamp + 5 days;
        uint256 expectedSupply = 500;

        SeasonReward memory reward = SeasonReward({
            collection: address(champion),
            rewardType: uint8(RewardType.ERC721),
            supply: expectedSupply,
            tokenId: 0,
            claimStart: expectedClaimStart,
            claimEnd: expectedClaimEnd
        });
        vm.prank(owner);
        vm.expectEmit();
        emit GenesisRewardDistributor.NewSeasonReward(nSeason);
        rewarder.allocate(nSeason, reward);

        // Duplicating SeasonReward 1 should revert with SeasonAlreadyExist
        vm.prank(owner);
        vm.expectRevert(Errors.SeasonAlreadyExist.selector);
        rewarder.allocate(nSeason, reward);

        // Create Season 2 with invalid start date
        // should revert with RewardsClaimStart
        SeasonReward memory reward2 = SeasonReward({
            collection: address(champion),
            rewardType: uint8(RewardType.ERC721),
            supply: expectedSupply,
            tokenId: 0,
            claimStart: block.timestamp - 1 days,
            claimEnd: block.timestamp + 1 days
        });
        vm.prank(owner);
        vm.expectRevert(Errors.RewardsClaimStart.selector);
        rewarder.allocate(2, reward2);

        // Create Season 2 with invalid end date
        // should revert with RewardsClaimEnd
        SeasonReward memory reward3 = SeasonReward({
            collection: address(champion),
            rewardType: uint8(RewardType.ERC721),
            supply: expectedSupply,
            tokenId: 0,
            claimStart: block.timestamp + 5 days,
            claimEnd: block.timestamp + 1 days
        });
        vm.prank(owner);
        vm.expectRevert(Errors.RewardsClaimEnd.selector);
        rewarder.allocate(2, reward3);

        // Create Season 2 with invalid supply
        // should revert with ZeroSupply
        SeasonReward memory reward4 = SeasonReward({
            collection: address(champion),
            rewardType: uint8(RewardType.ERC721),
            supply: 0,
            tokenId: 0,
            claimStart: block.timestamp + 1 minutes,
            claimEnd: block.timestamp + 1 days
        });
        vm.prank(owner);
        vm.expectRevert(Errors.ZeroSupply.selector);
        rewarder.allocate(2, reward4);

        // Create Season 2 with invalid reward address
        // should revert with ZeroAddress
        SeasonReward memory reward5 = SeasonReward({
            collection: address(0),
            rewardType: uint8(RewardType.ERC721),
            supply: expectedSupply,
            tokenId: 0,
            claimStart: block.timestamp + 1 minutes,
            claimEnd: block.timestamp + 1 days
        });
        vm.prank(owner);
        vm.expectRevert(Errors.ZeroAddress.selector);
        rewarder.allocate(2, reward5);

        // Cannot claim if supply has reached 0
        // Claim the supply prior to revert
        SeasonReward memory reward6 = SeasonReward({
            collection: address(champion),
            rewardType: uint8(RewardType.ERC721),
            supply: 5,
            tokenId: 0,
            claimStart: block.timestamp + 5 minutes,
            claimEnd: block.timestamp + 5 days
        });
        vm.prank(owner);
        rewarder.allocate(2, reward6);

        // Warp
        vm.warp(block.timestamp + 10 minutes);

        // Claim from a MINTER_ROLE wallet
        bytes32 userNonce = keccak256("claim-all");
        RewardClaim memory rc = RewardClaim({season: 2, to: minter, amount: 5, nonce: userNonce});
        vm.prank(minter);
        rewarder.claim(rc);

        // Minter balance increased
        assertEq(champion.balanceOf(minter), 5);
        // Supply decreased to 0
        (,, uint256 newSupply,,,) = rewarder.rewards(2);
        assertEq(newSupply, 0);

        // Claim again with different nonce
        bytes32 userNonce2 = keccak256("claim-all-2");
        RewardClaim memory rc2 = RewardClaim({season: 2, to: minter, amount: 5, nonce: userNonce2});
        vm.prank(minter);
        vm.expectRevert(Errors.MaxSupplyReached.selector);
        rewarder.claim(rc2);
    }

}
