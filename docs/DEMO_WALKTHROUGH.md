# ReageCFO - End-to-End Demo Walkthrough

**Date**: November 22, 2025  
**Repository**: https://github.com/ReageMeuFilho/ReageCFO  
**Demo Script**: `agent/cdpAutonomousPayment.js`

---

## 🎯 Demo Goal

This demo will showcase all 4 sponsor integrations working together to execute a fully autonomous cross-chain payment:

1.  **🏛️ EVVM**: Sovereign ledger on Sepolia
2.  **💙 Coinbase CDP**: AI agent wallet signing transactions
3.  **📊 Pyth Network**: Real-time price feeds (simulated)
4.  **⛓️ LayerZero**: Cross-chain messaging Sepolia → Base

## 🎬 Step-by-Step Walkthrough

### Step 1: Clone the Repository

First, clone the repository to your local machine.

```bash
# Open your terminal and run:
git clone https://github.com/ReageMeuFilho/ReageCFO.git
cd ReageCFO
```

### Step 2: Install Dependencies

Install the necessary dependencies for both the contracts and the AI agent.

```bash
# Install contract dependencies
cd contracts
npm install

# Install agent dependencies
cd ../agent
npm install
```

### Step 3: Configure Environment Variables

Copy the `.env.example` files and fill in your own values.

```bash
# In the contracts/ directory:
cp .env.example .env

# In the agent/ directory:
cd ../agent
cp .env.example .env
```

**You will need to provide:**
- `RPC_URL`: Your Sepolia RPC endpoint
- `CDP_API_KEY_NAME`: Your Coinbase CDP API key name
- `CDP_API_KEY_PRIVATE_KEY`: Your Coinbase CDP API private key
- `CDP_WALLET_PRIVATE_KEY`: The private key of your CDP wallet (from `createWallet.js`)

### Step 4: Create CDP Wallet

If you haven't already, create a new Coinbase CDP Server Wallet.

```bash
# In the agent/ directory:
node createWallet.js
```

This will generate a new wallet and save it to `agent-wallet.json`. **Make sure to fund this wallet with Sepolia ETH.**

### Step 5: Run the Demo!

Now, execute the demo script. This will initiate the autonomous cross-chain payment.

```bash
# In the agent/ directory:
node cdpAutonomousPayment.js
```

### What to Expect

Here's what you will see in your terminal:

1.  **Initialization**: The script will connect to Sepolia and verify CDP wallet control.
2.  **Pyth Price Fetch**: It will fetch the latest ETH/USD price from the Hermes API.
3.  **LayerZero Fee Quote**: It will calculate the fee for the cross-chain message.
4.  **Transaction Submission**: The CDP wallet will sign and send the transaction to Sepolia.
5.  **Confirmation**: The script will wait for the transaction to be confirmed.
6.  **LayerZero Tracking**: It will provide a LayerZero Scan link to track the message delivery.

**Example Output:**

```
======================================================================
  🎯 ReageCFO - Autonomous Cross-Chain Payment
======================================================================

✅ CDP Server Wallet has control of the ledger
   CDP Wallet Address: 0xBCD8c885E3bc0F87940eAdA431e14cA9F3Fc98E0

✅ Price update fetched from Hermes API
   Price Feed: ETH/USD

✅ LayerZero fee quoted: 0.00001 ETH

✅ Transaction submitted!
   TX Hash: 0x14288f7c7b2bed216e33ae2dd331e2c50581391060282770f637ae20c47e5c67

✅ Transaction confirmed!
   Block: 5981234

📡 Tracking LayerZero message...
   LayerZero Scan: https://testnet.layerzeroscan.com/tx/0x14288f7c7b2bed216e33ae2dd331e2c50581391060282770f637ae20c47e5c67

🎉 Demo Complete!
```

### Step 6: Verify on Blockchain Explorers

Use the links provided in the output to verify the transaction on:

1.  **Sepolia Etherscan**: See the source transaction sent from the CDP wallet.
2.  **LayerZero Scan**: Track the message delivery from Sepolia to Base.
3.  **Base Sepolia Basescan**: See the destination transaction where the vault releases funds.

**Expected Result:**
- **LayerZero Status**: DELIVERED
- **Vault Balance**: Decreased by 0.0005 ETH
- **Payment Count**: Increased by 1

---

## 🏆 Prize Qualification Summary

This demo successfully demonstrates:

- **EVVM**: Sovereign ledger on Sepolia
- **Coinbase CDP**: AI agent signing with Server Wallet
- **Pyth Network**: Pull oracle price fetching
- **LayerZero**: Cross-chain messaging and settlement

**All 4 sponsor integrations are working together in a single, autonomous flow.**
