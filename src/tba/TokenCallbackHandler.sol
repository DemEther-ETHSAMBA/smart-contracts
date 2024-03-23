// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.23;


/// -----------------------------------------------------------------------
/// Imports
/// -----------------------------------------------------------------------

//  ==========  External imports    ==========

import { IERC165 } from "@openzeppelin/contracts/utils/introspection/IERC165.sol";
import { IERC777Recipient } from "@openzeppelin/contracts/interfaces/IERC777Recipient.sol";
import { IERC721Receiver } from "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import { IERC1155Receiver } from "@openzeppelin/contracts/token/ERC1155/IERC1155Receiver.sol";

/// -----------------------------------------------------------------------
/// Contract
/// -----------------------------------------------------------------------

/**
 * @title Token callback handler.
 * @author Omnes Tech (Eduardo W. da Cunha - @EWCunha).
 * @notice Handles supported tokens callbacks, allowing account receiving these tokens.
 */
contract TokenCallbackHandler is IERC777Recipient, IERC721Receiver, IERC1155Receiver {
    /* solhint-disable no-empty-blocks */

    /// -----------------------------------------------------------------------
    /// View public/external functions
    /// -----------------------------------------------------------------------

    //  ==========  ERC777Recipient    ==========

    /// @inheritdoc IERC777Recipient
    function tokensReceived(
        address,
        address,
        address,
        uint256,
        bytes calldata,
        bytes calldata
    )
        external
        pure
        override(IERC777Recipient)
    { }

    //  ==========  ERC721Receiver    ==========

    /// @inheritdoc IERC721Receiver
    function onERC721Received(
        address,
        address,
        uint256,
        bytes calldata
    )
        external
        pure
        override(IERC721Receiver)
        returns (bytes4)
    {
        return IERC721Receiver.onERC721Received.selector;
    }

    //  ==========  ERC1155Receiver    ==========

    /// @inheritdoc IERC1155Receiver
    function onERC1155Received(
        address,
        address,
        uint256,
        uint256,
        bytes calldata
    )
        external
        pure
        override(IERC1155Receiver)
        returns (bytes4)
    {
        return IERC1155Receiver.onERC1155Received.selector;
    }

    /// @inheritdoc IERC1155Receiver
    function onERC1155BatchReceived(
        address,
        address,
        uint256[] calldata,
        uint256[] calldata,
        bytes calldata
    )
        external
        pure
        override(IERC1155Receiver)
        returns (bytes4)
    {
        return IERC1155Receiver.onERC1155BatchReceived.selector;
    }

    //  ==========  ERC165    ==========

    /// @inheritdoc IERC165
    function supportsInterface(bytes4 interfaceId) external view virtual override(IERC165) returns (bool) {
        return _supportsInterface(interfaceId);
    }

    /// -----------------------------------------------------------------------
    /// View internal/private functions
    /// -----------------------------------------------------------------------

    /**
     * @dev Internal function to check if the given interface ID is supported.
     * @param interfaceId: interface ID of this standard.
     * @return bool: true if the given interface ID is supported, false otherwise.
     */
    function _supportsInterface(bytes4 interfaceId) internal view virtual returns (bool) {
        return interfaceId == type(IERC721Receiver).interfaceId || interfaceId == type(IERC1155Receiver).interfaceId
            || interfaceId == type(IERC777Recipient).interfaceId || interfaceId == type(IERC165).interfaceId;
    }
}
