# ReageCFO Local Setup Guide

## Part 1: Clean Up Git Branches (Do This First)

### Problem
You have two branches: `master` and `main`. GitHub best practice is to use `main` as the default branch.

### Solution: Make `main` the only branch

**Step 1: Check which branch GitHub uses as default**
1. Go to: https://github.com/ReageMeuFilho/ReageCFO/settings/branches
2. Check which branch is set as "Default branch"
3. If it's not `main`, change it to `main` and click "Update"

**Step 2: Delete the `master` branch (if it exists)**

On your local machine (or in this sandbox), run:

```bash
cd /home/ubuntu/aperture-ledger

# Make sure you're on main
git checkout main

# Pull latest changes
git pull origin main

# Delete local master branch (if it exists)
git branch -D master

# Delete remote master branch
git push origin --delete master
```

**Done!** Now you only have `main` as your branch.

---

## Part 2: Cursor Prompt for Local Setup

### Copy this entire prompt and paste it into Cursor:

```
I need to set up the ReageCFO project locally on my machine so I can run the live demos for my ETHGlobal hackathon presentation.

PROJECT CONTEXT:
- Repo: https://github.com/ReageMeuFilho/ReageCFO
- Branch: main (only branch)
- This is an AI-powered treasury management system
- Uses Node.js for the agent, Solidity for contracts
- Connects to Sepolia and Base Sepolia testnets (no local blockchain needed)

WHAT I NEED:
1. Clone the repo to my local machine
2. Install all dependencies (Node.js packages)
3. Set up the .env file with my environment variables
4. Test that I can run the live demo scripts

SPECIFIC REQUIREMENTS:
- Node.js version: 22.13.0 (or compatible)
- Package manager: pnpm (preferred) or npm
- Main demo script: agent/live_v2_demo.js
- Secondary demo script: agent/live_v3_demo.js

ENVIRONMENT VARIABLES NEEDED:
The project uses a .env file in the agent/ directory with these variables:
- CDP_WALLET_PRIVATE_KEY (Coinbase CDP Server Wallet key)
- OPENAI_API_KEY (for AI agent)
- Various RPC URLs (Sepolia, Base Sepolia)

EXPECTED OUTCOME:
I should be able to run:
```bash
cd agent
node live_v2_demo.js
```

And see the live demo execute, connecting to Sepolia testnet and processing a cross-chain payment.

IMPORTANT NOTES:
- All contracts are already deployed on testnets
- I don't need to deploy anything
- I just need to run the agent scripts that interact with existing contracts
- The .env file should be in agent/.env (not root)

Please guide me through:
1. Cloning the repo
2. Installing dependencies
3. Setting up .env (I'll provide the actual keys)
4. Running the demo scripts
5. Troubleshooting common issues

Let's start with step 1: cloning the repo.
```

---

## Part 3: Manual Setup Instructions (If Cursor Doesn't Work)

### Step 1: Clone the Repository

```bash
# On your local machine, open terminal and run:
git clone https://github.com/ReageMeuFilho/ReageCFO.git
cd ReageCFO
```

### Step 2: Install Node.js Dependencies

```bash
# Navigate to the agent directory
cd agent

# Install dependencies using pnpm (recommended)
pnpm install

# OR using npm
npm install
```

### Step 3: Set Up Environment Variables

Create a `.env` file in the `agent/` directory:

```bash
# Create the .env file
touch .env

# Open it in your editor
# Copy the contents from the sandbox .env file
```

**Required variables:**
```env
CDP_WALLET_PRIVATE_KEY=your_cdp_wallet_private_key_here
OPENAI_API_KEY=your_openai_key_here

# RPC URLs (these are public, no need to change)
SEPOLIA_RPC_URL=https://ethereum-sepolia-rpc.publicnode.com
BASE_SEPOLIA_RPC_URL=https://sepolia.base.org
```

### Step 4: Get Your Environment Variables

**From the sandbox, run:**

```bash
# Show the .env file contents (with keys)
cat /home/ubuntu/aperture-ledger/agent/.env
```

**Copy those values** to your local `.env` file.

### Step 5: Test the Setup

```bash
# Make sure you're in the agent directory
cd agent

# Run the V2 demo
node live_v2_demo.js
```

