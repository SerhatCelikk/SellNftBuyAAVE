require("@nomiclabs/hardhat-waffle");

const PRIVATE_KEY ="";


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
      mainnet: {
        url: `https://api.avax.network/ext/bc/C/rpc`,
          accounts: [`${PRIVATE_KEY}`]
      },
      fuji: {
        url: `https://api.avax-test.network/ext/bc/C/rpc`,
         accounts: [`${PRIVATE_KEY}`]
      },
      rinkeby: {
        url: "https://eth-rinkeby.alchemyapi.io/v2/123abc123abc123abc123abc123abcde",
        accounts: [`${PRIVATE_KEY}`],
      }
    }
};