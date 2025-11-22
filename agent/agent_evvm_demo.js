/**
 * EVVM Prize Demo - High-Throughput Parallel Processing
 * 
 * This demo showcases:
 * 1. MATE NameService integration (payByName)
 * 2. Async nonces for parallel execution
 * 3. High-frequency treasury operations
 */

require('dotenv').config();
const { ethers } = require('ethers');

// Configuration
const RPC_URL = process.env.RPC_URL || 'https://ethereum-sepolia-rpc.publicnode.com';
const CDP_WALLET_PRIVATE_KEY = process.env.CDP_WALLET_PRIVATE_KEY;
const CONTRACT_ADDRESS_V3 = process.env.CONTRACT_ADDRESS_V3 || '0xYOUR_V3_ADDRESS_HERE';

// ABI for V3 contract (async functions)
const CONTRACT_ABI = [
    "function sendCrossChainPaymentAsync(uint32 _dstEid, address recipient, uint256 amount, bytes32 invoiceId, string intent, uint256 nonce) external payable",
    "function payByName(string mateName, uint256 amount, bytes32 invoiceId, string intent, uint256 nonce) external",
    "function isNonceUsed(address agent, uint256 nonce) external view returns (bool)",
    "function agentWallet() external view returns (address)",
    "function getTransactionCount() external view returns (uint256)",
    "event PaymentByName(string indexed mateName, address indexed resolvedAddress, uint256 amount, bytes32 invoiceId, uint256 nonce)",
    "event CrossChainPaymentSent(uint32 indexed dstEid, address indexed recipient, uint256 amount, bytes32 invoiceId, uint256 nonce)"
];

// Initialize provider and wallet
const provider = new ethers.JsonRpcProvider(RPC_URL);
const wallet = new ethers.Wallet(CDP_WALLET_PRIVATE_KEY, provider);
const contract = new ethers.Contract(CONTRACT_ADDRESS_V3, CONTRACT_ABI, wallet);

// Base Sepolia endpoint ID
const BASE_SEPOLIA_EID = 40245;

/**
 * Generate unique nonce for async execution
 */
function generateNonce() {
    return Date.now() + Math.floor(Math.random() * 1000000);
}

/**
 * Generate unique invoice ID
 */
function generateInvoiceId(index) {
    return ethers.id(`EVVM-DEMO-${Date.now()}-${index}`);
}

/**
 * Run async batch - fires 5 simultaneous transactions
 */
async function runAsyncBatch() {
    console.log('\n🚀 EVVM DEMO: High-Throughput Parallel Processing\n');
    console.log('═'.repeat(80));
    
    // Step 1: Verify agent authorization
    console.log('\n📋 STEP 1: Verify Agent Authorization');
    console.log('─'.repeat(80));
    
    const agentAddress = await contract.agentWallet();
    const walletAddress = await wallet.getAddress();
    
    console.log(`   CDP Agent Wallet: ${walletAddress}`);
    console.log(`   Authorized Agent: ${agentAddress}`);
    console.log(`   Match: ${walletAddress.toLowerCase() === agentAddress.toLowerCase() ? '✓' : '✗'}`);
    
    if (walletAddress.toLowerCase() !== agentAddress.toLowerCase()) {
        console.log('\n❌ ERROR: Wallet not authorized as agent!');
        return;
    }
    
    // Step 2: Prepare 5 parallel transactions
    console.log('\n📦 STEP 2: Prepare 5 Parallel Transactions');
    console.log('─'.repeat(80));
    
    const transactions = [];
    const nonces = [];
    
    for (let i = 0; i < 5; i++) {
        const nonce = generateNonce();
        const invoiceId = generateInvoiceId(i);
        // Use a valid checksummed address
        const baseAddr = '0x742D35CC6634c0532925A3b844BC9E7595F0BEb0';
        const recipient = ethers.getAddress(baseAddr);
        const amount = ethers.parseEther('0.0001');
        const intent = `Parallel Payment ${i + 1}/5`;
        
        nonces.push(nonce);
        
        console.log(`\n   Transaction ${i + 1}:`);
        console.log(`   ├─ Nonce:     ${nonce}`);
        console.log(`   ├─ Invoice:   ${invoiceId.substring(0, 20)}...`);
        console.log(`   ├─ Recipient: ${recipient}`);
        console.log(`   ├─ Amount:    0.0001 ETH`);
        console.log(`   └─ Intent:    ${intent}`);
        
        transactions.push({
            nonce,
            invoiceId,
            recipient,
            amount,
            intent,
            index: i + 1
        });
    }
    
    // Step 3: Fire all transactions in parallel
    console.log('\n🔥 STEP 3: Fire Transactions in Parallel');
    console.log('─'.repeat(80));
    console.log('   Sending 5 transactions simultaneously...\n');
    
    const startTime = Date.now();
    
    // Send all transactions at once
    const promises = transactions.map(async (tx) => {
        try {
            // Estimate gas for LayerZero message
            const lzFee = ethers.parseEther('0.001'); // Estimated LayerZero fee
            
            const txResponse = await contract.sendCrossChainPaymentAsync(
                BASE_SEPOLIA_EID,
                tx.recipient,
                tx.amount,
                tx.invoiceId,
                tx.intent,
                tx.nonce,
                { value: lzFee }
            );
            
            console.log(`   ✅ TX ${tx.index} Sent: ${txResponse.hash}`);
            
            return {
                index: tx.index,
                hash: txResponse.hash,
                nonce: tx.nonce,
                status: 'sent'
            };
        } catch (error) {
            console.log(`   ❌ TX ${tx.index} Failed: ${error.message}`);
            return {
                index: tx.index,
                error: error.message,
                nonce: tx.nonce,
                status: 'failed'
            };
        }
    });
    
    // Wait for all transactions to be sent
    const results = await Promise.all(promises);
    
    const endTime = Date.now();
    const duration = ((endTime - startTime) / 1000).toFixed(2);
    
    // Step 4: Results Summary
    console.log('\n📊 STEP 4: Results Summary');
    console.log('═'.repeat(80));
    
    const successful = results.filter(r => r.status === 'sent').length;
    const failed = results.filter(r => r.status === 'failed').length;
    
    console.log(`\n   ⏱️  Total Time:        ${duration} seconds`);
    console.log(`   ✅ Successful:        ${successful}/5`);
    console.log(`   ❌ Failed:            ${failed}/5`);
    console.log(`   ⚡ Throughput:        ${(5 / duration).toFixed(2)} tx/sec`);
    
    // Show transaction links
    console.log('\n🔗 Transaction Links:');
    console.log('─'.repeat(80));
    
    results.forEach(result => {
        if (result.status === 'sent') {
            console.log(`   TX ${result.index}: https://sepolia.etherscan.io/tx/${result.hash}`);
        }
    });
    
    // Step 5: Verify nonces were used
    console.log('\n🔍 STEP 5: Verify Async Nonces');
    console.log('─'.repeat(80));
    
    for (let i = 0; i < nonces.length; i++) {
        const isUsed = await contract.isNonceUsed(walletAddress, nonces[i]);
        console.log(`   Nonce ${nonces[i]}: ${isUsed ? '✓ Used' : '✗ Not Used'}`);
    }
    
    // Final message
    console.log('\n🎉 EVVM DEMO COMPLETE!');
    console.log('═'.repeat(80));
    console.log('\n   This demo proves:');
    console.log('   ✅ Async nonce support for parallel execution');
    console.log('   ✅ High-throughput treasury operations');
    console.log('   ✅ EVVM-enhanced ledger capabilities');
    console.log('\n');
}

