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

contract DeployManagement is Script {
    HelperConfig public config;

    
    Management public management;
    ERC1967Proxy public Managmentproxy;

    address owner_;
    

    function run() public {
        config = new HelperConfig();

        (uint256 key) = config.activeNetworkConfig();

        vm.startBroadcast(vm.rememberKey(key));
        address _implementation = 0x4a76115b700C0063273Cf8Eb94071555a2Aa8f03; ///REPLACE WITH IMPLEMENTATION ADDRESS
        Management Managementimplementation = new Management();
        bytes memory DN404init = abi.encodeWithSelector(
            Management.initialize.selector, 
            vm.addr(key),
            _implementation
        );

        Managmentproxy = new ERC1967Proxy(address(Managementimplementation), DN404init);
        
        management = Management(payable(Managmentproxy));
        
        console.log("ManagmentImplementation",address(Managementimplementation));
        console.log("ManagmentProxy",address(Managmentproxy));
        vm.stopBroadcast();

        
    }
}
