
# ReageCFO - AI-First Hybrid Ledger

**ETHGlobal Buenos Aires Hackathon Submission**

An autonomous financial agent with real-time market awareness and cross-chain settlement capabilities.

---

## 🎯 Project Vision

Traditional accounting systems are passive databases that blindly execute commands. **ReageCFO (Aperture)** is different - it's an intelligent, autonomous financial agent that:

- **Sees** market conditions through Pyth Network price feeds
- **Thinks** using AI-powered decision making via Coinbase CDP
- **Records** immutably on a sovereign EVVM blockchain
- **Executes** across any chain via LayerZero

This is the world's first **market-aware, AI-controlled, cross-chain accounting system**.

---

## 🚀 Quick Start & Demo

This guide provides everything you need to clone, set up, and run the complete end-to-end demo.

### Prerequisites

- Node.js 18+
- Foundry (for smart contract development)
- Git

### Step 1: Clone the Repository

```bash
# Clone the repository
git clone https://github.com/ReageMeuFilho/ReageCFO.git
cd ReageCFO
```

### Step 2: Install Dependencies

This project has two main parts: the smart contracts and the AI agent. You'll need to install dependencies for both.

```bash
# Install contract dependencies
cd contracts
npm install
forge install

# Install agent dependencies
cd ../agent
npm install
```

### Step 3: Set Up Environment Variables

You'll need to create a `.env` file in the `agent/` directory. This file will store your private keys and RPC URLs.

```bash
# Navigate to the agent directory
cd agent

# Create a .env file from the example
cp .env.example .env
```

Now, open the `.env` file and add the following:

```
# Your Sepolia RPC URL (e.g., from Alchemy or Infura)
RPC_URL="https://ethereum-sepolia-rpc.publicnode.com"

# The private key for your Coinbase CDP Server Wallet
# This is derived from the agent-wallet.json file
CDP_WALLET_PRIVATE_KEY="0x745bfc7d832eccd3628ce30a6c921068206504d6135dfba849c118f23f3184c4"
```

**Note:** The private key provided is for the demo wallet. For production, you would generate your own.

### Step 4: Run the End-to-End Demo

Now you're ready to run the complete demo! The `processInvoiceDetailed.js` script will:

1. Create a new mock invoice
2. Fetch the real-time ETH/USD price from Pyth Network
3. Use the AI agent (CDP wallet) to analyze the price and make a payment decision
4. Execute a cross-chain payment from Sepolia to Base Sepolia via LayerZero

```bash
# Run the detailed demo script
node processInvoiceDetailed.js
```

### What to Expect

You will see a detailed, step-by-step output in your terminal showing:

- ✅ **Pyth Price**: The actual ETH/USD price fetched from Hermes.
- ✅ **AI Decision**: The agent's logic for approving the payment based on the price.
- ✅ **CDP Wallet Signing**: Confirmation that the transaction was signed by the AI agent.
- ✅ **LayerZero Message**: The transaction hash and a link to track the cross-chain message.

**Example Output:**

```
┌─────────────────────────────────────────────────┐
│  ETH/USD PRICE (Pyth Network)                   │
├─────────────────────────────────────────────────┤
│  Price:      $  2751.68                         │
│  Confidence: ±$     0.56                        │
│  Updated:    2025-11-22T18:56:17.000Z           │
└─────────────────────────────────────────────────┘

🤖 STEP 4: AI Agent Makes Payment Decision
────────────────────────────────────────────────────────────────────────────────
   AI Agent analyzing invoice with market data...
   📊 Market Analysis:
      • Current ETH Price: $2751.68
      • Payment Amount: 0.0003 ETH
      • Payment Value (USD): $0.83

   🔍 Decision Criteria:
      • ETH price > $2000: ✓ ($2751.68)

   ✅ DECISION: APPROVE PAYMENT
```

### Step 5: Verify on Blockchain Explorers

After the script runs, you can use the provided links to see the transaction live on the blockchain:

- **Sepolia Etherscan**: To see the source transaction.
- **LayerZero Scan**: To track the cross-chain message delivery.
- **Base Sepolia Basescan**: To see the funds arrive in the vault.

---

## 🏗️ Architecture: "Heart, Brain, Hands"

```
┌─────────────────────────────────────────────────────────────────┐
│                         THE BRAIN                                │
│                  (Coinbase CDP AI Agent)                         │
│                                                                  │
│  • Autonomous decision making                                   │
│  • Server Wallet for signing                                    │
│  • Natural language processing                                  │
└──────────────────────┬───────────────────────────────────────────┘
                       │
                       ▼
┌─────────────────────────────────────────────────────────────────┐
│                         THE HEART                                │
│              (ApertureServiceV3 on Sepolia)                      │
│                                                                  │
│  • Double-entry accounting enforcement                          │
│  • Pyth price validation                                        │
│  • EVVM sovereign ledger backend                                │
│  • LayerZero cross-chain messaging                              │
└──────────────────────┬───────────────────────────────────────────┘
                       │
                       ▼
┌─────────────────────────────────────────────────────────────────┐
│                         THE HANDS                                │
│                (ApertureVault on Base Sepolia)                   │
│                                                                  │
│  • Holds real funds                                             │
│  • Receives LayerZero messages                                  │
│  • Executes settlement                                          │
└─────────────────────────────────────────────────────────────────┘
```

---

## 📊 Technical Implementation

### Smart Contracts

| Contract | Network | Address | Purpose |
|:---|:---|:---|:---|
| **ApertureServiceV2** | Ethereum Sepolia | `0xEDC4e211FE792f9B76605850567DD8b98A67A7E4` | Main ledger with Pyth integration |
| **ApertureVault** | Base Sepolia | `0x23742F2F911Ed434081177e5aA9DB6a5684ba0dC` | Settlement layer |

### AI Agent

| Component | Details |
|:---|:---|
| **Wallet Address** | `0xBCD8c885E3bc0F87940eAdA431e14cA9F3Fc98E0` |
| **Wallet Type** | Coinbase CDP Server Wallet |

### Integrations

| Partner | Integration | Status |
|:---|:---|:---:|
| **EVVM** | MATE Metaprotocol (ID: 2) | ✅ |
| **Pyth Network** | Real-time price feeds | ✅ |
| **LayerZero** | Cross-chain messaging | ✅ |
| **Coinbase CDP** | AI agent identity | ✅ |

---

## 📁 Repository Structure

```
ReageCFO/
├── contracts/          # Smart contracts (Solidity)
├── agent/              # AI Agent (Node.js)
└── docs/               # Documentation
```

---

## 👥 Team

**ReageMeuFilho** - Solo developer

Built for ETHGlobal Buenos Aires, November 2025.

---

## 📄 License

MIT License - Built for educational and hackathon purposes.
