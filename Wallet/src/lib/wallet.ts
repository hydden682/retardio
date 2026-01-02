import init, { Wallet as RustWallet } from "../../pkg/retardio_wallet.js";

let initialized = false;

export async function initWallet() {
    if (!initialized) {
        await init();
        initialized = true;
    }
}

export class Wallet {
    private inner: RustWallet;

    private constructor(inner: RustWallet) {
        this.inner = inner;
    }

    /**
     * Create a brand new wallet with a random 24-word recovery phrase.
     * @param passphrase Optional passphrase for extra security (salt).
     */
    static async create(passphrase?: string): Promise<Wallet> {
        await initWallet();
        return new Wallet(new RustWallet(passphrase));
    }

    /**
     * Restore a wallet using an existing 24-word recovery phrase.
     * @param phrase The 24-word mnemonic.
     * @param passphrase Optional passphrase used during creation.
     */
    static async fromMnemonic(phrase: string, passphrase?: string): Promise<Wallet> {
        await initWallet();
        try {
            const inner = RustWallet.fromMnemonic(phrase, passphrase);
            return new Wallet(inner);
        } catch (e) {
            throw new Error(`Failed to restore wallet: ${e}`);
        }
    }

    get address(): string {
        return this.inner.address();
    }

    get publicKey(): string {
        return this.inner.publicKey();
    }

    get privateKey(): string {
        return this.inner.privateKey();
    }

    /**
     * Returns the 24-word recovery phrase.
     * IMPORTANT: Only show this once and keep it secure!
     */
    get mnemonic(): string {
        return this.inner.mnemonic();
    }

    signMessage(message: Uint8Array): string {
        return this.inner.signMessage(message);
    }

    verifySignature(message: Uint8Array, signatureHex: string): boolean {
        return this.inner.verifySignature(message, signatureHex);
    }

    static hashMessage(message: string): string {
        return (RustWallet as any).hashMessage(message);
    }
}
