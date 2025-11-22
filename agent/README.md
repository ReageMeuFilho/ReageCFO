# Aperture AI Agent - The Autonomous CFO

**Phase II Implementation for ETHGlobal Buenos Aires Hackathon**

An autonomous AI agent powered by Coinbase CDP Server Wallets that controls a sovereign ledger with real-time market awareness through Pyth Network price feeds.

---

## 🎯 What This Agent Does

The Aperture AI Agent is an autonomous financial decision-maker that:

1. **Controls a Sovereign Ledger:** Has exclusive authority over the `ApertureServiceV2` smart contract deployed on Ethereum Sepolia
2. **Fetches Real-Time Market Data:** Queries Pyth Network's Hermes API for up-to-the-second price feeds
3. **Makes Intelligent Decisions:** Validates transactions against market conditions before execution
4. **Enforces Double-Entry Accounting:** Ensures all transactions balance (debits = credits)
5. **Prevents Fraud:** Validates price thresholds and detects stale data to protect against manipulation

---

## 🏗️ Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                    Aperture AI Agent                         │
│                  (Coinbase CDP Wallet)                       │
│                                                              │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐     │
│  │  Decision    │  │    Pyth      │  │   Contract   │     │
│  │   Engine     │──│   Oracle     │──│  Interaction │     │
│  └──────────────┘  └──────────────┘  └──────────────┘     │
└─────────────────────────────────────────────────────────────┘
                            │
                            ▼
        ┌───────────────────────────────────────┐
        │   ApertureServiceV2 Smart Contract    │
        │   (Ethereum Sepolia)                  │
        │                                       │
        │   - Double-Entry Ledger               │
        │   - Pyth Price Validation             │
        │   - LayerZero Cross-Chain             │
        │   - EVVM Integration                  │
        └───────────────────────────────────────┘
```

---

## 🚀 Setup & Installation

### Prerequisites

- Node.js 18+ and npm
- Coinbase Cloud API credentials
- Ethereum Sepolia testnet access

### Installation

```bash
# 1. Install dependencies
npm install

# 2. Configure environment variables
cp .env.example .env
# Edit .env with your credentials

# 3. Create the agent wallet (first time only)
node createWallet.js

# 4. Run the agent demo
node agent.js
```

---

## 🔑 Environment Variables

```env
# Coinbase CDP API Credentials
CDP_API_KEY_NAME=your-api-key-name
CDP_API_KEY_PRIVATE_KEY=your-private-key

# Deployed Contract Information
APERTURE_CONTRACT_ADDRESS=0x741d5a695367Fb7e00A24c8AFb2bc4C0BbC66e9D
AGENT_WALLET_ADDRESS=0xBCD8c885E3bc0F87940eAdA431e14cA9F3Fc98E0

# Network Configuration
RPC_URL=https://ethereum-sepolia-rpc.publicnode.com
CHAIN_ID=11155111

# Pyth Configuration
PYTH_HERMES_API=https://hermes.pyth.network
ETH_USD_PRICE_ID=0xff61491a931112ddf1bd8147cd1b641375f79f5825126d665480874634fd0ace
```

---

## 📊 Key Features

### 1. CDP Server Wallet Integration

The agent uses **Coinbase CDP Server Wallets** to maintain a secure, non-custodial identity on-chain. This wallet:

- Is created programmatically via the CDP SDK
- Holds the private keys securely in Coinbase's infrastructure
- Can sign and broadcast transactions autonomously
- Has exclusive control over the `ApertureServiceV2` contract

### 2. Pyth Network Price Feeds

Before executing any transaction, the agent:

- Queries the Pyth Hermes API for the latest price update
- Receives a Verifiable Action Approval (VAA) with cryptographic proof
- Passes this data to the smart contract for on-chain validation
- The contract verifies the price is recent and within acceptable thresholds

### 3. Intelligent Decision Making

The agent's workflow:

```
1. Receive payment request (invoice)
   ↓
