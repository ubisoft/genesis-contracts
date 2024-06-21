// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.24;


import {IAccessControl} from "@openzeppelin/contracts/access/IAccessControl.sol";
import {GenesisMinter_Base_Test} from "./GenesisMinter.t.sol";
import {AccessControl} from "openzeppelinV4/access/AccessControl.sol";
import {Strings} from "openzeppelinV4/utils/Strings.sol";
import {GenesisMinter} from "src/GenesisMinter.sol";
import {Errors} from "src/librairies/Errors.sol";
import {Events} from "test/utils/Events.sol";

contract GenesisMinter_Ownership_Test is GenesisMinter_Base_Test {

    function setUp() public virtual override {
        GenesisMinter_Base_Test.setUp();
    }

    /**
     * @dev owner can renounce ownership of the contract
     */
    function test_renounce_ownership() public {
        vm.startPrank(owner);

        // Owner is the current contract owner
        assertEq(minterImpl.owner(), address(owner));

        // Owner can renounce the ownership of the contract
        vm.expectEmit();
        emit Events.OwnershipTransferred(address(owner), address(0));
        minterImpl.renounceOwnership();

        assertEq(minterImpl.owner(), address(0));
        vm.stopPrank();
    }

    /**
     * @dev owner can transfer the contract ownership to a new address
     */
    function test_transfer_ownership() public {
        vm.startPrank(owner);

        // Owner is the current contract owner
        assertEq(minterImpl.owner(), address(owner));

        // Owner can transfer ownership to any address
        vm.expectEmit();
        emit Events.OwnershipTransferred(address(owner), bob);
        minterImpl.transferOwnership(bob);

        // Bob is the new owner
        assertEq(minterImpl.owner(), bob);
        vm.stopPrank();
    }

       /**
     * @dev user cannot transfer the contract ownership to a new address
     */
    function test_RevertWhen_transfer_ownership_caller_not_owner() public {
        vm.startPrank(bob);

        // Owner is the current contract owner
        assertEq(minterImpl.owner(), address(owner));

        // bob cannot transfer ownership to any address
        vm.expectRevert(abi.encodeWithSelector(Errors.OwnableUnauthorizedAccount.selector, bob));
        minterImpl.transferOwnership(bob);

        // Owner is still the owner
        assertEq(minterImpl.owner(), owner);

        vm.stopPrank();
    }

    /**
     * @dev DEFAULT_ADMIN can renounce its admin role
     */
    function test_RevertWhen_mint_after_renounce_MINTER_ROLE() public {
        vm.startPrank(owner);
        // Owner controls ADMIN_ROLE
        assertTrue(minterImpl.hasRole(minterImpl.DEFAULT_ADMIN_ROLE(), owner));

        // Minter has MINTER_ROLE
        assertTrue(minterImpl.hasRole(minterImpl.MINTER_ROLE(), minter));

        // Owner can revoke MINTER_ROLE from minter
        vm.expectEmit();
        emit Events.RoleRevoked(minterImpl.MINTER_ROLE(), minter, owner);
        minterImpl.revokeRole(minterImpl.MINTER_ROLE(), minter);
        vm.stopPrank();

        // Minter cannot mint anymore
        vm.startPrank(minter);
        vm.expectRevert(
            abi.encodeWithSelector(IAccessControl.AccessControlUnauthorizedAccount.selector, minter, minterImpl.MINTER_ROLE())
        );
        minterImpl.mint(deployments[0], minter, 5);
        vm.stopPrank();

        // Make the collection immutable by removing the owner
        vm.startPrank(owner);
        vm.expectEmit();
        emit Events.OwnershipTransferred(owner, address(0));
        minterImpl.renounceOwnership();
        vm.stopPrank();
    }


}
