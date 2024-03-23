//SPDX-License-Identifier: MIT
pragma solidity 0.8.23;

import { Script } from "forge-std/Script.sol";
import { console } from "../lib/forge-std/src/console.sol";
import { HelperConfig } from "./HelperConfig.s.sol";

//  ==========  Smart contract imports  ==========

import { L2TokenBridge } from "../src/L2TokenBridge.sol";
import { ERC1967Proxy } from "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";

/// -----------------------------------------------------------------------
/// Script
/// -----------------------------------------------------------------------

contract DeployAggregator is Script {

    HelperConfig public config;
    L2TokenBridge public bridge;

    address gateway_ = 0x058dec71E53079F9ED053F3a0bBca877F6f3eAcf;//SEPOLIA SAFEERC20 
    address counterpart_=  0x9F533D7d74CBEF6902331e05bEECD3280D13CfbA;
    string  name_ = "Bridge DN404";
    string  symbol_= "BDN404";
    uint96 initialTokenSupply = 1000e18;
    address initialSupplyOwner = 0x4a76115b700C0063273Cf8Eb94071555a2Aa8f03;
    
    function run() public {
        config = new HelperConfig();

        (uint256 key) = config.activeNetworkConfig();

        vm.startBroadcast(vm.rememberKey(key));

        bridge = new L2TokenBridge(gateway_,
        counterpart_, name_, symbol_, initialTokenSupply,initialSupplyOwner, vm.addr(key));

        console.log("BridgeL2",address(bridge));
        vm.stopBroadcast();

        
    }
}