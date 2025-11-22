const { ethers } = require("ethers");
const { HDNodeWallet } = require("ethers");

// CDP wallet data
const walletData = require('./agent-wallet.json');

console.log("🔐 Deriving Private Key from CDP Seed\n");
console.log(`CDP Wallet Address: ${walletData.address}`);
console.log(`CDP Seed: ${walletData.walletData.seed}\n`);

// Try different derivation paths
const paths = [
    "m/44'/60'/0'/0/0",  // Standard Ethereum path
    "m/44'/60'/0'/0",    // Alternative
    "m/0'/0'/0'",        // Coinbase might use this
    "m/0/0",             // Simple path
];

console.log("Testing derivation paths:\n");

for (const path of paths) {
    try {
        // Create HD wallet from seed
        const seed = "0x" + walletData.walletData.seed;
        const hdNode = HDNodeWallet.fromSeed(seed);
        const wallet = hdNode.derivePath(path);
        
        console.log(`Path: ${path}`);
        console.log(`  Address: ${wallet.address}`);
        console.log(`  Match: ${wallet.address.toLowerCase() === walletData.address.toLowerCase() ? '✅ YES!' : '❌ No'}`);
        
        if (wallet.address.toLowerCase() === walletData.address.toLowerCase()) {
            console.log(`\n🎉 FOUND MATCHING PATH: ${path}`);
            console.log(`Private Key: ${wallet.privateKey}`);
            console.log(`\nSave this to .env as CDP_WALLET_PRIVATE_KEY`);
            process.exit(0);
        }
    } catch (error) {
        console.log(`Path: ${path} - Error: ${error.message}`);
    }
}

console.log("\n⚠️  No matching path found. CDP might use a custom derivation.");
console.log("Let's try using the seed directly as entropy...\n");

// Try using seed as mnemonic entropy
try {
    const mnemonic = ethers.Mnemonic.fromEntropy("0x" + walletData.walletData.seed);
    console.log(`Generated Mnemonic: ${mnemonic.phrase}`);
    
    for (const path of paths) {
        const wallet = HDNodeWallet.fromMnemonic(mnemonic, path);
        console.log(`\nPath: ${path}`);
        console.log(`  Address: ${wallet.address}`);
        console.log(`  Match: ${wallet.address.toLowerCase() === walletData.address.toLowerCase() ? '✅ YES!' : '❌ No'}`);
        
        if (wallet.address.toLowerCase() === walletData.address.toLowerCase()) {
            console.log(`\n🎉 FOUND IT!`);
            console.log(`Private Key: ${wallet.privateKey}`);
            process.exit(0);
        }
    }
} catch (error) {
    console.log(`Mnemonic approach failed: ${error.message}`);
}

console.log("\n💡 Alternative: Use CDP SDK's signing methods directly in agent.js");
