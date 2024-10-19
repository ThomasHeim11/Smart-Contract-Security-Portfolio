import { deployContract } from "../../helpers/deployment.js";

const deployDepositContractFixture = async (numberOfERC20 = 5) => {
  const [owner] = await ethers.getSigners();
  const erc20Deployments = Array(numberOfERC20);
  for (let i = 0; i < numberOfERC20; i++) {
    erc20Deployments[i] = await deployContract("tstETH", [
      ethers.parseEther("1000000"),
      18,
    ]);
  }

  const nonWhitelistedToken = await deployContract("tstETH", [
    ethers.parseEther("1000000"),
    18,
  ]);

  const brokenERC20 = await deployContract("BrokenERC20", [
    ethers.parseEther("1000000"),
  ]);

  const contract = await deployContract("OmronDeposit", [
    owner.address,
    erc20Deployments.map((deployment) => deployment.address),
  ]);

  return {
    deposit: contract,
    erc20Deployments,
    nonWhitelistedToken,
    brokenERC20,
  };
};

const deployMockClaimContractFixture = async (depositContractAddress) => {
  const contract = await deployContract("MockClaim", [depositContractAddress]);
  return contract;
};

export { deployDepositContractFixture, deployMockClaimContractFixture };
