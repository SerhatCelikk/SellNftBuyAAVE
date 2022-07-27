require("@nomiclabs/hardhat-waffle");

const PRIVATE_KEY ="";


module.exports = {
    solidity: "0.8.10",
    networks: {

      hardhat:{
        forking: {
          url:"https://eth-rinkeby.alchemyapi.io/v2/sf7Mr0i_qcauE2bqJWAuR9syrrJ8y8vA"
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