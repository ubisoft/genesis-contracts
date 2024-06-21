// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.24;

import {AccessControl} from "openzeppelinV4/access/AccessControl.sol";
import {Strings} from "openzeppelinV4/utils/Strings.sol";
import {GenesisChampion} from "src/GenesisChampion.sol";
import {GenesisChampionArgs} from "src/types/GenesisChampionArgs.sol";
import {BaseTest} from "test/Base.t.sol";
import {Events} from "test/utils/Events.sol";

contract GenesisChampion_Constructor_Test is BaseTest {

    event DelegateSet(address sender, address delegate);

    function setUp() public virtual override {
        BaseTest.setUp();
    }

    /**
     * @dev test the correct contract creation of GenesisChampion and setup of AccessControl roles
     */
    function test_Constructor() external {
        vm.expectEmit();
        emit OwnershipTransferred({previousOwner: address(0), newOwner: owner});

        vm.expectEmit();
        emit RoleGranted({role: DEFAULT_ADMIN_ROLE, account: owner, sender: owner});

        vm.expectEmit();
        emit RoleGranted({role: MINTER_ROLE, account: minter, sender: owner});

        vm.prank(owner);
        champion = new GenesisChampion(
            GenesisChampionArgs({
                name: "GenesisChampion",
                symbol: "GEN",
                baseURI: "ipfs://Qmbcg4ykX7dTYMdRkfM4yJ8ovHBfqpDuk3GiEjdTKr1uw9/default.json",
                owner: owner,
                minter: minter,
                crafter: address(0),
                vault: vault,
                endpointL0: endpoints[eid1],
                defaultMaxCraftCount: GENESIS_CHAMP_DEFAULT_MAX_CRAFT_COUNT
            })
        );

        // defaultMaxCraftCount should be 8
        assertEq(champion.defaultMaxCraftCount(), GENESIS_CHAMP_DEFAULT_MAX_CRAFT_COUNT);

        // Contract owner does not have the MINTER_ROLE
        require(!champion.hasRole(MINTER_ROLE, owner));

        // Minter does not have the DEFAULT_ADMIN_ROLE
        require(!champion.hasRole(DEFAULT_ADMIN_ROLE, minter));

        // Not DEFAULT_ADMIN_ROLE user cannot revoke a role
        vm.prank(minter);
        string memory revokeRoleErrorMinterCaller = string(
            abi.encodePacked(
                "AccessControl: account ",
                Strings.toHexString(minter),
                " is missing role ",
                Strings.toHexString(uint256(DEFAULT_ADMIN_ROLE), 32)
            )
        );
        vm.expectRevert(bytes(revokeRoleErrorMinterCaller));
        champion.revokeRole(DEFAULT_ADMIN_ROLE, owner);
        require(champion.hasRole(DEFAULT_ADMIN_ROLE, owner) == true);

        // DEFAULT_ADMIN_ROLE user can revoke a role
        vm.prank(owner);
        champion.revokeRole(MINTER_ROLE, minter);

        // DEFAULT_ADMIN_ROLE user can grant a role to another user
        vm.prank(owner);
        champion.grantRole(MINTER_ROLE, bob);

        // Updating the default royalty to 15%, called by a non owner user, should revert
        vm.prank(bob);
        string memory revokeRoleErrorBobCaller = string(
            abi.encodePacked(
                "AccessControl: account ",
                Strings.toHexString(bob),
                " is missing role ",
                Strings.toHexString(uint256(DEFAULT_ADMIN_ROLE), 32)
            )
        );
        vm.expectRevert(bytes(revokeRoleErrorBobCaller));
        champion.updateDefaultRoyalty(bob, 1500);

        // Updating the default royalty to 15%, called by a owner user, should not revert
        vm.prank(owner);
        champion.updateDefaultRoyalty(bob, 1500);
    }

}
