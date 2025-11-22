# ReageCFO Setup Guide

This guide will help you clone, deploy, and run the ReageCFO system from scratch.

## Prerequisites

Before you begin, ensure you have:

- **Node.js 18+** installed
- **Foundry** installed (`curl -L https://foundry.paradigm.xyz | bash && foundryup`)
- **Git** installed
- **Coinbase Cloud API credentials** ([Get them here](https://portal.cdp.coinbase.com/))
- **Testnet ETH** on Sepolia and Base Sepolia

## Step 1: Clone the Repository

```bash
git clone https://github.com/ReageMeuFilho/ReageCFO.git
cd ReageCFO
```

## Step 2: Install Dependencies

### Smart Contracts

```bash
cd contracts
forge install
```

### AI Agent

```bash
cd ../agent
npm install
```

## Step 3: Set Up Environment Variables

### For the AI Agent

Create a `.env` file in the `agent/` directory:

```bash
cd agent
cp .env.example .env
```

Edit `.env` with your values:

```env
# Coinbase CDP API Credentials
CDP_API_KEY_NAME=your-api-key-name-here
CDP_API_KEY_PRIVATE_KEY=your-private-key-here

# Network Configuration
RPC_URL=https://ethereum-sepolia-rpc.publicnode.com
CHAIN_ID=11155111

# Deployed Contract Addresses
CONTRACT_ADDRESS=0xEDC4e211FE792f9B76605850567DD8b98A67A7E4

# Pyth Configuration
PYTH_HERMES_API=https://hermes.pyth.network
ETH_USD_PRICE_ID=0xff61491a931112ddf1bd8147cd1b641375f79f5825126d665480874634fd0ace
```

### For Smart Contracts (if deploying yourself)

Create a `.env` file in the `contracts/` directory:

```bash
cd ../contracts
cp .env.example .env
```

Edit `.env` with your values:

```env
PRIVATE_KEY=your-deployer-private-key-here
SEPOLIA_RPC_URL=https://ethereum-sepolia-rpc.publicnode.com
BASE_SEPOLIA_RPC_URL=https://sepolia.base.org
ETHERSCAN_API_KEY=your-etherscan-api-key
BASESCAN_API_KEY=your-basescan-api-key
```

## Step 4: Create a CDP Wallet for the AI Agent

The AI agent needs its own wallet to sign transactions autonomously.

```bash
cd agent
node createWallet.js
```

This will:
1. Create a new CDP Server Wallet
2. Save the wallet data to `agent-wallet.json`
3. Display the wallet address

**Important**: Fund this wallet with testnet ETH on Sepolia!

Get testnet ETH from:
- Sepolia: https://sepoliafaucet.com/
- Base Sepolia: https://www.coinbase.com/faucets/base-ethereum-sepolia-faucet

## Step 5: Run the Demo

### Option A: Use Pre-Deployed Contracts (Recommended)

The contracts are already deployed and configured:

- **ApertureServiceV2 (Sepolia)**: `0xEDC4e211FE792f9B76605850567DD8b98A67A7E4`
- **VendorVault (Base Sepolia)**: `0x23742F2F911Ed434081177e5aA9DB6a5684ba0dC`

Run the autonomous payment demo:

```bash
cd agent
node cdpAutonomousPayment.js
```

This will:
1. Connect to the deployed contracts
2. Use the CDP wallet to sign a transaction
3. Send a cross-chain payment from Sepolia to Base Sepolia
4. Display the transaction links

### Option B: Deploy Your Own Contracts

If you want to deploy your own instance:

```bash
cd contracts

# Deploy to Sepolia
forge script script/DeployAperture.s.sol:DeployAperture \
  --rpc-url $SEPOLIA_RPC_URL \
  --broadcast \
  --verify

# Deploy to Base Sepolia
forge script script/DeployAperture.s.sol:DeployAperture \
  --rpc-url $BASE_SEPOLIA_RPC_URL \
  --broadcast \
  --verify
```

Then configure the LayerZero peers:

```bash
# Set peer on Sepolia (pointing to Base)
cast send <SEPOLIA_CONTRACT> \
  "setPeer(uint32,bytes32)" \
  40245 \
  <BASE_CONTRACT_BYTES32> \
  --rpc-url $SEPOLIA_RPC_URL \
  --private-key $PRIVATE_KEY

# Set peer on Base (pointing to Sepolia)
cast send <BASE_CONTRACT> \
  "setPeer(uint32,bytes32)" \
  40161 \
  <SEPOLIA_CONTRACT_BYTES32> \
  --rpc-url $BASE_SEPOLIA_RPC_URL \
  --private-key $PRIVATE_KEY
```

## Step 6: Verify the Transaction

After running the demo, you'll see output like:

```
✅ Transaction sent!
   TX Hash: 0x14288f7c...
   Explorer: https://sepolia.etherscan.io/tx/0x14288f7c...
   LayerZero Scan: https://testnet.layerzeroscan.com/tx/0x14288f7c...
```

Visit the LayerZero Scan link to watch the cross-chain message delivery in real-time!

## Troubleshooting

### "Insufficient funds" error

Make sure your CDP wallet has testnet ETH on Sepolia. You need at least 0.01 ETH to cover gas fees and LayerZero fees.

### "Agent not authorized" error

The deployed contracts are configured for a specific CDP wallet. If you want to use your own wallet, you'll need to deploy your own contracts and set your wallet as the authorized agent.

### "Cannot find module" error

Make sure you ran `npm install` in the `agent/` directory.

### LayerZero message not delivering

This is normal - cross-chain messages can take 1-2 minutes to deliver. Check the LayerZero Scan link to monitor progress.

## Next Steps

Once you have the demo working, try:

1. **Modify the payment amount** in `cdpAutonomousPayment.js`
2. **Add your own invoice processing logic** in `agent.js`
3. **Integrate with real Pyth price feeds** for production use
4. **Build a frontend** to visualize agent decisions

## Support

For questions or issues:
- Check the [documentation](docs/)
- Review the [commit history](https://github.com/ReageMeuFilho/ReageCFO/commits/main)
- Open an issue on GitHub

## Deployed Contract Addresses

### Sepolia (Ethereum Testnet)
- **ApertureServiceV2**: `0xEDC4e211FE792f9B76605850567DD8b98A67A7E4`
- **Etherscan**: https://sepolia.etherscan.io/address/0xEDC4e211FE792f9B76605850567DD8b98A67A7E4

### Base Sepolia
- **VendorVault**: `0x23742F2F911Ed434081177e5aA9DB6a5684ba0dC`
- **Basescan**: https://sepolia.basescan.org/address/0x23742F2F911Ed434081177e5aA9DB6a5684ba0dC

### LayerZero Configuration
- **Sepolia Endpoint ID**: 40161
- **Base Sepolia Endpoint ID**: 40245
- **Peers**: Configured and verified ✅

## Live Demo Transaction

See a working example:
- **Sepolia TX**: https://sepolia.etherscan.io/tx/0x14288f7c7b2bed216e33ae2dd331e2c50581391060282770f637ae20c47e5c67
- **LayerZero Scan**: https://testnet.layerzeroscan.com/tx/0x14288f7c7b2bed216e33ae2dd331e2c50581391060282770f637ae20c47e5c67
- **Status**: DELIVERED ✅
