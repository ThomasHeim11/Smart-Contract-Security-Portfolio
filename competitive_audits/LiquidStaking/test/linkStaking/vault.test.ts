import { ethers } from 'hardhat'
import { assert, expect } from 'chai'
import {
  toEther,
  deploy,
  deployUpgradeable,
  getAccounts,
  setupToken,
  fromEther,
} from '../utils/helpers'
import { ERC677, CommunityVault, StakingMock, StakingRewardsMock } from '../../typechain-types'
import { loadFixture, time } from '@nomicfoundation/hardhat-network-helpers'

const unbondingPeriod = 28 * 86400
const claimPeriod = 7 * 86400

describe('Vault', () => {
  async function deployFixture() {
    const { accounts } = await getAccounts()
    const adrs: any = {}

    const token = (await deploy('contracts/core/tokens/base/ERC677.sol:ERC677', [
      'Chainlink',
      'LINK',
      1000000000,
    ])) as ERC677
    adrs.token = await token.getAddress()
    await setupToken(token, accounts)

    const rewardsController = (await deploy('StakingRewardsMock', [
      adrs.token,
    ])) as StakingRewardsMock
    adrs.rewardsController = await rewardsController.getAddress()

    const stakingController = (await deploy('StakingMock', [
      adrs.token,
      adrs.rewardsController,
      toEther(10),
      toEther(100),
      toEther(10000),
      unbondingPeriod,
      claimPeriod,
    ])) as StakingMock
    adrs.stakingController = await stakingController.getAddress()

    const vault = (await deployUpgradeable('CommunityVault', [
      adrs.token,
      accounts[0],
      adrs.stakingController,
      adrs.rewardsController,
    ])) as CommunityVault
    adrs.vault = await vault.getAddress()

    await token.approve(adrs.vault, ethers.MaxUint256)

    const signers = await ethers.getSigners()
    return { accounts, adrs, token, rewardsController, stakingController, vault, signers }
  }

  it('should be able to deposit', async () => {
    const { adrs, vault, token, stakingController } = await loadFixture(deployFixture)

    await vault.deposit(toEther(100))
    assert.equal(fromEther(await token.balanceOf(adrs.stakingController)), 100)
    assert.equal(
      fromEther(await stakingController.getStakerPrincipal(adrs.vault)),
      100,
      'balance does not match'
    )

    await vault.deposit(toEther(200))
    assert.equal(fromEther(await token.balanceOf(adrs.stakingController)), 300)
    assert.equal(
      fromEther(await stakingController.getStakerPrincipal(adrs.vault)),
      300,
      'balance does not match'
    )
  })

  it('should be able to unbond', async () => {
    const { adrs, vault, stakingController } = await loadFixture(deployFixture)

    await vault.deposit(toEther(100))
    await vault.unbond()
    let ts: any = (await ethers.provider.getBlock('latest'))?.timestamp
    assert.equal(
      Number(await stakingController.getClaimPeriodEndsAt(adrs.vault)),
      ts + unbondingPeriod + claimPeriod
    )
  })

  it('should be able to withdraw', async () => {
    const { adrs, vault, token, stakingController } = await loadFixture(deployFixture)

    await vault.deposit(toEther(100))
    await vault.unbond()

    await expect(vault.withdraw(toEther(30))).to.be.revertedWithCustomError(
      stakingController,
      'NotInClaimPeriod()'
    )

    await time.increase(unbondingPeriod + 1)

    await vault.withdraw(toEther(30))
    assert.equal(fromEther(await vault.getPrincipalDeposits()), 70)
    assert.equal(fromEther(await token.balanceOf(adrs.stakingController)), 70)
  })

  it('getPrincipalDeposits should work correctly', async () => {
    const { vault } = await loadFixture(deployFixture)

    await vault.deposit(toEther(10))
    assert.equal(fromEther(await vault.getPrincipalDeposits()), 10)

    await vault.deposit(toEther(30))
    assert.equal(fromEther(await vault.getPrincipalDeposits()), 40)
  })

  it('getRewards should work correctly', async () => {
    const { adrs, vault, rewardsController } = await loadFixture(deployFixture)

    await vault.deposit(toEther(100))
    await rewardsController.setReward(adrs.vault, toEther(10))
    assert.equal(fromEther(await vault.getRewards()), 10)

    await rewardsController.setReward(adrs.vault, toEther(40))
    assert.equal(fromEther(await vault.getRewards()), 40)
  })

  it('getTotalDeposits should work correctly', async () => {
    const { adrs, vault, rewardsController } = await loadFixture(deployFixture)

    await vault.deposit(toEther(100))
    await rewardsController.setReward(adrs.vault, toEther(10))
    assert.equal(fromEther(await vault.getTotalDeposits()), 110)

    await vault.deposit(toEther(150))
    await rewardsController.setReward(adrs.vault, toEther(40))
    assert.equal(fromEther(await vault.getTotalDeposits()), 290)
  })

  it('claimPeriodActive should work correctly', async () => {
    const { vault } = await loadFixture(deployFixture)

    assert.equal(await vault.claimPeriodActive(), false)

    await vault.deposit(toEther(100))
    assert.equal(await vault.claimPeriodActive(), false)

    await vault.unbond()
    assert.equal(await vault.claimPeriodActive(), false)

    await time.increase(unbondingPeriod + 1)
    assert.equal(await vault.claimPeriodActive(), true)

    await time.increase(claimPeriod)
    assert.equal(await vault.claimPeriodActive(), false)
  })
  //@audit
  it('should be able to deposit', async () => {
    const { adrs, vault, token, stakingController, signers } = await loadFixture(deployFixture)

    await vault.deposit(toEther(100))
    assert.equal(fromEther(await token.balanceOf(adrs.stakingController)), 100)
    assert.equal(
      fromEther(await stakingController.getStakerPrincipal(adrs.vault)),
      100,
      'balance does not match'
    )

    await vault.deposit(toEther(200))
    assert.equal(fromEther(await token.balanceOf(adrs.stakingController)), 300)
    assert.equal(
      fromEther(await stakingController.getStakerPrincipal(adrs.vault)),
      300,
      'balance does not match'
    )

    // @audit Edge case: Depositing zero amount
    await expect(vault.deposit(0)).to.be.revertedWith('Amount must be greater than zero')

    // @audit Edge case: Depositing more than the balance
    await expect(vault.deposit(toEther(1000))).to.be.revertedWith(
      'ERC20: transfer amount exceeds balance'
    )

    // @audit Edge case: Depositing from an unauthorized account
    await expect(vault.connect(signers[1]).deposit(toEther(100))).to.be.revertedWith(
      'Ownable: caller is not the owner'
    )
  })
  //@audit
  it('should be able to withdraw', async () => {
    const { adrs, vault, token, stakingController } = await loadFixture(deployFixture)

    await vault.deposit(toEther(100))
    await vault.unbond()

    await expect(vault.withdraw(toEther(30))).to.be.revertedWithCustomError(
      stakingController,
      'NotInClaimPeriod()'
    )

    await time.increase(unbondingPeriod + 1)

    await vault.withdraw(toEther(30))
    assert.equal(fromEther(await vault.getPrincipalDeposits()), 70)
    assert.equal(fromEther(await token.balanceOf(adrs.stakingController)), 70)
  })
  //@audit
  it('getTotalDeposits should work correctly', async () => {
    const { adrs, vault, rewardsController } = await loadFixture(deployFixture)

    // Edge Case: Initial state (no deposits or rewards)
    assert.equal(fromEther(await vault.getTotalDeposits()), 0, 'Initial state should be 0')

    // Edge Case: Zero deposit
    await vault.deposit(toEther(0))
    assert.equal(
      fromEther(await vault.getTotalDeposits()),
      0,
      'Total deposits should be 0 after zero deposit'
    )

    // Normal Case: Single deposit and reward
    await vault.deposit(toEther(100))
    await rewardsController.setReward(adrs.vault, toEther(10))
    assert.equal(
      fromEther(await vault.getTotalDeposits()),
      110,
      'Total deposits should be 110 after first deposit and reward'
    )

    // Normal Case: Multiple deposits and rewards
    await vault.deposit(toEther(150))
    await rewardsController.setReward(adrs.vault, toEther(40))
    assert.equal(
      fromEther(await vault.getTotalDeposits()),
      290,
      'Total deposits should be 290 after second deposit and reward'
    )

    // Edge Case: Negative rewards (if applicable)
    // Assuming the rewardsController can set negative rewards, which might not be the case in a real scenario
    // Uncomment the following lines if negative rewards are applicable
    // await rewardsController.setReward(adrs.vault, toEther(-10));
    // assert.equal(fromEther(await vault.getTotalDeposits()), 280, 'Total deposits should be 280 after negative reward');

    // Edge Case: Zero rewards
    await rewardsController.setReward(adrs.vault, toEther(0))
    assert.equal(
      fromEther(await vault.getTotalDeposits()),
      250,
      'Total deposits should be 250 after zero reward'
    )
  })
})
