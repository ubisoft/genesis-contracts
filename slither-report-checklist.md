# Checklist

This report was generated using:

```bash
$ slither src/ --checklist --show-ignored-findings
Compilation warnings/errors on src/GenesisPFP.sol:
Warning: Contract code size is 25496 bytes and exceeds 24576 bytes (a limit introduced in Spurious Dragon). This contract may not be deployable on Mainnet. Consider enabling the optimizer (with a low "runs" value!), turning off revert strings, or using libraries.
  --> src/GenesisPFP.sol:34:1:
   |
34 | contract GenesisPFP is GenesisBase, IGenesisPFP, ChainlinkVRFMetadata {
   | ^ (Relevant source part starts here and spans across multiple lines).

INFO:Detectors:
ChainlinkVRFMetadata.withdrawRemainingLink(address) (src/abstracts/ChainlinkVRFMetadata.sol#64-68) uses a dangerous strict equality: - balance == 0 (src/abstracts/ChainlinkVRFMetadata.sol#66)
Reference: https://github.com/crytic/slither/wiki/Detector-Documentation#dangerous-strict-equalities
INFO:Detectors:
ERC721Psi.tokensOfOwner(address).tokenIdsIdx (src/ERC721Psi/ERC721Psi.sol#507) is a local variable never initialized
ERC721Psi.balanceOf(address).count (src/ERC721Psi/ERC721Psi.sol#106) is a local variable never initialized
Reference: https://github.com/crytic/slither/wiki/Detector-Documentation#uninitialized-local-variables
INFO:Detectors:
ERC721Psi.\_checkOnERC721Received(address,address,uint256,uint256,bytes) (src/ERC721Psi/ERC721Psi.sol#460-486) ignores return value by IERC721Receiver(to).onERC721Received(\_msgSender(),from,tokenId,\_data) (src/ERC721Psi/ERC721Psi.sol#470-480)
Reference: https://github.com/crytic/slither/wiki/Detector-Documentation#unused-return
INFO:Detectors:
GenesisPFP.constructor(string,string,string,address,address,address,address).\_name (src/GenesisPFP.sol#72) shadows: - ERC721Psi.\_name (src/ERC721Psi/ERC721Psi.sol#35) (state variable)
GenesisPFP.constructor(string,string,string,address,address,address,address).\_symbol (src/GenesisPFP.sol#73) shadows: - ERC721Psi.\_symbol (src/ERC721Psi/ERC721Psi.sol#36) (state variable)
Reference: https://github.com/crytic/slither/wiki/Detector-Documentation#local-variable-shadowing
INFO:Detectors:
GenesisPFP.mintWithSignature(MintData,bytes) (src/GenesisPFP.sol#93-124) uses timestamp for comparisons
Dangerous comparisons: - block.timestamp < request.validity_start (src/GenesisPFP.sol#98) - block.timestamp > request.validity_end (src/GenesisPFP.sol#100)
Reference: https://github.com/crytic/slither/wiki/Detector-Documentation#block-timestamp
INFO:Detectors:
ERC721Psi.\_checkOnERC721Received(address,address,uint256,uint256,bytes) (src/ERC721Psi/ERC721Psi.sol#460-486) uses assembly - INLINE ASM (src/ERC721Psi/ERC721Psi.sol#476-478)
Reference: https://github.com/crytic/slither/wiki/Detector-Documentation#assembly-usage
INFO:Detectors:
ERC721Psi.\_baseURI() (src/ERC721Psi/ERC721Psi.sol#166-168) is never used and should be removed
Reference: https://github.com/crytic/slither/wiki/Detector-Documentation#dead-code
INFO:Detectors:
Pragma version^0.8.0 (src/ERC721Psi/ERC721Psi.sol#15) allows old versions
Pragma version^0.8.0 (src/ERC721Psi/extension/ERC721PsiAddressData.sol#12) allows old versions
Reference: https://github.com/crytic/slither/wiki/Detector-Documentation#incorrect-versions-of-solidity
INFO:Detectors:
Parameter ERC721Psi.safeTransferFrom(address,address,uint256,bytes).\_data (src/ERC721Psi/ERC721Psi.sol#266) is not in mixedCase
Variable ERC721Psi.\_owners (src/ERC721Psi/ERC721Psi.sol#39) is not in mixedCase
Variable ERC721PsiAddressData.\_addressData (src/ERC721Psi/extension/ERC721PsiAddressData.sol#24) is not in mixedCase
Parameter ChainlinkVRFMetadata.requestChainlinkVRF(uint32,uint16).\_callbackGasLimit (src/abstracts/ChainlinkVRFMetadata.sol#50) is not in mixedCase
Parameter ChainlinkVRFMetadata.requestChainlinkVRF(uint32,uint16).\_requestConfirmations (src/abstracts/ChainlinkVRFMetadata.sol#50) is not in mixedCase
Parameter ChainlinkVRFMetadata.fulfillRandomWords(uint256,uint256[]).\_requestId (src/abstracts/ChainlinkVRFMetadata.sol#82) is not in mixedCase
Parameter ChainlinkVRFMetadata.fulfillRandomWords(uint256,uint256[]).\_randomWords (src/abstracts/ChainlinkVRFMetadata.sol#82) is not in mixedCase
Parameter GenesisBase.setBaseURI(string).\_uri (src/abstracts/GenesisBase.sol#46) is not in mixedCase
Reference: https://github.com/crytic/slither/wiki/Detector-Documentation#conformance-to-solidity-naming-conventions
```

