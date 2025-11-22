/**
 * Create CDP Server Wallet for the AI Agent
 * This wallet will be granted control over the ApertureServiceV2 contract
 */

require('dotenv').config();
const { Coinbase, Wallet } = require('@coinbase/coinbase-sdk');
const fs = require('fs');

async function createAgentWallet() {
    try {
        console.log('🚀 Initializing Coinbase CDP SDK...');
        
        // Configure CDP with API credentials
        Coinbase.configure({
            apiKeyName: process.env.CDP_API_KEY_NAME,
            privateKey: process.env.CDP_API_KEY_PRIVATE_KEY.replace(/\\n/g, '\n')
        });

        console.log('✅ CDP SDK configured successfully');
        console.log('');
        console.log('🔐 Creating Server Wallet for AI Agent...');
        
        // Create a new wallet on Base Sepolia network (lower gas costs than Ethereum Sepolia)
        const wallet = await Wallet.create({
            networkId: Coinbase.networks.BaseSepolia
        });

        console.log('✅ Server Wallet created successfully!');
        console.log('');
        console.log('=== AGENT WALLET INFORMATION ===');
        console.log('Wallet ID:', wallet.getId());
        
        // Get the default address
        const address = await wallet.getDefaultAddress();
        const addressId = address.getId();
        
        console.log('Agent Address:', addressId);
        console.log('Network:', 'Base Sepolia');
        console.log('');
        
        // Export wallet data for persistence
        const walletData = wallet.export();
        
        // Save wallet data to file
        const walletInfo = {
            walletId: wallet.getId(),
            address: addressId,
            network: 'base-sepolia',
            walletData: walletData,
            createdAt: new Date().toISOString()
        };
        
        fs.writeFileSync(
            'agent-wallet.json',
            JSON.stringify(walletInfo, null, 2)
        );
        
        // Also update the .env file with the agent address
        let envContent = fs.readFileSync('.env', 'utf8');
        if (!envContent.includes('AGENT_WALLET_ADDRESS')) {
            envContent += `\n# Agent Wallet (Created ${new Date().toISOString()})\nAGENT_WALLET_ADDRESS=${addressId}\n`;
            fs.writeFileSync('.env', envContent);
        }
        
        console.log('💾 Wallet data saved to agent-wallet.json');
        console.log('💾 Agent address added to .env');
        console.log('');
        console.log('=== NEXT STEPS ===');
        console.log('1. Fund this wallet with Base Sepolia ETH for gas');
        console.log('   Get testnet ETH: https://www.alchemy.com/faucets/base-sepolia');
        console.log('');
        console.log('2. Grant this address control of the ApertureServiceV2 contract');
        console.log('   Command:');
        console.log(`   cast send ${process.env.APERTURE_CONTRACT_ADDRESS} \\`);
        console.log(`     "updateAgentWallet(address)" ${addressId} \\`);
        console.log(`     --rpc-url ${process.env.RPC_URL} \\`);
        console.log(`     --private-key ${process.env.DEPLOYER_PRIVATE_KEY}`);
        console.log('');
        console.log('✅ Agent wallet creation complete!');
        
    } catch (error) {
        console.error('❌ Error creating wallet:', error.message);
        if (error.response) {
            console.error('API Response:', error.response.data);
        }
        console.error('Full error:', error);
        process.exit(1);
    }
}

// Run the script
createAgentWallet();
