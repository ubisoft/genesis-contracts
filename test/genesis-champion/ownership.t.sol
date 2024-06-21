// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.24;

import {GenesisChampion_Base_Test} from "./GenesisChampion.t.sol";
import {AccessControl} from "openzeppelinV4/access/AccessControl.sol";
import {IAccessControl} from "openzeppelinV4/access/IAccessControl.sol";
import {Strings} from "openzeppelinV4/utils/Strings.sol";
import {GenesisChampion} from "src/GenesisChampion.sol";
import {Errors} from "src/librairies/Errors.sol";
import {BaseTest} from "test/Base.t.sol";
import {Events} from "test/utils/Events.sol";

contract GenesisChampion_Ownership_Test is GenesisChampion_Base_Test {

    function setUp() public virtual override {
        GenesisChampion_Base_Test.setUp();
    }

    /**
     * @dev owner can renounce ownership of the contract
     */
    function test_renounce_ownership() public {
        vm.startPrank(owner);

        // Owner is the current contract owner
        assertEq(champion.owner(), address(owner));

        // Owner can renounce the ownership of the contract
        vm.expectEmit();
        emit Events.OwnershipTransferred(address(owner), address(0));
        champion.renounceOwnership();

        assertEq(champion.owner(), address(0));
        vm.stopPrank();
    }

    /**
     * @dev owner can transfer the contract ownership to a new address
     */
    function test_transfer_ownership() public {
        vm.startPrank(owner);

        // Owner is the current contract owner
        assertEq(champion.owner(), address(owner));

        // Owner can transfer ownership to any address
        vm.expectEmit();
        emit Events.OwnershipTransferred(address(owner), bob);
        champion.transferOwnership(bob);

        // Bob is the new owner
        assertEq(champion.owner(), bob);
        vm.stopPrank();
    }

   /**
     * @dev user cannot transfer the contract ownership to a new address
     */
    function test_RevertWhen_transfer_ownership_caller_not_owner() public {
        vm.startPrank(bob);

        // Owner is the current contract owner
        assertEq(champion.owner(), address(owner));

        // bob cannot transfer ownership to any address
        vm.expectRevert(abi.encodeWithSelector(Errors.OwnableUnauthorizedAccount.selector, bob));
        champion.transferOwnership(bob);

        // Owner is still the owner
        assertEq(champion.owner(), owner);

        vm.stopPrank();
    }

    /**
     * @dev DEFAULT_ADMIN can renounce all roles from owner and minter
     */
    function test_RevertWhen_mint_after_renounce_MINTER_ROLE() public {
        vm.startPrank(owner);
        // Owner controls ADMIN_ROLE
        assertTrue(champion.hasRole(champion.DEFAULT_ADMIN_ROLE(), owner));

        // Minter has MINTER_ROLE
        assertTrue(champion.hasRole(champion.MINTER_ROLE(), minter));

        // Owner can revoke MINTER_ROLE from minter
        vm.expectEmit();
        emit Events.RoleRevoked(champion.MINTER_ROLE(), minter, owner);
        champion.revokeRole(champion.MINTER_ROLE(), minter);
        vm.stopPrank();

        // Minter cannot mint anymore
        vm.startPrank(minter);
        string memory revokeRoleError = string(
            abi.encodePacked(
                "AccessControl: account ",
                Strings.toHexString(minter),
                " is missing role ",
                Strings.toHexString(uint256(champion.MINTER_ROLE()), 32)
            )
        );
        vm.expectRevert(bytes(revokeRoleError));
        champion.mint(minter, 100);
        vm.stopPrank();

        // Make the collection immutable by removing the owner
        vm.startPrank(owner);
        vm.expectEmit();
        emit Events.OwnershipTransferred(owner, address(0));
        champion.renounceOwnership();
        vm.stopPrank();
    }

}
