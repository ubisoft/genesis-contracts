// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.24;

import {GenesisMinter_Base_Test} from "./GenesisMinter.t.sol";
import {IAccessControl} from "@openzeppelin/contracts/access/IAccessControl.sol";
import {Strings} from "openzeppelinV4/utils/Strings.sol";
import {GenesisChampion} from "src/GenesisChampion.sol";
import {GenesisChampionFactory} from "src/GenesisChampionFactory.sol";
import {GenesisMinter} from "src/GenesisMinter.sol";
import {Errors} from "src/librairies/Errors.sol";
import {GenesisChampionArgs} from "src/types/GenesisChampionArgs.sol";
import {MintData as MintDataV2} from "src/types/MintDataV2.sol";
import {SupplyConfig} from "src/types/SupplyConfig.sol";
import {Events} from "test/utils/Events.sol";

/**
 * @dev GenesisMinter_Claim_Test holds all tests related to the initial token claiming
 */
contract GenesisMinter_Claim_Test is GenesisMinter_Base_Test {

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

    function setUp() public virtual override {
        GenesisMinter_Base_Test.setUp();
    }

    // =============================================================
    //                   MINT TESTS
    // =============================================================

    /**
     * @dev `claim` can only be called by an address with `MINTER_ROLE`
     */
    function test_claim() public registerSupplyBeforeClaim {
        vm.startPrank(minter);

        // Get the supply config
        (uint256 sHolder, uint256 sPublic, bool init) = minterImpl.supply(address(champion));
        assertEq(sHolder, GENESIS_CHAMP_INITIAL_HOLDER_SUPPLY);
        assertEq(sPublic, GENESIS_CHAMP_INITIAL_PUBLIC_SUPPLY);
        assertEq(init, true);

        address to = reserveWallet;
        uint256 amount = GENESIS_CHAMP_CLAIM_HOLDERS;
        bytes32 nonce = bytes32("mint-holder-from-minter");
        MintDataV2 memory data =
            MintDataV2({collection: address(champion), to: to, amount: amount, nonce: nonce, holder: true});

        // caller cannot claim 0 tokens or more than the initial claimable supply
        uint256 exptectedSupplyAfterClaim = sHolder - amount;

        // claimWithSignature should emit Claim(indexed address, bytes32)
        vm.expectEmit();
        emit GenesisMinter.Claim(address(champion), nonce, amount);
        (uint256 firstId, uint256 lastId) = minterImpl.claim(data);

        // to's balance equals the requested `amount`
        uint256 balance = champion.balanceOf(to);
        assertEq(balance, amount);

        // get all tokens owned by address and verify they were minted in the range [firstId;lastId]
        uint256[] memory tokens = champion.tokensOfOwner(to);
        assertEq(tokens.length, amount);
        assertEq(tokens[0], firstId);
        assertEq(tokens[tokens.length - 1], lastId);

        // claimable supply decreased by `amount`
        (uint256 newSupplyHolder, uint256 newSupplyPublic,) = minterImpl.supply(address(champion));
        assertEq(newSupplyHolder, exptectedSupplyAfterClaim);
        assertEq(newSupplyPublic, sPublic);

        vm.stopPrank();
    }

    /**
     * @dev `claim` can only be called by an address with `MINTER_ROLE`
     */
    function test_claim_all() public registerSupplyBeforeClaim {
        vm.startPrank(minter);

        (uint256 sHolder, uint256 sPublic, bool init) = minterImpl.supply(address(champion));
        assertEq(sHolder, GENESIS_CHAMP_INITIAL_HOLDER_SUPPLY);
        assertEq(sPublic, GENESIS_CHAMP_INITIAL_PUBLIC_SUPPLY);
        assertEq(init, true);

        address to = reserveWallet;
        // Claim all holder tokens
        {
            uint256 amount = sHolder;
            bytes32 nonce = bytes32("mint-holder-all");
            MintDataV2 memory data =
                MintDataV2({collection: address(champion), to: to, amount: amount, nonce: nonce, holder: true});

            vm.expectEmit();
            emit GenesisMinter.Claim(address(champion), nonce, amount);
            minterImpl.claim(data);

            uint256 balance = champion.balanceOf(to);
            assertEq(balance, amount);

            // claimable supply decreased by `amount`
            (uint256 newSupplyHolder, uint256 newSupplyPublic,) = minterImpl.supply(address(champion));
            assertEq(newSupplyHolder, 0);
            assertEq(newSupplyPublic, sPublic);
        }
        // Claim all public tokens
        {
            uint256 amount = sPublic;
            bytes32 nonce = bytes32("mint-public-all");
            MintDataV2 memory data =
                MintDataV2({collection: address(champion), to: to, amount: amount, nonce: nonce, holder:false});

            vm.expectEmit();
            emit GenesisMinter.Claim(address(champion), nonce, amount);
            minterImpl.claim(data);

            uint256 balance = champion.balanceOf(to);
            assertEq(balance, (sHolder + sPublic));

            // claimable supply decreased by `amount`
            (uint256 newSupplyHolder, uint256 newSupplyPublic,) = minterImpl.supply(address(champion));
            assertEq(newSupplyHolder, 0);
            assertEq(newSupplyPublic, 0);
        }
        // Claim all holders a second time, will revert with MaxSupplyReached
        {
            uint256 amount = sHolder;
            bytes32 nonce = bytes32("mint-holder-all-twice");
            MintDataV2 memory data =
                MintDataV2({collection: address(champion), to: to, amount: amount, nonce: nonce, holder: true});

            vm.expectRevert(Errors.MaxSupplyReached.selector);
            minterImpl.claim(data);
        }
        // Claim all public a second time, will revert with MaxSupplyReached
        {
            uint256 amount = sPublic;
            bytes32 nonce = bytes32("mint-public-all-twice");
            MintDataV2 memory data =
                MintDataV2({collection: address(champion), to: to, amount: amount, nonce: nonce, holder: true});

            vm.expectRevert(Errors.MaxSupplyReached.selector);
            minterImpl.claim(data);
        }

        vm.stopPrank();
    }

    // =============================================================
    //                   REVERT TESTS
    // =============================================================

    /**
     * @dev will revert with "AccessControl: <role> is missing"
     */
    function test_RevertWhen_user_non_minter() public registerSupplyBeforeClaim {
        vm.startPrank(bob);

        // Get the supply config
        (uint256 sHolder, uint256 sPublic, bool init) = minterImpl.supply(address(champion));
        assertEq(sHolder, GENESIS_CHAMP_INITIAL_HOLDER_SUPPLY);
        assertEq(sPublic, GENESIS_CHAMP_INITIAL_PUBLIC_SUPPLY);
        assertEq(init, true);

        address to = bob;
        uint256 amount = GENESIS_CHAMP_CLAIM_HOLDERS;
        bytes32 nonce = bytes32("mint-holder-from-non-minter");
        MintDataV2 memory data =
            MintDataV2({collection: address(champion), to: to, amount: amount, nonce: nonce, holder: true});

        vm.expectRevert(
            abi.encodeWithSelector(IAccessControl.AccessControlUnauthorizedAccount.selector, bob, MINTER_ROLE)
        );
        minterImpl.claim(data);

        vm.stopPrank();
    }

    /**
     * @dev `claim` should revert if collection wasn't created by the factory
     */
    function test_RevertWhen_unregistered_collection() public {
        GenesisChampion impl = new GenesisChampion(
            GenesisChampionArgs({
                name: "GenesisChampion",
                symbol: "GN",
                baseURI: "ipfs://some_fake_cid/",
                owner: owner,
                minter: address(minterImpl),
                crafter: address(crafterImpl),
                vault: vault,
                endpointL0: endpoints[eid1],
                defaultMaxCraftCount: GENESIS_CHAMP_DEFAULT_MAX_CRAFT_COUNT
            })
        );

        bytes32 nonce = bytes32("collection-unknown");
        MintDataV2 memory data = MintDataV2({
            collection: address(impl),
            to: bob,
            amount: GENESIS_CHAMP_CLAIM_PUBLIC,
            nonce: nonce,
            holder: true
        });

        vm.expectRevert(abi.encodeWithSelector(Errors.CollectionUnknown.selector, address(impl)));
        vm.prank(bob);
        minterImpl.claim(data);
    }

    /**
     * @dev test the revert when the destination address is zero
     * @dev should revert with "ERC721Psi: transfer to the zero address"
     */
    function test_RevertWhen_claim_zero_address() public registerSupplyBeforeClaim {
        // Get the supply config
        (uint256 sHolder, uint256 sPublic, bool init) = minterImpl.supply(address(champion));
        assertEq(sHolder, GENESIS_CHAMP_INITIAL_HOLDER_SUPPLY);
        assertEq(sPublic, GENESIS_CHAMP_INITIAL_PUBLIC_SUPPLY);
        assertEq(init, true);

        address to = address(0);
        uint256 amount = GENESIS_CHAMP_CLAIM_HOLDERS;
        bytes32 nonce = bytes32("mint-holder-zero-address");
        MintDataV2 memory data =
            MintDataV2({collection: address(champion), to: to, amount: amount, nonce: nonce, holder: true});

        vm.prank(minter);
        vm.expectRevert("ERC721Psi: mint to the zero address");
        minterImpl.claim(data);
    }

}
