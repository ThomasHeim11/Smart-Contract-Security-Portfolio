import { ethers } from 'hardhat'
import { assert, expect } from 'chai'
import {
  toEther,
  deploy,
  deployUpgradeable,
  getAccounts,
  setupToken,
  fromEther,
  deployImplementation,
} from '../utils/helpers'
import {
  ERC677,
  CommunityVCS,
  StakingMock,
  StakingRewardsMock,
  CommunityVault,
} from '../../typechain-types'
import { loadFixture } from '@nomicfoundation/hardhat-network-helpers'

const unbondingPeriod = 28 * 86400
const claimPeriod = 7 * 86400

const encodeVaults = (vaults: number[]) => {
  return ethers.AbiCoder.defaultAbiCoder().encode(['uint64[]'], [vaults])
}

describe('CommunityVCS', () => {
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

    let vaultImplementation = await deployImplementation('CommunityVault')

    const vaultDepositController = await deploy('VaultDepositController')

    const strategy = (await deployUpgradeable(
      'CommunityVCS',
      [
        adrs.token,
        accounts[0],
        adrs.stakingController,
        vaultImplementation,
        [[accounts[4], 500]],
        9000,
        toEther(100),
        10,
        20,
        vaultDepositController.target,
      ],
      { unsafeAllow: ['delegatecall'] }
    )) as CommunityVCS
    adrs.strategy = await strategy.getAddress()

    await token.approve(adrs.strategy, ethers.MaxUint256)
    await token.transfer(adrs.rewardsController, toEther(10000))

    const vaults = await strategy.getVaults()

    return { accounts, adrs, token, rewardsController, stakingController, strategy, vaults }
  }

  it('addVaults should work correctly', async () => {
    const { adrs, strategy } = await loadFixture(deployFixture)

    await strategy.addVaults(10)
    let vaults = await strategy.getVaults()
    assert.equal(vaults.length, 30)
    for (let i = 0; i < vaults.length; i += 5) {
      let vault = await ethers.getContractAt('CommunityVault', vaults[i])
      assert.equal(await vault.token(), adrs.token)
      assert.equal(await vault.vaultController(), adrs.strategy)
      assert.equal(await vault.stakeController(), adrs.stakingController)
      assert.equal(await vault.rewardsController(), adrs.rewardsController)
    }
  })

  it('checkUpkeep should work correctly', async () => {
    const { strategy } = await loadFixture(deployFixture)

    await strategy.deposit(toEther(1000), encodeVaults([]))
    assert.equal((await strategy.checkUpkeep('0x'))[0], false)

    await strategy.deposit(toEther(90), encodeVaults([]))
    assert.equal((await strategy.checkUpkeep('0x'))[0], false)

    await strategy.deposit(toEther(10), encodeVaults([]))
    assert.equal((await strategy.checkUpkeep('0x'))[0], true)
  })

  it('performUpkeep should work correctly', async () => {
    const { strategy } = await loadFixture(deployFixture)

    await strategy.deposit(toEther(1000), encodeVaults([]))
    expect(strategy.performUpkeep('0x')).to.be.revertedWith('VaultsAboveThreshold()')

    await strategy.deposit(toEther(90), encodeVaults([]))
    expect(strategy.performUpkeep('0x')).to.be.revertedWith('VaultsAboveThreshold()')

    await strategy.deposit(toEther(10), encodeVaults([]))
    await strategy.performUpkeep('0x')
    assert.equal((await strategy.getVaults()).length, 40)
    assert.equal((await strategy.checkUpkeep('0x'))[0], false)
  })

  it('claimRewards should work correctly', async () => {
    const { adrs, strategy, rewardsController, token } = await loadFixture(deployFixture)

    let vaults = await strategy.getVaults()
    await strategy.deposit(toEther(1000), encodeVaults([]))
    await rewardsController.setReward(vaults[1], toEther(5))
    await rewardsController.setReward(vaults[3], toEther(7))
    await rewardsController.setReward(vaults[5], toEther(8))

    await strategy.claimRewards([1, 3, 5], toEther(10))
    assert.equal(fromEther(await token.balanceOf(adrs.strategy)), 0)

    await rewardsController.setReward(vaults[6], toEther(10))
    await rewardsController.setReward(vaults[7], toEther(7))
    await rewardsController.setReward(vaults[8], toEther(15))

    await strategy.claimRewards([6, 7, 8], toEther(10))
    assert.equal(fromEther(await token.balanceOf(adrs.strategy)), 25)

    await rewardsController.setReward(vaults[9], toEther(15))
    await rewardsController.setReward(vaults[10], toEther(15))
    await rewardsController.setReward(vaults[11], toEther(15))

    await strategy.claimRewards([9, 10, 11], toEther(10))
    assert.equal(fromEther(await token.balanceOf(adrs.strategy)), 70)

    await expect(strategy.claimRewards([100], 0)).to.be.reverted
  })

  //@audit
  it('claimRewards should work correctly', async () => {
    const { adrs, strategy, rewardsController, token } = await loadFixture(deployFixture)

    let vaults = await strategy.getVaults()
    await strategy.deposit(toEther(1000), encodeVaults([]))

    // No rewards available //@audit
    await strategy.claimRewards([1, 3, 5], toEther(10))
    console.log('Balance after no rewards:', fromEther(await token.balanceOf(adrs.strategy)))
    assert.equal(fromEther(await token.balanceOf(adrs.strategy)), 0)

    // Rewards less than _minRewards //@audit
    await rewardsController.setReward(vaults[1], toEther(5))
    await rewardsController.setReward(vaults[3], toEther(7))
    await rewardsController.setReward(vaults[5], toEther(8))
    await strategy.claimRewards([1, 3, 5], toEther(10))
    console.log(
      'Balance after rewards less than _minRewards:',
      fromEther(await token.balanceOf(adrs.strategy))
    )
    assert.equal(fromEther(await token.balanceOf(adrs.strategy)), 0)

    // Rewards equal to _minRewards //@audit
    await rewardsController.setReward(vaults[1], toEther(10))
    await strategy.claimRewards([1], toEther(10))
    console.log(
      'Balance after rewards equal to _minRewards:',
      fromEther(await token.balanceOf(adrs.strategy))
    )
    assert.equal(fromEther(await token.balanceOf(adrs.strategy)), 10)

    // Rewards greater than _minRewards
    await rewardsController.setReward(vaults[6], toEther(10))
    await rewardsController.setReward(vaults[7], toEther(7)) // This should not be included
    await rewardsController.setReward(vaults[8], toEther(15))
    await strategy.claimRewards([6, 8], toEther(10)) // Exclude vault 7
    console.log(
      'Balance after rewards greater than _minRewards:',
      fromEther(await token.balanceOf(adrs.strategy))
    )
    assert.equal(fromEther(await token.balanceOf(adrs.strategy)), 25)

    // Multiple claims //@audit
    await rewardsController.setReward(vaults[9], toEther(15))
    await rewardsController.setReward(vaults[10], toEther(15))
    await rewardsController.setReward(vaults[11], toEther(15))
    await strategy.claimRewards([9, 10, 11], toEther(10))
    console.log('Balance after multiple claims:', fromEther(await token.balanceOf(adrs.strategy)))
    assert.equal(fromEther(await token.balanceOf(adrs.strategy)), 70)

    // Claim with zero _minRewards //@audit
    await rewardsController.setReward(vaults[12], toEther(5))
    await strategy.claimRewards([12], 0)
    console.log(
      'Balance after claim with zero _minRewards:',
      fromEther(await token.balanceOf(adrs.strategy))
    )
    assert.equal(fromEther(await token.balanceOf(adrs.strategy)), 75)

    // Invalid vault index //@audit
    await expect(strategy.claimRewards([100], 0)).to.be.reverted

    // Empty vault list //@audit
    await strategy.claimRewards([], 0)
    console.log('Balance after empty vault list:', fromEther(await token.balanceOf(adrs.strategy)))
    assert.equal(fromEther(await token.balanceOf(adrs.strategy)), 75)
  })
})
