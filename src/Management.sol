//SPDX-License-Identifier: MIT
pragma solidity 0.8.23;

/// -----------------------------------------------------------------------
/// Imports
/// -----------------------------------------------------------------------

//  ==========  External imports  ==========

import { UUPSUpgradeable } from "@openzeppelin/contracts/proxy/utils/UUPSUpgradeable.sol";
import { ERC1967Proxy } from "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";

//  ==========  Internal imports  ==========

import { SecurityUpgradeable } from "./SecurityUpgradeable.sol";
import { DN404Upgradeable } from "./DN404Upgradeable.sol";

//deploy your Oracle With Chainlink Aggregator
import { MockV3Aggregator } from "./chainlink/MockV3Aggregator.sol";

/// -----------------------------------------------------------------------
/// Contract
/// -----------------------------------------------------------------------

/**
 * @title Management contract.
 * @author Eduardo W. da Cunha (@EWCunha).
 */
contract Management is SecurityUpgradeable, UUPSUpgradeable {
    event DeployedDN404(address indexed deployer, address indexed _contract);

    event DeployedOracle(address indexed deployer, address indexed _contract);

    /**
     * @notice Intializes the function.
     * @param owner_: address of the owner of the contract
     */
    function initialize(address owner_) external initializer {
        __Security_init(owner_);
    }

    function deployDN404(
        address owner_,
        string memory name_,
        string memory symbol_,
        uint96 initialTokenSupply,
        address initialSupplyOwner
    ) external {
        _checkPermission(msg.sender);

        bytes memory data = abi.encodeWithSelector(
            DN404Upgradeable.initialize.selector,
            owner_,
            name_,
            symbol_,
            initialTokenSupply,
            initialSupplyOwner
        );

        DN404Upgradeable dn404 = new DN404Upgradeable();
        ERC1967Proxy proxy = new ERC1967Proxy(address(dn404), data);

        emit DeployedDN404(msg.sender, address(proxy));
    }

    function deployOracle(
        uint8 _decimals,
        int256 _initialAnswer
    ) external {
        _checkPermission(msg.sender);

        MockV3Aggregator oracle = new MockV3Aggregator(_decimals,_initialAnswer);

        emit DeployedOracle(msg.sender, address(oracle));
    }


    function _authorizeUpgrade(address /* newImplementation */) internal view override(UUPSUpgradeable) {
        __onlyOwner();
    }
}
