// SPDX-License-Identifier: MIT
pragma solidity 0.8.23;

/// -----------------------------------------------------------------------
/// Imports
/// -----------------------------------------------------------------------

import {Test, console} from "forge-std/Test.sol";
import {StdCheats} from "forge-std/StdCheats.sol";

import {Management} from "../src/Management.sol";
import {HelperConfig} from "../script/HelperConfig.s.sol";
import {ERC1967Proxy} from "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";
import {DN404Upgradeable} from "../src/DN404Upgradeable.sol";

/// -----------------------------------------------------------------------
/// Contract (test)
/// -----------------------------------------------------------------------

/**
 * @title Management smart contract unit test.
 * @author Eduardo W. da Cunha (@EWCunha).
 */
contract ManagementTest is StdCheats, Test {
    /// -----------------------------------------------------------------------
    /// Test variables
    /// -----------------------------------------------------------------------

    Management public management;
    HelperConfig public config;
    DN404Upgradeable public token;

    address public owner = makeAddr("owner");
    address public backend = makeAddr("backend");
    address public tbaAddress = makeAddr("tbaAddress");
    address public signer;
    uint256 public constant UPDATE_INTERVAL = 10;

    string name_ = "ETH_SAMBA";
    string symbol_ = "DN404SAMBA";
    uint96 initialTokenSupply = 100000000e18;
    address initialSupplyOwner = makeAddr("initialSupplyOwner");
    uint updateInterval = 10; //seconds
    address priceFeed = 0x4b7360Be27A6E5891c211B78A50987395B39F3bC; //0x965a8e45E282da1AE5275392e3D408CB21f0F7Af;
    //address scrollpricefeed = 0x1E3b98102e19D3a164d239BdD190913C2F02E756;
    string[] SafraMedium = [
        "https://ipfs.io/ipfs/QmWYLkVwHR29GzYXQzZfAnvjNFQtWs2QGJSxEHspgr71YL"
    ];

    address public user = makeAddr("user");

    /// -----------------------------------------------------------------------
    /// Test setup
    /// -----------------------------------------------------------------------

    function setUp() public {
        config = new HelperConfig();
        uint256 key = config.activeNetworkConfig();

        signer = vm.rememberKey(key);
        vm.startBroadcast(signer);

        token = new DN404Upgradeable();

        bytes memory init = abi.encodeWithSelector(
            Management.initialize.selector,
            owner,
            address(token),
            priceFeed
        );
        Management managementImplementation = new Management();
        ERC1967Proxy proxy = new ERC1967Proxy(
            address(managementImplementation),
            init
        );
        management = Management(payable(proxy));

        vm.stopBroadcast();
    }

    function testAddress() public {
        bytes memory data = abi.encodeWithSelector(
            DN404Upgradeable.initialize.selector,
            address(management),
            owner,
            name_,
            symbol_,
            initialTokenSupply,
            initialSupplyOwner,
            UPDATE_INTERVAL,
            priceFeed
        );
        uint256 nonce = management.nonce(tbaAddress);
        bytes32 salt = keccak256(abi.encode(tbaAddress, nonce));
        address predicted = management.getAddress(salt, data);

        address actual = management.deployDN404(
            owner,
            name_,
            symbol_,
            initialTokenSupply,
            initialSupplyOwner,
            tbaAddress
        );

        console.log(
            actual,
            DN404Upgradeable(payable(actual)).owner(),
            owner,
            address(management)
        );

        assertEq(predicted, actual);
    }
}
