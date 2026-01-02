use k256::{
    ecdsa::{signature::Signer, signature::Verifier, Signature, SigningKey, VerifyingKey},
    elliptic_curve::sec1::ToEncodedPoint,
    PublicKey, SecretKey,
};
use ripemd::{Digest as RipemdDigest, Ripemd160};
use sha2::Sha256;
use bip39::{Mnemonic, Language};
use bip32::{Mnemonic as Bip32Mnemonic, XPrv};
use wasm_bindgen::prelude::*;

/// -----------------------------------------------------------------
/// Internal implementation (pure-Rust k256 for secp256k1 + RIP-0)
/// -----------------------------------------------------------------
#[derive(Clone)]
struct WalletInner {
    secret: SecretKey,
    public_key: PublicKey,
    mnemonic: Option<String>,
}

impl WalletInner {
    /// Create a new wallet with a random 24-word recovery phrase and optional passphrase
    pub fn new_random(passphrase: Option<&str>) -> Self {
        // Generate a 24-word mnemonic in English
        // bip39 2.2.2 (rust-bitcoin) uses generate_in
        let mnemonic = Mnemonic::generate_in(Language::English, 24)
            .expect("Failed to generate mnemonic");
        
        // Use empty string if no passphrase provided
        let pass = passphrase.unwrap_or("");
        
        // Use bip32 crate to derive the seed with passphrase salt
        // This handles "mnemonic" + passphrase internally
        let seed = mnemonic.to_seed(pass); 

        // Derive Master Extended Private Key
        let xprv = XPrv::new(&seed).expect("Failed to create XPrv");
        
        // Derive standard path m/44'/0'/0'/0/0 (Retardio/Bitcoin Standard)
        // 44' = BIP44, 0' = BTC/Retardio, 0' = Account 0, 0 = Change(Ext), 0 = Index
        let _child_path = "m/44'/0'/0'/0/0";
        let child_xprv = xprv.derive_child(bip32::ChildNumber::new(44, true).unwrap())
            .unwrap()
            .derive_child(bip32::ChildNumber::new(0, true).unwrap())
            .unwrap()
            .derive_child(bip32::ChildNumber::new(0, true).unwrap())
            .unwrap()
            .derive_child(bip32::ChildNumber::new(0, false).unwrap())
            .unwrap()
            .derive_child(bip32::ChildNumber::new(0, false).unwrap())
            .unwrap();

        let secret = SecretKey::from_slice(&child_xprv.private_key().to_bytes()).expect("32 bytes key");
        let public_key = secret.public_key();
        
        WalletInner { 
            secret, 
            public_key, 
            mnemonic: Some(mnemonic.to_string()) 
        }
    }

    /// Restore a wallet from an existing 24-word mnemonic and optional passphrase
    pub fn from_mnemonic(phrase: &str, passphrase: Option<&str>) -> Result<Self, String> {
        let mnemonic = Mnemonic::parse(phrase)
            .map_err(|e| format!("Invalid mnemonic: {}", e))?;
            
        let pass = passphrase.unwrap_or("");
        let seed = mnemonic.to_seed(pass);
        
        // Derive Master Extended Private Key
        let xprv = XPrv::new(&seed).map_err(|_| "Failed to create XPrv from seed")?;
        
        // Standard Path m/44'/0'/0'/0/0
        let child_xprv = xprv.derive_child(bip32::ChildNumber::new(44, true).unwrap())
             .unwrap()
             .derive_child(bip32::ChildNumber::new(0, true).unwrap())
             .unwrap()
             .derive_child(bip32::ChildNumber::new(0, true).unwrap())
             .unwrap()
             .derive_child(bip32::ChildNumber::new(0, false).unwrap())
             .unwrap()
             .derive_child(bip32::ChildNumber::new(0, false).unwrap())
             .unwrap();

        let secret = SecretKey::from_slice(&child_xprv.private_key().to_bytes()).expect("32 bytes key");
        let public_key = secret.public_key();
        
        Ok(WalletInner { 
            secret, 
            public_key, 
            mnemonic: Some(phrase.to_string()) 
        })
    }

    /// Restore from a raw hex private key (Standard secp256k1)
    pub fn from_private_key(hex: &str) -> Result<Self, String> {
        let bytes = hex_decode(hex).map_err(|e| e.to_string())?;
        let secret = SecretKey::from_slice(&bytes).map_err(|_| "Invalid private key bytes")?;
        let public_key = secret.public_key();
        
        Ok(WalletInner {
            secret,
            public_key,
            mnemonic: None
        })
    }

    /// Return a *String* address – Retardio-style Base58Check encoding.
    pub fn address(&self) -> String {
        let pk_point = self.public_key.to_encoded_point(true);
        let pk_serialized = pk_point.as_bytes();

        let sha256_hash: [u8; 32] = Sha256::digest(pk_serialized).into();
        let ripemd160_hash: [u8; 20] = Ripemd160::digest(sha256_hash).into();

        let mut versioned = vec![35];  // Retardio mainnet version byte (addresses start with 'F')
        versioned.extend_from_slice(&ripemd160_hash);

        let check: [u8; 32] = Sha256::digest(Sha256::digest(&versioned)).into();
        let checksum = &check[..4];

        let mut payload = versioned;
        payload.extend_from_slice(checksum);

        base58_encode(&payload)
    }

    pub fn public_key_hex(&self) -> String {
        let pk_point = self.public_key.to_encoded_point(true);
        hex_encode(pk_point.as_bytes())
    }

    pub fn private_key_hex(&self) -> String {
        hex_encode(self.secret.to_bytes().as_slice())
    }

    pub fn mnemonic(&self) -> String {
        self.mnemonic.clone().unwrap_or_else(|| "N/A (Imported from Private Key)".to_string())
    }
}

