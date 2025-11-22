// SPDX-License-Identifier: MIT
pragma solidity ^0.8.22;

import "forge-std/Script.sol";
import "../src/ApertureServiceV2.sol";

/**
 * @title DeployAperture
 * @notice Deployment script for ApertureServiceV2 to Sepolia testnet
 * 
 * Usage:
 * forge script script/DeployAperture.s.sol:DeployAperture --rpc-url sepolia --broadcast --verify
 */
contract DeployAperture is Script {
    // ============ Sepolia Testnet Addresses ============
    
    /// @notice LayerZero V2 Endpoint on Sepolia
    address constant LAYERZERO_ENDPOINT_SEPOLIA = 0x6EDCE65403992e310A62460808c4b910D972f10f;
    
    /// @notice Pyth Network Oracle on Sepolia
    address constant PYTH_ORACLE_SEPOLIA = 0xDd24F84d36BF92C65F92307595335bdFab5Bbd21;
    
    /// @notice LayerZero Endpoint ID for Base Sepolia (destination chain)
    uint32 constant BASE_SEPOLIA_EID = 40245;
    
    /// @notice LayerZero Endpoint ID for Arbitrum Sepolia (alternative destination)
    uint32 constant ARB_SEPOLIA_EID = 40231;

    function run() external {
        // Get deployer private key from environment
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        address deployer = vm.addr(deployerPrivateKey);
        
        console.log("Deploying ApertureServiceV2...");
        console.log("Deployer:", deployer);
        console.log("LayerZero Endpoint:", LAYERZERO_ENDPOINT_SEPOLIA);
        console.log("Pyth Oracle:", PYTH_ORACLE_SEPOLIA);
        console.log("Destination EID (Base Sepolia):", BASE_SEPOLIA_EID);

        vm.startBroadcast(deployerPrivateKey);

        // Deploy ApertureServiceV2
        // Parameters:
        // 1. _endpoint: LayerZero endpoint address
        // 2. _delegate: Contract owner/delegate (deployer)
        // 3. _agentWallet: AI agent's wallet (for now, use deployer, will update later)
        // 4. _pythOracle: Pyth Network oracle address
        // 5. _destinationEid: LayerZero endpoint ID for destination chain
        ApertureServiceV2 aperture = new ApertureServiceV2(
            LAYERZERO_ENDPOINT_SEPOLIA,
            deployer,              // delegate (owner)
            deployer,              // agentWallet (temporary, update after Coinbase agent setup)
            PYTH_ORACLE_SEPOLIA,
            BASE_SEPOLIA_EID
        );

        console.log("ApertureServiceV2 deployed at:", address(aperture));
        console.log("");
        console.log("=== Deployment Summary ===");
        console.log("Contract:", address(aperture));
        console.log("Owner:", aperture.owner());
        console.log("Agent Wallet:", aperture.agentWallet());
        console.log("Pyth Oracle:", address(aperture.pythOracle()));
        console.log("Destination EID:", aperture.destinationEid());
        console.log("EVVM ID:", aperture.EVVM_ID());
        console.log("");
        console.log("=== Next Steps ===");
        console.log("1. Verify contract on Etherscan");
        console.log("2. Update agent wallet address after Coinbase CDP setup");
        console.log("3. Set price thresholds for monitored assets");
        console.log("4. Deposit initial funds for testing");
        console.log("5. Configure LayerZero peer on destination chain");
        console.log("");
        console.log("=== Useful Commands ===");
        console.log("Update agent wallet:");
        console.log("  cast send", address(aperture), "\"updateAgentWallet(address)\" <NEW_AGENT_ADDRESS> --rpc-url sepolia --private-key $PRIVATE_KEY");
        console.log("");
        console.log("Set price threshold (example for ETH/USD):");
        console.log("  cast send", address(aperture), "\"setPriceThreshold(bytes32,int64)\" 0xff61491a931112ddf1bd8147cd1b641375f79f5825126d665480874634fd0ace 2000000000000 --rpc-url sepolia --private-key $PRIVATE_KEY");
        console.log("");
        console.log("Deposit test funds:");
        console.log("  cast send", address(aperture), "\"deposit(address,uint256)\" <ACCOUNT_ADDRESS> 1000000000000000000 --value 1ether --rpc-url sepolia --private-key $PRIVATE_KEY");

        vm.stopBroadcast();
    }
}
