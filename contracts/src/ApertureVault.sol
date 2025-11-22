// SPDX-License-Identifier: MIT
pragma solidity ^0.8.22;

import {OApp, Origin, MessagingFee} from "@layerzerolabs/lz-evm-oapp-v2/contracts/oapp/OApp.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

/**
 * @title ApertureVault - The Settlement Layer
 * @notice Holds real funds on Base Sepolia and releases them when instructed by the Ledger
 * @dev Receives LayerZero messages from ApertureServiceV2 on Sepolia
 */
contract ApertureVault is OApp {
    
    // ============ Events ============
    
    event FundsReleased(
        address indexed recipient,
        uint256 amount,
        bytes32 invoiceId,
        string intent
    );
    
    event FundsDeposited(
        address indexed depositor,
        uint256 amount
    );
    
    event MessageReceived(
        uint32 indexed srcEid,
        bytes32 indexed sender,
        bytes payload
    );
    
    // ============ Errors ============
    
    error InsufficientVaultBalance(uint256 requested, uint256 available);
    error InvalidRecipient();
    error InvalidAmount();
    
    // ============ State Variables ============
    
    /// @notice Total funds available in the vault
    uint256 public vaultBalance;
    
    /// @notice Track processed invoices to prevent double-payment
    mapping(bytes32 => bool) public processedInvoices;
    
    /// @notice Payment history for auditing
    struct Payment {
        address recipient;
        uint256 amount;
        bytes32 invoiceId;
        string intent;
        uint256 timestamp;
    }
    
    Payment[] public paymentHistory;
    
    // ============ Constructor ============
    
    constructor(
        address _endpoint,
        address _owner
    ) OApp(_endpoint, _owner) Ownable(_owner) {}
    
    // ============ External Functions ============
    
    /**
     * @notice Deposit funds into the vault
     */
    function deposit() external payable {
        require(msg.value > 0, "Must send ETH");
        vaultBalance += msg.value;
        emit FundsDeposited(msg.sender, msg.value);
    }
    
    /**
     * @notice Withdraw funds (owner only, for emergencies)
     */
    function withdraw(uint256 amount) external onlyOwner {
        require(amount <= vaultBalance, "Insufficient balance");
        vaultBalance -= amount;
        payable(owner()).transfer(amount);
    }
    
    /**
     * @notice Get total payment count
     */
    function getPaymentCount() external view returns (uint256) {
        return paymentHistory.length;
    }
    
    // ============ LayerZero Receive Function ============
    
    /**
     * @notice Receives cross-chain messages from the Ledger
     * @dev Called by LayerZero endpoint when a message arrives
     */
    function _lzReceive(
        Origin calldata _origin,
        bytes32 _guid,
        bytes calldata _payload,
        address /*_executor*/,
        bytes calldata /*_extraData*/
    ) internal override {
        
        emit MessageReceived(_origin.srcEid, _origin.sender, _payload);
        
        // Fix: Decode specific types instead of complex struct
        (address recipient, uint256 amount) = abi.decode(_payload, (address, uint256));
        
        // Validate
        if (recipient == address(0)) revert InvalidRecipient();
        if (amount == 0) revert InvalidAmount();
        if (amount > vaultBalance) {
            revert InsufficientVaultBalance(amount, vaultBalance);
        }
        
        // Release funds
        vaultBalance -= amount;
        payable(recipient).transfer(amount);
        
        // Record payment with simplified data
        bytes32 invoiceId = keccak256(abi.encodePacked(recipient, amount, block.timestamp));
        paymentHistory.push(Payment({
            recipient: recipient,
            amount: amount,
            invoiceId: invoiceId,
            intent: "Cross-chain payment",
            timestamp: block.timestamp
        }));
        
        emit FundsReleased(recipient, amount, invoiceId, "Cross-chain payment");
    }
    
    // ============ Fallback ============
    
    receive() external payable {
        vaultBalance += msg.value;
        emit FundsDeposited(msg.sender, msg.value);
    }
}
