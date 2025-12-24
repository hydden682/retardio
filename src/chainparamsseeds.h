#ifndef BITCOIN_CHAINPARAMSSEEDS_H
#define BITCOIN_CHAINPARAMSSEEDS_H
/**
 * List of fixed seed nodes for the Retardio network
 *
 * This file has been cleared for Retardio - a new altcoin network.
 * Bitcoin's seed nodes have been removed.
 *
 * Add your own Retardio seed nodes here once you have stable nodes running.
 * Each line should contain a BIP155 serialized (networkID, addr, port) tuple.
 *
 * To generate seed nodes, use contrib/seeds/generate-seeds.py once you have
 * a list of stable node IP addresses.
 */
static const uint8_t chainparams_seed_main[] = {
    // Empty - no hardcoded seed nodes yet
    // Nodes will need to manually connect using:
    // - addnode=<ip>:18333 in retardio.conf
    // - retardio-cli addnode <ip>:18333 add
};
#endif // BITCOIN_CHAINPARAMSSEEDS_H
