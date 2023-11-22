// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.18;

import {AccessControl} from "openzeppelin/access/AccessControl.sol";
import {BaseTest} from "test/Base.t.sol";
import {Events} from "test/utils/Events.sol";
import {GenesisPFP} from "src/GenesisPFP.sol";
import {Strings} from "openzeppelin/utils/Strings.sol";

contract GenesisPFP_Constructor_Test is BaseTest {
    function setUp() public virtual override {
        BaseTest.setUp();
    }

    /**
     * @dev test the correct contract creation of GenesisPFP and setup of AccessControl roles
     */
    function test_Constructor() external {
        vm.expectEmit();
        emit OwnershipTransferred({previousOwner: address(0), newOwner: address(owner)});

        vm.expectEmit();
        emit RoleGranted({role: DEFAULT_ADMIN_ROLE, account: address(owner), sender: address(owner)});

        vm.expectEmit();
        emit RoleGranted({role: MINTER_ROLE, account: address(minter), sender: address(owner)});

        vm.prank(owner);
        genesis =
        new GenesisPFP("GenesisPFP", "GEN", "1.0", address(minter), address(vault), address(linkToken), address(wrapper));

        require(genesis.remainingSupply() == GENESIS_PFP_INITIAL_REMAINING_SUPPLY);

        // cast keccak "MintData(address to,uint256 validity_start,uint256 validity_end,uint256 chain_id,uint256 mint_amount,uint256 vest_amount,bytes32 user_nonce)"
        bytes32 typehash = 0x5671fbb49e96506fa1bf458ae595e6b5aa91747fa8fd744a8e7987e92b4e7eb1;
        assertEq(typehash, genesis.MINT_DATA_TYPEHASH());

        // Contract owner does not have the MINTER_ROLE
        require(!genesis.hasRole(MINTER_ROLE, owner));

        // Minter does not have the DEFAULT_ADMIN_ROLE
        require(!genesis.hasRole(DEFAULT_ADMIN_ROLE, minter));

        // Not DEFAULT_ADMIN_ROLE user cannot revoke a role
        vm.prank(minter);
        string memory revokeRoleError = string(
            abi.encodePacked(
                "AccessControl: account ",
                Strings.toHexString(minter),
                " is missing role ",
                Strings.toHexString(uint256(DEFAULT_ADMIN_ROLE), 32)
            )
        );
        vm.expectRevert(bytes(revokeRoleError));
        genesis.revokeRole(DEFAULT_ADMIN_ROLE, owner);
        require(genesis.hasRole(DEFAULT_ADMIN_ROLE, owner) == true);

        // DEFAULT_ADMIN_ROLE user can revoke a role
        vm.prank(owner);
        genesis.revokeRole(MINTER_ROLE, minter);

        // DEFAULT_ADMIN_ROLE user can grant a role to another user
        vm.prank(owner);
        genesis.grantRole(MINTER_ROLE, bob);

        // Updating the default royalty to 15%, called by a non owner user, should revert
        vm.prank(bob);
        vm.expectRevert("Ownable: caller is not the owner");
        genesis.updateDefaultRoyalty(address(bob), 1500);

        // Updating the default royalty to 15%, called by a owner user, should not revert
        vm.prank(owner);
        genesis.updateDefaultRoyalty(address(bob), 1500);
    }
}
