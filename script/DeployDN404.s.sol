// SPDX-License-Identifier: MIT
pragma solidity 0.8.23;

import {Script, console} from "forge-std/Script.sol";
import {HelperConfig} from "./HelperConfig.s.sol";

//  ==========  Smart contract imports  ==========

import {DN404Upgradeable} from "../src/DN404Upgradeable.sol";
import {ERC1967Proxy} from "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";

/// -----------------------------------------------------------------------
/// Script
/// -----------------------------------------------------------------------

contract DeployDN404 is Script {
    HelperConfig public config;

    //DN404Upgradeable public DN404implementation;
    DN404Upgradeable public DN404;
    ERC1967Proxy public DN404proxy;

    address owner_;
    string name_ = "ETH_SAMBA";
    string symbol_ = "DN404SAMBA";
    uint96 initialTokenSupply = 100000000e18;
    address initialSupplyOwner;
    uint updateInterval = 10; //seconds
    address _priceFeed = 0x965a8e45E282da1AE5275392e3D408CB21f0F7Af;
    //address scrollpricefeed = 0x1E3b98102e19D3a164d239BdD190913C2F02E756;
    string[] SafraMedium = [
        "https://ipfs.io/ipfs/QmWYLkVwHR29GzYXQzZfAnvjNFQtWs2QGJSxEHspgr71YL"
    ];

    bytes32 salt = bytes32("Demether");

    function run() public {
        config = new HelperConfig();

        uint256 key = config.activeNetworkConfig();

        vm.startBroadcast(vm.rememberKey(key));

        DN404Upgradeable DN404implementation = new DN404Upgradeable{
            salt: salt
        }();
        bytes memory DN404init = abi.encodeWithSelector(
            DN404Upgradeable.initialize.selector,
            vm.addr(key),
            name_,
            symbol_,
            initialTokenSupply,
            vm.addr(key),
            updateInterval,
            _priceFeed
        );

        DN404proxy = new ERC1967Proxy(address(DN404implementation), DN404init);
        //https://ipfs.io/ipfs/QmTXGUE8ciatzL1epqZTQRDDpzCXQSksQndQnaATfT9ATN5

        DN404 = DN404Upgradeable(payable(DN404proxy));
        DN404.setBaseURI(
            "https://ipfs.io/ipfs/QmWYLkVwHR29GzYXQzZfAnvjNFQtWs2QGJSxEHspgr71YL"
        );

        console.log("DN404", address(DN404implementation));
        console.log("Proxy", address(DN404proxy));
        vm.stopBroadcast();
    }
}
