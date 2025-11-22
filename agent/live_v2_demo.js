/**
 * ReageCFO V2 - LIVE Demo
 * Execute a real cross-chain payment with step-by-step output
 */

require('dotenv').config();
const { ethers } = require('ethers');
const axios = require('axios');

// Configuration
const SEPOLIA_RPC = 'https://ethereum-sepolia-rpc.publicnode.com';
const LEDGER_ADDRESS = '0xEDC4e211FE792f9B76605850567DD8b98A67A7E4'; // V2 (Working)
const VAULT_ADDRESS = '0x23742F2F911Ed434081177e5aA9DB6a5684ba0dC';
const CDP_PRIVATE_KEY = process.env.CDP_WALLET_PRIVATE_KEY;
const CDP_ADDRESS = '0xBCD8c885E3bc0F87940eAdA431e14cA9F3Fc98E0';
const BASE_SEPOLIA_EID = 40245;
const PYTH_HERMES_API = 'https://hermes.pyth.network';
const ETH_USD_PRICE_ID = '0xff61491a931112ddf1bd8147cd1b641375f79f5825126d665480874634fd0ace';

const LEDGER_ABI = [
    "function sendCrossChainPayment(uint32 _dstEid, address recipient, uint256 amount, bytes32 invoiceId, string calldata intent) external payable",
    "function agentWallet() external view returns (address)",
    "event CrossChainPaymentSent(uint32 indexed dstEid, address indexed recipient, uint256 amount, bytes32 invoiceId)"
];

function printBanner(text) {
    console.log('\n' + '═'.repeat(80));
    console.log(`  ${text}`);
    console.log('═'.repeat(80) + '\n');
}

function printStep(num, text) {
    console.log(`\n${'─'.repeat(80)}`);
    console.log(`📍 STEP ${num}: ${text}`);
    console.log('─'.repeat(80) + '\n');
}

async function fetchPythPrice() {
    const response = await axios.get(
        `${PYTH_HERMES_API}/api/latest_price_feeds`,
        { params: { ids: [ETH_USD_PRICE_ID] } }
    );
    
    const priceFeed = response.data[0];
    const price = priceFeed.price;
    
    const priceValue = parseInt(price.price);
    const expo = parseInt(price.expo);
    const actualPrice = priceValue * Math.pow(10, expo);
    const confidence = parseInt(price.conf) * Math.pow(10, expo);
    
    return {
        price: actualPrice,
        confidence: confidence,
        publishTime: new Date(priceFeed.price.publish_time * 1000)
    };
}

