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
    
    bytes32 salt = bytes32("DemetherETHSamba10");
    function run() public {
        config = new HelperConfig();

        (uint256 key) = config.activeNetworkConfig();

        vm.startBroadcast(vm.rememberKey(key));
        address _implementation = 0x9159718813035c026254d119D6B723Fc5f5Ec5C9; ///REPLACE WITH IMPLEMENTATION ADDRESS
        address pricefeed = 0x4b7360Be27A6E5891c211B78A50987395B39F3bC;
        Management Managementimplementation = new Management{
            salt: salt
        }();
        bytes memory DN404init = abi.encodeWithSelector(
            Management.initialize.selector, 
            vm.addr(key),
            _implementation,
            pricefeed
        );

        Managmentproxy = new ERC1967Proxy(address(Managementimplementation), DN404init);
        
        management = Management(payable(Managmentproxy));
        
        console.log("ManagmentImplementation",address(Managementimplementation));
        console.log("ManagmentProxy",address(Managmentproxy));
        vm.stopBroadcast();

        
    }
}
