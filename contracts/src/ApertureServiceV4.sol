// SPDX-License-Identifier: MIT
pragma solidity ^0.8.22;

import {OApp, Origin, MessagingFee} from "@layerzerolabs/lz-evm-oapp-v2/contracts/oapp/OApp.sol";
import {OptionsBuilder} from "@layerzerolabs/lz-evm-oapp-v2/contracts/oapp/libs/OptionsBuilder.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import "@pythnetwork/pyth-sdk-solidity/IPyth.sol";
import "@pythnetwork/pyth-sdk-solidity/PythStructs.sol";

/**
 * @title ApertureServiceV4 - The Market-Aware Sovereign Ledger with Pyth Integration
 * @notice An AI-controlled, double-entry accounting ledger with real-time price validation
 * @dev Properly implements Pyth pull oracle: fetch from Hermes → update on-chain → consume price
 */
contract ApertureServiceV4 is OApp {
    using OptionsBuilder for bytes;
    
    IPyth public pyth;
    address public agentWallet;
    uint256 public constant EVVM_ID = 2;
    
    // Pyth price feed configuration
    bytes32 public constant ETH_USD_PRICE_ID = 0xff61491a931112ddf1bd8147cd1b641375f79f5825126d665480874634fd0ace;
    int64 public minEthPriceUsd; // Minimum ETH price in USD (8 decimals) to allow payments
    uint256 public maxPriceAge; // Maximum age of price data in seconds

    struct Posting {
        address account;
        uint256 amount;
        bool isDebit;
    }

    struct LedgerEntry {
        string intent;
        string agentId;
        int64 ethPriceAtExecution; // ETH/USD price at time of execution
        uint256 timestamp;
    }

    mapping(address => mapping(address => uint256)) public balances;
    LedgerEntry[] public transactionHistory;
    mapping(bytes32 => bool) public processedInvoices;

    event EntryPosted(
        uint256 indexed entryId, 
        string intent, 
        string agentId, 
        int64 ethPrice
    );
    event CrossChainPaymentSent(
        uint32 indexed dstEid,
        address indexed recipient,
        uint256 amount,
        bytes32 invoiceId
    );
    event PriceValidationFailed(
        bytes32 invoiceId,
        int64 currentPrice,
        int64 minPrice
    );
    
    error UnauthorizedAgent();
    error LedgerImbalance(uint256 totalDebits, uint256 totalCredits);
    error InsufficientFunds(address account, uint256 required, uint256 available);
    error InvoiceAlreadyProcessed(bytes32 invoiceId);
    error EthPriceTooLow(int64 currentPrice, int64 minPrice);
    error StalePriceData(uint256 age, uint256 maxAge);

    constructor(
        address _endpoint,
        address _pythContract,
        address _agentWallet,
        address _owner,
        int64 _minEthPriceUsd,
        uint256 _maxPriceAge
    ) OApp(_endpoint, _owner) Ownable(_owner) {
        pyth = IPyth(_pythContract);
        agentWallet = _agentWallet;
        minEthPriceUsd = _minEthPriceUsd;
        maxPriceAge = _maxPriceAge;
    }

    modifier onlyAgent() {
        if (msg.sender != agentWallet) revert UnauthorizedAgent();
        _;
    }

    /**
     * @notice Execute a double-entry batch transaction with Pyth price validation
     * @param postings Array of debits and credits (must balance)
     * @param meta Metadata for the transaction
     * @param invoiceId Unique invoice identifier
     * @param priceUpdate Pyth price update data from Hermes
     * @dev This implements the full Pyth pull oracle flow:
     *      1. Agent fetches price update from Hermes API
     *      2. Contract updates on-chain price via updatePriceFeeds
     *      3. Contract consumes price via getPriceNoOlderThan
     */
    function executeBatch(
        Posting[] memory postings,
        LedgerEntry memory meta,
        bytes32 invoiceId,
        bytes[] calldata priceUpdate
    ) external payable onlyAgent {
        // Prevent double-payment
        if (processedInvoices[invoiceId]) {
            revert InvoiceAlreadyProcessed(invoiceId);
        }
        processedInvoices[invoiceId] = true;

        // STEP 1: Update Pyth price on-chain (pull oracle requirement)
        uint fee = pyth.getUpdateFee(priceUpdate);
        pyth.updatePriceFeeds{value: fee}(priceUpdate);

        // STEP 2: Consume the price (pull oracle requirement)
        PythStructs.Price memory ethPrice = pyth.getPriceNoOlderThan(
            ETH_USD_PRICE_ID, 
            maxPriceAge
        );

        // STEP 3: Validate price meets minimum threshold
        if (ethPrice.price < minEthPriceUsd) {
            emit PriceValidationFailed(invoiceId, ethPrice.price, minEthPriceUsd);
            revert EthPriceTooLow(ethPrice.price, minEthPriceUsd);
        }

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

        // Record with price data
        meta.ethPriceAtExecution = ethPrice.price;
        meta.timestamp = block.timestamp;
        transactionHistory.push(meta);

        emit EntryPosted(
            transactionHistory.length - 1,
            meta.intent,
            meta.agentId,
            ethPrice.price
        );
    }

    /**
     * @notice Send cross-chain payment via LayerZero with price validation
     */
    function sendCrossChainPayment(
        uint32 _dstEid,
        address _recipient,
        uint256 _amount,
        bytes32 _invoiceId,
        string memory _intent,
        bytes[] calldata priceUpdate
    ) external payable onlyAgent {
        // Validate price before sending cross-chain payment
        uint fee = pyth.getUpdateFee(priceUpdate);
        pyth.updatePriceFeeds{value: fee}(priceUpdate);

        PythStructs.Price memory ethPrice = pyth.getPriceNoOlderThan(
            ETH_USD_PRICE_ID,
            maxPriceAge
        );

        if (ethPrice.price < minEthPriceUsd) {
            emit PriceValidationFailed(_invoiceId, ethPrice.price, minEthPriceUsd);
            revert EthPriceTooLow(ethPrice.price, minEthPriceUsd);
        }

        // Encode message for destination chain
        bytes memory payload = abi.encode(_recipient, _amount);
        
        // Configure LayerZero options
        bytes memory options = OptionsBuilder.newOptions().addExecutorLzReceiveOption(500000, 0);
        
        // Calculate LayerZero fee (separate from Pyth fee)
        MessagingFee memory lzFee = _quote(_dstEid, payload, options, false);
        
        // Send cross-chain message
        _lzSend(
            _dstEid,
            payload,
            options,
            lzFee,
            payable(msg.sender)
        );

        emit CrossChainPaymentSent(_dstEid, _recipient, _amount, _invoiceId);
    }

    /**
     * @notice Quote the fee for a cross-chain payment
     */
    function quoteCrossChainPayment(
        uint32 _dstEid,
        address _recipient,
        uint256 _amount
    ) external view returns (uint256 nativeFee) {
        bytes memory payload = abi.encode(_recipient, _amount);
        bytes memory options = OptionsBuilder.newOptions().addExecutorLzReceiveOption(500000, 0);
        
        MessagingFee memory fee = _quote(_dstEid, payload, options, false);
        return fee.nativeFee;
    }

    /**
     * @notice Deposit funds into an account
     */
    function deposit(address account) external payable {
        balances[account][address(0)] += msg.value;
    }

    /**
     * @notice Get balance of an account
     */
    function getBalance(address account, address token) external view returns (uint256) {
        return balances[account][token];
    }

    /**
     * @notice Update agent wallet address
     */
    function setAgentWallet(address _newAgent) external onlyOwner {
        agentWallet = _newAgent;
    }

    /**
     * @notice Update minimum ETH price threshold
     */
    function setMinEthPrice(int64 _minPrice) external onlyOwner {
        minEthPriceUsd = _minPrice;
    }

    /**
     * @notice Update maximum price age
     */
    function setMaxPriceAge(uint256 _maxAge) external onlyOwner {
        maxPriceAge = _maxAge;
    }

    /**
     * @notice LayerZero receive function (not used in this version)
     */
    function _lzReceive(
        Origin calldata,
        bytes32,
        bytes calldata,
        address,
        bytes calldata
    ) internal override {
        // This contract only sends, doesn't receive
    }

    receive() external payable {}
}
