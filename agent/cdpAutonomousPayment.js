require('dotenv').config();
const { ethers } = require("ethers");

// Contract ABIs
const APERTURE_SERVICE_ABI = [
    "function sendCrossChainPayment(uint32 _dstEid, address recipient, uint256 amount, bytes32 invoiceId, string memory intent) external payable returns (bytes32 guid)",
    "function quoteCrossChainPayment(uint32 _dstEid, address recipient, uint256 amount, bytes32 invoiceId, string calldata intent) external view returns (tuple(uint256 nativeFee, uint256 lzTokenFee) fee)",
    "function agentWallet() external view returns (address)"
];

async function main() {
    console.log("╔══════════════════════════════════════════════════════════════╗");
    console.log("║  CDP-POWERED AUTONOMOUS CROSS-CHAIN PAYMENT                 ║");
    console.log("║  ReageCFO AI Agent Using Coinbase CDP Server Wallet         ║");
    console.log("╚══════════════════════════════════════════════════════════════╝\n");

    // Setup provider and CDP wallet
    const provider = new ethers.JsonRpcProvider(process.env.RPC_URL);
    const cdpWallet = new ethers.Wallet(process.env.CDP_WALLET_PRIVATE_KEY, provider);
    
    console.log("🤖 AI AGENT WALLET (CDP):");
    console.log(`   Address: ${cdpWallet.address}`);
    console.log(`   Balance: ${ethers.formatEther(await provider.getBalance(cdpWallet.address))} ETH\n`);

    // Connect to contract
    const contractAddress = "0xEDC4e211FE792f9B76605850567DD8b98A67A7E4"; // New ApertureServiceV2
    const contract = new ethers.Contract(contractAddress, APERTURE_SERVICE_ABI, cdpWallet);

    // Verify agent authorization
    const authorizedAgent = await contract.agentWallet();
    console.log("🔐 CONTRACT AUTHORIZATION:");
    console.log(`   Authorized Agent: ${authorizedAgent}`);
    console.log(`   CDP Wallet: ${cdpWallet.address}`);
    console.log(`   Match: ${authorizedAgent.toLowerCase() === cdpWallet.address.toLowerCase() ? '✅ AUTHORIZED' : '❌ NOT AUTHORIZED'}\n`);

    if (authorizedAgent.toLowerCase() !== cdpWallet.address.toLowerCase()) {
        console.log("❌ CDP wallet is not authorized! Exiting...");
        return;
    }

    // Payment details (simulating AI agent decision)
    const recipient = "0x5555555555555555555555555555555555555555";
    const amount = ethers.parseEther("0.0005"); // 0.0005 ETH
    const invoiceId = ethers.id("CDP-AUTO-PAYMENT-001");
    const description = "Autonomous payment via CDP AI Agent";

    console.log("💼 PAYMENT DETAILS (AI Agent Decision):");
    console.log(`   Recipient: ${recipient}`);
    console.log(`   Amount: ${ethers.formatEther(amount)} ETH`);
    console.log(`   Invoice ID: ${invoiceId}`);
    console.log(`   Description: ${description}\n`);

    // Quote LayerZero fee
    const dstEid = 40245; // Base Sepolia endpoint ID
    console.log("💰 Quoting LayerZero fee...");
    const feeQuote = await contract.quoteCrossChainPayment(dstEid, recipient, amount, invoiceId, description);
    const fee = feeQuote.nativeFee;
    console.log(`   LayerZero Fee: ${ethers.formatEther(fee)} ETH\n`);

    // Send cross-chain payment using CDP wallet
    console.log("🚀 SENDING CROSS-CHAIN PAYMENT (CDP WALLET SIGNING)...");
    console.log("   This transaction is signed by the CDP Server Wallet");
    console.log("   Demonstrating autonomous AI agent operation\n");

    try {
        const tx = await contract.sendCrossChainPayment(
            dstEid,
            recipient,
            amount,
            invoiceId,
            description,
            { value: fee }
        );

        console.log("✅ Transaction sent!");
        console.log(`   TX Hash: ${tx.hash}`);
        console.log(`   Explorer: https://sepolia.etherscan.io/tx/${tx.hash}`);
        console.log(`   LayerZero Scan: https://testnet.layerzeroscan.com/tx/${tx.hash}\n`);

        console.log("⏳ Waiting for confirmation...");
        const receipt = await tx.wait();
        console.log(`✅ Confirmed in block ${receipt.blockNumber}\n`);

        console.log("╔══════════════════════════════════════════════════════════════╗");
        console.log("║  ✅ SUCCESS! CDP AI AGENT SENT CROSS-CHAIN PAYMENT          ║");
        console.log("╚══════════════════════════════════════════════════════════════╝\n");

        console.log("🎉 CDP INTEGRATION PROOF:");
        console.log("   ✅ CDP Server Wallet created and funded");
        console.log("   ✅ AI Agent authorized in smart contract");
        console.log("   ✅ CDP wallet signed and sent transaction");
        console.log("   ✅ Cross-chain payment initiated autonomously");
        console.log("   ✅ LayerZero message sent to Base Sepolia\n");

        console.log("📊 WAIT 60-90 SECONDS FOR CROSS-CHAIN DELIVERY");
        console.log(`   Track at: https://testnet.layerzeroscan.com/tx/${tx.hash}\n`);

    } catch (error) {
        console.error("❌ Transaction failed:", error.message);
        if (error.data) {
            console.error("Error data:", error.data);
        }
    }
}

main().catch(console.error);
