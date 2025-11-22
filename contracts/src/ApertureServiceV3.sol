// SPDX-License-Identifier: MIT
pragma solidity ^0.8.22;

import {OApp, Origin, MessagingFee} from "@layerzerolabs/lz-evm-oapp-v2/contracts/oapp/OApp.sol";
import {OptionsBuilder} from "@layerzerolabs/lz-evm-oapp-v2/contracts/oapp/libs/OptionsBuilder.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {IPyth} from "@pythnetwork/pyth-sdk-solidity/IPyth.sol";
import {PythStructs} from "@pythnetwork/pyth-sdk-solidity/PythStructs.sol";

/**
 * @title ApertureServiceV3 - The Market-Aware Sovereign Ledger with Cross-Chain Settlement
 * @notice An AI-controlled, double-entry accounting ledger with LayerZero cross-chain capabilities
 * @dev Integrates EVVM, Pyth Network, and LayerZero for complete financial automation
 */
contract ApertureServiceV3 is OApp {
    using OptionsBuilder for bytes;
    
    // ============ State Variables ============
    
    /// @notice The AI agent's wallet address (Coinbase CDP Server Wallet)
    address public agentWallet;
    
    /// @notice EVVM ID for the MATE Metaprotocol
    uint256 public constant EVVM_ID = 2;
    
    /// @notice Pyth Oracle for price feeds
    IPyth public immutable pythOracle;
    
    /// @notice LayerZero destination chain EID (Base Sepolia)
    uint32 public destinationEid;
    
    // ============ Accounting Structures ============
    
    /// @notice Represents a single posting in the double-entry system
    struct Posting {
        address account;
        uint256 amount;
        bool isDebit;  // true = Debit, false = Credit
    }
    
    /// @notice Ledger entry with semantic metadata
    struct LedgerEntry {
        string intent;
        string agentId;
        bytes32 pythPriceId;
        int64 priceAtExecution;
        uint256 timestamp;
    }
    
    /// @notice Account balances mapping
    mapping(address => mapping(address => uint256)) public balances;
    
    /// @notice Transaction history for auditing
    LedgerEntry[] public transactionHistory;
    
    /// @notice Processed invoices to prevent double-payment
    mapping(bytes32 => bool) public processedInvoices;
    
    /// @notice Price thresholds per asset (Pyth price ID => minimum price)
    mapping(bytes32 => int64) public priceThresholds;
    
    // ============ Events ============
    
    event EntryPosted(uint256 indexed entryId, string intent, string agentId);
    event CrossChainPaymentInitiated(bytes32 indexed invoiceId, uint32 destinationEid, address recipient, uint256 amount);
    event PriceThresholdSet(bytes32 indexed priceId, int64 threshold);
    
    // ============ Errors ============
    
    error UnauthorizedAgent();
    error LedgerImbalance(uint256 totalDebits, uint256 totalCredits);
    error InsufficientFunds(address account, uint256 required, uint256 available);
    error InvoiceAlreadyProcessed(bytes32 invoiceId);
    error PriceBelowThreshold(int64 currentPrice, int64 threshold);
    error StalePriceData();
    
    // ============ Constructor ============
    
    constructor(
        address _endpoint,
        address _agentWallet,
        address _pythOracle,
        uint32 _destinationEid
    ) OApp(_endpoint, msg.sender) Ownable(msg.sender) {
        agentWallet = _agentWallet;
        pythOracle = IPyth(_pythOracle);
        destinationEid = _destinationEid;
    }
    
    // ============ Modifiers ============
    
    modifier onlyAgent() {
        if (msg.sender != agentWallet) revert UnauthorizedAgent();
        _;
    }
    
    // ============ Core Functions ============
    
    /**
     * @notice Execute a double-entry batch transaction with Pyth price validation
     * @param postings Array of debits and credits (must balance)
     * @param meta Metadata for the transaction
     * @param pythPriceUpdate Pyth price update data
     * @param invoiceId Unique invoice identifier
     */
    function executeBatch(
        Posting[] memory postings,
        LedgerEntry memory meta,
        bytes[] calldata pythPriceUpdate,
        bytes32 invoiceId
    ) external payable onlyAgent {
        // Prevent double-payment
        if (processedInvoices[invoiceId]) {
            revert InvoiceAlreadyProcessed(invoiceId);
        }
        processedInvoices[invoiceId] = true;
        
        // Update Pyth price (requires fee)
        uint256 pythFee = pythOracle.getUpdateFee(pythPriceUpdate);
        pythOracle.updatePriceFeeds{value: pythFee}(pythPriceUpdate);
        
        // Get and validate price
        PythStructs.Price memory price = pythOracle.getPriceUnsafe(meta.pythPriceId);
        
        // Check price threshold if set
        int64 threshold = priceThresholds[meta.pythPriceId];
        if (threshold > 0 && price.price < threshold) {
            revert PriceBelowThreshold(price.price, threshold);
        }
        
        // Store price in metadata
        meta.priceAtExecution = price.price;
        
        // Enforce double-entry logic
        uint256 totalDebits = 0;
        uint256 totalCredits = 0;
        
        for (uint i = 0; i < postings.length; i++) {
            if (postings[i].isDebit) {
                totalDebits += postings[i].amount;
                uint256 currentBalance = balances[postings[i].account][address(0)];
                if (currentBalance < postings[i].amount) {
                    revert InsufficientFunds(
                        postings[i].account,
                        postings[i].amount,
                        currentBalance
                    );
                }
                balances[postings[i].account][address(0)] -= postings[i].amount;
            } else {
                totalCredits += postings[i].amount;
                balances[postings[i].account][address(0)] += postings[i].amount;
            }
        }
        
        // Verify balance
        if (totalDebits != totalCredits) {
            revert LedgerImbalance(totalDebits, totalCredits);
        }
        
        // Record transaction
        meta.timestamp = block.timestamp;
        transactionHistory.push(meta);
        
        emit EntryPosted(transactionHistory.length - 1, meta.intent, meta.agentId);
    }
    
    /**
     * @notice Execute a cross-chain payment via LayerZero
     * @param recipient Address to receive funds on destination chain
     * @param amount Amount to send
     * @param invoiceId Unique invoice identifier
     * @param intent Description of the payment
     */
    function executeCrossChainPayment(
        address recipient,
        uint256 amount,
        bytes32 invoiceId,
        string calldata intent
    ) external payable onlyAgent {
        // Encode the payment instruction
        bytes memory payload = abi.encode(recipient, amount, invoiceId, intent);
        
        // Build LayerZero options
        bytes memory options = OptionsBuilder.newOptions().addExecutorLzReceiveOption(200000, 0);
        
        // Send the message
        _lzSend(
            destinationEid,
            payload,
            options,
            MessagingFee(msg.value, 0),
            payable(msg.sender)
        );
        
        emit CrossChainPaymentInitiated(invoiceId, destinationEid, recipient, amount);
    }
    
    /**
     * @notice Set price threshold for an asset
     * @param priceId Pyth price feed ID
     * @param threshold Minimum acceptable price (in Pyth format)
     */
    function setPriceThreshold(bytes32 priceId, int64 threshold) external onlyOwner {
        priceThresholds[priceId] = threshold;
        emit PriceThresholdSet(priceId, threshold);
    }
    
    /**
     * @notice Update the agent wallet address
     */
    function updateAgentWallet(address newAgent) external onlyOwner {
        agentWallet = newAgent;
    }
    
    /**
     * @notice Get account balance
     */
    function getBalance(address account, address token) external view returns (uint256) {
        return balances[account][token];
    }
    
    /**
     * @notice Get transaction count
     */
    function getTransactionCount() external view returns (uint256) {
        return transactionHistory.length;
    }
    
    /**
     * @notice Deposit funds to an account
     */
    function deposit(address account, uint256 amount) external payable {
        require(msg.value >= amount, "Insufficient value sent");
        balances[account][address(0)] += amount;
    }
    
    /**
     * @notice Estimate LayerZero fee for cross-chain message
     */
    function quote(
        address recipient,
        uint256 amount,
        bytes32 invoiceId,
        string calldata intent
    ) public view returns (uint256 nativeFee) {
        bytes memory payload = abi.encode(recipient, amount, invoiceId, intent);
        bytes memory options = OptionsBuilder.newOptions().addExecutorLzReceiveOption(200000, 0);
        
        MessagingFee memory fee = _quote(destinationEid, payload, options, false);
        return fee.nativeFee;
    }
    
    // ============ LayerZero Receive Function ============
    
    /**
     * @notice Receives cross-chain messages (for future bidirectional communication)
     */
    function _lzReceive(
        Origin calldata /*_origin*/,
        bytes32 /*_guid*/,
        bytes calldata /*_payload*/,
        address /*_executor*/,
        bytes calldata /*_extraData*/
    ) internal override {
        // For Phase III, we only send messages, not receive
        // Future enhancement: receive confirmations from vault
    }
    
    // ============ Fallback ============
    
    receive() external payable {}
}
