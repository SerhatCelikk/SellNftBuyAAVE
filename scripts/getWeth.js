const {getNamedAccounts,ethers} = require("hardhat");

const AMOUNT= ethers.utils.parseEther("0.02")

async function getWeth(){

    const {deployer} = await getNamedAccounts()
    const iWeth = await ethers.getContractAt("IWeth","0xDf032Bc4B9dC2782Bb09352007D4C57B75160B15",deployer)
    const tx = await iWeth.deposit({value:AMOUNT});
    await tx.wait(1);
    const wethBalance = await iWeth.balanceOf(deplyor);
    console.log(`You have ${wethBalance.toString()}`);
    
}
module.exports = {getWeth}