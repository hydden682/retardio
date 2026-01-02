import { Wallet } from "../lib/wallet.ts";

async function main() {
    console.log("🚀 Initializing Retardio Wallet (Deno Edition) with RIP-0...\n");

    // 1. Create a new wallet
    const wallet = await Wallet.create();
    console.log("✅ Wallet Created!");
    console.log("📍 Address:", wallet.address);
    console.log("📝 RIP-0 Phrase:", wallet.mnemonic);

    // 2. Demonstrate Signing
    const message = "Hello Retardio World!";
    console.log("\n📝 Signing message:", message);

    // Use the core hash utility
    const hashHex = Wallet.hashMessage(message);
    const hashBytes = hexToBytes(hashHex);

    const signature = wallet.signMessage(hashBytes);
    console.log("🔏 Signature (Hex):", signature);

    // 3. Demonstrate Verification
    console.log("\n🔍 Verifying signature...");
    const isValid = wallet.verifySignature(hashBytes, signature);
    console.log("✨ Is Valid?", isValid ? "YES ✅" : "NO ❌");

    // 4. Test invalid verification
    console.log("\n🛡️ Tamper Check...");
    const temperedHash = hexToBytes(Wallet.hashMessage("Liquidate the shorts"));
    const isTemperedValid = wallet.verifySignature(temperedHash, signature);
    console.log("📊 Result:", isTemperedValid ? "INVALID ❌" : "OK (Tamper Detected) ✅");
}

function hexToBytes(hex: string): Uint8Array {
    const bytes = new Uint8Array(hex.length / 2);
    for (let i = 0; i < hex.length; i += 2) {
        bytes[i / 2] = parseInt(hex.substr(i, 2), 16);
    }
    return bytes;
}

main().catch(console.error);
