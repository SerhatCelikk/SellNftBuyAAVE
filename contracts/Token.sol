// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract Token is ERC1155, Ownable {
    string public name;
    string public symbol;
    uint256 public mintPrice = 1 ether;
    uint256 randNonce=0;
    address[] public particapants;
    uint256 lastLottery;

    constructor() ERC1155("") {
        name = "AAVE Lottery";
        symbol = "LOT";
    }

    function setMintPrice(uint256 _mintPrice) public onlyOwner {
        mintPrice = _mintPrice;
    }

    function setURI(string memory newuri) public onlyOwner {
        _setURI(newuri);
    }

    function mint(address account, uint256 amount, bytes memory data)
        public
        payable
    {
        require(msg.value>=mintPrice,"You don't have enough ether to mint");
        _mint(account, 1, amount, data);
    }

    function mintBatch(address to, uint256[] memory ids, uint256[] memory amounts, bytes memory data)
        public
        onlyOwner
    {
        _mintBatch(to, ids, amounts, data);
    }

    function buyAAVE() public {
    }

    function randMod(uint256 _modulus) internal returns(uint){
        randNonce++;
        return uint(keccak256(abi.encodePacked(block.timestamp,msg.sender,randNonce)))%_modulus;
    }
    
    function drawWinner()public{
        require(block.timestamp>(lastLottery+ 7 days),"waiting period has not expired");
        uint256 winnerIndex = randMod(particapants.length);
        payable(particapants[winnerIndex]).transfer(address(this).balance);
        lastLottery=block.timestamp;
    }

    
}
