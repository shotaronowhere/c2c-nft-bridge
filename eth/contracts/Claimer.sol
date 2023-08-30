//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/Create2.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "./IStarknetMessaging.sol";
import "./Escrow721.sol";

struct Commit721 {
    IERC721 token;
    uint256 tokenId;
    uint256 minter; // starknet address to send NFT to
    uint256 nonce;
}

error NotMinter();

/// @dev contract intended to be deployed to L1
contract Claimer {
    bytes32 immutable public escrowBytecodeHash;
    IStarknetMessaging immutable public starknetMessaging; // L2<->L1 messaging contract
    uint256 immutable public gateway; // gateway on starknet

    constructor(IStarknetMessaging _starknetMessaging, uint256 _gateway) {
        starknetMessaging = _starknetMessaging;
        gateway = _gateway;
        escrowBytecodeHash = keccak256(type(Escrow721).creationCode);
    }
    
    function getEscrowAddress(bytes32 commitHash) external view returns (address) {
        return Create2.computeAddress(commitHash, escrowBytecodeHash, address(this));
    }

    /// @dev this is the only codepath that releases NFTs from escrow
    function claimEscrow(
        Commit721 calldata commit,
        uint256[] calldata payload
    ) external {
        // reverts if invalid L2->L1 message
        starknetMessaging.consumeMessageFromL2(gateway, payload);

        // commitHash u256 is split into two u128s
        uint128 low = uint128(payload[0]);
        uint128 high = uint128(payload[1]);
        bytes32 commitHash = bytes32(uint256(low) + (uint256(high) >> 128));

        uint256 minter = payload[2]; // starknet minter
        address claimTo = address(uint160(payload[3]));

        require(getCommitHash(commit) == commitHash, "Invalid commit hash");
        require(commit.minter == minter, "Invalid minter");

        // we expect this step to revert if the NFT is not held in escrow
        new Escrow721{ salt: commitHash }(commit.token, commit.tokenId, claimTo);
    }

    function getCommitHash(Commit721 calldata commit) public pure returns (bytes32) {
        return keccak256(abi.encodePacked(
            commit.token, commit.tokenId, commit.minter, commit.nonce
        ));
    }
}
