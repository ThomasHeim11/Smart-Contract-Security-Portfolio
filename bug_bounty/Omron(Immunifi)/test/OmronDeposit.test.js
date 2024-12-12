import { loadFixture, time } from "@nomicfoundation/hardhat-network-helpers";
import { expect } from "chai";
import { ZeroAddress, parseEther } from "ethers";
import { deployContract } from "../helpers/deployment.js";
import {
  deployDepositContractFixture,
  deployMockClaimContractFixture,
} from "./helpers/fixtures.js";
import { addAllowance, depositTokens } from "./helpers/interactions.js";

describe("OmronDeposit", () => {
  let owner, user1, user2;
  before(async () => {
    [owner, user1, user2] = await ethers.getSigners();
  });

  let deposit,
    erc20Deployments,
    token1,
    token2,
    nonWhitelistedToken,
    brokenERC20;
  beforeEach(async () => {
    ({ deposit, erc20Deployments, nonWhitelistedToken, brokenERC20 } =
      await loadFixture(deployDepositContractFixture));
    [token1, token2] = erc20Deployments;
  });
  describe("constructor", () => {
    it("Should revert with ZeroAddress if any whitelisted token is zero address", async () => {
      await expect(
        deployContract("OmronDeposit", [owner.address, [ZeroAddress]])
      ).to.be.revertedWithCustomError(deposit.contract, "ZeroAddress");
    });
    it("Should emit events for each whitelisted token", async () => {
      const tokenAddresses = [...[...erc20Deployments].map((x) => x.address)];

      const txHash = deposit.hash;
      const tx = await ethers.provider.getTransaction(txHash);

      const receipt = await ethers.provider.getTransactionReceipt(txHash);

      const events = receipt.logs.map((x) =>
        deposit.contract.interface.parseLog(x)
      );

      const whitelistedTokenEvents = events.filter(
        (x) => x.name === "WhitelistedTokenAdded"
      );
      expect(whitelistedTokenEvents).to.have.lengthOf(tokenAddresses.length);
      const whitelistedTokenAddresses = whitelistedTokenEvents.map(
        (x) => x.args[0]
      );
      expect(whitelistedTokenAddresses).to.have.members(tokenAddresses);
    });
    it("Should whitelist tokens as expected", async () => {
      const whitelist = await deposit.contract.getAllWhitelistedTokens();
      expect([...whitelist]).to.have.members([
        ...erc20Deployments.map((x) => x.address),
      ]);
    });
  });
  describe("getAllWhitelistedTokens", () => {
    it("Should return all whitelisted tokens", async () => {
      const whitelistedTokens =
        await deposit.contract.getAllWhitelistedTokens();
      expect([...whitelistedTokens]).to.have.members([
        ...erc20Deployments.map((x) => x.address),
      ]);
    });
    it("Should get updated whitelisted tokens after adding a new token", async () => {
      await deposit.contract.addWhitelistedToken(nonWhitelistedToken.address);
      const whitelistedTokens =
        await deposit.contract.getAllWhitelistedTokens();

      expect([...whitelistedTokens]).to.have.members([
        ...erc20Deployments.map((x) => x.address),
        nonWhitelistedToken.address,
      ]);
    });
  });
  describe("pause", () => {
    it("Should reject pause when not owner", async () => {
      await expect(
        deposit.contract.connect(user1).pause()
      ).to.be.revertedWithCustomError(
        deposit.contract,
        "OwnableUnauthorizedAccount"
      );
    });
    it("Should reject pause when already paused", async () => {
      await deposit.contract.connect(owner).pause();
      await expect(
        deposit.contract.connect(owner).pause()
      ).to.be.revertedWithCustomError(deposit.contract, "EnforcedPause");
    });
    it("Should accept pause when not paused", async () => {
      await expect(deposit.contract.connect(owner).pause())
        .to.emit(deposit.contract, "Paused")
        .withArgs(owner.address);
    });
  });
  describe("unpause", () => {
    it("Should reject unpause when not owner", async () => {
      await expect(
        deposit.contract.connect(user1).unpause()
      ).to.be.revertedWithCustomError(
        deposit.contract,
        "OwnableUnauthorizedAccount"
      );
    });
    it("Should reject unpause when not paused", async () => {
      await expect(
        deposit.contract.connect(owner).unpause()
      ).to.be.revertedWithCustomError(deposit.contract, "ExpectedPause");
    });
    it("Should accept unpause when paused", async () => {
      await deposit.contract.connect(owner).pause();
      await expect(deposit.contract.connect(owner).unpause())
        .to.emit(deposit.contract, "Unpaused")

        .withArgs(owner.address);
    });
  });

  describe("deposit", () => {
    it("Should reject deposit of zero tokens", async () => {
      await addAllowance(token1, owner, deposit, parseEther("1"));
      await depositTokens(
        deposit,
        token1,
        parseEther("0"),
        owner,
        true,
        "ZeroAmount"
      );
    });
    it("Should reject deposit when past deposit stop time", async () => {
      await deposit.contract.setClaimManager(user1.address);
      const currentTime = await time.latest();
      await deposit.contract.stopDeposits();
      await time.increase(3600);
      await expect(
        deposit.contract.connect(owner).deposit(token1.address, parseEther("1"))
      ).to.be.revertedWithCustomError(deposit.contract, "DepositsStopped");
    });
    it("Should reject deposit when paused", async () => {
      await deposit.contract.connect(owner).pause();

      await expect(
        deposit.contract.connect(user1).deposit(token1.address, parseEther("1"))
      ).to.be.revertedWithCustomError(deposit.contract, "EnforcedPause");
    });
    it("Should handle falsy transferFrom response", async () => {
      await addAllowance(brokenERC20, owner, deposit, parseEther("1"));
      await deposit.contract.addWhitelistedToken(brokenERC20.address);
      await brokenERC20.contract.setTransfersEnabled(false);
      await expect(
        deposit.contract.deposit(brokenERC20.address, parseEther("1"))
      ).to.be.revertedWithCustomError(
        deposit.contract,
        "SafeERC20FailedOperation"
      );
    });
    it("Should reject deposit with no allowance", async () => {
      await expect(
        deposit.contract.deposit(token1.address, parseEther("1"))
      ).to.be.revertedWithCustomError(
        token1.contract,
        "ERC20InsufficientAllowance"
      );
    });
    it("Should reject deposit with empty balance", async () => {
      await addAllowance(token1, user2, deposit, parseEther("1"));

      await expect(
        deposit.contract.connect(user2).deposit(token1.address, parseEther("1"))
      ).to.be.revertedWithCustomError(
        token1.contract,
        "ERC20InsufficientBalance"
      );
    });
    it("Should accept valid deposit", async () => {
      await addAllowance(token1, owner, deposit, parseEther("1"));

      await expect(deposit.contract.deposit(token1.address, parseEther("1")))
        .to.emit(deposit.contract, "Deposit")
        .withArgs(owner.address, token1.address, parseEther("1"));
    });
    it("Should reject deposit of non-whitelisted token", async () => {
      const { deposit, nonWhitelistedToken } = await loadFixture(
        deployDepositContractFixture
      );

      await addAllowance(nonWhitelistedToken, owner, deposit, parseEther("1"));
      await expect(
        deposit.contract
          .connect(owner)
          .deposit(nonWhitelistedToken.address, parseEther("1"))
      ).to.be.revertedWithCustomError(deposit.contract, "TokenNotWhitelisted");
    });
  });
  describe("tokenBalance", () => {
    it("Should correctly return ERC20 token balance", async () => {
      await addAllowance(token1, owner, deposit, parseEther("1"));
      await deposit.contract.deposit(token1.address, parseEther("1"));
      const balance = await deposit.contract.tokenBalance(
        owner.address,
        token1.address
      );
      expect(balance).to.equal(parseEther("1"));
    });
  });
  describe("setClaimManager", () => {
    it("Should set claim manager when owner", async () => {
      await expect(
        deposit.contract.connect(owner).setClaimManager(user2.address)
      )
        .to.emit(deposit.contract, "ClaimManagerSet")
        .withArgs(user2.address);
    });

    it("Should not set claim manager provided zero address", async () => {
      await expect(
        deposit.contract.connect(owner).setClaimManager(ZeroAddress)
      ).to.be.revertedWithCustomError(deposit.contract, "ZeroAddress");
    });
    it("Should not set claim manager when not owner", async () => {
      await expect(
        deposit.contract.connect(user1).setClaimManager(user2.address)
      ).to.be.revertedWithCustomError(
        deposit.contract,
        "OwnableUnauthorizedAccount"
      );
    });
  });

  describe("stopDeposits", () => {
    it("Should only allow owner to stop deposits", async () => {
      await expect(deposit.contract.connect(user1).stopDeposits())
        .to.be.revertedWithCustomError(
          deposit.contract,
          "OwnableUnauthorizedAccount"
        )
        .withArgs(user1.address);
    });
    it("Should prevent stopping deposits once they're already stopped", async () => {
      await deposit.contract.stopDeposits();
      await expect(
        deposit.contract.connect(owner).stopDeposits()
      ).to.be.revertedWithCustomError(
        deposit.contract,
        "DepositsAlreadyStopped"
      );
    });
  });

  describe("withdrawTokens", () => {
    it("Should accept valid token withdrawal", async () => {
      await deposit.contract.setClaimManager(user1.address);

      await token1.contract.transfer(user2.address, parseEther("1"));
      await token2.contract.transfer(user2.address, parseEther("1"));
      await addAllowance(token1, user2, deposit, parseEther("1"));
      await addAllowance(token2, user2, deposit, parseEther("1"));
      await depositTokens(deposit, token1, parseEther("1"), user2);
      await time.increase(3599);
      await depositTokens(deposit, token2, parseEther("1"), user2);
      await time.increase(3599);
      // 3 points earned here. txs take 1s each, and the first point is in the contract for 2hr while the second is in there for 1 hr
      await deposit.contract.stopDeposits();
      await expect(
        deposit.contract.connect(user1).withdrawTokens(user2.address)
      )
        .to.emit(deposit.contract, "WithdrawTokens")
        .withArgs(
          user2.address,
          erc20Deployments.map((token) =>
            [token1.address, token2.address].includes(token.address)
              ? parseEther("1")
              : parseEther("0")
          )
        );
      const newDepositBalances = await Promise.all([
        deposit.contract.tokenBalance(user2.address, token1.address),
        deposit.contract.tokenBalance(user2.address, token2.address),
      ]);
      expect(newDepositBalances).to.eql([parseEther("0"), parseEther("0")]);
      const userInfo = await deposit.contract.getUserInfo(user2.address);
      expect(userInfo.pointsPerHour).to.eql(parseEther("0"));
      expect(userInfo.pointBalance).to.eql(parseEther("3"));
    });
    it("Should withdraw when all tokens have a balance", async () => {
      await deposit.contract.setClaimManager(user2.address);
      for (const token of erc20Deployments) {
        await token.contract.transfer(user1.address, parseEther("1"));
        await addAllowance(token, user1, deposit, parseEther("1"));
        await depositTokens(deposit, token, parseEther("1"), user1);
      }
      await deposit.contract.stopDeposits();
      await expect(
        deposit.contract.connect(user2).withdrawTokens(user1.address)
      )
        .to.emit(deposit.contract, "WithdrawTokens")
        .withArgs(
          user1.address,
          erc20Deployments.map((token) => parseEther("1"))
        );
      const newClaimBalances = await Promise.all(
        erc20Deployments.map(
          async (token) => await token.contract.balanceOf(user2.address)
        )
      );
      expect(newClaimBalances).to.eql(
        erc20Deployments.map((token) => parseEther("1"))
      );
    });
    it("Should not transfer any tokens on double withdraw", async () => {
      let originalBalances = await Promise.all(
        erc20Deployments.map(
          async (token) => await token.contract.balanceOf(user1.address)
        )
      );
      await deposit.contract.setClaimManager(user2.address);
      await token1.contract.transfer(user1.address, parseEther("1"));
      await addAllowance(token1, user1, deposit, parseEther("1"));
      await depositTokens(deposit, token1, parseEther("1"), user1);
      await deposit.contract.stopDeposits();
      await expect(
        deposit.contract.connect(user2).withdrawTokens(user1.address)
      )
        .to.emit(deposit.contract, "WithdrawTokens")
        .withArgs(
          user1.address,
          erc20Deployments.map((token) =>
            [token1.address].includes(token.address)
              ? parseEther("1")
              : parseEther("0")
          )
        );
      let newBalances = await Promise.all(
        erc20Deployments.map(
          async (token) => await token.contract.balanceOf(user1.address)
        )
      );
      expect(newBalances).to.eql(originalBalances);
      await expect(
        deposit.contract.connect(user2).withdrawTokens(user1.address)
      )
        .to.emit(deposit.contract, "WithdrawTokens")
        .withArgs(
          user1.address,
          erc20Deployments.map((token) => parseEther("0"))
        );
      newBalances = await Promise.all(
        erc20Deployments.map(
          async (token) => await token.contract.balanceOf(user1.address)
        )
      );
      expect(newBalances).to.eql(originalBalances);
    });
    it("Should reject when not called from claim manager", async () => {
      await deposit.contract.setClaimManager(user2.address);
      await expect(
        deposit.contract.connect(user1).withdrawTokens(user1.address)
      ).to.be.revertedWithCustomError(deposit.contract, "NotClaimManager");
    });
    it("Should reject when called before deposit stop time", async () => {
      await deposit.contract.setClaimManager(user1.address);
      await expect(
        deposit.contract.connect(user1).withdrawTokens(user1.address)
      ).to.be.revertedWithCustomError(deposit.contract, "DepositsNotStopped");
    });
    it("Should reject withdrawal when contract paused", async () => {
      await deposit.contract.pause();
      await expect(
        deposit.contract.connect(user1).withdrawTokens(user1.address)
      ).to.be.revertedWithCustomError(deposit.contract, "EnforcedPause");
    });
    it("Should reject withdrawal for null address", async () => {
      await deposit.contract.setClaimManager(user1.address);
      await deposit.contract.stopDeposits();
      await expect(
        deposit.contract.connect(user1).withdrawTokens(ZeroAddress)
      ).to.be.revertedWithCustomError(deposit.contract, "ZeroAddress");
    });
  });
  describe("removeWhitelistedToken", async () => {
    it("Should remove a token from the whitelist", async () => {
      const originalLength = (await deposit.contract.getAllWhitelistedTokens())
        .length;
      await expect(deposit.contract.removeWhitelistedToken(token1.address))
        .to.emit(deposit.contract, "WhitelistedTokenRemoved")
        .withArgs(token1.address);
      const newLength = (await deposit.contract.getAllWhitelistedTokens())
        .length;
      expect(newLength).to.equal(originalLength - 1);
      expect(await deposit.contract.getAllWhitelistedTokens()).to.not.include(
        token1.address
      );
    });
    it("Should not allow removal of the null address", async () => {
      await expect(
        deposit.contract.removeWhitelistedToken(ZeroAddress)
      ).to.be.revertedWithCustomError(deposit.contract, "ZeroAddress");
    });
    it("Should not allow removal of a token that is not whitelisted", async () => {
      await expect(
        deposit.contract.removeWhitelistedToken(nonWhitelistedToken.address)
      ).to.be.revertedWithCustomError(deposit.contract, "TokenNotWhitelisted");
    });
    it("Should cease allowing deposits of a token that is no longer whitelisted", async () => {
      await token1.contract.transfer(user1.address, parseEther("1"));
      await addAllowance(token1, user1, deposit, parseEther("1"));
      await depositTokens(deposit, token1, parseEther("1"), user1);
      await deposit.contract.removeWhitelistedToken(token1.address);
      await expect(
        deposit.contract.deposit(token1.address, parseEther("1"))
      ).to.be.revertedWithCustomError(deposit.contract, "TokenNotWhitelisted");
    });
    it("Should not do withdrawals of a token that is no longer whitelisted", async () => {
      await token1.contract.transfer(user1.address, parseEther("1"));
      await addAllowance(token1, user1, deposit, parseEther("1"));
      await depositTokens(deposit, token1, parseEther("1"), user1);
      await deposit.contract.setClaimManager(owner.address);
      await deposit.contract.stopDeposits();
      await deposit.contract.removeWhitelistedToken(token1.address);
      await deposit.contract.withdrawTokens(user1.address);
      expect(await token1.contract.balanceOf(user1.address)).to.equal(
        parseEther("0")
      );
    });
    it("Should restrict access to owner", async () => {
      await expect(
        deposit.contract.connect(user1).removeWhitelistedToken(token1.address)
      ).to.be.revertedWithCustomError(
        deposit.contract,
        "OwnableUnauthorizedAccount"
      );
    });
    it("Should allow withdraw if a whitelisted token is re-added", async () => {
      await token1.contract.transfer(user1.address, parseEther("1"));
      await addAllowance(token1, user1, deposit, parseEther("1"));
      await depositTokens(deposit, token1, parseEther("1"), user1);
      await deposit.contract.setClaimManager(user2.address);
      await deposit.contract.stopDeposits();
      await expect(deposit.contract.removeWhitelistedToken(token1.address))
        .to.emit(deposit.contract, "WhitelistedTokenRemoved")
        .withArgs(token1.address);
      expect(await deposit.contract.getAllWhitelistedTokens()).to.not.include(
        token1.address
      );
      await expect(
        deposit.contract.connect(user2).withdrawTokens(user1.address)
      )
        .to.emit(deposit.contract, "WithdrawTokens")
        .withArgs(user1.address, [
          parseEther("0"),
          parseEther("0"),
          parseEther("0"),
          parseEther("0"),
        ]);
      expect(await token1.contract.balanceOf(user1.address)).to.equal(
        parseEther("0")
      );
      await expect(deposit.contract.addWhitelistedToken(token1.address))
        .to.emit(deposit.contract, "WhitelistedTokenAdded")
        .withArgs(token1.address);
      await expect(
        deposit.contract.connect(user2).withdrawTokens(user1.address)
      )
        .to.emit(deposit.contract, "WithdrawTokens")
        .withArgs(user1.address, [
          parseEther("0"),
          parseEther("0"),
          parseEther("0"),
          parseEther("0"),
          parseEther("1"),
        ]);
      expect(await token1.contract.balanceOf(user2.address)).to.equal(
        parseEther("1")
      );
    });
    it("Should allow cycles of addition and removal for the same token", async () => {
      await expect(deposit.contract.removeWhitelistedToken(token1.address))
        .to.emit(deposit.contract, "WhitelistedTokenRemoved")
        .withArgs(token1.address);
      expect(await deposit.contract.getAllWhitelistedTokens()).to.not.include(
        token1.address
      );
      await expect(deposit.contract.addWhitelistedToken(token1.address))
        .to.emit(deposit.contract, "WhitelistedTokenAdded")
        .withArgs(token1.address);
      expect(await deposit.contract.getAllWhitelistedTokens()).to.include(
        token1.address
      );
      await expect(deposit.contract.removeWhitelistedToken(token1.address))
        .to.emit(deposit.contract, "WhitelistedTokenRemoved")
        .withArgs(token1.address);
      expect(await deposit.contract.getAllWhitelistedTokens()).to.not.include(
        token1.address
      );
    });
  });
  describe("claim", () => {
    it("Should correctly claim using mock claim contract", async () => {
      const mockClaimContract = await deployMockClaimContractFixture(
        deposit.address
      );
      await deposit.contract.setClaimManager(mockClaimContract.address);
      await token1.contract.transfer(user2.address, parseEther("1"));
      await addAllowance(token1, user2, deposit, parseEther("2"));
      await depositTokens(deposit, token1, parseEther("1"), user2);
      await time.increase(3599);
      await deposit.contract.stopDeposits();
      await expect(mockClaimContract.contract.claimPoints(user2.address))
        .to.emit(mockClaimContract.contract, "PointsClaimed")
        .withArgs(user2.address, parseEther("1"));
    });
    it("Should accept claim and reduce user's point balance to zero", async () => {
      await deposit.contract.setClaimManager(user1.address);
      await token1.contract.transfer(user2.address, parseEther("2"));
      await addAllowance(token1, user2, deposit, parseEther("2"));
      await depositTokens(deposit, token1, parseEther("1"), user2);
      await time.increase(3599);
      await depositTokens(deposit, token1, parseEther("1"), user2);
      await deposit.contract.stopDeposits();
      const initialInfo = await deposit.contract.getUserInfo(user2.address);
      expect(initialInfo.pointBalance).to.equal(parseEther("1"));
      await deposit.contract.connect(user1).claim(user2.address);
      const info = await deposit.contract.getUserInfo(user2.address);
      expect(info.pointBalance).to.equal(parseEther("0"));
    });
    it("Should return no points on double claim", async () => {
      await deposit.contract.setClaimManager(user2.address);
      await token1.contract.transfer(user1.address, parseEther("1"));
      await addAllowance(token1, user1, deposit, parseEther("1"));
      await depositTokens(deposit, token1, parseEther("1"), user1);
      await time.increase(3599);
      await deposit.contract.stopDeposits();
      await expect(deposit.contract.connect(user2).claim(user1.address))
        .to.emit(deposit.contract, "ClaimPoints")
        .withArgs(user1.address, parseEther("1"));
      await expect(deposit.contract.connect(user2).claim(user1.address))
        .to.emit(deposit.contract, "ClaimPoints")
        .withArgs(user1.address, parseEther("0"));
    });

    it("Should correctly handle point accrual and claim process", async () => {
      await deposit.contract.setClaimManager(user1.address);

      // Transfer and allow tokens for deposit
      await token1.contract.transfer(user2.address, parseEther("2"));
      await addAllowance(token1, user2, deposit, parseEther("2"));

      // Initial deposit
      await depositTokens(deposit, token1, parseEther("1"), user2);
      // In two hours, the contract will switch to claim mode
      await time.increase(7199);

      // Make a last-second deposit
      await depositTokens(deposit, token1, parseEther("1"), user2);

      // Stop deposits
      await deposit.contract.stopDeposits();

      const additionalPointsFromLastDeposit = parseEther(
        "0.000555555555555555"
      );

      // Simulate another hour passing, post-deposit stop time
      await time.increase(3600);

      // Verify initial point balance before claim
      const initialInfo = await deposit.contract.getUserInfo(user2.address);
      expect(initialInfo.pointBalance).to.equal(parseEther("2"));

      // Perform claim and verify event emission
      await expect(deposit.contract.connect(user1).claim(user2.address))
        .to.emit(deposit.contract, "ClaimPoints")
        .withArgs(
          user2.address,
          parseEther("2") + additionalPointsFromLastDeposit
        );

      // Confirm point balance is reset to zero after claim
      const postClaimInfo = await deposit.contract.getUserInfo(user2.address);
      expect(postClaimInfo.pointBalance).to.equal(parseEther("0"));
    });

    it("Should reject when contract paused", async () => {
      await deposit.contract.setClaimManager(user1.address);
      await deposit.contract.stopDeposits();
      await time.increase(1);
      await deposit.contract.pause();
      await expect(
        deposit.contract.connect(user1).claim(user2.address)
      ).to.be.revertedWithCustomError(deposit.contract, "EnforcedPause");
    });
    it("Should reject when claim address is null", async () => {
      const currentTime = await time.latest();
      await deposit.contract.stopDeposits();
      await time.increase(3601);
      await expect(
        deposit.contract.claim(user1.address)
      ).to.be.revertedWithCustomError(deposit.contract, "ClaimManagerNotSet");
    });
    it("Should reject claim for null address", async () => {
      await deposit.contract.setClaimManager(user1.address);
      const currentTime = await time.latest();
      await deposit.contract.stopDeposits();
      await expect(
        deposit.contract.connect(user1).claim(ZeroAddress)
      ).to.be.revertedWithCustomError(deposit.contract, "ZeroAddress");
    });
    it("Should reject when not claim address", async () => {
      await deposit.contract.setClaimManager(user2.address);
      const currentTime = await time.latest();
      await deposit.contract.stopDeposits();
      await expect(
        deposit.contract.connect(user1).claim(user2.address)
      ).to.be.revertedWithCustomError(deposit.contract, "NotClaimManager");
    });
    it("Should reject when before deposit stop time", async () => {
      await deposit.contract.setClaimManager(user2.address);
      await expect(
        deposit.contract.connect(user2).claim(user2.address)
      ).to.be.revertedWithCustomError(deposit.contract, "DepositsNotStopped");
    });
  });
  describe("addWhitelistedToken", () => {
    it("Should reject token at zero address", async () => {
      await expect(
        deposit.contract.connect(owner).addWhitelistedToken(ZeroAddress)
      ).to.be.revertedWithCustomError(deposit.contract, "ZeroAddress");
    });
    it("Should reject addWhitelistedToken when not owner", async () => {
      await expect(
        deposit.contract
          .connect(user1)
          .addWhitelistedToken(nonWhitelistedToken.address)
      ).to.be.revertedWithCustomError(
        deposit.contract,
        "OwnableUnauthorizedAccount"
      );
    });
    it("Should accept addWhitelistedToken when owner", async () => {
      await expect(
        deposit.contract
          .connect(owner)
          .addWhitelistedToken(nonWhitelistedToken.address)
      )
        .to.emit(deposit.contract, "WhitelistedTokenAdded")
        .withArgs(nonWhitelistedToken.address);
    });
  });
  describe("Points per hour", () => {
    it("Should handle simple points per hour increase with ERC20 Deposits", async () => {
      let info = await deposit.contract.getUserInfo(owner);
      expect(info.pointsPerHour).to.equal(parseEther("0"));
      await addAllowance(token1, owner, deposit, parseEther("1"));
      await deposit.contract.deposit(token1.address, parseEther("1"));
      info = await deposit.contract.getUserInfo(owner);
      expect(info.pointsPerHour).to.equal(parseEther("1"));
      await addAllowance(token2, owner, deposit, parseEther("1"));
      await deposit.contract.deposit(token2.address, parseEther("1"));
      info = await deposit.contract.getUserInfo(owner);
      expect(info.pointsPerHour).to.equal(parseEther("2"));
    });
  });
  describe("calculatePoints and pointBalance", () => {
    it("Should keep points consistent between withdrawal and claim", async () => {
      let calculatedPoints = await deposit.contract.calculatePoints(
        user1.address
      );
      expect(calculatedPoints).to.equal(parseEther("0"));
      let userInfo = await deposit.contract.getUserInfo(user1.address);
      expect(userInfo.pointBalance).to.equal(parseEther("0"));
      await token1.contract.transfer(user1.address, parseEther("1"));
      await addAllowance(token1, user1, deposit, parseEther("1"));
      await depositTokens(deposit, token1, parseEther("1"), user1);
      await time.increase(3599);
      await deposit.contract.stopDeposits();
      await deposit.contract.setClaimManager(owner.address);
      await time.increase(3600);
      calculatedPoints = await deposit.contract.calculatePoints(user1.address);
      expect(calculatedPoints).to.equal(parseEther("1"));
      userInfo = await deposit.contract.getUserInfo(user1.address);
      expect(userInfo.pointBalance).to.equal(parseEther("0"));
      await deposit.contract.withdrawTokens(user1.address);
      await time.increase(3600);
      calculatedPoints = await deposit.contract.calculatePoints(user1.address);
      expect(calculatedPoints).to.equal(parseEther("1"));
      userInfo = await deposit.contract.getUserInfo(user1.address);
      expect(userInfo.pointBalance).to.equal(parseEther("1"));
      await deposit.contract.claim(user1.address);
      await time.increase(3600);
      calculatedPoints = await deposit.contract.calculatePoints(user1.address);
      expect(calculatedPoints).to.equal(parseEther("0"));
      userInfo = await deposit.contract.getUserInfo(user1.address);
      expect(userInfo.pointBalance).to.equal(parseEther("0"));
    });
    it("Should keep points consistent between withdrawal and claim (backwards) ", async () => {
      let calculatedPoints = await deposit.contract.calculatePoints(
        user1.address
      );
      expect(calculatedPoints).to.equal(parseEther("0"));
      let userInfo = await deposit.contract.getUserInfo(user1.address);
      expect(userInfo.pointBalance).to.equal(parseEther("0"));
      await token1.contract.transfer(user1.address, parseEther("1"));
      await addAllowance(token1, user1, deposit, parseEther("1"));
      await depositTokens(deposit, token1, parseEther("1"), user1);
      await time.increase(3599);
      await deposit.contract.stopDeposits();
      await deposit.contract.setClaimManager(owner.address);
      await time.increase(3600);
      await deposit.contract.claim(user1.address);
      await time.increase(3600);
      calculatedPoints = await deposit.contract.calculatePoints(user1.address);
      expect(calculatedPoints).to.equal(parseEther("0"));
      userInfo = await deposit.contract.getUserInfo(user1.address);
      expect(userInfo.pointBalance).to.equal(parseEther("0"));
      await deposit.contract.withdrawTokens(user1.address);
      await time.increase(3600);
      calculatedPoints = await deposit.contract.calculatePoints(user1.address);
      expect(calculatedPoints).to.equal(parseEther("0"));
      userInfo = await deposit.contract.getUserInfo(user1.address);
      expect(userInfo.pointBalance).to.equal(parseEther("0"));
    });
    it("Should correctly calculate points after deposit stop", async () => {
      let calculatedPoints = await deposit.contract.calculatePoints(
        owner.address
      );
      expect(calculatedPoints).to.equal(parseEther("0"));
      await addAllowance(token1, owner, deposit, parseEther("1"));
      await depositTokens(deposit, token1, parseEther("1"), owner);
      await time.increase(3599);
      await deposit.contract.stopDeposits();
      await time.increase(3600);
      calculatedPoints = await deposit.contract.calculatePoints(owner.address);
      // Since deposit stop is in effect, points should only be calculated until depositStop (1 hour = 1 point)
      expect(calculatedPoints).to.equal(parseEther("1"));
    });
    it("Should correctly calculate points after deposit stop and claim", async () => {
      let calculatedPoints = await deposit.contract.calculatePoints(
        owner.address
      );
      expect(calculatedPoints).to.equal(parseEther("0"));
      await addAllowance(token1, owner, deposit, parseEther("1"));
      await depositTokens(deposit, token1, parseEther("1"), owner);
      await time.increase(3599);
      await deposit.contract.stopDeposits();
      await deposit.contract.setClaimManager(owner);
      calculatedPoints = await deposit.contract.calculatePoints(owner.address);
      // Since deposit stop is in effect, points should only be calculated until depositStop (1 hour = 1 point)
      expect(calculatedPoints).to.equal(parseEther("1"));
      await deposit.contract.claim(owner.address);
      await time.increase(3600);
      calculatedPoints = await deposit.contract.calculatePoints(owner.address);
      // Points should reset to zero now that they have been claimed
      expect(calculatedPoints).to.equal(parseEther("0"));
    });
    it("Should correctly calculate points for a user that has never deposited", async () => {
      let calculatedPoints = await deposit.contract.calculatePoints(
        user1.address
      );
      expect(calculatedPoints).to.equal(parseEther("0"));
    });
    it("Should correctly calculate points after deposit stop and withdrawal", async () => {
      let calculatedPoints = await deposit.contract.calculatePoints(
        user1.address
      );
      expect(calculatedPoints).to.equal(parseEther("0"));
      await token1.contract.transfer(user1.address, parseEther("1"));
      await addAllowance(token1, user1, deposit, parseEther("1"));
      await depositTokens(deposit, token1, parseEther("1"), user1);
      await time.increase(3599);
      await deposit.contract.stopDeposits();
      await deposit.contract.setClaimManager(owner.address);
      calculatedPoints = await deposit.contract.calculatePoints(user1.address);
      // Since deposit stop is in effect, points should only be calculated until depositStop (1 hour = 1 point)
      expect(calculatedPoints).to.equal(parseEther("1"));
      await deposit.contract.withdrawTokens(user1.address);
      await time.increase(3600);
      calculatedPoints = await deposit.contract.calculatePoints(user1.address);
      // Points should still be 1 since they haven't yet been claimed
      expect(calculatedPoints).to.equal(parseEther("1"));
    });
    it("Should correctly increase balance for ERC20 deposit", async () => {
      let info = await deposit.contract.getUserInfo(owner);
      expect(info.pointBalance).to.equal(parseEther("0"));
      await addAllowance(token1, owner, deposit, parseEther("1"));
      await deposit.contract.deposit(token1.address, parseEther("1"));
      await time.increase(3600);
      info = await deposit.contract.getUserInfo(owner);
      expect(info.pointBalance).to.equal(parseEther("0"));
      const calculatedPoints = await deposit.contract.calculatePoints(
        owner.address
      );
      expect(calculatedPoints).to.equal(parseEther("1"));
      await time.increase(3600);
      info = await deposit.contract.getUserInfo(owner);
      expect(info.pointBalance).to.equal(parseEther("0"));
      const calculatedPoints2 = await deposit.contract.calculatePoints(
        owner.address
      );
      expect(calculatedPoints2).to.equal(parseEther("2"));
    });
  });
  describe("pointBalance", () => {
    it("Should correctly increase points with a simple ERC20 deposit", async () => {
      let userInfo = await deposit.contract.getUserInfo(owner.address);
      expect(userInfo.pointBalance).to.equal(parseEther("0"));
      await addAllowance(token1, owner, deposit, parseEther("1"));
      await deposit.contract.deposit(token1.address, parseEther("1"));
      // Block time increases by 2h
      await time.increase(3600 * 2 - 2);
      await addAllowance(token1, owner, deposit, parseEther("1"));
      await deposit.contract.deposit(token1.address, parseEther("1"));
      userInfo = await deposit.contract.getUserInfo(owner.address);
      expect(userInfo.pointBalance).to.equal(parseEther("2"));
    });
    it("Should correctly increase points with an ERC20 deposit", async () => {
      let userInfo = await deposit.contract.getUserInfo(owner.address);
      expect(userInfo.pointBalance).to.equal(parseEther("0"));

      await addAllowance(token1, owner, deposit, parseEther("10"));

      // pointBalance should be 0 since no deposits have been made, pointsPerHour should be 2 now
      await deposit.contract.deposit(token1.address, parseEther("2"));

      userInfo = await deposit.contract.getUserInfo(owner.address);
      expect(userInfo.pointBalance).to.equal(parseEther("0"));
      expect(userInfo.pointsPerHour).to.equal(parseEther("2"));

      await time.increase(3599);

      // Block time increases by 1h again, points is now 2pph*1h + existing 0 point = 2 points
      await deposit.contract.deposit(token1.address, parseEther("2"));
      userInfo = await deposit.contract.getUserInfo(owner.address);
      expect(userInfo.pointBalance).to.equal(parseEther("2"));
    });
  });
  ///////////////////////////
  ///////////////////////////
  ///////////////////////////
  ///////////////////////////
  ///////////////////////////
  ///////////////////////////
  ///////////////////////////
  describe("Audit Tests", () => {
    let token1, omronDeposit, owner, user1, user2;

    beforeEach(async () => {
      [owner, user1, user2] = await ethers.getSigners();

      const Token = await ethers.getContractFactory("ERCMock");
      token1 = await Token.deploy(
        "Token1",
        "TK1",
        owner.address,
        ethers.utils.parseEther("1000")
      );
      await token1.deployed();

      const OmronDeposit = await ethers.getContractFactory("OmronDeposit");
      omronDeposit = await OmronDeposit.deploy(owner.address, [token1.address]);
      await omronDeposit.deployed();
    });

    //@audit Manipulation of governance voting result deviating from voted outcome and resulting in a direct change from intended effect of original results
    it("Should prevent manipulation of governance voting results", async function () {
      // This test is not applicable to OmronDeposit as it does not involve governance voting
      // Instead, we will test for manipulation of deposit and withdrawal results

      await token1
        .connect(owner)
        .approve(omronDeposit.address, ethers.utils.parseEther("10"));
      await omronDeposit
        .connect(owner)
        .deposit(token1.address, ethers.utils.parseEther("10"));

      // Attempt to manipulate withdrawal
      await expect(
        omronDeposit.connect(user1).withdrawTokens(owner.address)
      ).to.be.revertedWith("NotClaimManager");

      // Ensure the correct balance remains
      const balance = await token1.balanceOf(omronDeposit.address);
      expect(balance).to.equal(ethers.utils.parseEther("10"));
    });

    //   //@audit Direct theft of any user funds, whether at-rest or in-motion, other than unclaimed yield
    //   it("Should prevent direct theft of user funds", async () => {
    //     // Implement test logic to ensure user funds cannot be stolen
    //     // Example: Ensure that only the owner can withdraw their funds
    //     await addAllowance(token1, owner, deposit, parseEther("1"));
    //     await depositTokens(deposit, token1, parseEther("1"), owner);
    //     await expect(
    //       deposit.contract.connect(user1).withdrawTokens(owner.address)
    //     ).to.be.revertedWithCustomError(deposit.contract, "NotClaimManager");
    //   });

    //   //@audit Permanent freezing of funds
    //   it("Should prevent permanent freezing of funds", async () => {
    //     // Implement test logic to ensure funds cannot be permanently frozen
    //     // Example: Ensure that funds can always be withdrawn unless explicitly paused by the owner
    //     await addAllowance(token1, owner, deposit, parseEther("1"));
    //     await depositTokens(deposit, token1, parseEther("1"), owner);
    //     await deposit.contract.connect(owner).pause();
    //     await expect(
    //       deposit.contract.connect(owner).withdrawTokens(owner.address)
    //     ).to.be.revertedWithCustomError(deposit.contract, "EnforcedPause");
    //     await deposit.contract.connect(owner).unpause();
    //     await expect(
    //       deposit.contract.connect(owner).withdrawTokens(owner.address)
    //     )
    //       .to.emit(deposit.contract, "WithdrawTokens")
    //       .withArgs(owner.address, [parseEther("1")]);
    //   });

    //   //@audit Protocol insolvency
    //   it("Should prevent protocol insolvency", async () => {
    //     // Implement test logic to ensure protocol cannot become insolvent
    //     // Example: Ensure that the protocol maintains a minimum balance to cover all user deposits
    //     await addAllowance(token1, owner, deposit, parseEther("100"));
    //     await depositTokens(deposit, token1, parseEther("100"), owner);
    //     const protocolBalance = await token1.contract.balanceOf(deposit.address);
    //     expect(protocolBalance).to.be.at.least(parseEther("100"));
    //   });

    //   //@audit Theft of funds via Generating a false ZK proof that the verify algorithm deems as correct (breaking protocol soundness)
    //   it("Should prevent theft of funds via false ZK proof", async () => {
    //     // Implement test logic to ensure false ZK proofs cannot be generated
    //     // Example: Ensure that the verify algorithm correctly identifies and rejects false proofs
    //     const zkVerifier = await deployContract("ZKVerifier", [owner.address]);
    //     const falseProof = "0x1234"; // Example false proof
    //     await expect(zkVerifier.verify(falseProof)).to.be.revertedWithCustomError(
    //       zkVerifier,
    //       "InvalidProof"
    //     );
    //   });

    //   //@audit Malicious interactions with an already-connected wallet, such as: Modifying transaction arguments or parameters Substituting contract addresses Submitting malicious transactions
    //   it("Should prevent malicious interactions with connected wallets", async () => {
    //     // Implement test logic to ensure malicious interactions with connected wallets are prevented
    //     // Example: Ensure that transaction arguments and parameters cannot be modified by unauthorized parties
    //     await addAllowance(token1, owner, deposit, parseEther("1"));
    //     await depositTokens(deposit, token1, parseEther("1"), owner);
    //     await expect(
    //       deposit.contract.connect(user1).deposit(token1.address, parseEther("1"))
    //     ).to.be.revertedWithCustomError(deposit.contract, "NotAuthorized");
    //   });

    //   //@audit Theft of unclaimed yield
    //   it("Should prevent theft of unclaimed yield", async () => {
    //     // Implement test logic to ensure unclaimed yield cannot be stolen
    //     // Example: Ensure that only the rightful owner can claim their yield
    //     await deposit.contract.setClaimManager(owner.address);
    //     await expect(
    //       deposit.contract.connect(user1).claimYield(owner.address)
    //     ).to.be.revertedWithCustomError(deposit.contract, "NotClaimManager");
    //   });

    //   //@audit Theft of unclaimed royalties
    //   it("Should prevent theft of unclaimed royalties", async () => {
    //     // Implement test logic to ensure unclaimed royalties cannot be stolen
    //     // Example: Ensure that only the rightful owner can claim their royalties
    //     await deposit.contract.setClaimManager(owner.address);
    //     await expect(
    //       deposit.contract.connect(user1).claimRoyalties(owner.address)
    //     ).to.be.revertedWithCustomError(deposit.contract, "NotClaimManager");
    //   });

    //   //@audit Permanent freezing of unclaimed yield
    //   it("Should prevent permanent freezing of unclaimed yield", async () => {
    //     // Implement test logic to ensure unclaimed yield cannot be permanently frozen
    //     // Example: Ensure that unclaimed yield can always be claimed unless explicitly paused by the owner
    //     await deposit.contract.setClaimManager(owner.address);
    //     await deposit.contract.pause();
    //     await expect(
    //       deposit.contract.connect(owner).claimYield(owner.address)
    //     ).to.be.revertedWithCustomError(deposit.contract, "EnforcedPause");
    //     await deposit.contract.unpause();
    //     await expect(deposit.contract.connect(owner).claimYield(owner.address))
    //       .to.emit(deposit.contract, "YieldClaimed")
    //       .withArgs(owner.address, parseEther("1"));
    //   });

    //   //@audit Permanent freezing of unclaimed royalties
    //   it("Should prevent permanent freezing of unclaimed royalties", async () => {
    //     // Implement test logic to ensure unclaimed royalties cannot be permanently frozen
    //     // Example: Ensure that unclaimed royalties can always be claimed unless explicitly paused by the owner
    //     await deposit.contract.setClaimManager(owner.address);
    //     await deposit.contract.pause();
    //     await expect(
    //       deposit.contract.connect(owner).claimRoyalties(owner.address)
    //     ).to.be.revertedWithCustomError(deposit.contract, "EnforcedPause");
    //     await deposit.contract.unpause();
    //     await expect(
    //       deposit.contract.connect(owner).claimRoyalties(owner.address)
    //     )
    //       .to.emit(deposit.contract, "RoyaltiesClaimed")
    //       .withArgs(owner.address, parseEther("1"));
    //   });

    //   //@audit Temporary freezing of funds for at least 24 hours
    //   it("Should prevent temporary freezing of funds for at least 24 hours", async () => {
    //     // Implement test logic to ensure funds cannot be temporarily frozen for at least 24 hours
    //     // Example: Ensure that funds can be withdrawn within a reasonable time frame
    //     await addAllowance(token1, owner, deposit, parseEther("1"));
    //     await depositTokens(deposit, token1, parseEther("1"), owner);
    //     await deposit.contract.pause();
    //     await time.increase(86400); // Increase time by 24 hours
    //     await deposit.contract.unpause();
    //     await expect(
    //       deposit.contract.connect(owner).withdrawTokens(owner.address)
    //     )
    //       .to.emit(deposit.contract, "WithdrawTokens")
    //       .withArgs(owner.address, [parseEther("1")]);
    //   });

    //   //@audit Smart contract unable to operate due to lack of token funds Block stuffing
    //   it("Should prevent smart contract from being unable to operate due to lack of token funds", async () => {
    //     // Implement test logic to ensure smart contract can operate even with low token funds
    //     // Example: Ensure that the contract has a mechanism to handle low token balances
    //     await addAllowance(token1, owner, deposit, parseEther("1"));
    //     await depositTokens(deposit, token1, parseEther("1"), owner);
    //     await deposit.contract.withdrawTokens(owner.address);
    //     const contractBalance = await token1.contract.balanceOf(deposit.address);
    //     expect(contractBalance).to.be.at.least(parseEther("0"));
    //   });

    //   //@audit Griefing (e.g. no profit motive for an attacker, but damage to the users or the protocol)
    //   it("Should prevent griefing attacks", async () => {
    //     // Implement test logic to ensure griefing attacks are prevented
    //     // Example: Ensure that the contract has mechanisms to detect and mitigate griefing attempts
    //     await addAllowance(token1, owner, deposit, parseEther("1"));
    //     await depositTokens(deposit, token1, parseEther("1"), owner);
    //     await expect(
    //       deposit.contract.connect(user1).grief(owner.address)
    //     ).to.be.revertedWithCustomError(deposit.contract, "NotAuthorized");
    //   });

    //   //@audit Theft of gas
    //   it("Should prevent theft of gas", async () => {
    //     // Implement test logic to ensure gas cannot be stolen
    //     // Example: Ensure that gas costs are correctly accounted for and cannot be manipulated
    //     await addAllowance(token1, owner, deposit, parseEther("1"));
    //     await depositTokens(deposit, token1, parseEther("1"), owner);
    //     const gasUsed = await deposit.contract.estimateGas.withdrawTokens(
    //       owner.address
    //     );
    //     expect(gasUsed).to.be.below(parseEther("0.01")); // Example gas limit
    //   });

    //   //@audit Unbounded gas consumption
    //   it("Should prevent unbounded gas consumption", async () => {
    //     // Implement test logic to ensure gas consumption is bounded
    //     // Example: Ensure that functions have gas limits and cannot consume excessive gas
    //     await addAllowance(token1, owner, deposit, parseEther("1"));
    //     await depositTokens(deposit, token1, parseEther("1"), owner);
    //     const gasUsed = await deposit.contract.estimateGas.deposit(
    //       token1.address,
    //       parseEther("1")
    //     );
    //     expect(gasUsed).to.be.below(parseEther("0.01")); // Example gas limit
    //   });

    //   //@audit Contract fails to deliver promised returns, but doesn't lose value
    //   it("Should ensure contract delivers promised returns", async () => {
    //     // Implement test logic to ensure contract delivers promised returns
    //     // Example: Ensure that the contract correctly calculates and distributes returns to users
    //     await addAllowance(token1, owner, deposit, parseEther("1"));
    //     await depositTokens(deposit, token1, parseEther("1"), owner);
    //     await deposit.contract.setClaimManager(owner.address);
    //     await deposit.contract.stopDeposits();
    //     await expect(deposit.contract.connect(owner).claim(owner.address))
    //       .to.emit(deposit.contract, "ClaimPoints")
    //       .withArgs(owner.address, parseEther("1"));
    //   });
  });
});
