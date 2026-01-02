export const HALVING_INTERVAL = 210000;
export const INITIAL_REWARD = 50;

export function getHalvingInfo(currentHeight: number) {
    const era = Math.floor(currentHeight / HALVING_INTERVAL);
    const nextHalvingHeight = (era + 1) * HALVING_INTERVAL;
    const blocksRemaining = nextHalvingHeight - currentHeight;
    const currentReward = INITIAL_REWARD / Math.pow(2, era);
    const blocksPercentage = ((currentHeight % HALVING_INTERVAL) / HALVING_INTERVAL) * 100;

    return {
        era,
        currentReward,
        nextHalvingHeight,
        blocksRemaining,
        blocksPercentage: Math.min(Math.max(blocksPercentage, 0), 100) // Clamp 0-100
    };
}
