// SPDX-License-Identifier: MIT
pragma solidity ^0.8.22;

import {OApp, Origin, MessagingFee} from "@layerzerolabs/lz-evm-oapp-v2/contracts/oapp/OApp.sol";
import {OptionsBuilder} from "@layerzerolabs/lz-evm-oapp-v2/contracts/oapp/libs/OptionsBuilder.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

// EVVM MATE NameService Interface
interface INameService {
    function getOwnerOfIdentity(string memory _username) external view returns (address);
    function verifyStrictAndGetOwnerOfIdentity(string memory _username) external view returns (address);
}

/**
 * @title ApertureServiceV3 - EVVM-Enhanced Market-Aware Sovereign Ledger
 * @notice An AI-controlled ledger with MATE NameService integration and async nonce support
 * @dev V3 Enhancement: Adds human-readable payment destinations and high-throughput parallel processing
 * 
 * EVVM Integration:
 * - MATE NameService for human-readable addresses
 * - Async nonces for parallel transaction processing
 * - High-throughput treasury operations
 */
contract ApertureServiceV3 is OApp {
    using OptionsBuilder for bytes;
    
    address public agentWallet;
    uint256 public constant EVVM_ID = 2;
    INameService public immutable nameService;

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

    // Async Nonce Support: Track nonces per agent to allow parallel execution
    mapping(address => mapping(uint256 => bool)) public usedNonces;
    
    mapping(address => mapping(address => uint256)) public balances;
    LedgerEntry[] public transactionHistory;
    mapping(bytes32 => bool) public processedInvoices;

    event EntryPosted(uint256 indexed entryId, string intent, string agentId, uint256 nonce);
    event CrossChainPaymentSent(
        uint32 indexed dstEid,
        address indexed recipient,
        uint256 amount,
        bytes32 invoiceId,
        uint256 nonce
    );
    event PaymentByName(
        string indexed mateName,
        address indexed resolvedAddress,
        uint256 amount,
        bytes32 invoiceId,
        uint256 nonce
    );
    
    error UnauthorizedAgent();
    error LedgerImbalance(uint256 totalDebits, uint256 totalCredits);
    error InsufficientFunds(address account, uint256 required, uint256 available);
    error InvoiceAlreadyProcessed(bytes32 invoiceId);
    error NonceAlreadyUsed(address agent, uint256 nonce);
    error NameResolutionFailed(string mateName);

    constructor(
        address _endpoint,
        address _agentWallet,
        address _owner,
        address _nameService
    ) OApp(_endpoint, _owner) Ownable(_owner) {
        agentWallet = _agentWallet;
        nameService = INameService(_nameService);
    }

    modifier onlyAgent() {
        if (msg.sender != agentWallet) revert UnauthorizedAgent();
        _;
    }

    /**
     * @notice Check if a nonce has been used (for async nonce validation)
     * @param agent Address of the agent
     * @param nonce Nonce to check
     */
    function isNonceUsed(address agent, uint256 nonce) external view returns (bool) {
        return usedNonces[agent][nonce];
    }

    /**
     * @notice Execute a double-entry batch transaction with async nonce support
     * @param postings Array of debits and credits (must balance)
     * @param meta Metadata for the transaction
     * @param invoiceId Unique invoice identifier
     * @param nonce Async nonce for parallel execution
     */
    function executeBatchAsync(
        Posting[] memory postings,
        LedgerEntry memory meta,
        bytes32 invoiceId,
        uint256 nonce
    ) public onlyAgent {
        // Async nonce validation - allows parallel execution
        if (usedNonces[msg.sender][nonce]) {
            revert NonceAlreadyUsed(msg.sender, nonce);
        }
        usedNonces[msg.sender][nonce] = true;

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

        emit EntryPosted(transactionHistory.length - 1, meta.intent, meta.agentId, nonce);
    }

    /**
     * @notice Pay by MATE name - resolves human-readable name to address
     * @param mateName MATE NameService username (e.g., "vendor.mate")
     * @param amount Amount to pay
     * @param invoiceId Unique invoice identifier
     * @param intent Description of payment
     * @param nonce Async nonce for parallel execution
     */
    function payByName(
        string calldata mateName,
        uint256 amount,
        bytes32 invoiceId,
        string calldata intent,
        uint256 nonce
    ) external onlyAgent {
        // Async nonce validation
        if (usedNonces[msg.sender][nonce]) {
            revert NonceAlreadyUsed(msg.sender, nonce);
        }
        usedNonces[msg.sender][nonce] = true;

        // Prevent double-payment
        if (processedInvoices[invoiceId]) {
            revert InvoiceAlreadyProcessed(invoiceId);
        }
        processedInvoices[invoiceId] = true;

        // Resolve MATE name to address
        address recipient = nameService.getOwnerOfIdentity(mateName);
        if (recipient == address(0)) {
            revert NameResolutionFailed(mateName);
        }

        // Execute payment logic (simplified - could integrate with executeBatch)
        // For now, just record the intent
        LedgerEntry memory meta = LedgerEntry({
            intent: intent,
            agentId: "PayByName",
            timestamp: block.timestamp
        });
        transactionHistory.push(meta);

        emit PaymentByName(mateName, recipient, amount, invoiceId, nonce);
        emit EntryPosted(transactionHistory.length - 1, intent, "PayByName", nonce);
    }

    /**
     * @notice Send cross-chain payment with async nonce support
     * @param _dstEid Destination endpoint ID (Base Sepolia = 40245)
     * @param recipient Address to receive funds on Base
     * @param amount Amount to send
     * @param invoiceId Unique invoice identifier
     * @param intent Description of payment
     * @param nonce Async nonce for parallel execution
     */
    function sendCrossChainPaymentAsync(
        uint32 _dstEid,
        address recipient,
        uint256 amount,
        bytes32 invoiceId,
        string calldata intent,
        uint256 nonce
    ) public payable onlyAgent {
        // Async nonce validation
        if (usedNonces[msg.sender][nonce]) {
            revert NonceAlreadyUsed(msg.sender, nonce);
        }
        usedNonces[msg.sender][nonce] = true;

        // Prevent double-payment
        if (processedInvoices[invoiceId]) {
            revert InvoiceAlreadyProcessed(invoiceId);
        }
        processedInvoices[invoiceId] = true;

        // Encode payment instruction
        bytes memory payload = abi.encode(recipient, amount);

        // Build options for gas on destination
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
            agentId: "CrossChainPaymentAsync",
            timestamp: block.timestamp
        });
        transactionHistory.push(meta);

        emit CrossChainPaymentSent(_dstEid, recipient, amount, invoiceId, nonce);
        emit EntryPosted(transactionHistory.length - 1, intent, "CrossChainPaymentAsync", nonce);
    }

    /**
     * @notice Backward compatibility: Execute batch without async nonce
     */
    function executeBatch(
        Posting[] memory postings,
        LedgerEntry memory meta,
        bytes32 invoiceId
    ) external onlyAgent {
        // Use timestamp + gasleft as pseudo-nonce for backward compatibility
        uint256 pseudoNonce = uint256(keccak256(abi.encodePacked(block.timestamp, gasleft(), msg.sender)));
        this.executeBatchAsync(postings, meta, invoiceId, pseudoNonce);
    }

    /**
     * @notice Backward compatibility: Send cross-chain payment without async nonce
     */
    function sendCrossChainPayment(
        uint32 _dstEid,
        address recipient,
        uint256 amount,
        bytes32 invoiceId,
        string calldata intent
    ) external payable onlyAgent {
        // Use timestamp + gasleft as pseudo-nonce for backward compatibility
        uint256 pseudoNonce = uint256(keccak256(abi.encodePacked(block.timestamp, gasleft(), msg.sender)));
        this.sendCrossChainPaymentAsync{value: msg.value}(
            _dstEid,
            recipient,
            amount,
            invoiceId,
            intent,
            pseudoNonce
        );
    }

    /**
     * @notice Quote the fee for sending a cross-chain payment
     */
    function quoteCrossChainPayment(
        uint32 _dstEid,
        address recipient,
        uint256 amount
    ) external view returns (MessagingFee memory fee) {
        bytes memory payload = abi.encode(recipient, amount);
        bytes memory options = OptionsBuilder
            .newOptions()
            .addExecutorLzReceiveOption(500000, 0);
        
        fee = _quote(_dstEid, payload, options, false);
    }

    /**
     * @notice Receive cross-chain messages (not used in current design)
     */
    function _lzReceive(
        Origin calldata /*_origin*/,
        bytes32 /*_guid*/,
        bytes calldata /*_payload*/,
        address /*_executor*/,
        bytes calldata /*_extraData*/
    ) internal override {
        // This contract only sends messages
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