2. Fetch Pyth price update for relevant asset
   ↓
3. Validate double-entry balance (debits = credits)
   ↓
4. Prepare transaction with Pyth proof
   ↓
5. Sign with CDP Server Wallet
   ↓
6. Submit to smart contract
   ↓
7. Contract validates price and executes
```

If the price is stale or below the configured threshold, the contract **reverts the transaction**, protecting the organization from executing payments during unfavorable market conditions.

---

## 🎬 Demo Scenario

The included demo (`node agent.js`) shows:

**Invoice 1: Normal Payment**
- Amount: 0.1 ETH
- Description: "Payment for consulting services"
- Result: ✅ Transaction prepared with valid Pyth price data

**Invoice 2: Large Purchase**
- Amount: 0.5 ETH
- Description: "Large equipment purchase"
- Result: ✅ Transaction prepared with price validation

In a production environment with funded wallets, the agent would:
- Successfully execute Invoice 1 (price is acceptable)
- Intelligently reject Invoice 2 if the market price falls below the threshold

---

## 🏆 Hackathon Prize Tracks

This implementation qualifies for:

### Coinbase CDP ($5,000)
- ✅ **CDP Server Wallets:** Core identity and signing mechanism
- ✅ **Multiple CDP Products:** Potential for CDP Data API integration
- ✅ **Product Quality:** Fully functional, non-trivial use case
- ✅ **Developer Feedback:** Documented experience (see FEEDBACK.md)

### Additional Integrations
- ✅ **Pyth Network:** Real-time price feeds with on-chain verification
- ✅ **EVVM:** Sovereign ledger backend (MATE Metaprotocol)
- ✅ **LayerZero:** Cross-chain messaging capabilities

---

## 📁 Project Structure

```
aperture-agent/
├── agent.js              # Main agent logic
├── createWallet.js       # CDP wallet creation script
├── agent-wallet.json     # Wallet data (gitignored)
├── .env                  # Environment configuration
├── package.json          # Dependencies
└── README.md            # This file
```

---

## 🔗 Important Links

- **Smart Contract (Sepolia):** https://sepolia.etherscan.io/address/0x741d5a695367Fb7e00A24c8AFb2bc4C0BbC66e9D
- **Agent Wallet:** `0xBCD8c885E3bc0F87940eAdA431e14cA9F3Fc98E0`
- **Control Transfer TX:** https://sepolia.etherscan.io/tx/0xdb8b37d7c2b1cf929323e2c157657428c042e1b96f33f6682ef0e6963693dba3

---

## 🎓 What We Learned

### What Worked Well

1. **CDP SDK is Developer-Friendly:** The wallet creation and management API is intuitive and well-documented
2. **Pyth Integration is Seamless:** The Hermes API provides reliable, low-latency price data
3. **Smart Contract Composability:** EVVM, Pyth, and LayerZero integrate cleanly

### Areas for Improvement

1. **CDP Documentation:** More examples for Server Wallet transaction signing would be helpful
2. **Testnet Faucets:** Base Sepolia faucets are often rate-limited; better developer access would help
3. **Error Messages:** More descriptive error messages from the CDP SDK would speed up debugging

---

## 🚀 Future Enhancements

- **AI-Powered Decision Engine:** Integrate OpenAI or Anthropic for natural language invoice processing
- **Multi-Chain Support:** Expand to Base, Optimism, and Arbitrum via LayerZero
- **Dashboard UI:** Build a React frontend to visualize agent decisions in real-time
- **Advanced Risk Management:** Implement portfolio rebalancing and liquidity monitoring

---

## 👥 Team

Built for **ETHGlobal Buenos Aires** by the ReageCFO team.

**Contact:** @ReageMeuFilho on X

---

## 📄 License

MIT License - Built for educational and hackathon purposes.

---

**Status:** ✅ Phase II Complete - Ready for Submission

**Demo Video:** Coming soon!