**Expected output:**
- Demo starts
- Fetches Pyth price
- CDP wallet signs
- Transaction sent to Sepolia
- TX hash displayed

### Step 6: Verify It Works

If you see:
```
✅ TRANSACTION SENT!
   TX Hash: 0x...
```

**You're good to go!** ✅

---

## Part 4: Troubleshooting

### Issue: "Module not found"

**Solution:**
```bash
cd agent
pnpm install
# or
npm install
```

### Issue: "Cannot find .env file"

**Solution:**
Make sure `.env` is in the `agent/` directory, not the root:
```bash
ls agent/.env  # Should exist
```

### Issue: "Invalid private key"

**Solution:**
Check that your `CDP_WALLET_PRIVATE_KEY` in `.env` is correct:
- Should start with `0x`
- Should be 64 hex characters (+ 0x prefix)
- No spaces or quotes

### Issue: "RPC connection failed"

**Solution:**
Check your internet connection and RPC URLs in `.env`:
```env
SEPOLIA_RPC_URL=https://ethereum-sepolia-rpc.publicnode.com
BASE_SEPOLIA_RPC_URL=https://sepolia.base.org
```

### Issue: "Transaction reverted"

**Solution:**
- Check that CDP wallet has enough ETH on Sepolia
- Check balance:
```bash
cast balance 0xBCD8c885E3bc0F87940eAdA431e14cA9F3Fc98E0 --rpc-url https://ethereum-sepolia-rpc.publicnode.com
```

---

## Part 5: What You DON'T Need to Do

❌ **Don't deploy contracts** - They're already deployed on testnets
❌ **Don't run a local blockchain** - Everything connects to Sepolia/Base
❌ **Don't install Foundry** - Only needed for contract development
❌ **Don't set up a database** - Everything is on-chain

✅ **You only need:**
- Node.js
- pnpm/npm
- The agent scripts
- A .env file with keys

---

## Part 6: Quick Reference

### Key Files
```
ReageCFO/
├── agent/
│   ├── .env                    # Your environment variables
│   ├── live_v2_demo.js         # Main demo script
│   ├── live_v3_demo.js         # Parallel execution demo
│   └── package.json            # Dependencies
├── contracts/                  # Smart contracts (already deployed)
└── docs/                       # Documentation
```

### Key Commands
```bash
# Install dependencies
cd agent && pnpm install

# Run V2 demo
node live_v2_demo.js

# Run V3 demo
node live_v3_demo.js

# Check CDP wallet balance
cast balance 0xBCD8c885E3bc0F87940eAdA431e14cA9F3Fc98E0 --rpc-url https://ethereum-sepolia-rpc.publicnode.com
```

### Key Contracts (Already Deployed)
- **V2 Ledger (Sepolia)**: `0xEDC4e211FE792f9B76605850567DD8b98A67A7E4`
- **V3 Ledger (Sepolia)**: `0xDfE96d2D70f5D1438Ef3593C977F0BfD13569d97`
- **Vault (Base Sepolia)**: `0x23742F2F911Ed434081177e5aA9DB6a5684ba0dC`
- **CDP Wallet**: `0xBCD8c885E3bc0F87940eAdA431e14cA9F3Fc98E0`

---

## Part 7: Presentation Setup

### Before Your Pitch

1. **Open Terminal** - Navigate to `agent/` directory
2. **Test Demo** - Run `node live_v2_demo.js` once to verify
3. **Open Browser Tabs** - Pre-load Etherscan, LayerZero Scan
4. **Check Balance** - Make sure CDP wallet has enough ETH

### During Your Pitch

1. **Run Demo Live** - Execute `node live_v2_demo.js`
2. **Narrate** - Explain what's happening as it runs
3. **Switch to Browser** - Show transaction on Etherscan when TX hash appears
4. **Show Proof** - Navigate to LayerZero Scan, show DELIVERED status

---

## Summary

**To run locally:**
1. Clone repo: `git clone https://github.com/ReageMeuFilho/ReageCFO.git`
2. Install deps: `cd agent && pnpm install`
3. Copy .env: Get keys from sandbox, create `agent/.env`
4. Run demo: `node live_v2_demo.js`

**To clean up branches:**
1. Set `main` as default on GitHub
2. Delete `master`: `git push origin --delete master`

**You're ready!** 🚀
