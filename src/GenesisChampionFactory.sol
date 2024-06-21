// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.8.24;

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {GenesisChampion} from "src/GenesisChampion.sol";
import {IGenesisChampionFactory} from "src/interfaces/IGenesisChampionFactory.sol";
import {Errors} from "src/librairies/Errors.sol";
import {GenesisChampionArgs} from "src/types/GenesisChampionArgs.sol";

contract GenesisChampionFactory is IGenesisChampionFactory, Ownable {

    /// @notice emitted after deploying a new instance of GenesisChampion
    event ContractCreated(address, uint256);

    /// @notice Array of deployed contracts
    mapping(address => uint256) public deployedVersions;

    // /// @notice Reference implementation address of GenesisChampion
    // address immutable public referenceContract;

    /// @notice Most recent deployment address
    address public lastDeployment;

    /// @notice Most recent deployment version
    uint256 public lastVersion;

    /// @notice Constructor only herits from Ownable
    constructor(address owner_) Ownable(owner_) {
    }

    /**
     * @inheritdoc IGenesisChampionFactory
     */
    function deploy(GenesisChampionArgs calldata _args) public onlyOwner returns (address, uint256) {
        uint256 newVersion = lastVersion + 1;
        // Deploy a new instance of GenesisChampion
        GenesisChampion impl = new GenesisChampion(_args);
        // Update the deployments
        address newDeployment = address(impl);
        deployedVersions[newDeployment] = newVersion;
        lastDeployment = newDeployment;
        lastVersion = newVersion;
        // Emit the contract address
        emit ContractCreated(newDeployment, newVersion);

        return (newDeployment, newVersion);
    }

}