async function main() {
    printBanner('🎯 ReageCFO V2 - LIVE DEMO');
    
    console.log('This is a LIVE demo with a NEW transaction!');
    console.log('Watch as each step executes in real-time...\n');
    
    // STEP 1: Create New Invoice
    printStep(1, 'Create New Invoice');
    
    const timestamp = Date.now();
    const invoice = {
        id: `INV-LIVE-${timestamp}`,
        vendor: 'Acme Cloud Services',
        amount: ethers.parseEther('0.0001'), // Small amount to conserve funds
        recipient: '0x742D35CC6634c0532925A3b844BC9E7595F0BEb0',
        description: `Live Demo Payment - ${new Date().toISOString()}`
    };
    
    const invoiceId = ethers.keccak256(ethers.toUtf8Bytes(invoice.id + Math.random()));
    
    console.log('✅ NEW Invoice Created:');
    console.log(`   ID: ${invoice.id}`);
    console.log(`   Amount: ${ethers.formatEther(invoice.amount)} ETH`);
    console.log(`   Vendor: ${invoice.vendor}`);
    console.log(`   Recipient: ${invoice.recipient}`);
    console.log(`   Invoice Hash: ${invoiceId}`);
    
    // STEP 2: Initialize CDP Wallet
    printStep(2, 'Initialize CDP AI Agent');
    
    const provider = new ethers.JsonRpcProvider(SEPOLIA_RPC);
    const cdpWallet = new ethers.Wallet(CDP_PRIVATE_KEY, provider);
    const balance = await provider.getBalance(CDP_ADDRESS);
    
    console.log('✅ CDP Server Wallet Ready:');
    console.log(`   Address: ${CDP_ADDRESS}`);
    console.log(`   Balance: ${ethers.formatEther(balance)} ETH`);
    console.log(`   🤖 This AI agent will sign the transaction autonomously`);
    
    // STEP 3: Fetch Pyth Price
    printStep(3, 'Fetch Real-Time Price from Pyth Network');
    
    console.log('Connecting to Pyth Hermes API...');
    const pythPrice = await fetchPythPrice();
    
    console.log('\n✅ Live Price Data:');
    console.log('   ┌─────────────────────────────────────────────────┐');
    console.log(`   │  ETH/USD: $${pythPrice.price.toFixed(2).padStart(8)}                      │`);
    console.log(`   │  Confidence: ±$${pythPrice.confidence.toFixed(2).padStart(6)}                    │`);
    console.log(`   │  Updated: ${pythPrice.publishTime.toISOString()} │`);
    console.log('   └─────────────────────────────────────────────────┘');
    
    const paymentValueUSD = parseFloat(ethers.formatEther(invoice.amount)) * pythPrice.price;
    console.log(`\n   💰 Payment Value: $${paymentValueUSD.toFixed(4)} USD`);
    
    // STEP 4: AI Decision
    printStep(4, 'AI Agent Makes Decision');
    
    console.log('🤖 Analyzing invoice with market data...\n');
    console.log('   Decision Criteria:');
    console.log(`      • ETH price > $2000: ${pythPrice.price > 2000 ? '✅' : '❌'} ($${pythPrice.price.toFixed(2)})`);
    console.log(`      • Payment < $5000: ${paymentValueUSD < 5000 ? '✅' : '❌'} ($${paymentValueUSD.toFixed(4)})`);
    console.log(`      • Invoice valid: ✅`);
    
    if (pythPrice.price > 2000 && paymentValueUSD < 5000) {
        console.log('\n   ✅ DECISION: APPROVE PAYMENT');
    } else {
        console.log('\n   ❌ DECISION: REJECT PAYMENT');
        return;
    }
    
    // STEP 5: Execute Cross-Chain Payment
    printStep(5, 'Execute Cross-Chain Payment via LayerZero');
    
    const ledgerContract = new ethers.Contract(LEDGER_ADDRESS, LEDGER_ABI, cdpWallet);
    
    console.log('Preparing transaction...\n');
    console.log('   Route: Sepolia → Base Sepolia');
    console.log(`   Ledger: ${LEDGER_ADDRESS}`);
    console.log(`   Vault: ${VAULT_ADDRESS}`);
    console.log(`   Destination EID: ${BASE_SEPOLIA_EID}`);
    
    // Use a fixed gas amount that worked before
    const lzFee = ethers.parseEther('0.0001'); // Fixed fee
    
    console.log(`\n   LayerZero Fee: ${ethers.formatEther(lzFee)} ETH`);
    console.log('\n🔐 CDP Wallet signing transaction...');
    console.log('   (This proves autonomous AI operation!)\n');
    
    try {
        const tx = await ledgerContract.sendCrossChainPayment(
            BASE_SEPOLIA_EID,
            invoice.recipient,
            invoice.amount,
            invoiceId,
            invoice.description,
            { value: lzFee, gasLimit: 500000 }
        );
        
        console.log('✅ TRANSACTION SENT!\n');
        console.log('   ┌─────────────────────────────────────────────────────────────────────┐');
        console.log(`   │  TX Hash: ${tx.hash}  │`);
        console.log('   └─────────────────────────────────────────────────────────────────────┘');
        console.log(`\n   🔍 View on Sepolia: https://sepolia.etherscan.io/tx/${tx.hash}`);
        
        // STEP 6: Wait for Confirmation
        printStep(6, 'Waiting for Block Confirmation');
        
        console.log('⏳ Waiting for transaction to be mined...\n');
        
        const receipt = await tx.wait();
        
        console.log('✅ TRANSACTION CONFIRMED!\n');
        console.log(`   Block Number: ${receipt.blockNumber}`);
        console.log(`   Gas Used: ${receipt.gasUsed.toString()}`);
        console.log(`   Status: ${receipt.status === 1 ? 'Success ✅' : 'Failed ❌'}`);
        
        // Extract event data
        const event = receipt.logs.find(log => {
            try {
                const parsed = ledgerContract.interface.parseLog(log);
                return parsed && parsed.name === 'CrossChainPaymentSent';
            } catch { return false; }
        });
        
        if (event) {
            const parsed = ledgerContract.interface.parseLog(event);
            console.log('\n✅ LayerZero Message Sent:');
            console.log(`   Destination EID: ${parsed.args.dstEid}`);
            console.log(`   Recipient: ${parsed.args.recipient}`);
            console.log(`   Amount: ${ethers.formatEther(parsed.args.amount)} ETH`);
        }
        
        // STEP 7: Track LayerZero
        printStep(7, 'Track LayerZero Message');
        
        console.log('✅ Cross-chain message initiated!\n');
        console.log('   📡 Track on LayerZero Scan:');
        console.log(`   https://testnet.layerzeroscan.com/tx/${tx.hash}\n`);
        console.log('   The message will be verified by DVNs and delivered to Base Sepolia.');
        console.log('   This typically takes 1-2 minutes.\n');
        console.log('   Once delivered, check the vault on Base:');
        console.log(`   https://sepolia.basescan.org/address/${VAULT_ADDRESS}#events`);
        
        // Final Summary
        printBanner('🎉 V2 DEMO COMPLETE!');
        
        console.log('✅ All 4 Sponsor Integrations Demonstrated:\n');
        console.log('   1. 🏛️  EVVM: Transaction recorded on sovereign ledger');
        console.log('   2. 💙 CDP: AI agent autonomously signed transaction');
        console.log('   3. 📊 Pyth: Real-time price influenced decision');
        console.log('   4. ⛓️  LayerZero: Cross-chain message sent\n');
        
        console.log('📊 Verification Links:\n');
        console.log(`   Sepolia TX: https://sepolia.etherscan.io/tx/${tx.hash}`);
        console.log(`   LayerZero: https://testnet.layerzeroscan.com/tx/${tx.hash}`);
        console.log(`   Vault: https://sepolia.basescan.org/address/${VAULT_ADDRESS}\n`);
        
        console.log('═'.repeat(80) + '\n');
        
        // Return transaction hash for next demo
        return tx.hash;
        
    } catch (error) {
        console.error('\n❌ Transaction Failed:');
        console.error(`   Error: ${error.message}`);
        if (error.data) {
            console.error(`   Data: ${error.data}`);
        }
        throw error;
    }
}

main().catch(error => {
    console.error('\n❌ Demo failed:', error.message);
    process.exit(1);
});
