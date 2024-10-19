import hre from "hardhat";
import {
  deployContract,
  deploymentLogger,
  logDeployedContracts,
} from "../helpers/deployment.js";

const tokens = {
  mainnet: {
    WETH: "0xc02aaa39b223fe8d0a0e5c4f27ead9083c756cc2",
    ezETH: "0xbf5495Efe5DB9ce00f80364C8B423567e58d2110",
  },
  sepolia: {
    WETH: "0xfFf9976782d46CC05630D1f6eBAb18b2324d6B14",
    ezETH: "0x8b78223e2FD9FEa8D30F1A6E36D7A1dEfab28c5e",
  },
  localhost: {},
};

async function main() {
  deploymentLogger.time("Deployment Time");

  deploymentLogger[process.env.DRY_RUN ? "dry_run" : "start"](
    "Deploying contracts..."
  );
  const wallets = await hre.ethers.getSigners(10);
  // Deploy contracts here using deployContract
  let tokenAddresses = Object.values(tokens[hre.network.name]);
  if (hre.network.name === "localhost") {
    const erc20Deployments = [];
    for (let i = 0; i < 5; i++) {
      erc20Deployments[i] = await deployContract("tstETH", [
        ethers.parseEther("1000000"),
        18,
      ]);
    }
    tokenAddresses = erc20Deployments.map((d) => d.address);
  }

  const { contract } = await deployContract("OmronDeposit", [
    wallets[0].address,
    tokenAddresses,
  ]);
  await contract.pause();
}
let wasError = false;
main()
  .then(() => {
    deploymentLogger.timeEnd("Deployment Time");
    deploymentLogger
      .scope("Deployment")
      [process.env.DRY_RUN ? "dry_run" : "start"](`All contracts deployed.`);
  })
  .catch((error) => {
    deploymentLogger.fatal("Deployments Failed\n", error);
    wasError = true;
  })
  .finally(() => {
    logDeployedContracts();
    process.exit(+wasError);
  });
