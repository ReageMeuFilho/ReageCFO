// SPDX-License-Identifier: MIT
pragma solidity ^0.8.22;

import {OApp, Origin, MessagingFee} from "@layerzerolabs/lz-evm-oapp-v2/contracts/oapp/OApp.sol";
import {OptionsBuilder} from "@layerzerolabs/lz-evm-oapp-v2/contracts/oapp/libs/OptionsBuilder.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

/**
 * @title ApertureServiceV2 - The Market-Aware Sovereign Ledger
 * @notice An AI-controlled, double-entry accounting ledger with cross-chain payment capabilities
 */
contract ApertureServiceV2 is OApp {
    using OptionsBuilder for bytes;
    
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
    event CrossChainPaymentSent(
        uint32 indexed dstEid,
        address indexed recipient,
        uint256 amount,
        bytes32 invoiceId
    );
    
    error UnauthorizedAgent();
    error LedgerImbalance(uint256 totalDebits, uint256 totalCredits);
    error InsufficientFunds(address account, uint256 required, uint256 available);
    error InvoiceAlreadyProcessed(bytes32 invoiceId);

    constructor(
        address _endpoint,
        address _agentWallet,
        address _owner
    ) OApp(_endpoint, _owner) Ownable(_owner) {
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

    /**
     * @notice Send cross-chain payment instruction to vault on Base Sepolia
     * @param _dstEid Destination endpoint ID (Base Sepolia = 40245)
     * @param recipient Address to receive funds on Base
     * @param amount Amount to send
     * @param invoiceId Unique invoice identifier
     * @param intent Description of payment
     */
    function sendCrossChainPayment(
        uint32 _dstEid,
        address recipient,
        uint256 amount,
        bytes32 invoiceId,
        string calldata intent
    ) external payable onlyAgent {
        // Prevent double-payment
        if (processedInvoices[invoiceId]) {
            revert InvoiceAlreadyProcessed(invoiceId);
        }
        processedInvoices[invoiceId] = true;

        // Encode payment instruction - simplified to match receiver
        bytes memory payload = abi.encode(recipient, amount);

        // Build options for gas on destination - increased gas limit
        bytes memory options = OptionsBuilder
            .newOptions()
            .addExecutorLzReceiveOption(500000, 0);

        // Send cross-chain message
        _lzSend(
            _dstEid,
            payload,
            options,
            MessagingFee(msg.value, 0),
            payable(msg.sender)
        );

        // Record in ledger
        LedgerEntry memory meta = LedgerEntry({
            intent: intent,
            agentId: "CrossChainPayment",
            timestamp: block.timestamp
        });
        transactionHistory.push(meta);

        emit CrossChainPaymentSent(_dstEid, recipient, amount, invoiceId);
        emit EntryPosted(transactionHistory.length - 1, intent, "CrossChainPayment");
    }

    /**
     * @notice Quote the fee for sending a cross-chain payment
     * @param _dstEid Destination endpoint ID
     * @param recipient Address to receive funds
     * @param amount Amount to send
     * @param invoiceId Invoice identifier
     * @param intent Payment description
     */
    function quoteCrossChainPayment(
        uint32 _dstEid,
        address recipient,
        uint256 amount,
        bytes32 invoiceId,
        string calldata intent
    ) external view returns (MessagingFee memory fee) {
        bytes memory payload = abi.encode(recipient, amount);
        bytes memory options = OptionsBuilder
            .newOptions()
            .addExecutorLzReceiveOption(500000, 0);
        
        fee = _quote(_dstEid, payload, options, false);
    }

    /**
     * @notice Receive cross-chain messages (not used in current design, but required by OApp)
     */
    function _lzReceive(
        Origin calldata /*_origin*/,
        bytes32 /*_guid*/,
        bytes calldata /*_payload*/,
        address /*_executor*/,
        bytes calldata /*_extraData*/
    ) internal override {
        // This contract only sends messages, doesn't receive them
        // But we need to implement this function to satisfy OApp interface
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