/// Simple hex encoder
fn hex_encode(data: &[u8]) -> String {
    data.iter().map(|b| format!("{:02x}", b)).collect()
}

/// Simple hex decoder
fn hex_decode(s: &str) -> Result<Vec<u8>, &'static str> {
    if s.len() % 2 != 0 {
        return Err("Hex string must have even length");
    }
    (0..s.len())
        .step_by(2)
        .map(|i| u8::from_str_radix(&s[i..i + 2], 16).map_err(|_| "Invalid hex character"))
        .collect()
}

/// Simple, pure-Rust Base58 encoder.
fn base58_encode(data: &[u8]) -> String {
    const ALPHABET: &[u8] = b"123456789ABCDEFGHJKLMNPQRSTUVWXYZabcdefghijkmnopqrstuvwxyz";

    let mut leading_zeros = 0;
    while leading_zeros < data.len() && data[leading_zeros] == 0 {
        leading_zeros += 1;
    }

    let mut digits: Vec<usize> = Vec::new();
    for &byte in &data[leading_zeros..] {
        let mut carry = byte as usize;
        for j in (0..digits.len()).rev() {
            carry += digits[j] << 8;
            digits[j] = carry % 58;
            carry /= 58;
        }
        while carry > 0 {
            digits.insert(0, carry % 58);
            carry /= 58;
        }
    }

    let mut result = std::iter::repeat('1')
        .take(leading_zeros)
        .collect::<String>();

    for d in digits {
        result.push(ALPHABET[d] as char);
    }

    result
}

// ---------------------------------------------------------------------
// wasm-bindgen export surface
// ---------------------------------------------------------------------

#[wasm_bindgen]
pub struct Wallet {
    inner: WalletInner,
}

#[wasm_bindgen]
impl Wallet {
    #[wasm_bindgen(constructor)]
    pub fn new(passphrase: Option<String>) -> Wallet {
        Wallet { inner: WalletInner::new_random(passphrase.as_deref()) }
    }

    #[wasm_bindgen(js_name = fromMnemonic)]
    pub fn from_mnemonic(phrase: &str, passphrase: Option<String>) -> Result<Wallet, JsValue> {
        let inner = WalletInner::from_mnemonic(phrase, passphrase.as_deref())
            .map_err(|e| JsValue::from_str(&e))?;
        Ok(Wallet { inner })
    }

    #[wasm_bindgen(js_name = fromPrivateKey)]
    pub fn from_private_key(hex: &str) -> Result<Wallet, JsValue> {
        let inner = WalletInner::from_private_key(hex)
            .map_err(|e| JsValue::from_str(&e))?;
        Ok(Wallet { inner })
    }

    #[wasm_bindgen(js_name = address)]
    pub fn js_address(&self) -> String {
        self.inner.address()
    }

    #[wasm_bindgen(js_name = publicKey)]
    pub fn js_public_key(&self) -> String {
        self.inner.public_key_hex()
    }

    #[wasm_bindgen(js_name = privateKey)]
    pub fn js_private_key(&self) -> String {
        self.inner.private_key_hex()
    }

    #[wasm_bindgen(js_name = mnemonic)]
    pub fn js_mnemonic(&self) -> String {
        self.inner.mnemonic()
    }

    #[wasm_bindgen(js_name = signMessage)]
    pub fn sign_message(&self, message_hash: &[u8]) -> Result<String, JsValue> {
        if message_hash.len() != 32 {
            return Err(JsValue::from_str("Message hash must be 32 bytes"));
        }
        
        let signing_key = SigningKey::from(&self.inner.secret);
        let signature: Signature = signing_key.sign(message_hash);
        Ok(hex_encode(signature.to_bytes().as_slice()))
    }

    #[wasm_bindgen(js_name = verifySignature)]
    pub fn verify_signature(&self, message_hash: &[u8], signature_hex: &str) -> bool {
        if message_hash.len() != 32 {
            return false;
        }
        
        let sig_bytes = match hex_decode(signature_hex) {
            Ok(b) => b,
            Err(_) => return false,
        };
        
        let signature = match Signature::try_from(sig_bytes.as_slice()) {
            Ok(s) => s,
            Err(_) => return false,
        };
        
        let verifying_key = VerifyingKey::from(&self.inner.public_key);
        verifying_key.verify(message_hash, &signature).is_ok()
    }

    #[wasm_bindgen(js_name = hashMessage)]
    pub fn hash_message(message: &str) -> String {
        let hash: [u8; 32] = Sha256::digest(message.as_bytes()).into();
        hex_encode(&hash)
    }
}

// ---------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_mnemonic_generation_and_recovery() {
        let w1 = WalletInner::new_random(None);
        let mnemonic = w1.mnemonic();
        assert_eq!(mnemonic.split_whitespace().count(), 24);

        let w2 = WalletInner::from_mnemonic(&mnemonic, None).unwrap();
        assert_eq!(w1.address(), w2.address());
        assert_eq!(w1.private_key_hex(), w2.private_key_hex());
    }
    
    #[test]
    fn test_passphrase_security() {
        let w1 = WalletInner::new_random(Some("secret"));
        let mnemonic = w1.mnemonic();
        
        // Same phrase, different pass (None) => Different keys
        let w2 = WalletInner::from_mnemonic(&mnemonic, None).unwrap();
        assert_ne!(w1.address(), w2.address());
        
        // Same phrase, same pass => Same keys
        let w3 = WalletInner::from_mnemonic(&mnemonic, Some("secret")).unwrap();
        assert_eq!(w1.address(), w3.address());
    }

    #[test]
    fn test_invalid_mnemonic() {
        let result = WalletInner::from_mnemonic("invalid mnemonic phrase", None);
        assert!(result.is_err());
    }
}
