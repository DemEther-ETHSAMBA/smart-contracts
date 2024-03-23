//SPDX-License-Identifier: MIT
pragma solidity 0.8.23;

/// -----------------------------------------------------------------------
/// Imports
/// -----------------------------------------------------------------------

//  ==========  External imports  ==========

import {Create2} from "@openzeppelin/contracts/utils/Create2.sol";
import {UUPSUpgradeable} from "@openzeppelin/contracts/proxy/utils/UUPSUpgradeable.sol";
import {ERC1967Proxy} from "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";

//  ==========  Internal imports  ==========

import {SecurityUpgradeable} from "./SecurityUpgradeable.sol";
import {DN404Upgradeable} from "./DN404Upgradeable.sol";

//deploy your Oracle With Chainlink Aggregator
//import { MockV3Aggregator } from "./chainlink/MockV3Aggregator.sol";

/// -----------------------------------------------------------------------
/// Contract
/// -----------------------------------------------------------------------

/**
 * @title Management contract.
 * @author Eduardo W. da Cunha (@EWCunha).
 */
contract Management is SecurityUpgradeable, UUPSUpgradeable {
    event DeployedDN404(address indexed deployer, address indexed _contract);

    event ChangeImplementation(address indexed _old, address indexed _new);

    //event DeployedOracle(address indexed deployer, address indexed _contract);

    event DeployedL2TokenBridge(
        address indexed deployer,
        address indexed _contract
    );

    address public implementation;
    mapping(address => uint256) public nonce;
    address public priceFeed;
    uint256 public constant UPDATE_INTERVAL = 10;

    /**
     * @notice Intializes the function.
     * @param owner_: address of the owner of the contract
     */
    // function initialize (address owner_, address _implementation) external onlyInitializing{
    //     __Security_init(owner_);
    //     implementation = _implementation;
    //     emit ChangeImplementation(address(0), _implementation);
    // }
    function initialize(
        address owner_,
        address _implementation,
        address _priceFeed
    ) external initializer {
        __Security_init(owner_);
        implementation = _implementation;
        priceFeed = _priceFeed;
        emit ChangeImplementation(address(0), _implementation);
    }

    function deployDN404(
        address owner_,
        string memory name_,
        string memory symbol_,
        uint96 initialTokenSupply,
        address initialSupplyOwner,
        address tbaAddress
    ) external returns (address) {
        bytes memory data = abi.encodeWithSelector(
            DN404Upgradeable.initialize.selector,
            address(this),
            owner_,
            name_,
            symbol_,
            initialTokenSupply,
            initialSupplyOwner,
            UPDATE_INTERVAL,
            priceFeed
        );
        bytes32 salt = keccak256(abi.encode(tbaAddress, nonce[tbaAddress]));

        address addr = getAddress(salt, data);
        if (addr.code.length > 0) {
            return addr;
        }

        ERC1967Proxy proxy = new ERC1967Proxy{salt: salt}(implementation, data);
        nonce[tbaAddress]++;

        emit DeployedDN404(msg.sender, address(proxy));

        return address(proxy);
    }

    function changeImplementation(address _implementation) public onlyOwner {
        emit ChangeImplementation(implementation, _implementation);

        implementation = _implementation;
    }

    // function deployOracle(
    //     uint8 _decimals,
    //     int256 _initialAnswer
    // ) external {

    //     MockV3Aggregator oracle = new MockV3Aggregator(_decimals,_initialAnswer);

    //     emit DeployedOracle(msg.sender, address(oracle));
    // }

    function _authorizeUpgrade(
        address /* newImplementation */
    ) internal view override(UUPSUpgradeable) {
        __onlyOwner();
    }

    function getAddress(
        bytes32 salt,
        bytes memory dataCall
    ) public view returns (address) {
        return
            Create2.computeAddress(
                salt,
                keccak256(
                    abi.encodePacked(
                        type(ERC1967Proxy).creationCode,
                        abi.encode(implementation, dataCall)
                    )
                )
            );
    }
}
