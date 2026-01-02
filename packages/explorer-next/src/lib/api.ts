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

const RPC_USER = process.env.RPC_USER || "user";
const RPC_PASSWORD = process.env.RPC_PASSWORD || "pass";
const RPC_URL = `http://${process.env.RPC_HOST || "127.0.0.1"}:${process.env.RPC_PORT || "18332"}`;

const rpcCall = async (method: string, params: any[] = []) => {
    if (!process.env.RPC_USER) {
        console.warn("RPC_USER not set, using mock data");
        return null;
    }
    const headers = {
        "content-type": "text/plain;",
    };
    const auth = Buffer.from(`${RPC_USER}:${RPC_PASSWORD}`).toString("base64");
    // @ts-ignore
    headers["Authorization"] = `Basic ${auth}`;

    try {
        console.log(`RPC Call: ${method} to ${RPC_URL}`);
        const res = await fetch(RPC_URL, {
            method: "POST",
            headers,
            body: JSON.stringify({
                jsonrpc: "1.0",
                id: "explorer",
                method,
                params,
            }),
            cache: "no-store"
        });

        if (!res.ok) {
            console.error(`RPC HTTP Error: ${res.status} ${res.statusText}`);
            return null;
        }

        const data = await res.json();
        if (data.error) {
            console.error(`RPC Application Error:`, data.error);
            throw new Error(data.error.message);
        }
        return data.result;
    } catch (e) {
        console.error(`RPC Exception (${method}):`, e);
        return null;
    }
};

export const api = {
    getStats: async () => {
        const info = await rpcCall("getmininginfo");
        if (!info) {
            return {
                height: 10500,
                hashrate: "420.69 MH/s",
                difficulty: "1,234.56",
                supply: "525,000 RTC",
                avgBlockTime: "60s"
            };
        }
        return {
            height: info.blocks,
            hashrate: `${(info.networkhashps / 1000000).toFixed(2)} MH/s`,
            difficulty: info.difficulty.toFixed(2),
            supply: `${(info.blocks * 50).toLocaleString()} RTC`, // Approximation
            avgBlockTime: "60s"
        };
    },
    getLatestBlocks: async () => {
        const height = await rpcCall("getblockcount");
        if (!height) return MOCK_BLOCKS;

        const blocks: Block[] = [];
        const count = 10;
        for (let i = 0; i < count; i++) {
            const h = height - i;
            if (h < 0) break;
            const hash = await rpcCall("getblockhash", [h]);
            const block = await rpcCall("getblock", [hash]);
            if (block) {
                blocks.push({
                    height: block.height,
                    hash: block.hash,
                    timestamp: block.time * 1000,
                    size: block.size,
                    tx_count: block.tx.length,
                    miner: "Retardio Miner", // P2Pool attribution is harder, straightforward placeholder
                    reward: 50
                });
            }
        }
        return blocks;
    },
    getBlock: async (height: number) => {
        const hash = await rpcCall("getblockhash", [Number(height)]);
        if (!hash) return MOCK_BLOCKS[0];
        const block = await rpcCall("getblock", [hash]);
        return {
            height: block.height,
            hash: block.hash,
            timestamp: block.time * 1000,
            size: block.size,
            tx_count: block.tx.length,
            miner: "Retardio Miner",
            reward: 50
        };
    }
};
