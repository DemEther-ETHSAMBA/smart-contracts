//SPDX-License-Identifier: MIT
pragma solidity 0.8.23;

import {Script, console} from "forge-std/Script.sol";
import {HelperConfig} from "./HelperConfig.s.sol";
import {ReferenceERC6551Registry} from "../src/tba/ReferenceERC6551Registry.sol";

contract DeployERC6551Registry is Script {
    ReferenceERC6551Registry public erc6551Registry;
    HelperConfig public config;
    address public signer;

    function run() public {
        config = new HelperConfig();
        uint256 deployerKey = config.activeNetworkConfig();
        signer = vm.rememberKey(deployerKey);

        vm.startBroadcast(signer);
        erc6551Registry = new ReferenceERC6551Registry();
        console.log("Erc6551Registry:", address(erc6551Registry));
        vm.stopBroadcast();
    }
}
