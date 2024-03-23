//SPDX-License-Identifier: MIT
pragma solidity 0.8.23;

/// -----------------------------------------------------------------------
/// Imports
/// -----------------------------------------------------------------------

//  ==========  External imports    ==========

import { IERC6551Account } from "@ERC6551/interfaces/IERC6551Account.sol";
import { IERC6551Executable } from "@ERC6551/interfaces/IERC6551Executable.sol";
import { IERC721 } from "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import { IERC1155 } from "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import { IERC1271 } from "@openzeppelin/contracts/interfaces/IERC1271.sol";

//  ==========  Internal imports    ==========

import { TokenCallbackHandler } from "./TokenCallbackHandler.sol";

/// -----------------------------------------------------------------------
/// Contract
/// -----------------------------------------------------------------------

/**
 * @title ERC-6551 token bound account (TBA) implementation.
 * @author Lumx (Eduardo W. da Cunha - @EWCunha).
 * @notice Simple implementation of the ERC-6551 standard.
 * @dev {TokenCallbackHandler} smart contract is used to allow this TBA to own
 * different tokens (ERC-20, ERC-721, and ERC-1155).
 */
contract ERC6551Account is IERC6551Account, IERC6551Executable, TokenCallbackHandler {
    /// -----------------------------------------------------------------------
    /// Custom errors
    /// -----------------------------------------------------------------------

    /**
     * @dev Error for when caller is not owner.
     * @param caller: address from the function caller.
     */
    error ERC6551Account__CallerNotOwner(address caller);

    /**
     * @dev Error for when an invalid operation is given in `execute` function.
     * @param operation: operation ID.
     */
    error ERC6551Account__InvalidOperation(uint8 operation);

    /// -----------------------------------------------------------------------
    /// State variables
    /// -----------------------------------------------------------------------

    /* solhint-disable-next-line var-name-mixedcase */
    uint256 private s_nonce;

    /// -----------------------------------------------------------------------
    /// Fallback/receive functions
    /// -----------------------------------------------------------------------

    /* solhint-disable-next-line no-empty-blocks */
    receive() external payable {}

    /// -----------------------------------------------------------------------
    /// State-change public/external functions
    /// -----------------------------------------------------------------------

    /**
     * @notice Executes the operation specified by the `operation` parameter.
     * @dev Supported operations:
     * - 0 (CALL)
     * @param to: address to which the operation will be sent.
     * @param value: value of native currency to send along with the operation.
     * @param data: data to be sent along with the operation. Used mainly to call
     * functions in a smart contract.
     * @param operation: operation specifier.
     * @return bytes of the returned data from the operation.
     */
    function execute(
        address to,
        uint256 value,
        bytes calldata data,
        uint8 operation
    ) external payable override(IERC6551Executable) returns (bytes memory) {
        if (!_isValidSigner(msg.sender)) {
            revert ERC6551Account__CallerNotOwner(msg.sender);
        }
        if (operation != 0) {
            revert ERC6551Account__InvalidOperation(operation);
        }

        unchecked {
            ++s_nonce;
        }

        (bool success, bytes memory result) = to.call{ value: value }(data);

        if (!success) {
            /* solhint-disable-next-line no-inline-assembly */
            assembly {
                revert(add(result, 32), mload(result))
            }
        }

        return result;
    }

    /// -----------------------------------------------------------------------
    /// View internal/private functions
    /// -----------------------------------------------------------------------

    /**
     * @dev Checks if given signers address is valid.
     * @param signer: address of the transaction signer.
     * @return boolen: true if valid, false otherwise.
     */
    function _isValidSigner(address signer) internal view returns (bool) {
        return signer == owner();
    }

    /// -----------------------------------------------------------------------
    /// View public/external functions
    /// -----------------------------------------------------------------------

    /**
     * @notice Reads the main information of the token
     * used to create this TBA.
     * @return chainId uint256 value for the chain ID; tokenContract address of the token smart contract;
     * and tokenId uint256 value for the token ID.
     */
    function token()
        public
        view
        override(IERC6551Account)
        returns (uint256 chainId, address tokenContract, uint256 tokenId)
    {
        bytes memory footer = new bytes(0x60);

        /* solhint-disable-next-line no-inline-assembly */
        assembly {
            extcodecopy(address(), add(footer, 0x20), 0x4d, 0x60)
        }

        return abi.decode(footer, (uint256, address, uint256));
    }

    /**
     * @notice Returns the current state of the TBA. In other words,
     * reads the s_nonce storage variable.
     * @return uint256 value for the current nonce.
     */
    function state() external view override(IERC6551Account) returns (uint256) {
        return s_nonce;
    }

    /**
     * @notice Gets the current owner of the token used to create this TBA.
     * @return address of the current owner.
     */
    function owner() public view returns (address) {
        (uint256 chainid, address tokenContract, uint256 tokenId) = token();
        if (chainid != block.chainid) return address(0);

        bytes memory funCall = abi.encodeWithSignature("ownerOf(uint256)", tokenId);
        (bool success, bytes memory result) = tokenContract.staticcall(funCall);
        if (!success) {
            /* solhint-disable-next-line no-inline-assembly */
            assembly {
                revert(add(result, 32), mload(result))
            }
        }

        return abi.decode(result, (address));
    }

    /**
     * @notice Checks if transaction signer is valid.
     * @dev Currently, a very simple implementation is being used. No context or actual
     * signature is used to verify the signer.
     * @return a magic value that specifies if signer is valid or not.
     */
    function isValidSigner(
        address signer,
        bytes calldata /* context */
    ) external view override(IERC6551Account) returns (bytes4 /* magicValue */) {
        if (_isValidSigner(signer)) {
            return IERC1271.isValidSignature.selector;
        }

        return bytes4(0);
    }

    /**
     * @notice Returns a valid interface ID for this smart contract.
     * @param interfaceId: 4 bytes that specifies the interface ID to be checked.
     * @return boolean: true if given interface is supported, false otherwise.
     */
    function supportsInterface(bytes4 interfaceId) external view virtual override(TokenCallbackHandler) returns (bool) {
        return
            interfaceId == type(IERC721).interfaceId ||
            interfaceId == type(IERC1155).interfaceId ||
            interfaceId == type(IERC6551Account).interfaceId ||
            interfaceId == type(IERC6551Executable).interfaceId ||
            TokenCallbackHandler._supportsInterface(interfaceId);
    }
}
