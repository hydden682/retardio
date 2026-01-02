import init, { Wallet } from "./pkg/retardio_wallet.js";

let wallet = null;

const UI = {
    setupSection: document.getElementById('setup-section'),
    backupSection: document.getElementById('backup-section'),
    walletSection: document.getElementById('wallet-section'),
    walletSection: document.getElementById('wallet-section'),
    mainDashboard: document.getElementById('main-dashboard'),

    generateBtn: document.getElementById('generate-btn'),
    restoreBtn: document.getElementById('restore-btn'),
    restoreArea: document.getElementById('restore-input-area'),

    tabMnemonic: document.getElementById('tab-mnemonic'),
    tabPrivKey: document.getElementById('tab-privkey'),
    restoreMnemonicContent: document.getElementById('restore-mnemonic-content'),
    restorePrivKeyContent: document.getElementById('restore-privkey-content'),

    mnemonicInput: document.getElementById('mnemonic-input'),
    privKeyInput: document.getElementById('privkey-input'),
    passphraseInput: document.getElementById('passphrase-input'),
    restorePassInput: document.getElementById('restore-passphrase-input'),
    confirmRestoreBtn: document.getElementById('confirm-restore-btn'),

    displayAddress: document.getElementById('display-address'),

    // Grids
    backupMnemonicGrid: document.getElementById('backup-mnemonic-grid'),

    // Dashboard Alert removed

    copyMnemonicBtn: document.getElementById('copy-mnemonic-btn'),
    backupConfirmBtn: document.getElementById('backup-confirm-btn'),

    // Deploy Inputs
    deployPrivKeyInput: document.getElementById('deploy-privkey-input'),
    deployMnemonicInput: document.getElementById('deploy-mnemonic-input'),
    deployBtn: document.getElementById('deploy-btn'),
    deployResult: document.getElementById('deploy-result'),

    tabs: document.querySelectorAll('.tab-btn'),
    tabContents: document.querySelectorAll('.tab-content'),

    // Removed verify/sign inputs as they are deleted from UI

    displayPub: document.getElementById('display-pubkey'),
    displayPriv: document.getElementById('display-privkey'),
    revealPrivBtn: document.getElementById('reveal-privBtn'),

    logoutBtn: document.getElementById('logout-btn'),
    copyAddressBtn: document.getElementById('copy-address'),
    toast: document.getElementById('notification-toast')
};

async function start() {
    try {
        await init();
        console.log("WASM Initialized");
        attachEvents();
    } catch (e) {
        showToast("Failed to initialize WASM: " + e.message);
    }
}

function attachEvents() {
    UI.generateBtn.addEventListener('click', createWallet);
    UI.restoreBtn.addEventListener('click', () => {
        UI.restoreArea.classList.toggle('hidden');
    });

    UI.confirmRestoreBtn.addEventListener('click', restoreWallet);

    UI.backupConfirmBtn.addEventListener('click', () => {
        UI.backupSection.classList.add('hidden');
        UI.walletSection.classList.remove('hidden');
        showToast("Wallet Active!");
    });

    // Hide seed button removed

    UI.copyMnemonicBtn.addEventListener('click', () => {
        // Use the wallet object source of truth if available, otherwise fallback to DOM
        const text = wallet ? wallet.mnemonic() : "";
        if (text && !text.startsWith("N/A")) {
            navigator.clipboard.writeText(text);
            showToast("Recovery Phrase copied!");
        } else {
            showToast("No mnemonic to copy!");
        }
    });

    // Restore Tabs
    UI.tabMnemonic.addEventListener('click', () => switchRestoreTab('mnemonic'));
    UI.tabPrivKey.addEventListener('click', () => switchRestoreTab('privkey'));

    UI.tabs.forEach(tab => {
        tab.addEventListener('click', () => {
            UI.tabs.forEach(t => t.classList.remove('active'));
            UI.tabContents.forEach(c => c.classList.add('hidden'));
            tab.classList.add('active');
            document.getElementById(tab.dataset.tab + '-tab').classList.remove('hidden');
        });
    });

    UI.deployBtn.addEventListener('click', handleDeploy);

    UI.revealPrivBtn.addEventListener('click', () => {
        UI.displayPriv.classList.toggle('blur');
        UI.revealPrivBtn.textContent = UI.displayPriv.classList.contains('blur') ? 'REVEAL' : 'HIDE';
    });

    UI.copyAddressBtn.addEventListener('click', () => {
        navigator.clipboard.writeText(UI.displayAddress.textContent);
        showToast("Address copied to clipboard!");
    });

    UI.logoutBtn.addEventListener('click', confirmLogout);

    // Add listener for new dashboard logout too
    const dashLogout = document.getElementById('logout-btn-dashboard');
    if (dashLogout) dashLogout.addEventListener('click', confirmLogout);
}

