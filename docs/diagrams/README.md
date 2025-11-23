# ReageCFO Visual Diagrams

This directory contains Mermaid diagrams and their rendered PNG images for the ReageCFO presentation.

## Diagrams

### 1. V2 End-to-End Flow (`v2-flow.png`)
**Purpose:** Show the complete V2 cross-chain payment flow

**Shows:**
- Invoice received by AI agent
- Pyth Network price fetch
- CDP wallet signing
- EVVM ledger recording
- LayerZero cross-chain message
- Vault releasing funds
- Complete end-to-end flow

**Use in pitch:** Slides 4-7 (The System "Comes Alive")

**Key points:**
- All 4 sponsors integrated
- Real transaction: 0x9ec4ae37...
- Status: DELIVERED ✅

---

### 2. V3 Parallel Execution (`v3-parallel.png`)
**Purpose:** Show high-throughput parallel processing with async nonces

**Shows:**
- 3 invoices processed simultaneously
- Async nonces (1763844456777, 1763844456778, 1763844456779)
- All 3 transactions in same block (9685199)
- Parallel LayerZero messages
- Advanced EVVM features

**Use in pitch:** Slide 9 (The "Mic Drop")

**Key points:**
- Proves parallel execution
- 8.2 seconds for 3 transactions
- 0.37 tx/sec throughput

---

### 3. System Architecture (`architecture.png`)
**Purpose:** Show the complete system architecture with all layers

**Shows:**
- AI Layer (CDP Agent)
- Data Layer (Pyth)
- Ledger Layer (EVVM V2 & V3)
- Messaging Layer (LayerZero)
- Settlement Layer (Vault)
- How everything connects

**Use in pitch:** Slide 13 (The Close)

**Key points:**
- Brain: CDP
- Eyes: Pyth
- Heart: EVVM
- Hands: LayerZero

---

### 4. Sponsor Integration (`sponsors.png`)
**Purpose:** Show how each sponsor contributes to the system

**Shows:**
- EVVM: 4 features (Ledger, Async Nonces, MATE, Executor)
- CDP: 3 features (Server Wallet, Autonomous Signing, Key Management)
- Pyth: 3 features (Real-time Prices, Confidence, Market Logic)
- LayerZero: 3 features (Cross-chain, OApp, Atomic Settlement)

**Use in pitch:** Slide 13 or as backup

**Key points:**
- All 4 sponsors fully integrated
- Each provides critical functionality
- Complete ecosystem

---

### 5. Financial Tension (`financial-tension.png`)
**Purpose:** Explain TigerBeetle's "Financial Tension" concept

**Shows:**
- State transitions: Available → Pending → InTransit → Settled
- Automatic rollback if LayerZero fails
- Safety guarantees (no lost funds, no stuck transactions)
- Zero-sum ledger enforcement

**Use in pitch:** Slide 8 (TigerBeetle's "Financial Tension")

**Key points:**
- Reserve → Commit pattern
- Automatic rollback
- Double-entry invariants
- Production-ready safety

---

## Usage in Presentation

### Recommended Flow

1. **Intro (Slides 1-3):** No diagrams, just talk
2. **V2 Demo (Slides 4-7):** Show `v2-flow.png` + live terminal
3. **TigerBeetle (Slide 8):** Show `financial-tension.png`
4. **V3 Demo (Slide 9):** Show `v3-parallel.png` + browser
5. **LayerZero (Slide 10-11):** Keep `v2-flow.png` or show browser
6. **Close (Slide 13):** Show `architecture.png` or `sponsors.png`

### Tips

- **Keep diagrams visible** while narrating
- **Point to specific elements** as you explain
- **Use diagrams as backup** if live demo fails
- **Print them** if presenting in person

---

## Source Files

All diagrams are created from Mermaid source files (`.mmd`):
- `v2-flow.mmd` → `v2-flow.png`
- `v3-parallel.mmd` → `v3-parallel.png`
- `architecture.mmd` → `architecture.png`
- `sponsors.mmd` → `sponsors.png`
- `financial-tension.mmd` → `financial-tension.png`

To regenerate PNG images:
```bash
manus-render-diagram [source.mmd] [output.png]
```

---

## Embedding in Slides

### PowerPoint/Keynote
1. Insert → Picture
2. Select the PNG file
3. Resize as needed

### Google Slides
1. Insert → Image
2. Upload from computer
3. Select the PNG file

### Markdown Presentations
```markdown
![V2 Flow](docs/diagrams/v2-flow.png)
```

---

## Color Scheme

- **CDP (Blue):** #4A90E2
- **Pyth (Purple):** #7B61FF
- **EVVM (Green):** #00D4AA
- **LayerZero (Pink):** #FF6B9D
- **Vault (Orange):** #FFB84D

Consistent across all diagrams for brand recognition.

---

Created for ETHGlobal Buenos Aires 2025
