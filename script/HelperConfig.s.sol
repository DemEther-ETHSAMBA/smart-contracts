// SPDX-License-Identifier: MIT
/* solhint-disable compiler-version */
pragma solidity ^0.8.19;

import { Script } from "forge-std/Script.sol";

contract HelperConfig is Script {
    struct NetworkConfig {
        uint256 key;
    }

    NetworkConfig public activeNetworkConfig;

    uint256 public constant ANVIL_KEY = 0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80;

    constructor() {
        if (
            block.chainid == 1287 || 
            block.chainid == 137 || 
            block.chainid == 11_155_111 || 
            block.chainid == 5 || 
            block.chainid == 80_001 || 
            block.chainid == 1 || 
            block.chainid == 59_140 || 
            block.chainid == 17_000 || 
            block.chainid == 25_022_022 
        ) {
            activeNetworkConfig = getPublicConfig();
        } else {
            activeNetworkConfig = getAnvilConfig();
        }
    }

    function getPublicConfig() public view returns (NetworkConfig memory) {
        return NetworkConfig({ key: vm.envUint("PRIVATE_KEY") });
    }

    function getAnvilConfig() public pure returns (NetworkConfig memory) {
        return NetworkConfig({ key: ANVIL_KEY });
    }
}
