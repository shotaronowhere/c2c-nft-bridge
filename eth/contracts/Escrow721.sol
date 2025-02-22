//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";

contract Escrow721 {
    constructor(IERC721 token, uint256 tokenId, address to) {
        token.transferFrom(address(this), to, tokenId);
        selfdestruct(payable(address(0)));
    }
}
