# Genesis PFP Specifications

## Overview

The Genesis project releases 9 999 Profile Picture NFTs.

- The collection is composed of:
  - A minimum of 200 NFTs reserved for marketing.
  - 9799 NFTs available for acquisition during the Claim Sessions.
- During the Public Claim Session, each User (Public and Private mint phase) can mint 2 NFTs.
  - Allowlisted Users have the privilege of an early access to the claim acquisition, called Private Session. (see Dates and Values)
    - Among the Allowlisted Users, Ubisoft collaborators can also mint up to 2 NFTs. This privilege is still valid during the Public Session (i.e. if they didn't submit their transactions during early access, they can still mint 2 NFTs, but in competition with regular Users).
  - When the period for Claim is open, the procedure for acquisition respects a FCFS order (first-come-first-serve), among the Users that fulfill the requirements. (see the Claim procedure)
  - The NFTs are minted in the Ethereum blockchain.
  - The NFTs are free (ie no payment required), however the transaction fees are paid by the User.
  - The NFTs are distributed in a random way, since the concept of rarity is implicitly present. (see Claim and Reveal for more details)

The Profile Picture NFTs can give priority to purchase of Genesis Figurines.

## Key Values and Events

- Size of PFP Collection: 9999 NFTs
  - 200 NFTs (minimum) reserved for marketing (RESERVE).
  - 9799 NFTs available for claim acquisition (PUBLIC + PRIVATE).
- Date of release of the PFP webapp: TBD
- Start of Claim session: TBD
- Start of Early Access: 1 hour before the start of Claim Session.
- End of Claim session: 24 hours after the start of Claim Session.
- Date of Reveal: 24h (TBD 48h) after end of Claim Session (Fixed date, independent of soldout).
- Date of Snapshot: 2 days before the Claim of Genesis Figurines.
- Date of deactivation of PFP webapp: release of Genesis Figurines.

## General aspects

### Collection size

The PFP Collection is composed of 9,999 NFTs (see Values and Dates).

We can consider that the Collection size is Fixed and, once the Claim Session is ended, the NFTs not claimed by Users are minted and considered as part of the Marketing Reserve.

- Given the context, we can say that the Marketing Reserve has a minimum length, however not a maximum one.
- Example: if all NFTs are minted during the Claim Session, the size of the collection is 9,999 NFTs (200 Reserved + 9799 Distributed).
- Example: if only 5,000 NFTs are minted at the end of the Claim Session, the size of the collection is anyway 9,999 
NFTs (4999 Reserved + 5000 Distributed).

The Smart Contract is responsible for ensuring the Collection size.

### Constraints for Possession

- There are no restrictions on the amount of NFTs that a User can own.
- Certain constraints are applied by the tools that enable the acquisition, such as the Primary Market managed by Ubisoft. But these rules are not ensured outside the Ubisoft ecosystem.

### Early Access/Private Session

An Allowlist for Ubisoft Collaborators and others gives the benefit of a period for early access to the Claim.

- While the Claim session is open for early access, authorized Users can acquire PFPs following the conditions presented at Overview.
- The maximum amount of NFTs that can be minted in total during the early access is defined by the number of Users in the Allowlist and the amount of NFTs that they can claim.
- Once the early access session is over, the NFTs not claimed become available for the public Claim Session that starts in the sequence.
- The Allowlist is filled with Ubisoft Account IDs.

### ID Distribution

The IDs of the NFTs are defined following the rules:

- The first NFT IDs are dedicated to the Marketing Reserve, given the amount allocated to it. (see Values and Dates)
- The subsequent NFT IDs are defined in a consecutive order given the first-come-first-served mint mechanism. It implies that Users minting in Early Access will acquire the smaller IDs.
- It is important to mention that the metadatas of the NFTs are not automatically associated to their IDs: All Users will have access to this information at the same time. The procedure to randomize it is described below. (see Metadata Reveal)

### Metadata Reveal

With the objective of providing a fair distribution of NFTs (avoiding that Users "predict" and "choose" the Tokens to be minted, obtaining an advantage given the rarity of some PFPs), the attribution of NFTs' metadata is done via a Deferred Reveal. In this case, the set of metadata for all NFTs is public and published in advance, along with the smart contracts. However, they are not associated to the NFTs themselves.
The Users only know the metadata of their NFTs simultaneously, and determined by a random factor, when the NFTs are linked to the metadata:

- An random offset defines the matching between the ordered set of NFT IDs and ordered set of Metadata, retrieved using Chainlink VRF.

These restrictions prevent that Ubisoft collaborators benefit of privileged information. Find the considerations around this decision in the Mint Strategy documentation.

### Secondary Market

Genesis does not provide a Marketplace for the PFPs. Players are able to exchange them externally.

- External Marketplaces define their own constraints and methods for acquisition, which means that the age, location and Ubisoft Account validation can be skipped in this case.
- External Marketplaces apply fees on the purchase.
- There is no restriction on the amount of PFPs that can be acquired by a User.
- The acquisition in the Secondary Market can happen even while the Claim Session is open, I.e., once NFTs are minted
- Even while metadata is not yet revealed.

### Direct Transfers

- Players are allowed to transfer PFPs to other Players without payment (There can exist a payment, but it is not secured by the blockchain).

This operation must be performed by external tools, such as wallets or marketplaces, since it is not available in the PFP webapp.
