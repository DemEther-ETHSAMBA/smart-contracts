// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;


import { DN404 } from "@DN404/src/DN404.sol";
import { DN404Mirror } from "@DN404/src/DN404Mirror.sol";
import { LibString } from "@DN404/lib/solady/src/utils/LibString.sol";
import { SafeTransferLib } from "@DN404/lib/solady/src/utils/SafeTransferLib.sol";
import { UUPSUpgradeable } from "@openzeppelin/contracts/proxy/utils/UUPSUpgradeable.sol";

import "./scroll/ERC20/IScrollERC20Extension.sol";
import { SecurityUpgradeable } from "./SecurityUpgradeable.sol";


contract L2TokenBridge is DN404, IScrollERC20Extension, SecurityUpgradeable {
  // We store the gateway and the L1 token address to provide the gateway() and counterpart() functions which are needed from the Scroll Standard ERC20 interface
  address _gateway;
  address _counterpart;
  string private _name;
    string private _symbol;
    string private _baseURI;

  // In the constructor we pass as parameter the Custom L2 Gateway and the L1 token address as parameters
  constructor(address gateway_, 
  address counterpart_, 
  string memory name_,
  string memory symbol_,
  uint96 initialTokenSupply,
  address initialSupplyOwner,
  address owner_) {
    _gateway = gateway_;
    _counterpart = counterpart_;
    __Security_init(owner_);

        _name = name_;
        _symbol = symbol_;

        address mirror = address(new DN404Mirror(owner_));
        _initializeDN404(initialTokenSupply, initialSupplyOwner, mirror);
  }

  function gateway() public view returns (address) {
    return _gateway;
  }

  function counterpart() external view returns (address) {
    return _counterpart;
  }

  // We allow minting only to the Gateway so it can mint new tokens when bridged from L1
  function transferAndCall(address receiver, uint256 amount, bytes calldata data) external returns (bool success) {
    transfer(receiver, amount);
    data;
    return true;
  }

  // We allow minting only to the Gateway so it can mint new tokens when bridged from L1
  function mint(address _to, uint256 _amount) external onlyGateway {
    _mint(_to, _amount);
  }

  // Similarly to minting, the Gateway is able to burn tokens when bridged from L2 to L1
  function burn(address _from, uint256 _amount) external onlyGateway {
    _burn(_from, _amount);
  }

  modifier onlyGateway() {
    require(gateway() == msg.sender, "Ownable: caller is not the gateway");
    _;
  }

    function name() public view override returns (string memory) {
        return _name;
    }

    function symbol() public view override returns (string memory) {
        return _symbol;
    }

    function tokenURI(uint256 tokenId) public view override(DN404) returns (string memory result) {
        result = string(abi.encodePacked(_baseURI, LibString.toString(tokenId)));//insert ".json" ;
    }

    function withdraw() public onlyOwner {
        SafeTransferLib.safeTransferAllETH(msg.sender);
    }
}