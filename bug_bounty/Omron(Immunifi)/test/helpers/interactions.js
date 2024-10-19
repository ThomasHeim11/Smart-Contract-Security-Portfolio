import { expect } from "chai";

export const addAllowance = async (token, owner, spender, amount) => {
  const action = token.contract.connect(owner).approve(spender.address, amount);
  await expect(action).to.emit(token.contract, "Approval");
};

export const depositTokens = async (
  deposit,
  token,
  amount,
  depositor = owner,
  shouldRevert = false,
  revertMessage = ""
) => {
  const action = deposit.contract
    .connect(depositor)
    .deposit(token.address, amount);
  if (shouldRevert) {
    await expect(action).to.be.revertedWithCustomError(
      deposit.contract,
      revertMessage
    );
  } else {
    await expect(action)
      .to.emit(deposit.contract, "Deposit")
      .withArgs(depositor.address, token.address, amount);
  }
};

export const withdrawTokens = async (
  deposit,
  token,
  amount,
  withdrawer = owner,
  shouldRevert = false,
  revertMessage = ""
) => {
  const action = deposit.contract
    .connect(withdrawer)
    .withdraw(token.address, amount);
  if (shouldRevert) {
    await expect(action).to.be.revertedWithCustomError(
      deposit.contract,
      revertMessage
    );
  } else {
    await expect(action)
      .to.emit(deposit.contract, "Withdrawal")
      .withArgs(withdrawer.address, token.address, amount);
  }
};

export const enableWithdrawals = async (
  enabled = true,
  sender = owner,
  shouldRevert = false,
  revertMessage = ""
) => {
  const action = deposit.contract
    .connect(sender)
    .setWithdrawalsEnabled(enabled);
  if (shouldRevert) {
    await expect(action).to.be.revertedWithCustomError(
      deposit.contract,
      revertMessage
    );
  } else {
    await expect(action)
      .to.emit(deposit.contract, "WithdrawalsEnabled")
      .withArgs(enabled);
  }
};

export const pauseContract = async (
  shouldRevert = false,
  revertMessage = ""
) => {
  const action = deposit.contract.connect(owner).pause();
  if (shouldRevert) {
    await expect(action).to.be.revertedWithCustomError(
      deposit.contract,
      revertMessage
    );
  } else {
    await expect(action)
      .to.emit(deposit.contract, "Paused")
      .withArgs(owner.address);
  }
};

export const unpauseContract = async (
  shouldRevert = false,
  revertMessage = ""
) => {
  const action = deposit.contract.connect(owner).unpause();
  if (shouldRevert) {
    await expect(action).to.be.revertedWithCustomError(
      deposit.contract,
      revertMessage
    );
  } else {
    await expect(action)
      .to.emit(deposit.contract, "Unpaused")
      .withArgs(owner.address);
  }
};

export const addTokenToWhitelist = async (
  token,
  shouldRevert = false,
  revertMessage = ""
) => {
  const action = deposit.contract
    .connect(owner)
    .addWhitelistedToken(token.address);
  if (shouldRevert) {
    await expect(action).to.be.revertedWithCustomError(
      deposit.contract,
      revertMessage
    );
  } else {
    await expect(action)
      .to.emit(deposit.contract, "WhitelistedTokenAdded")
      .withArgs(token.address);
  }
};

export const verifyUserInfo = async (
  user,
  expectedPointBalance = null,
  expectedPointsPerHour = null,
  expectedLastUpdated = null
) => {
  const userInfo = await deposit.contract.getUserInfo(user.address);

  if (expectedPointBalance !== null) {
    expect(userInfo.pointBalance).to.equal(
      expectedPointBalance,
      `Incorrect point balance for ${user.address}`
    );
  }

  if (expectedPointsPerHour !== null) {
    expect(userInfo.pointsPerHour).to.equal(
      expectedPointsPerHour,
      `Incorrect points per hour for ${user.address}`
    );
  }

  if (expectedLastUpdated !== null) {
    expect(userInfo.lastUpdated).to.equal(
      expectedLastUpdated,
      `Incorrect last updated for ${user.address}`
    );
  }
};
