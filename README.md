# Genesis Contracts

Smart contracts for [Champions Tactics™ Grimoria Chronicles](https://championstactics.ubisoft.com/) written in [Solidity](https://soliditylang.org/).

Champions Tactics™ Grimoria Chronicles is a PVP Tactical RPG game on PC by Ubisoft. Assemble a team of mythical Champions and craft you legend in the dark and mystical world of Grimoria.

## Security

The `GenesisPFP` smart contract is deployed on Ethereum mainnet at address `0xE841e6e68BECFC54b621A23a41f8C1a829a4cf44` and has been audited by KALOS. The report can be found [here](<./audit/[KALOS] Ubisoft Genesis PFP Audit Report v1.0 (ENG).pdf>).

### Slither reports

- [Checklist report can be found here](./slither-report-checklist.md)
- [Human summary report can be found here](./slither-report-human-summary.md)

## Installation

1. Clone this repository
2. Install [Foundry](https://book.getfoundry.sh/getting-started/installation)
3. Initialize the submodules

```bash
git submodule deinit --force .
git submodule update --init --recursive
```

## Contract documentation

Contract documentation is auto-generated using `forge doc`.

`forge doc -s` allows you to serve it locally at [localhost:3000](http://localhost:3000).

## Build, test and deploy

### Build

```bash
forge build
```

Genesis PFP's contract ABI can be found in [`out/GenesisPFP.sol/GenesisPFP.json`](out/GenesisPFP.sol/GenesisPFP.json) after building the contracts

### Test

```bash
forge test
```

#### Coverage report

LCOV file can be generated and viewed as an HTML file using the following commands:

```bash
$ forge coverage --report lcov
$ genhtml --branch-coverage --output "coverage" lcov.info
```

### Deploy

#### Deploy locally

1. Start a local testnet using [anvil](https://book.getfoundry.sh/anvil/) or any local testnet client
2. In another terminal, setup the required env variables and run `forge create` to deploy the contract as below

> Use the `--unlocked` flag with Anvil's first test account used as sender with `ETH_FROM`

```bash
export ETH_FROM="0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266"
export MINTER_ADDRESS="0x..."
export VAULT_ADDRESS="0x..."
export LINK_ADDRESS="0x0000000000000000000000000000000000000000"
export VRF_WRAPPER_ADDRESS="0x0000000000000000000000000000000000000000"
export RPC_URL="http://localhost:8545" # Anvil local RPC

forge create                                    \
    --rpc-url $RPC_URL --unlocked               \
    src/GenesisPFP.sol:GenesisPFP               \
    --constructor-args "Genesis PFP" "PFP" "1"  \
        $MINTER_ADDRESS $VAULT_ADDRESS          \
        $LINK_ADDRESS $VRF_WRAPPER_ADDRESS
```

#### Deploy on a public network

We use the Sepolia testnet to deploy and test our contracts in dev environment.

Chainlink's VRF configuration for Sepolia can be found [here](https://docs.chain.link/resources/link-token-contracts#sepolia-testnet).

Deployment parameters are listed below in the same order as the contract constructor takes them:

| Parameter      | Value                                                 |
| -------------- | ----------------------------------------------------- |
| Name           | GenesisPFP                                            |
| Symbol         | PFP                                                   |
| Version        | 1                                                     |
| Minter address | Address granted with MINTER_ROLE on contract creation |
| Vault address  | Address receiving marketplace royalties               |
| LINK Token     | 0x779877A7B0D9E8603169DdbD7836e478b4624789            |
| VRF Wrapper    | 0xab18414CD93297B0d12ac29E63Ca20f515b3DB46            |

You will need to provide a mnemonic phrase, private key, ledger or any wallet solution to deploy your contract on a live network. Please refer to Foundry's documentation for options.

To deploy the contracts on Sepolia, run the following command (replace `$RPC_URL` with a valid Sepolia RPC endpoint):

```bash
forge create                                    \
    --rpc-url $RPC_URL                  \
    src/GenesisPFP.sol:GenesisPFP               \
    --constructor-args "Genesis PFP" "PFP" "1"  \
        $MINTER_ADDRESS $VAULT_ADDRESS          \
        $LINK_ADDRESS $VRF_WRAPPER_ADDRESS
```

## Authors

* Nicolas LAW YIM WAN
* Louis GAROCHE

## License

This project is available under the [Apache 2.0 License](./LICENSE.md)