## Summary

- [incorrect-equality](#incorrect-equality) (1 results) (Medium)
- [uninitialized-local](#uninitialized-local) (2 results) (Medium)
- [unused-return](#unused-return) (1 results) (Medium)
- [shadowing-local](#shadowing-local) (2 results) (Low)
- [timestamp](#timestamp) (1 results) (Low)
- [assembly](#assembly) (1 results) (Informational)
- [dead-code](#dead-code) (1 results) (Informational)
- [solc-version](#solc-version) (2 results) (Informational)
- [naming-convention](#naming-convention) (8 results) (Informational)

### incorrect-equality

Impact: Medium
Confidence: High

- [ ] ID-0
      [ChainlinkVRFMetadata.withdrawRemainingLink(address)](src/abstracts/ChainlinkVRFMetadata.sol#L64-L68) uses a dangerous strict equality: - [balance == 0](src/abstracts/ChainlinkVRFMetadata.sol#L66)

src/abstracts/ChainlinkVRFMetadata.sol#L64-L68

### uninitialized-local

Impact: Medium
Confidence: Medium

- [ ] ID-1
      [ERC721Psi.tokensOfOwner(address).tokenIdsIdx](src/ERC721Psi/ERC721Psi.sol#L507) is a local variable never initialized

src/ERC721Psi/ERC721Psi.sol#L507

- [ ] ID-2
      [ERC721Psi.balanceOf(address).count](src/ERC721Psi/ERC721Psi.sol#L106) is a local variable never initialized

src/ERC721Psi/ERC721Psi.sol#L106

### unused-return

Impact: Medium
Confidence: Medium

- [ ] ID-3
      [ERC721Psi.\_checkOnERC721Received(address,address,uint256,uint256,bytes)](src/ERC721Psi/ERC721Psi.sol#L460-L486) ignores return value by [IERC721Receiver(to).onERC721Received(\_msgSender(),from,tokenId,\_data)](src/ERC721Psi/ERC721Psi.sol#L470-L480)

src/ERC721Psi/ERC721Psi.sol#L460-L486

### shadowing-local

Impact: Low
Confidence: High

- [ ] ID-4
      [GenesisPFP.constructor(string,string,string,address,address,address,address).\_name](src/GenesisPFP.sol#L72) shadows: - [ERC721Psi.\_name](src/ERC721Psi/ERC721Psi.sol#L35) (state variable)

src/GenesisPFP.sol#L72

- [ ] ID-5
      [GenesisPFP.constructor(string,string,string,address,address,address,address).\_symbol](src/GenesisPFP.sol#L73) shadows: - [ERC721Psi.\_symbol](src/ERC721Psi/ERC721Psi.sol#L36) (state variable)

src/GenesisPFP.sol#L73

### timestamp

Impact: Low
Confidence: Medium

- [ ] ID-6
      [GenesisPFP.mintWithSignature(MintData,bytes)](src/GenesisPFP.sol#L93-L124) uses timestamp for comparisons
      Dangerous comparisons: - [block.timestamp < request.validity_start](src/GenesisPFP.sol#L98) - [block.timestamp > request.validity_end](src/GenesisPFP.sol#L100)

src/GenesisPFP.sol#L93-L124

### assembly

Impact: Informational
Confidence: High

- [ ] ID-7
      [ERC721Psi.\_checkOnERC721Received(address,address,uint256,uint256,bytes)](src/ERC721Psi/ERC721Psi.sol#L460-L486) uses assembly - [INLINE ASM](src/ERC721Psi/ERC721Psi.sol#L476-L478)

src/ERC721Psi/ERC721Psi.sol#L460-L486

### dead-code

Impact: Informational
Confidence: Medium

- [ ] ID-8
      [ERC721Psi.\_baseURI()](src/ERC721Psi/ERC721Psi.sol#L166-L168) is never used and should be removed

src/ERC721Psi/ERC721Psi.sol#L166-L168

### solc-version

Impact: Informational
Confidence: High

- [ ] ID-9
      Pragma version[^0.8.0](src/ERC721Psi/extension/ERC721PsiAddressData.sol#L12) allows old versions

src/ERC721Psi/extension/ERC721PsiAddressData.sol#L12

- [ ] ID-10
      Pragma version[^0.8.0](src/ERC721Psi/ERC721Psi.sol#L15) allows old versions

src/ERC721Psi/ERC721Psi.sol#L15

### naming-convention

Impact: Informational
Confidence: High

- [ ] ID-11
      Parameter [ERC721Psi.safeTransferFrom(address,address,uint256,bytes).\_data](src/ERC721Psi/ERC721Psi.sol#L266) is not in mixedCase

src/ERC721Psi/ERC721Psi.sol#L266

- [ ] ID-12
      Variable [ERC721Psi.\_owners](src/ERC721Psi/ERC721Psi.sol#L39) is not in mixedCase

src/ERC721Psi/ERC721Psi.sol#L39

- [ ] ID-13
      Variable [ERC721PsiAddressData.\_addressData](src/ERC721Psi/extension/ERC721PsiAddressData.sol#L24) is not in mixedCase

src/ERC721Psi/extension/ERC721PsiAddressData.sol#L24

- [ ] ID-14
      Parameter [ChainlinkVRFMetadata.requestChainlinkVRF(uint32,uint16).\_requestConfirmations](src/abstracts/ChainlinkVRFMetadata.sol#L50) is not in mixedCase

src/abstracts/ChainlinkVRFMetadata.sol#L50

- [ ] ID-15
      Parameter [ChainlinkVRFMetadata.requestChainlinkVRF(uint32,uint16).\_callbackGasLimit](src/abstracts/ChainlinkVRFMetadata.sol#L50) is not in mixedCase

src/abstracts/ChainlinkVRFMetadata.sol#L50

- [ ] ID-16
      Parameter [ChainlinkVRFMetadata.fulfillRandomWords(uint256,uint256[]).\_randomWords](src/abstracts/ChainlinkVRFMetadata.sol#L82) is not in mixedCase

src/abstracts/ChainlinkVRFMetadata.sol#L82

- [ ] ID-17
      Parameter [GenesisBase.setBaseURI(string).\_uri](src/abstracts/GenesisBase.sol#L46) is not in mixedCase

src/abstracts/GenesisBase.sol#L46

- [ ] ID-18
      Parameter [ChainlinkVRFMetadata.fulfillRandomWords(uint256,uint256[]).\_requestId](src/abstracts/ChainlinkVRFMetadata.sol#L82) is not in mixedCase

src/abstracts/ChainlinkVRFMetadata.sol#L82

INFO:Slither:src/ analyzed (32 contracts with 85 detectors), 19 result(s) found