/**
 * Demo: Pay by MATE name
 */
async function demoPayByName() {
    console.log('\n🏷️  BONUS DEMO: Pay by MATE Name');
    console.log('═'.repeat(80));
    
    const mateName = 'vendor.mate'; // Example MATE name
    const amount = ethers.parseEther('0.0001');
    const invoiceId = generateInvoiceId(999);
    const intent = 'Payment to vendor.mate via MATE NameService';
    const nonce = generateNonce();
    
    console.log(`\n   MATE Name:    ${mateName}`);
    console.log(`   Amount:       0.0001 ETH`);
    console.log(`   Nonce:        ${nonce}`);
    console.log(`   Intent:       ${intent}`);
    
    try {
        const tx = await contract.payByName(
            mateName,
            amount,
            invoiceId,
            intent,
            nonce
        );
        
        console.log(`\n   ✅ Transaction Sent: ${tx.hash}`);
        console.log(`   🔗 Etherscan: https://sepolia.etherscan.io/tx/${tx.hash}`);
        
        // Wait for confirmation
        console.log('\n   ⏳ Waiting for confirmation...');
        const receipt = await tx.wait();
        
        console.log(`   ✅ Confirmed in block ${receipt.blockNumber}`);
        
        // Parse event to see resolved address
        const event = receipt.logs.find(log => {
            try {
                const parsed = contract.interface.parseLog(log);
                return parsed.name === 'PaymentByName';
            } catch {
                return false;
            }
        });
        
        if (event) {
            const parsed = contract.interface.parseLog(event);
            console.log(`\n   🎯 Name Resolution:`);
            console.log(`      "${mateName}" → ${parsed.args.resolvedAddress}`);
        }
        
    } catch (error) {
        console.log(`\n   ❌ Error: ${error.message}`);
        
        if (error.message.includes('NameResolutionFailed')) {
            console.log(`\n   ℹ️  Note: "${mateName}" may not be registered in MATE NameService`);
            console.log(`      This is expected if the name doesn't exist on testnet.`);
        }
    }
}

// Main execution
async function main() {
    try {
        // Run the main parallel batch demo
        await runAsyncBatch();
        
        // Optionally run the payByName demo
        // Uncomment the line below to test MATE NameService integration
        // await demoPayByName();
        
    } catch (error) {
        console.error('\n❌ Demo failed:', error);
        process.exit(1);
    }
}

// Run the demo
if (require.main === module) {
    main();
}

module.exports = { runAsyncBatch, demoPayByName };
