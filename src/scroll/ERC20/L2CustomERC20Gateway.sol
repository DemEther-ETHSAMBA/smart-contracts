// SPDX-License-Identifier: MIT

pragma solidity ^0.8.16;

import "@openzeppelin/contracts/access/Ownable.sol";

import "./L2/gateways/L2ERC20Gateway.sol";
import { IL2ScrollMessenger } from "./L2/IL2ScrollMessenger.sol";
import { IL1ERC20Gateway } from "./L1/gateways/IL1ERC20Gateway.sol";
import { ScrollGatewayBase } from "./libraries/gateway/ScrollGatewayBase.sol";
import "./libraries/token/IScrollERC20Extension.sol";

import { IL2ERC20Gateway } from "./L2/gateways/IL2ERC20Gateway.sol";

// This contract will be used to send and receive tokens from L1
contract L2CustomERC20Gateway is L2ERC20Gateway, ScrollGatewayBase, Ownable(msg.sender) {
  event UpdateTokenMapping(address indexed l2Token, address indexed oldL1Token, address indexed newL1Token);

  // solhint-disable-next-line var-name-mixedcase
  mapping(address => address) public tokenMapping;

  constructor() {}

  // Like with the L1 version of the Gateway, this must be called once after both the L1 and L2 gateways are deployed
  function initialize(address _counterpart, address _router, address _messenger) external {
    require(_router != address(0), "zero router address");

    ScrollGatewayBase._initialize(_counterpart, _router, _messenger);
  }

  /// Returns the address of the token representing the token on L2
  function getL1ERC20Address(address _l2Token) external view override returns (address) {
    return tokenMapping[_l2Token];
  }

  // This returns the L2 token address
  function getL2ERC20Address(address) public pure override returns (address) {
    revert("unimplemented");
  }

  // This function finalizes the token deposit on L2 when the deposit was not finalized due to not enough gas sent from L1
  function finalizeDepositERC20(
    address _l1Token,
    address _l2Token,
    address _from,
    address _to,
    uint256 _amount,
    bytes calldata _data
  ) external payable override onlyCallByCounterpart  {
    require(msg.value == 0, "nonzero msg.value");
    require(_l1Token != address(0), "token address cannot be 0");
    require(_l1Token == tokenMapping[_l2Token], "l1 token mismatch");

    IScrollERC20Extension(_l2Token).mint(_to, _amount);

    _doCallback(_to, _data);

    emit FinalizeDepositERC20(_l1Token, _l2Token, _from, _to, _amount, _data);
  }

  // Same as in the L1 version of this contract, this function "binds" a token with a token on the other chain
  function updateTokenMapping(address _l2Token, address _l1Token) external onlyOwner {
    require(_l1Token != address(0), "token address cannot be 0");

    address _oldL1Token = tokenMapping[_l2Token];
    tokenMapping[_l2Token] = _l1Token;

    emit UpdateTokenMapping(_l2Token, _oldL1Token, _l1Token);
  }

  // Internal function holding the withdraw logic
  function _withdraw(
    address _token,
    address _to,
    uint256 _amount,
    bytes memory _data,
    uint256 _gasLimit
  ) internal virtual override  {
    address _l1Token = tokenMapping[_token];
    require(_l1Token != address(0), "no corresponding l1 token");

    require(_amount > 0, "withdraw zero amount");

    // 1. Extract real sender if this call is from L2GatewayRouter.
    address _from = msg.sender;
    if (router == msg.sender) {
      (_from, _data) = abi.decode(_data, (address, bytes));
    }

    // 2. Burn token.
    IScrollERC20Extension(_token).burn(_from, _amount);

    // 3. Generate message passed to L1StandardERC20Gateway.
    bytes memory _message = abi.encodeCall(
      IL1ERC20Gateway.finalizeWithdrawERC20,
      (_l1Token, _token, _from, _to, _amount, _data)
    );

    // 4. send message to L2ScrollMessenger
    IL2ScrollMessenger(messenger).sendMessage{ value: msg.value }(counterpart, 0, _message, _gasLimit);

    emit WithdrawERC20(_l1Token, _token, _from, _to, _amount, _data);
  }
}