// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

interface IMollectorCard {
    function DNAs(uint) external view returns (uint);
    function ownerOf(uint) external view returns (address);
    function spawn(address _owner, uint256 _dna) external returns (uint);
    function burn(uint256 _tokenId) external;
    function update(uint _tokenId, uint256 _dna) external;
    function link(uint _tokenId, uint256 _nftLinkIndex, uint256 _nftLinkTokenId) external;
    function addLink(uint _network, address _add) external;
    function contractURI() external view returns (string memory);
    function togglePause() external;
    function setBaseURI(string memory _uri) external;
    function setContractURI(string memory _uri) external;
    function addOperator(address _add) external;
    function removeOperator(address _add) external;
}