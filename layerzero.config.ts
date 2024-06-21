import { EndpointId } from '@layerzerolabs/lz-definitions'

import type { OAppOmniGraphHardhat, OmniPointHardhat } from '@layerzerolabs/toolbox-hardhat'

const homeverseContract: OmniPointHardhat = {
    eid: EndpointId.HOMEVERSE_V2_MAINNET,
    contractName: 'GenesisChampion',
}

const config: OAppOmniGraphHardhat = {
    contracts: [
        {
            contract: homeverseContract,
        }
    ],
    connections: [
    ],
}

export default config
