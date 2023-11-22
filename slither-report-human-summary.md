# Slither

This report was generated using: `slither src/ --print human-summary`

```bash
$ slither src/ --print human-summary
Compilation warnings/errors on src/GenesisPFP.sol:
Warning: Contract code size is 25496 bytes and exceeds 24576 bytes (a limit introduced in Spurious Dragon). This contract may not be deployable on Mainnet. Consider enabling the optimizer (with a low "runs" value!), turning off revert strings, or using libraries.
  --> src/GenesisPFP.sol:34:1:
   |
34 | contract GenesisPFP is GenesisBase, IGenesisPFP, ChainlinkVRFMetadata {
   | ^ (Relevant source part starts here and spans across multiple lines).


INFO:Printers:
Compiled with solc
Number of lines: 3679 (+ 0 in dependencies, + 0 in tests)
Number of assembly lines: 0
Number of contracts: 32 (+ 0 in dependencies, + 0 tests)

Number of optimization issues: 0
Number of informational issues: 12
Number of low issues: 3
Number of medium issues: 4
Number of high issues: 0

ERCs: ERC721, ERC20, ERC165

+---------------------------+-------------+---------------+------------+--------------+--------------------+
|            Name           | # functions |      ERCS     | ERC20 info | Complex code |      Features      |
+---------------------------+-------------+---------------+------------+--------------+--------------------+
|     LinkTokenInterface    |      12     |     ERC20     | No Minting |      No      |                    |
|                           |             |               |            |              |                    |
| VRFCoordinatorV2Interface |      10     |               |            |      No      |                    |
|   VRFV2WrapperInterface   |      3      |               |            |      No      |                    |
|      IERC721Receiver      |      1      |               |            |      No      |                    |
|          Address          |      13     |               |            |      No      |      Send ETH      |
|                           |             |               |            |              |    Delegatecall    |
|                           |             |               |            |              |      Assembly      |
|        StorageSlot        |      4      |               |            |      No      |      Assembly      |
|          Strings          |      5      |               |            |      No      |      Assembly      |
|           ECDSA           |      10     |               |            |      No      |     Ecrecover      |
|                           |             |               |            |              |      Assembly      |
|            Math           |      14     |               |            |     Yes      |      Assembly      |
|          BitMaps          |      11     |               |            |      No      |                    |
|          BitScan          |      6      |               |            |      No      |                    |
|          Popcount         |      3      |               |            |      No      |                    |
|         GenesisPFP        |     109     | ERC165,ERC721 |            |     Yes      |     Ecrecover      |
|                           |             |               |            |              | Tokens interaction |
|                           |             |               |            |              |      Assembly      |
|           Errors          |      0      |               |            |      No      |                    |
+---------------------------+-------------+---------------+------------+--------------+--------------------+
INFO:Slither:src/ analyzed (32 contracts)
```
