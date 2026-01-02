// Basic API client structure - designed to be swapped with real Indexer calls later
// Currently mocks data for UI development

export interface Block {
    height: number;
    hash: string;
    timestamp: number;
    size: number;
    tx_count: number;
    miner: string;
    reward: number;
}

const MOCK_BLOCKS: Block[] = Array.from({ length: 10 }).map((_, i) => ({
    height: 10500 - i,
    hash: `000000000019d6689c085ae165831e934ff763ae46a2a6c172b3f1b60a8ce26f`,
    timestamp: Date.now() - i * 600 * 1000,
    size: 1420 + i * 5,
    tx_count: 5 + i,
    miner: "RetardioPool",
    reward: 50
}));

export const api = {
    getStats: async () => {
        return {
            height: 10500,
            hashrate: "420.69 MH/s",
            difficulty: "1,234.56",
            supply: "525,000 RTC",
            avgBlockTime: "60s"
        };
    },
    getLatestBlocks: async () => {
        return MOCK_BLOCKS;
    },
    getBlock: async (height: number) => {
        return MOCK_BLOCKS[0]; // TODO: Real implementation
    }
};
