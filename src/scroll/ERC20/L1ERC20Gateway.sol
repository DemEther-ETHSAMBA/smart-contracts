// SPDX-License-Identifier: MIT

// Although it's possible to use other Solidity versions, we recommend using version 0.8.16 because that's where our contracts were audited
pragma solidity ^0.8.16;

import "@openzeppelin/contracts/access/Ownable.sol";

import { IL2ERC20Gateway } from "./L2/gateways/IL2ERC20Gateway.sol";
import { IL1ScrollMessenger } from "./L1/IL1ScrollMessenger.sol";
import { IL1ERC20Gateway } from "./L1/gateways/IL1ERC20Gateway.sol";

import { ScrollGatewayBase } from "./libraries/gateway/ScrollGatewayBase.sol";
import { L1ERC20Gateway } from "./L1/gateways/L1ERC20Gateway.sol";

// This contract will be used to send and receive tokens from L2
contract L1CustomERC20Gateway is L1ERC20Gateway, Ownable(msg.sender) {
  // Tokens must be mapped to "bind" them to a token that represents the original token on the original. This event will be emitted when the token mapping for ERC20 token is updated.
  event UpdateTokenMapping(address indexed l1Token, address indexed oldL2Token, address indexed newL2Token);

  mapping(address => address) public tokenMapping;

  constructor() {}

  // This function must be called once after both the L1 and L2 contract was deployed
  function initialize(address _counterpart, address _router, address _messenger) external {
    require(_router != address(0), "zero router address");

    ScrollGatewayBase._initialize(_counterpart, _router, _messenger);
  }

  /// This function returns the address of the token on L2
  function getL2ERC20Address(address _l1Token) public view override returns (address) {
    return tokenMapping[_l1Token];
  }

  // Updates the token mapping that "binds" a token with another one on the other chain
  function updateTokenMapping(address _l1Token, address _l2Token) external onlyOwner {
    require(_l2Token != address(0), "token address cannot be 0");

    address _oldL2Token = tokenMapping[_l1Token];
    tokenMapping[_l1Token] = _l2Token;

    emit UpdateTokenMapping(_l1Token, _oldL2Token, _l2Token);
  }

  // Callback called before a token is withdrawn on L1
  function _beforeFinalizeWithdrawERC20(
    address _l1Token,
    address _l2Token,
    address,
    address,
    uint256,
    bytes calldata
  ) internal virtual override {
    require(msg.value == 0, "nonzero msg.value");
    require(_l2Token != address(0), "token address cannot be 0");
    require(_l2Token == tokenMapping[_l1Token], "l2 token mismatch");
  }

  // Token bridged can be "canceled" or dropped. This callback is called before that happens.
  function _beforeDropMessage(address, address, uint256) internal virtual override {
    require(msg.value == 0, "nonzero msg.value");
  }

  // Internal function holding the deposit logic
  function _deposit(
    address _token,
    address _to,
    uint256 _amount,
    bytes memory _data,
    uint256 _gasLimit
  ) internal virtual override  {
    address _l2Token = tokenMapping[_token];
    require(_l2Token != address(0), "no corresponding l2 token");

    // 1. Transfer token into this contract.
    address _from;
    (_from, _amount, _data) = _transferERC20In(_token, _amount, _data);

    // 2. Generate message passed to L2CustomERC20Gateway.
    bytes memory _message = abi.encodeCall(
      IL2ERC20Gateway.finalizeDepositERC20,
      (_token, _l2Token, _from, _to, _amount, _data)
    );

    // 3. Send message to L1ScrollMessenger.
    IL1ScrollMessenger(messenger).sendMessage{ value: msg.value }(counterpart, 0, _message, _gasLimit, _from);

    emit DepositERC20(_token, _l2Token, _from, _to, _amount, _data);
  }
}