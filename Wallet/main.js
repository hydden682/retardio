import init, { Wallet } from "./pkg/retardio_wallet.js";

let wallet = null;

const UI = {
    setupSection: document.getElementById('setup-section'),
    backupSection: document.getElementById('backup-section'),
    walletSection: document.getElementById('wallet-section'),

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
    backupMnemonicGrid: document.getElementById('backup-mnemonic-grid'),
    copyMnemonicBtn: document.getElementById('copy-mnemonic-btn'),
    backupConfirmBtn: document.getElementById('backup-confirm-btn'),

    deployBtn: document.getElementById('deploy-btn'),
    deployResult: document.getElementById('deploy-result'),

    tabs: document.querySelectorAll('.tab-btn'),
    tabContents: document.querySelectorAll('.tab-content'),

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
        console.log("Retardio Wallet Core Initialized");
        attachEvents();
    } catch (e) {
        showToast("Initialization Error: " + e.message);
    }
}

function attachEvents() {
    UI.generateBtn.addEventListener('click', createWallet);
    UI.restoreBtn.addEventListener('click', () => {
        UI.restoreArea.classList.toggle('hidden');
        if (!UI.restoreArea.classList.contains('hidden')) {
            UI.restoreArea.scrollIntoView({ behavior: 'smooth' });
        }
    });

    UI.confirmRestoreBtn.addEventListener('click', restoreWallet);

    UI.backupConfirmBtn.addEventListener('click', () => {
        UI.backupSection.classList.add('hidden');
        UI.walletSection.classList.remove('hidden');
        showToast("Wallet Active!");
    });

    UI.copyMnemonicBtn.addEventListener('click', () => {
        const text = wallet ? wallet.mnemonic() : "";
        if (text && !text.startsWith("N/A")) {
            navigator.clipboard.writeText(text);
            showToast("Recovery Phrase copied!");
        } else {
            showToast("No mnemonic to copy!");
        }
    });

    UI.tabMnemonic.addEventListener('click', () => switchRestoreTab('mnemonic'));
    UI.tabPrivKey.addEventListener('click', () => switchRestoreTab('privkey'));

    UI.tabs.forEach(tab => {
        tab.addEventListener('click', () => {
            if (!tab.dataset.tab) return;
            UI.tabs.forEach(t => t.classList.remove('active'));
            UI.tabContents.forEach(c => c.classList.add('hidden'));
            tab.classList.add('active');
            const target = document.getElementById(tab.dataset.tab + '-tab');
            if (target) target.classList.remove('hidden');
        });
    });

    UI.deployBtn.addEventListener('click', handleDeploy);

    UI.revealPrivBtn.addEventListener('click', () => {
        UI.displayPriv.classList.toggle('blur');
        UI.revealPrivBtn.textContent = UI.displayPriv.classList.contains('blur') ? 'REVEAL' : 'HIDE';
    });

    UI.copyAddressBtn.addEventListener('click', () => {
        const address = UI.displayAddress.textContent;
        navigator.clipboard.writeText(address);
        showToast("Address copied!");
    });

    UI.logoutBtn.addEventListener('click', confirmLogout);

    // Initial network stats fetch
    updateNetworkStats();
    setInterval(updateNetworkStats, 10000);
}

async function updateNetworkStats() {
    try {
        const response = await fetch('http://localhost:3002/api/stats');
        const stats = await response.json();

        const deployTab = document.getElementById('deploy-tab');
        if (deployTab) {
            const banner = deployTab.querySelector('.banner');
            if (banner) {
                banner.innerHTML = `
                    <p style="margin-bottom: 10px; color: inherit;"><strong>Node Status:</strong> Syncing (Block #${stats.blocks.toLocaleString()})</p>
                    <p style="font-size: 0.8rem; opacity: 0.8; margin-bottom: 5px;">Difficulty: ${parseFloat(stats.difficulty).toFixed(4)}</p>
                    <p style="font-size: 0.8rem; opacity: 0.8; margin-bottom: 0;">Connections: ${stats.connections}</p>
                `;
            }
        }
    } catch (e) {
        console.warn("Retardio Node not reachable for stats");
    }
}

function confirmLogout() {
    if (confirm("Destroy current session? Make sure you have your recovery phrase saved!")) {
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
        if (!pass) return showToast("A security password is required!");
        if (pass.length < 8) return showToast("Password is too short (min 8 chars)");

        wallet = new Wallet(pass);

        UI.setupSection.classList.add('hidden');
        UI.backupSection.classList.remove('hidden');

        const words = wallet.mnemonic().split(' ');
        const gridHtml = words.map((w, i) => `<span><strong>${i + 1}.</strong> ${w}</span>`).join('');

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
    if (!wallet) return;
    UI.displayAddress.textContent = wallet.address();
    UI.displayPub.textContent = wallet.publicKey();
    UI.displayPriv.textContent = wallet.privateKey();
}

function handleDeploy() {
    UI.deployResult.className = 'banner success fade-in';
    UI.deployResult.classList.remove('hidden');
    UI.deployResult.innerHTML = "✅ <strong>KEYS VERIFIED</strong><br>Wallet is ready for Retardio Network.";
    showToast("Verification Successful");
}

function showToast(msg) {
    UI.toast.textContent = msg;
    UI.toast.classList.add('show');
    setTimeout(() => UI.toast.classList.remove('show'), 3000);
}

start();
