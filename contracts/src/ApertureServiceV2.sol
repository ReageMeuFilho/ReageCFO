// SPDX-License-Identifier: MIT
pragma solidity ^0.8.22;

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

/**
 * @title ApertureServiceV2 - The Market-Aware Sovereign Ledger
 * @notice An AI-controlled, double-entry accounting ledger
 */
contract ApertureServiceV2 is Ownable {
    
    address public agentWallet;
    uint256 public constant EVVM_ID = 2;

    struct Posting {
        address account;
        uint256 amount;
        bool isDebit;
    }

    struct LedgerEntry {
        string intent;
        string agentId;
        uint256 timestamp;
    }

    mapping(address => mapping(address => uint256)) public balances;
    LedgerEntry[] public transactionHistory;
    mapping(bytes32 => bool) public processedInvoices;

    event EntryPosted(uint256 indexed entryId, string intent, string agentId);
    
    error UnauthorizedAgent();
    error LedgerImbalance(uint256 totalDebits, uint256 totalCredits);
    error InsufficientFunds(address account, uint256 required, uint256 available);
    error InvoiceAlreadyProcessed(bytes32 invoiceId);

    constructor(address _agentWallet) Ownable(msg.sender) {
        agentWallet = _agentWallet;
    }

    modifier onlyAgent() {
        if (msg.sender != agentWallet) revert UnauthorizedAgent();
        _;
    }

    /**
     * @notice Execute a double-entry batch transaction
     * @param postings Array of debits and credits (must balance)
     * @param meta Metadata for the transaction
     * @param invoiceId Unique invoice identifier
     */
    function executeBatch(
        Posting[] memory postings,
        LedgerEntry memory meta,
        bytes32 invoiceId
    ) external onlyAgent {
        // Prevent double-payment
        if (processedInvoices[invoiceId]) {
            revert InvoiceAlreadyProcessed(invoiceId);
        }
        processedInvoices[invoiceId] = true;

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

    function getBalance(address account, address token) external view returns (uint256) {
        return balances[account][token];
    }

    function getTransactionCount() external view returns (uint256) {
        return transactionHistory.length;
    }

    function updateAgentWallet(address newAgent) external onlyOwner {
        agentWallet = newAgent;
    }

    function deposit(address account, uint256 amount) external payable {
        require(msg.value >= amount, "Insufficient value sent");
        balances[account][address(0)] += amount;
    }

    receive() external payable {}
}
