# Genesis PFP

## Contract documentation

Contract documentation is auto-generated using `forge doc`.

## Installation

### Foundry

- Intall [Foundry](https://book.getfoundry.sh/getting-started/installation)
- Clone the project

```bash
git clone git@gitlab-ncsa.ubisoft.org:blockchain-initiative/genesis-pfp.git
```

### Submodules

Fetch the submodules used with these commands:

```bash
git submodule deinit --force .
git submodule update --init --recursive
```

## Building the contract

```bash
forge build
```

Contract ABIs can be found in `out/GenesisPFP.sol/GenesisPFP.json` after building the contracts

## Tests

```bash
forge test
```

### Coverage report

LCOV file can be generated and viewed as an HTML file using the following commands:

```bash
$ forge coverage --report lcov
$ genhtml --branch-coverage --output "coverage" lcov.info

```

## Slither reports

A Slither checklist report can be found [here](./slither-report-checklist.md).

A Slither human-summary report can be found [here](./slither-report-human-summary.md).

### Using locally

1. Start a local testnet using `anvil` or any local testnet client
2. In another terminal, setup the `RPC_URL`, `MINTER_ADDRESS` and `VAULT_ADDRESS` env variables
3. Run `forge create` to deploy the contract as below

> Use the `--unlocked` flag with Anvil's first test account used as `ETH_FROM`

```bash
export ETH_FROM="0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266" # first account from Anvil test mnemonic
export MINTER_ADDRESS="0x70997970C51812dc3A010C7d01b50e0d17dc79C8"
export VAULT_ADDRESS="0x90F79bf6EB2c4f870365E785982E1f101E93b906"
export RPC_URL="http://localhost:8545" # Anvil local RPC

forge create                                    \
    --rpc-url $RPC_URL --unlocked               \
    src/GenesisPFP.sol:GenesisPFP               \
    --constructor-args "Genesis PFP" "PFP" "1"  \
        $MINTER_ADDRESS $VAULT_ADDRESS        \
        "0x0000000000000000000000000000000000000000" "0x0000000000000000000000000000000000000000"

[⠒] Compiling...
No files changed, compilation skipped
Deployer: 0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266
Deployed to: 0x5FbDB2315678afecb367f032d93F642f64180aa3
Transaction hash: 0x3e6af8ef8b352e3abb969b4956f0ed2d16602de705fd4b253dae0d602c8c109b
```
