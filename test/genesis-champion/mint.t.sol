// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.24;

import {GenesisChampion_Base_Test} from "./GenesisChampion.t.sol";
import {AccessControl} from "openzeppelinV4/access/AccessControl.sol";
import {IAccessControl} from "openzeppelinV4/access/IAccessControl.sol";
import {Strings} from "openzeppelinV4/utils/Strings.sol";
import {GenesisChampion} from "src/GenesisChampion.sol";
import {Errors} from "src/librairies/Errors.sol";
import {BaseTest} from "test/Base.t.sol";

contract GenesisChampion_Mint_Test is GenesisChampion_Base_Test {

    function setUp() public virtual override {
        GenesisChampion_Base_Test.setUp();
    }

    /**
     * @dev caller with MINTER_ROLE can call `mint`
     */
    function test_mint() public {
        vm.startPrank(minter);
        address to = bob;
        uint256 amount = 100;

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
    }

    /**
     * @dev caller without MINTER_ROLE cannot call `mint`
     */
    function test_mint_RevertWhen_AccessControl_Missing_Role() public {
        address to = bob;
        uint256 amount = 100;

        vm.startPrank(to);
        string memory revokeRoleError = string(
            abi.encodePacked(
                "AccessControl: account ",
                Strings.toHexString(to),
                " is missing role ",
                Strings.toHexString(uint256(champion.MINTER_ROLE()), 32)
            )
        );
        vm.expectRevert(bytes(revokeRoleError));
        champion.mint(to, amount);

        uint256 balance = champion.balanceOf(to);
        assertEq(balance, 0);
        vm.stopPrank();
    }

}
