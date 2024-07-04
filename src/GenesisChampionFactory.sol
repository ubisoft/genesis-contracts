// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.8.24;

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {GenesisChampion} from "src/GenesisChampion.sol";
import {IGenesisChampionFactory} from "src/interfaces/IGenesisChampionFactory.sol";
import {GenesisChampionArgs} from "src/types/GenesisChampionArgs.sol";

contract GenesisChampionFactory is IGenesisChampionFactory, Ownable {

    /// @notice emitted after deploying a new instance of GenesisChampion
    event ContractCreated(address, uint256);

    /// @notice Mapping of deployed contracts addresses to their order of deployment
    mapping(address contractAddress => uint256 index) public deployedVersions;

    /// @notice Most recent deployment address
    address public lastDeployment;

    /// @notice Most recent deployment index
    uint256 public lastVersion;

    /// @notice Constructor only herits from Ownable
    constructor(address owner_) Ownable(owner_) {
    }

    /**
     * @inheritdoc IGenesisChampionFactory
     */
    function deploy(GenesisChampionArgs calldata _args) public onlyOwner returns (address, uint256) {
        // index is auto-incremental
        uint256 newIndex = lastVersion + 1;
        // Deploy a new instance of GenesisChampion
        GenesisChampion impl = new GenesisChampion(_args);
        // Update the deployments
        address newDeployment = address(impl);
        deployedVersions[newDeployment] = newIndex;
        lastDeployment = newDeployment;
        lastVersion = newIndex;
        // Emit the contract address
        emit ContractCreated(newDeployment, newIndex);
        return (newDeployment, newIndex);
    }

}
