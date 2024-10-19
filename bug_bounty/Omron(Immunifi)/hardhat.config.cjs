require("@nomicfoundation/hardhat-toolbox");
require("hardhat-tracer");

const SEPOLIA_PRIVATE_KEY = process.env.SEPOLIA_PRIVATE_KEY;
const MAINNET_PRIVATE_KEY = process.env.MAINNET_PRIVATE_KEY;

const sepoliaConfig = {
  url: "https://sepolia.infura.io/v3/c7fda47531884d49aa5878876dbbabf3",
};
if (SEPOLIA_PRIVATE_KEY) {
  sepoliaConfig.accounts = [SEPOLIA_PRIVATE_KEY];
}

const mainnetConfig = {
  url: "https://mainnet.infura.io/v3/c7fda47531884d49aa587876dbbabf3",
};
if (MAINNET_PRIVATE_KEY) {
  mainnetConfig.accounts = [MAINNET_PRIVATE_KEY];
}

/** @type import('hardhat/config').HardhatUserConfig */
module.exports = {
  defaultNetwork: "hardhat",
  networks: {
    hardhat: {},
    sepolia: {
      url: "https://sepolia.infura.io/v3/c7fda47531884d49aa5878876dbbabf3",
      //accounts: [process.env.SEPOLIA_PRIVATE_KEY],
    },
    mainnet: {
      url: "https://mainnet.infura.io/v3/c7fda47531884d49aa5878876dbbabf3",
      //accounts: [process.env.MAINNET_PRIVATE_KEY],
    },
  },
  namedAccounts: {
    deployer: 0,
  },
  solidity: {
    version: "0.8.21",
    settings: {
      optimizer: {
        enabled: true,
        runs: 4_000,
      },
    },
  },
};
