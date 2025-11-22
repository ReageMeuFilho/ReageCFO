// SPDX-License-Identifier: MIT
pragma solidity ^0.8.22;

import {Script, console} from "forge-std/Script.sol";
import {ApertureVault} from "../src/ApertureVault.sol";

/**
 * @title DeployVault
 * @notice Deploys the ApertureVault contract on Base Sepolia
 */
contract DeployVault is Script {
    
    // Base Sepolia LayerZero Endpoint
    address constant BASE_SEPOLIA_ENDPOINT = 0x6EDCE65403992e310A62460808c4b910D972f10f;
    
    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        address deployer = vm.addr(deployerPrivateKey);
        
        console.log("===========================================");
        console.log("Deploying ApertureVault to Base Sepolia");
        console.log("===========================================");
        console.log("Deployer:", deployer);
        console.log("LayerZero Endpoint:", BASE_SEPOLIA_ENDPOINT);
        console.log("");
        
        vm.startBroadcast(deployerPrivateKey);
        
        // Deploy the vault
        ApertureVault vault = new ApertureVault(
            BASE_SEPOLIA_ENDPOINT,
            deployer
        );
        
        console.log("Vault deployed at:", address(vault));
        console.log("");
        console.log("=== NEXT STEPS ===");
        console.log("1. Fund the vault with Base Sepolia ETH:");
        console.log("   cast send", address(vault), "--value 0.1ether --rpc-url <BASE_SEPOLIA_RPC> --private-key $PRIVATE_KEY");
        console.log("");
        console.log("2. Set the peer on the Ledger contract (Sepolia):");
        console.log("   cast send <LEDGER_ADDRESS> 'setPeer(uint32,bytes32)' 40245");
        console.logBytes32(bytes32(uint256(uint160(address(vault)))));
        console.log("   (Use this as the peer address)");
        console.log("");
        console.log("3. Set the peer on the Vault contract (Base Sepolia):");
        console.log("   cast send", address(vault), "'setPeer(uint32,bytes32)' 40161 <LEDGER_ADDRESS_AS_BYTES32>");
        console.log("");
        
        vm.stopBroadcast();
    }
}
