import { ZeroAddress, ZeroHash } from "ethers";
import fs from "fs";
import hre from "hardhat";
import { isEmpty, uniqueId } from "lodash-es";
import logger from "not-a-log";
import signale from "signale-logger";

const deploymentLogger = new signale.Signale({
  stream: [process.stdout, fs.createWriteStream("deploy.log")],
  scope: "Deployment",
  types: {
    dry_run: {
      badge: "🌵",
      color: "yellow",
      label: "Dry Run",
    },
  },
});

let deployedContracts = {};
/**
 * Deploys a contract
 * @param {string} contractName The name of the contract to deploy
 * @param {any[]} [args] The arguments to pass to the contract constructor
 * @returns {Promise<{contract: ethers.Contract, address: string}>} A promise containing the contract and the contract address after deployment
 */
const deployContract = async (contractName, args) => {
  const contractDeploymentLogger = deploymentLogger.scope(
    "Deployment",
    contractName
  );
  try {
    let contract, contractAddress, transactionHash;
    if (process.env.DRY_RUN === "true") {
      contractDeploymentLogger.dry_run(
        "Contract",
        contractName,
        "would have been deployed with args",
        args
      );
      contract = null;
      contractAddress = ZeroAddress;
      transactionHash = ZeroHash;
    } else {
      contractDeploymentLogger.await("Deploying...");
      contract = await hre.ethers.deployContract(
        contractName,
        ...(isEmpty(args) ? [] : [args])
      );
      transactionHash = contract.deploymentTransaction().hash;
      contractDeploymentLogger.info("Transaction Hash:", transactionHash);
      await contract.waitForDeployment();
      contractAddress = await contract.getAddress();
      contractDeploymentLogger.complete(`Deployed to ${contractAddress}`);
    }
    if (!isEmpty(deployedContracts[contractName])) {
      deployedContracts[contractName + " " + uniqueId()] = {
        contractAddress,
        transactionHash,
      };
    } else {
      deployedContracts[contractName] = { contractAddress, transactionHash };
    }
    return { contract, address: contractAddress, hash: transactionHash };
  } catch (e) {
    contractDeploymentLogger.error(`Failed to deploy ${contractName}\n`, e);
    throw e;
  }
};

const logDeployedContracts = () => {
  const table = logger.table(deployedContracts);
  deploymentLogger.info("Deployed Contracts:\r\n" + table);
};
export { deployContract, deploymentLogger, logDeployedContracts };
