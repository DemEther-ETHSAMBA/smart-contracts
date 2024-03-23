// SPDX-License-Identifier: MIT
pragma solidity 0.8.23;


import { Script, console } from "forge-std/Script.sol";
import { HelperConfig } from "./HelperConfig.s.sol";

//  ==========  Smart contract imports  ==========

import { Management } from "../src/Management.sol";
import { ERC1967Proxy } from "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";

/// -----------------------------------------------------------------------
/// Script
/// -----------------------------------------------------------------------

contract DeployDN404 is Script {
    HelperConfig public config;

    
    Management public management;
    ERC1967Proxy public Managmentproxy;

    address owner_;
    

    function run() public {
        config = new HelperConfig();

        (uint256 key) = config.activeNetworkConfig();

        vm.startBroadcast(vm.rememberKey(key));

        Management Managementimplementation = new Management();
        bytes memory DN404init = abi.encodeWithSelector(
            Management.initialize.selector, 
            vm.addr(key)
        );

        Managmentproxy = new ERC1967Proxy(address(Managementimplementation), DN404init);
        //https://ipfs.io/ipfs/QmTXGUE8ciatzL1epqZTQRDDpzCXQSksQndQnaATfT9ATN5

        management = Management(payable(Managmentproxy));
        
        console.log("DN404",address(Managementimplementation));
        console.log("Proxy",address(Managmentproxy));
        vm.stopBroadcast();

        
    }
}
