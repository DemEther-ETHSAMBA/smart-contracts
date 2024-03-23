// SPDX-License-Identifier: MIT
pragma solidity 0.8.23;

/// -----------------------------------------------------------------------
/// Imports
/// -----------------------------------------------------------------------

import { Test, console } from "forge-std/Test.sol";
import { StdCheats } from "forge-std/StdCheats.sol";

import { DN404Upgradeable } from "../../../src/DN404Upgradeable.sol";
import { IPriceSafraAgregadorV3 } from "../../../src/chainlink/IPriceSafraAgregadorV3.sol";
import { HelperConfig } from "../../../script/HelperConfig.s.sol";
import { ERC1967Proxy } from "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";

/// -----------------------------------------------------------------------
/// Contract (fixture)
/// -----------------------------------------------------------------------

/**
 * @title DN404Upgradeable smart contract fixture.
 * @author Eduardo W. da Cunha (@EWCunha).
 * @dev Used to test internal/private functions.
 */
contract DN404UpgradeableFixture is DN404Upgradeable {
    function authorizeUpgradeInternal() external view {
        _authorizeUpgrade(address(0));
    }

    receive() external payable override {}
}

/// -----------------------------------------------------------------------
/// Contract (test)
/// -----------------------------------------------------------------------

/**
 * @title DN404Upgradeable smart contract unit test.
 * @author Eduardo W. da Cunha (@EWCunha).
 */
contract DN404UpgradeableTest is StdCheats, Test {
    /// -----------------------------------------------------------------------
    /// Test variables
    /// -----------------------------------------------------------------------

    DN404Upgradeable public token;
    //DN404UpgradeableFixture public tokenFixture;

    HelperConfig public config;

    address public owner = makeAddr("owner");
    address public backend = makeAddr("backend");

    string  name_= "ETH_SAMBA";
    string  symbol_= "DN404SAMBA";
    uint96 initialTokenSupply = 100000000e18;
    address initialSupplyOwner;
    uint updateInterval = 10;//seconds
    address _priceFeed = 0x965a8e45E282da1AE5275392e3D408CB21f0F7Af;
    //address scrollpricefeed = 0x1E3b98102e19D3a164d239BdD190913C2F02E756;
    string[] SafraMedium = [
        "https://ipfs.io/ipfs/QmWYLkVwHR29GzYXQzZfAnvjNFQtWs2QGJSxEHspgr71YL"
    ];

    address public user = makeAddr("user");

    /// -----------------------------------------------------------------------
    /// Test setup
    /// -----------------------------------------------------------------------

    function setUp() public {
        vm.startPrank(owner);
    
        bytes memory init = abi.encodeWithSelector(
            DN404Upgradeable.initialize.selector,
           owner, name_, symbol_, initialTokenSupply, owner,
            updateInterval, _priceFeed
        );

        // contract
        DN404Upgradeable tokenImplementation = new DN404Upgradeable();
        ERC1967Proxy proxy = new ERC1967Proxy(address(tokenImplementation), init);
        token = DN404Upgradeable(payable(proxy));

        // fixture
        // DN404UpgradeableFixture tokenImplementationFixture = new DN404UpgradeableFixture();
        // ERC1967Proxy proxyFixture = new ERC1967Proxy(address(tokenImplementationFixture), init);
        // tokenFixture = DN404UpgradeableFixture(payable(proxyFixture));

        vm.stopPrank();

    }

    /// -----------------------------------------------------------------------
    /// Internal functions
    /// -----------------------------------------------------------------------

    //  ==========  _authorizeUpgrade  ==========

    

    /// -----------------------------------------------------------------------
    /// Public/external functions
    /// -----------------------------------------------------------------------

    //  ==========  initialize  ==========

    
    

    //  ==========  mint  ==========

    function testMintSuccess() public {
        uint256 amount = 1 ether;
        uint256 balanceOfBefore = token.balanceOf(user);

        vm.prank(owner);
        token.mint(user, amount);

        uint256 balanceOfAfter = token.balanceOf(user);

        assertEq(balanceOfBefore, 0);
        assertEq(balanceOfAfter, amount);
    }


    //  ==========  withdraw  ==========

    // function testWithdrawSuccess() public {
    //     vm.deal(address(this), 1 ether);
    //     uint256 transferAmount = 0.5 ether;
    //     uint256 balanceBefore = owner.balance;

    //     // @solidity disable-next-line
    //     (bool a, ) = payable(tokenFixture).call{ value: transferAmount }("");
    //     a;

    //     vm.prank(owner);
    //     tokenFixture.withdraw();

    //     uint256 balanceAfter = owner.balance;

    //     assertEq(balanceBefore, 0);
    //     assertEq(balanceAfter, transferAmount);
    // }

    //  ==========  name  ==========

    //  ==========  tokenURI  ==========

    function testTokenURI() public {
        string memory baseURI = "baseURI";



        vm.prank(owner);
        token.setBaseURI(baseURI);

        assertEq(token.tokenURI(0), string(abi.encodePacked(baseURI)));
    }

    //  ==========  getBaseURI  ==========

    function testGetBaseURI() public {
        string memory baseURI = "baseURI";

        vm.prank(owner);
        token.setBaseURI(baseURI);

        assertEq(token.getBaseURI(), baseURI);
    }

    function test_upkeep() public {
        console.log("Previous URI: ", token.getBaseURI());
        console.log("Safra medium URI: ", token.SafraMedium());
        IPriceSafraAgregadorV3(_priceFeed).updateAnswer(int256(10));
        token.performUpkeep(abi.encode(""));
        vm.warp(block.timestamp + 40);
        IPriceSafraAgregadorV3(_priceFeed).updateAnswer(int256(13));
        token.performUpkeep(abi.encode(""));
        console.log("Safra hype URI: ", token.SafraHype());
        console.log("Post URI: ", token.getBaseURI());
    }

    
}