function confirmLogout() {
    if (confirm("Are you sure? This will destroy the current session. Make sure you have your recovery phrase!")) {
        wallet = null;
        location.reload();
    }
}

function switchRestoreTab(mode) {
    if (mode === 'mnemonic') {
        UI.tabMnemonic.classList.add('active');
        UI.tabPrivKey.classList.remove('active');
        UI.restoreMnemonicContent.classList.remove('hidden');
        UI.restorePrivKeyContent.classList.add('hidden');
    } else {
        UI.tabMnemonic.classList.remove('active');
        UI.tabPrivKey.classList.add('active');
        UI.restoreMnemonicContent.classList.add('hidden');
        UI.restorePrivKeyContent.classList.remove('hidden');
    }
}

function createWallet() {
    try {
        const pass = UI.passphraseInput.value.trim();
        if (!pass) return showToast("Password is REQUIRED for security!");
        if (pass.length < 8) return showToast("Password must be at least 8 characters!");

        wallet = new Wallet(pass);

        // Show Backup Screen
        UI.setupSection.classList.add('hidden');
        UI.backupSection.classList.remove('hidden');

        const words = wallet.mnemonic().split(' ');
        const gridHtml = words.map((w, i) => `<span>${i + 1}. ${w}</span>`).join('');

        if (UI.backupMnemonicGrid) UI.backupMnemonicGrid.innerHTML = gridHtml;

        renderWalletInfo();
    } catch (e) {
        showToast("Generation failed: " + e);
    }
}

function restoreWallet() {
    try {
        if (UI.tabMnemonic.classList.contains('active')) {
            const phrase = UI.mnemonicInput.value.trim();
            const pass = UI.restorePassInput.value.trim() || undefined;
            if (!phrase) return showToast("Enter Mnemonic Phrase");
            wallet = Wallet.fromMnemonic(phrase, pass);
        } else {
            const hex = UI.privKeyInput.value.trim();
            if (!hex) return showToast("Enter Private Key");
            wallet = Wallet.fromPrivateKey(hex);
        }

        UI.setupSection.classList.add('hidden');
        UI.walletSection.classList.remove('hidden');
        renderWalletInfo();
        showToast("Wallet Restored!");
    } catch (e) {
        showToast("Restore Failed: " + e);
    }
}

function renderWalletInfo() {
    UI.displayAddress.textContent = wallet.address();
    UI.displayPub.textContent = wallet.publicKey();
    UI.displayPriv.textContent = wallet.privateKey();
}

function handleDeploy() {
    try {
        // Success
        UI.deployResult.className = 'banner success';
        UI.deployResult.classList.remove('hidden');
        UI.deployResult.innerHTML = "✅ <strong>KEYS CONFIRMED</strong><br>Entering Retardio Network...";
        showToast("Welcome to Retardio Network");

        // Delay to show success message then switch
        setTimeout(() => {
            UI.walletSection.classList.add('hidden');
            UI.mainDashboard.classList.remove('hidden');
        }, 1500);

    } catch (e) {
        showToast("Deployment Error: " + e);
    }
}

function hexToBytes(hex) {
    const bytes = new Uint8Array(hex.length / 2);
    for (let i = 0; i < hex.length; i += 2) {
        bytes[i / 2] = parseInt(hex.substr(i, 2), 16);
    }
    return bytes;
}

function showToast(msg) {
    UI.toast.textContent = msg;
    UI.toast.classList.add('show');
    setTimeout(() => UI.toast.classList.remove('show'), 3000);
}

start();
Greenland 
