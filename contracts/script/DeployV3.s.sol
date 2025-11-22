// SPDX-License-Identifier: MIT
pragma solidity ^0.8.22;

import "forge-std/Script.sol";
import "../src/ApertureServiceV3.sol";

contract DeployV3 is Script {
    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        
        // Contract addresses
        address lzEndpoint = 0x6EDCE65403992e310A62460808c4b910D972f10f; // Sepolia LZ Endpoint
        address cdpWallet = 0xBCD8c885E3bc0F87940eAdA431e14cA9F3Fc98E0; // CDP Agent Wallet
        address deployer = vm.addr(deployerPrivateKey);
        address nameService = 0x93DFFaEd15239Ec77aaaBc79DF3b9818dD3E406A; // MATE NameService
        
        vm.startBroadcast(deployerPrivateKey);
        
        // Deploy V3
        ApertureServiceV3 v3 = new ApertureServiceV3(
            lzEndpoint,
            cdpWallet,
            deployer,
            nameService
        );
        
        console.log("ApertureServiceV3 deployed to:", address(v3));
        console.log("CDP Agent Wallet:", cdpWallet);
        console.log("MATE NameService:", nameService);
        console.log("EVVM ID:", v3.EVVM_ID());
        
        vm.stopBroadcast();
    }
}
