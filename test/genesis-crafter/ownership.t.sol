// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.24;

import {GenesisCrafter_Base_Test} from "./GenesisCrafter.t.sol";
import {AccessControl} from "openzeppelinV4/access/AccessControl.sol";
import {IAccessControl} from "openzeppelinV4/access/IAccessControl.sol";
import {Strings} from "openzeppelinV4/utils/Strings.sol";
import {GenesisCrafter} from "src/GenesisCrafter.sol";
import {Errors} from "src/librairies/Errors.sol";
import {Events} from "test/utils/Events.sol";

contract GenesisCrafter_Ownership_Test is GenesisCrafter_Base_Test {

    function setUp() public virtual override {
        GenesisCrafter_Base_Test.setUp();
    }

    /**
     * @dev owner can renounce ownership of the contract
     */
    function test_renounce_ownership() public {
        vm.startPrank(owner);

        // Owner is the current contract owner
        assertEq(crafterImpl.owner(), address(owner));

        // Owner can renounce the ownership of the contract
        vm.expectEmit();
        emit Events.OwnershipTransferred(address(owner), address(0));
        crafterImpl.renounceOwnership();

        assertEq(crafterImpl.owner(), address(0));
        vm.stopPrank();
    }

    /**
     * @dev owner can transfer the contract ownership to a new address
     */
    function test_transfer_ownership() public {
        vm.startPrank(owner);

        // Owner is the current contract owner
        assertEq(crafterImpl.owner(), address(owner));

        // Owner can transfer ownership to any address
        vm.expectEmit();
        emit Events.OwnershipTransferred(address(owner), bob);
        crafterImpl.transferOwnership(bob);

        // Bob is the new owner
        assertEq(crafterImpl.owner(), bob);
        vm.stopPrank();
    }

       /**
     * @dev user cannot transfer the contract ownership to a new address
     */
    function test_RevertWhen_transfer_ownership_caller_not_owner() public {
        vm.startPrank(bob);

        // Owner is the current contract owner
        assertEq(crafterImpl.owner(), address(owner));

        // bob cannot transfer ownership to any address
        vm.expectRevert(abi.encodeWithSelector(Errors.OwnableUnauthorizedAccount.selector, bob));
        crafterImpl.transferOwnership(bob);

        // Owner is still the owner
        assertEq(crafterImpl.owner(), owner);

        vm.stopPrank();
    }

    // /**
    //  * @dev DEFAULT_ADMIN can renounce its admin role
    //  */
    // function test_RevertWhen_mint_after_renounce_MINTER_ROLE() public {
    //     vm.startPrank(owner);
    //     // Owner controls ADMIN_ROLE
    //     assertTrue(crafterImpl.hasRole(crafterImpl.DEFAULT_ADMIN_ROLE(), owner));

    //     // Minter has MINTER_ROLE
    //     assertTrue(crafterImpl.hasRole(crafterImpl.MINTER_ROLE(), minter));

    //     // Owner can revoke MINTER_ROLE from minter
    //     vm.expectEmit();
    //     emit Events.RoleRevoked(crafterImpl.MINTER_ROLE(), minter, owner);
    //     crafterImpl.revokeRole(crafterImpl.MINTER_ROLE(), minter);
    //     vm.stopPrank();

    //     // Minter cannot mint anymore
    //     vm.startPrank(minter);
    //     string memory revokeRoleError = string(
    //         abi.encodePacked(
    //             "AccessControl: account ",
    //             Strings.toHexString(minter),
    //             " is missing role ",
    //             Strings.toHexString(uint256(crafterImpl.MINTER_ROLE()), 32)
    //         )
    //     );
    //     vm.expectRevert(bytes(revokeRoleError));
    //     crafterImpl.mint(minter, 100);
    //     vm.stopPrank();

    //     // Make the collection immutable by removing the owner
    //     vm.startPrank(owner);
    //     vm.expectEmit();
    //     emit Events.OwnershipTransferred(owner, address(0));
    //     crafterImpl.renounceOwnership();
    //     vm.stopPrank();
    // }


}
