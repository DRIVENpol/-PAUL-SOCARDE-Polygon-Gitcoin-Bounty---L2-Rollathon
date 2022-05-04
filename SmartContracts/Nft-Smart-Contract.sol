// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";

contract NftScCreators is ERC721URIStorage, Ownable {
    using Counters for Counters.Counter;
    Counters.Counter private _tokenIds;

    // URIS
    string public uri100Claps;
    string public uri1000Claps;
    string public uri5000Claps;

    address public minter;

    constructor(
        string memory _uri100Claps,
        string memory _uri1000Claps,
        string memory _uri5000Claps,
        address _minter
    ) ERC721("NFT REWARD FOR CREATORS", "NRFC") {
        uri100Claps = _uri100Claps;
        uri1000Claps = _uri1000Claps;
        uri5000Claps = _uri5000Claps;
        minter = _minter;
    }

    modifier onlyMinter {
        require(msg.sender == minter && msg.sender == owner(), "You are not the minter!");
        _;
    }

    function mintNft(address receiver, uint256 _option) external onlyMinter returns (uint256) {
        _tokenIds.increment();
        string memory tokenURI;
        
        if(_option != 3) {
            if(_option == 2) {
                tokenURI = uri1000Claps;
            } else {
                tokenURI = uri100Claps;
            }
        } else {
            tokenURI = uri5000Claps;
        }

        uint256 newNftTokenId = _tokenIds.current();
        _mint(receiver, newNftTokenId);
        _setTokenURI(newNftTokenId, tokenURI);

        return newNftTokenId;
    }
}

