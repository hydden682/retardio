// Node.js test script for Retardio Wallet with 24-word Recovery Phrase
const { Wallet } = require('./pkg/retardio_wallet.js');

async function main() {
    console.log("🚀 Initializing Retardio Wallet with RIP-0...\n");

    // 1. Create a new wallet
    const wallet = new Wallet();
    const mnemonic = wallet.mnemonic();

    console.log("✅ Wallet Created!");
    console.log("📍 Address:", wallet.address());
    console.log("📝 Recovery Phrase (24 words):\n  ", mnemonic);
    console.log("\n🔑 Public Key:", wallet.publicKey());
    console.log("🔐 Private Key (Derived from phrase):", wallet.privateKey());

    // 1b. Test Passphrase (Security Feature)
    console.log("\n🔒 Testing Passphrase Protection...");
    const phrase = wallet.mnemonic();
    const walletNoPass = await Wallet.fromMnemonic(phrase);
    const walletPass = await Wallet.fromMnemonic(phrase, "super-secret-salt");

    console.log("  No Passphrase Address: ", walletNoPass.address());
    console.log("  With Passphrase Addr:  ", walletPass.address());

    if (walletNoPass.address() !== walletPass.address()) {
        console.log("✅ Passphrase correctly changed the derived keys (Salted).");
    } else {
        console.log("❌ ERROR: Passphrase had no effect!");
    }

    // 2. Demonstrate Recovery
    console.log("\n🔄 Testing Wallet Recovery...");
    try {
        const recoveredWallet = Wallet.fromMnemonic(mnemonic);
        console.log("✅ Wallet Recovered!");
        console.log("📍 Recovered Address:", recoveredWallet.address());

        if (recoveredWallet.address() === wallet.address()) {
            console.log("✨ Match! Recovery successful. ✅");
        } else {
            console.log("❌ Mismatch! Recovery failed. 😭");
        }
    } catch (e) {
        console.error("❌ Recovery Error:", e);
    }

    // 3. Demonstrate Signing & Verification with Recovered Wallet
    const message = "Retardio recovery check";
    const messageHash = Wallet.hashMessage(message);
    const hashBytes = Buffer.from(messageHash, 'hex');

    console.log("\n🔏 Signing with recovered wallet...");
    const signature = wallet.signMessage(hashBytes);
    const isValid = wallet.verifySignature(hashBytes, signature);
    console.log("✨ Signature Valid?", isValid ? "YES ✅" : "NO ❌");

    // 4. Test Invalid Recovery
    console.log("\n🛡️ Testing Invalid Mnemonic...");
    try {
        Wallet.fromMnemonic("invalid phrase here");
        console.log("❌ Error: Invalid mnemonic was accepted!");
    } catch (e) {
        console.log("✅ Correctly rejected invalid mnemonic. Error:", e.message || e);
    }

    console.log("\n🎉 Retardio Wallet Mnemonic demo complete!");
}

main().catch(console.error);
