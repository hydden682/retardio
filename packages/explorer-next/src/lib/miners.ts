// Map of known miner addresses or coinbase tags to names
const KNOWN_MINERS: Record<string, string> = {
    // Pools
    "rt1q...pool": "RetardioPool",
    // Devs
    "rt1q...dev": "Dev Fund",
};

export function identifyMiner(address?: string, coinbaseTag?: string): { name: string; isPool: boolean } {
    if (address && KNOWN_MINERS[address]) {
        return { name: KNOWN_MINERS[address], isPool: true };
    }

    if (coinbaseTag) {
        if (coinbaseTag.includes("/RetardioPool/")) return { name: "RetardioPool", isPool: true };
    }

    // Default fallback
    return { name: address ? address.substring(0, 12) + "..." : "Unknown Miner", isPool: false };
}
