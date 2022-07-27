require("@nomiclabs/hardhat-waffle");

task("accounts", "Prints the list of accounts", async (taskArgs, hre) => {
  const accounts = await hre.ethers.getSigners();

  for (const account of accounts) {
    console.log(account.address);
  }
});


module.exports = {
    solidity: {
      compilers:[{version:"0.8.7"},{version:"0.6.6"},{version:"0.4.19"},{version:"0.8.10"},{version:"0.6.12"}],
    },
    networks: {

      hardhat:{
        forking: {
          url: "https://api.avax.network/ext/bc/C/rpc",
        }
        
      },
      // mainnet: {
      //   url: `https://api.avax.network/ext/bc/C/rpc`,
      //     accounts: [`${PRIVATE_KEY}`]
      // },
      // fuji: {
      //   url: `https://api.avax-test.network/ext/bc/C/rpc`,
      //    accounts: [`${PRIVATE_KEY}`]
      // },
      // rinkeby: {
      //   url: "https://eth-rinkeby.alchemyapi.io/v2/123abc123abc123abc123abc123abcde",
      //   accounts: [`${PRIVATE_KEY}`],
      // }
    }
};