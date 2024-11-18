// SPDX-License-Identifier: No License
// Compatible with OpenZeppelin Contracts ^5.0.0
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Context.sol";

contract CertNFT is ERC721, Ownable {
    uint256 private _nextTokenId;

    constructor()
        ERC721("CertNFT", "CRT")
        Ownable(_msgSender())
    {}

    function _baseURI() internal pure override returns (string memory) {
        return "https://ipfs.filebase.io/ipfs/bafybeiems3qujyx3jfgv4ybujwwevbh6z2jw62jyjrrp2varpsb2fbyvhu/";
    }

    function _mintCert(address to) internal {
        uint256 tokenId = _nextTokenId++;
        _safeMint(to, tokenId);
    }

    function tokenURI(uint256 tokenId) override public pure returns (string memory) {
        return string(
        abi.encodePacked(
            _baseURI(),
            Strings.toString(tokenId),
            ".json"
        )
        );
    }
}
