// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@aave/core-v3/contracts/protocol/pool/Pool.sol";
// import "./interfaces/ILendingPool.sol";
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

error StableHedge__WrongPath(address[] wrongPath);
error StableHedge__NotEnoughBalance();

contract Token is ERC1155, Ownable {

    uint256 constant USDC_RATIO = 100;

    // IWeth wethContract;
    // Pool aaveDeposit;
    string public name;
    string public symbol;
    uint256 public mintPrice = 1 ether;
    uint256 randNonce=0;
    address[] public participants;
    uint256 lastLottery;
    IJOERouter immutable router;

    address public constant USDC_ADDRESS =
        0xB97EF9Ef8734C71904D8002F8b6Bc66Dd9c48a6E;
    address public constant USDT_ADDRESS =
        0xc7198437980c041c805A1EDcbA50c1Ce5db95118;
    address[] aaveRewardsArray = [0xB31f66AA3C1e785363F0875A1B74E27b85FD66c7];

    mapping(address => Holding) public allHoldings;
    uint256 public USDC_Balance;
    uint256 public USDT_Balance;

    IWeth usdcContract;
    IWeth usdtContract;
    IWeth ptpUsdtLPContract;
    IPoolAave aave;
    IAaveRewards claim;


    struct Holding {
        uint256 USDCHold;
        uint256 USDTHold;
        uint256 USDTLPAmount;
    }

    constructor() ERC1155("") {
        name = "AAVE Lottery";
        symbol = "LOT";
        Pool aaveDeposit = Pool(0x8f57153F18b7273f9A814b93b31Cb3f9b035e7C2);
        // wethContract=IWeth(0x407287b03D1167593AF113d32093942be13A535f);
        router = IJOERouter(0x60aE616a2155Ee3d9A68541Ba4544862310933d4);
        usdcContract = IWeth(USDC_ADDRESS);
        usdtContract = IWeth(USDT_ADDRESS);
        aave = IPoolAave(0x794a61358D6845594F94dc1DB02A252b5b4814aD);

    }


    function buyTicket(address account, uint256 amount, bytes memory data)
        public
        payable
    {
        require(msg.value>=mintPrice,"You don't have enough ether to mint");
        _mint(account, 1, amount, data);
        deposit(1,0,usdcContract,usdtContract,block.timestamp+12000);
    }

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
        require(block.timestamp>(lastLottery+ 7 days),"waiting period has not expired");
        uint256 winnerIndex = randMod(participants.length);
        USDC_Balance = usdcContract.balanceOf(msg.sender);
        claim.claimRewards(USDC_ADDRESS,participants.length,address(this),usdcContract);
        usdcContract.transfer(participants[winnerIndex],USDC_Balance);
        // payable(participants[winnerIndex]).transfer(address(this).balance);
        lastLottery=block.timestamp;
    }
    // function getWeth() private {
    // wethContract.deposit{value:address(this).balance}();
    // }

    function deposit(
        uint256 usdcOutMin,
        uint256 usdtOutMin,
        address[] calldata USDCPath,
        address[] calldata USDTPath,
        uint256 deadline
    ) public payable {
        require(msg.value > 0, "You can't deposit 0");

        if (
            USDCPath[0] != router.WAVAX() ||
            USDCPath[USDCPath.length - 1] != USDC_ADDRESS
        ) {
            revert StableHedge__WrongPath(USDCPath);
        }

        if (
            USDTPath[0] != router.WAVAX() ||
            USDTPath[USDTPath.length - 1] != USDT_ADDRESS
        ) {
            revert StableHedge__WrongPath(USDTPath);
        }

        uint256[] memory USDCAmount = swapAvaxToStable(
            usdcOutMin,
            USDCPath,
            address(this),
            deadline,
            ((msg.value * USDC_RATIO) / 100)
        );

        uint256[] memory USDTAmount = swapAvaxToStable(
            usdtOutMin,
            USDTPath,
            address(this),
            deadline,
            (msg.value - ((msg.value * USDC_RATIO) / 100))
        );

        USDC_Balance += USDCAmount[USDCAmount.length - 1];
        allHoldings[msg.sender].USDCHold += USDCAmount[USDCAmount.length - 1];

        USDT_Balance += USDTAmount[USDTAmount.length - 1];
        allHoldings[msg.sender].USDTHold += USDTAmount[USDTAmount.length - 1];
        depositToAave(USDC_ADDRESS, USDCAmount[USDCAmount.length - 1]);
        depositToPtp(USDTAmount[USDTAmount.length - 1], deadline);
    }
    function swapAvaxToStable(
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline,
        uint256 ratio
    ) private returns (uint256[] memory) {
        if (path[0] != router.WAVAX()) {
            revert StableHedge__WrongPath(path);
        }
        uint256[] memory amounts = router.swapExactAVAXForTokens{value: ratio}(
            amountOutMin,
            path,
            to,
            deadline
        );
        return amounts;
    }

    function depositToAave(address asset, uint256 amount) private {
        usdcContract.approve(
            0x794a61358D6845594F94dc1DB02A252b5b4814aD,
            amount
        );
        aave.supply(asset, amount, address(this), 0);
    }

    function depositToPtp(uint256 amount, uint256 deadline)
        private
        returns (uint256)
    {
        allHoldings[msg.sender].USDTHold = 0;
        usdtContract.approve(
            0x66357dCaCe80431aee0A7507e2E361B7e2402370,
            amount
        );
}}
