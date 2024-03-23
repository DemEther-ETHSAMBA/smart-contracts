//SPDX-License-Identifier: MIT
pragma solidity 0.8.23;

import { Script } from "forge-std/Script.sol";
import { console } from "../lib/forge-std/src/console.sol";
import { HelperConfig } from "./HelperConfig.s.sol";

//  ==========  Smart contract imports  ==========

import { MockV3Aggregator } from "../src/chainlink/MockV3Aggregator.sol";
import { ERC1967Proxy } from "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";

/// -----------------------------------------------------------------------
/// Script
/// -----------------------------------------------------------------------

contract DeployAggregator is Script {

    HelperConfig public config;
    MockV3Aggregator public mockV3Aggregator;
    function run() public {
        config = new HelperConfig();

        (uint256 key) = config.activeNetworkConfig();

        vm.startBroadcast(vm.rememberKey(key));

        mockV3Aggregator = new MockV3Aggregator(8,1000000);

        console.log("Aggregator",address(mockV3Aggregator));
        // console.log("Proxy",proxy);
        vm.stopBroadcast();

        
    }
}