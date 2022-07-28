// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@aave/core-v3/contracts/protocol/pool/Pool.sol";
import "./interfaces/IJOERouter.sol";
import "./interfaces/IPoolAave.sol";
import "./interfaces/IPoolPlatypus.sol";
import "./interfaces/IStakePlatypus.sol";
import "./interfaces/IAaveRewards.sol";

interface IWeth {
  function allowance(address owner, address spender) external view returns (uint256 remaining);

  function approve(address spender, uint256 value) external returns (bool success);

  function balanceOf(address owner) external view returns (uint256 balance);

  function decimals() external view returns (uint8 decimalPlaces);

  function name() external view returns (string memory tokenName);

  function symbol() external view returns (string memory tokenSymbol);

  function totalSupply() external view returns (uint256 totalTokensIssued);

  function transfer(address to, uint256 value) external returns (bool success);

  function transferFrom(
    address from,
    address to,
    uint256 value
  ) external returns (bool success);

  function deposit() external payable;

  function withdraw(uint256 wad) external;
}


contract Token is ERC1155, Ownable {


    IWeth wethContract;
    string public name;
    string public symbol;
    uint256 public mintPrice = 1 ether;
    uint256 randNonce=0;
    address[] public participants;
    uint256 lastLottery;
    IJOERouter immutable router;
    uint wethBalance;


    IPoolAave aave;
    address[] aaveRewardsArray = [0xB31f66AA3C1e785363F0875A1B74E27b85FD66c7];
    IAaveRewards aaveRewards;


    //initialize the contract and nft
    constructor() ERC1155("") {
        name = "AAVE Lottery";
        symbol = "LOT";
        Pool aaveDeposit = Pool(0x8f57153F18b7273f9A814b93b31Cb3f9b035e7C2);
        wethContract=IWeth(0x407287b03D1167593AF113d32093942be13A535f);
        router = IJOERouter(0x60aE616a2155Ee3d9A68541Ba4544862310933d4);
        aave = IPoolAave(0x794a61358D6845594F94dc1DB02A252b5b4814aD);
        aaveRewards = IAaveRewards(0x929EC64c34a17401F460460D4B9390518E5B473e); 
    }

    //sell ticket
    function buyTicket(address account, uint256 amount, bytes memory data)
        public
        payable
    {
        require(msg.value>=mintPrice,"You don't have enough ether to mint");
        _mint(account, 1, amount, data);
        getWeth();
        depositToAave();
    }

    //set the mint price
    function setMintPrice(uint256 _mintPrice) public onlyOwner {
        mintPrice = _mintPrice;
    }

    function setURI(string memory newuri) public onlyOwner {
        _setURI(newuri);
    }


    // function mintBatch(address to, uint256[] memory ids, uint256[] memory amounts, bytes memory data)
    //     public
    //     onlyOwner
    // {
    //     _mintBatch(to, ids, amounts, data);
    // }


    //Choose Random Winner
    function randMod(uint256 _modulus) internal returns(uint){
        randNonce++;
        return uint(keccak256(abi.encodePacked(block.timestamp,msg.sender,randNonce)))%_modulus;
    }
    

    //Send to winner total ETH
    function drawWinner()public{
        //waiting period has to expired
        require(block.timestamp>(lastLottery+ 7 days),"waiting period has not expired");
        //set the winner index
        uint256 winnerIndex = randMod(participants.length);
        //claims AaveRewards
        claimAaveRewards();
        //Send to winner all rewards
        wethBalance = wethContract.balanceOf(address(this));
        wethContract.transfer(participants[winnerIndex],wethBalance);
        //set the waiting period
        lastLottery=block.timestamp;
    }

    //swap avax to wavax
     function getWeth() private {
     wethContract.deposit{value:address(this).balance}();
     }
    
    //gets weth balance of contract
     function getWethBalance() public view {
        wethContract.balanceOf(address(this));
     }

    //deposit to aave all weths
    function depositToAave() private {
        wethBalance = wethContract.balanceOf(address(this));
        aave.supply(0x407287b03D1167593AF113d32093942be13A535f, wethBalance, address(this), 0);
    }

    //claims aave rewards
    function claimAaveRewards() private {
        aaveRewards.claimAllRewards(aaveRewardsArray, address(this));
    }

}
