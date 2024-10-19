import { ethers } from 'hardhat'
import { assert, expect } from 'chai'
import {
  toEther,
  deploy,
  deployUpgradeable,
  deployImplementation,
  getAccounts,
  setupToken,
  fromEther,
} from '../utils/helpers'
import {
  ERC677,
  OperatorVault,
  VCSMock,
  StakingMock,
  CommunityVault,
  StakingRewardsMock,
  CommunityVaultV2Mock,
  FundFlowController,
} from '../../typechain-types'
import { Interface } from 'ethers'
import { loadFixture, time } from '@nomicfoundation/hardhat-network-helpers'

const unbondingPeriod = 28 * 86400
const claimPeriod = 7 * 86400

function encodeVaults(vaults: number[]) {
  return ethers.AbiCoder.defaultAbiCoder().encode(['uint64[]'], [vaults])
}

describe('VaultControllerStrategy', () => {
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
      'VCSMock',
      [
        adrs.token,
        accounts[0],
        adrs.stakingController,
        vaultImplementation,
        [[accounts[4], 500]],
        toEther(100),
        vaultDepositController.target,
      ],
      { unsafeAllow: ['delegatecall'] }
    )) as VCSMock
    adrs.strategy = await strategy.getAddress()

    const strategy2 = (await deployUpgradeable(
      'VCSMock',
      [
        adrs.token,
        accounts[0],
        adrs.stakingController,
        vaultImplementation,
        [[accounts[4], 500]],
        toEther(100),
        vaultDepositController.target,
      ],
      { unsafeAllow: ['delegatecall'] }
    )) as VCSMock
    adrs.strategy2 = await strategy2.getAddress()

    const vaults = []
    const vaultContracts = []
    for (let i = 0; i < 15; i++) {
      let vault = (await deployUpgradeable('CommunityVault', [
        adrs.token,
        adrs.strategy,
        adrs.stakingController,
        adrs.rewardsController,
      ])) as CommunityVault
      vaultContracts.push(vault)
      vaults.push(await vault.getAddress())
    }

    for (let i = 0; i < 15; i++) {
      vaultContracts[i].transferOwnership(adrs.strategy)
    }

    await strategy.addVaults(vaults)
    await token.approve(adrs.strategy, ethers.MaxUint256)

    const fundFlowController = (await deployUpgradeable('FundFlowController', [
      adrs.strategy2,
      adrs.strategy,
      unbondingPeriod,
      claimPeriod,
      5,
    ])) as FundFlowController
    adrs.fundFlowController = await fundFlowController.getAddress()

    await strategy.setFundFlowController(adrs.fundFlowController)
    await strategy2.setFundFlowController(adrs.fundFlowController)

    return {
      accounts,
      adrs,
      token,
      rewardsController,
      stakingController,
      strategy,
      strategy2,
      vaults,
      vaultContracts,
      fundFlowController,
      vaultDepositController, // Add this line
    }
  }

  it('getVaults should work correctly', async () => {
    const { strategy, vaults } = await loadFixture(deployFixture)

    assert.deepEqual(await strategy.getVaults(), vaults)
  })

  it('getVaultDepositLimits should work correctly', async () => {
    const { strategy } = await loadFixture(deployFixture)

    assert.deepEqual(
      (await strategy.getVaultDepositLimits()).map((v) => fromEther(v)),
      [10, 100]
    )
  })

  it('depositToVaults should work correctly', async () => {
    const { adrs, strategy, token, stakingController, vaults, fundFlowController } =
      await loadFixture(deployFixture)

    // Deposit into vaults that don't yet belong to a group

    await strategy.deposit(toEther(50), encodeVaults([]))
    assert.equal(fromEther(await token.balanceOf(adrs.stakingController)), 50)
    assert.equal(fromEther(await stakingController.getStakerPrincipal(vaults[0])), 50)
    assert.equal(Number((await strategy.globalVaultState())[3]), 0)

    await strategy.deposit(toEther(155), encodeVaults([]))
    assert.equal(fromEther(await token.balanceOf(adrs.stakingController)), 200)
    assert.equal(fromEther(await stakingController.getStakerPrincipal(vaults[0])), 100)
    assert.equal(fromEther(await stakingController.getStakerPrincipal(vaults[1])), 100)
    assert.equal(fromEther(await stakingController.getStakerPrincipal(vaults[2])), 0)
    assert.equal(Number((await strategy.globalVaultState())[3]), 2)

    await strategy.deposit(toEther(1000), encodeVaults([]))
    assert.equal(fromEther(await token.balanceOf(adrs.stakingController)), 1200)
    assert.equal(Number((await strategy.globalVaultState())[3]), 12)

    // Deposit into vault groups

    await fundFlowController.updateVaultGroups()
    await time.increase(claimPeriod)
    await fundFlowController.updateVaultGroups()
    await time.increase(claimPeriod)
    await fundFlowController.updateVaultGroups()
    await time.increase(claimPeriod)
    await fundFlowController.updateVaultGroups()
    await time.increase(claimPeriod)
    await fundFlowController.updateVaultGroups()
    await strategy.withdraw(toEther(50), encodeVaults([0, 5]))
    await time.increase(claimPeriod)
    await fundFlowController.updateVaultGroups()
    await strategy.withdraw(toEther(270), encodeVaults([1, 6, 11]))
    await time.increase(claimPeriod)
    await fundFlowController.updateVaultGroups()
    await strategy.withdraw(toEther(100), encodeVaults([2, 7]))
    await time.increase(claimPeriod)
    await fundFlowController.updateVaultGroups()
    await strategy.withdraw(toEther(120), encodeVaults([3, 8]))
    await time.increase(claimPeriod)
    await fundFlowController.updateVaultGroups()
    await strategy.withdraw(toEther(200), encodeVaults([4, 9]))

    assert.equal(fromEther(await token.balanceOf(adrs.stakingController)), 460)

    await strategy.deposit(toEther(50), encodeVaults([0, 1, 6]))
    assert.equal(fromEther(await token.balanceOf(adrs.stakingController)), 510)
    assert.equal(fromEther(await stakingController.getStakerPrincipal(vaults[1])), 50)
    assert.equal(fromEther(await strategy.canWithdraw()), 0)
    assert.deepEqual(
      await strategy.vaultGroups(1).then((d) => [Number(d[0]), fromEther(d[1])]),
      [11, 220]
    )

    await time.increase(claimPeriod)
    await fundFlowController.updateVaultGroups()
    await time.increase(claimPeriod)
    await fundFlowController.updateVaultGroups()

    await expect(
      strategy.deposit(toEther(200), encodeVaults([6, 11, 4]))
    ).to.be.revertedWithCustomError(strategy, 'DepositFailed()')
    await expect(
      strategy.deposit(toEther(200), encodeVaults([1, 12]))
    ).to.be.revertedWithCustomError(strategy, 'DepositFailed()')

    await strategy.deposit(toEther(200), encodeVaults([1, 6, 11, 4]))
    assert.equal(fromEther(await token.balanceOf(adrs.stakingController)), 710)
    assert.equal(fromEther(await stakingController.getStakerPrincipal(vaults[1])), 100)
    assert.equal(fromEther(await stakingController.getStakerPrincipal(vaults[6])), 100)
    assert.equal(fromEther(await stakingController.getStakerPrincipal(vaults[4])), 50)
    assert.equal(fromEther(await strategy.canWithdraw()), 30)
    assert.deepEqual(
      await strategy.vaultGroups(1).then((d) => [Number(d[0]), fromEther(d[1])]),
      [11, 70]
    )
    assert.deepEqual(
      await strategy.vaultGroups(4).then((d) => [Number(d[0]), fromEther(d[1])]),
      [9, 150]
    )

    await strategy.deposit(toEther(100), encodeVaults([4, 9]))
    assert.equal(fromEther(await token.balanceOf(adrs.stakingController)), 810)
    assert.equal(fromEther(await stakingController.getStakerPrincipal(vaults[4])), 100)
    assert.equal(fromEther(await stakingController.getStakerPrincipal(vaults[9])), 50)
    assert.equal(fromEther(await strategy.canWithdraw()), 30)
    assert.deepEqual(
      await strategy.vaultGroups(4).then((d) => [Number(d[0]), fromEther(d[1])]),
      [4, 50]
    )

    // Deposit into vault groups and non-group vaults

    await strategy.deposit(toEther(600), encodeVaults([9, 0, 1, 2, 3, 4, 5, 6, 7, 8, 10, 11]))
    assert.equal(fromEther(await token.balanceOf(adrs.stakingController)), 1360)
    assert.deepEqual(
      await strategy.vaultGroups(0).then((d) => [Number(d[0]), fromEther(d[1])]),
      [0, 50]
    )
    assert.deepEqual(
      await strategy.vaultGroups(1).then((d) => [Number(d[0]), fromEther(d[1])]),
      [11, 70]
    )
    assert.deepEqual(
      await strategy.vaultGroups(2).then((d) => [Number(d[0]), fromEther(d[1])]),
      [7, 0]
    )
    assert.deepEqual(
      await strategy.vaultGroups(3).then((d) => [Number(d[0]), fromEther(d[1])]),
      [8, 20]
    )
    assert.deepEqual(
      await strategy.vaultGroups(4).then((d) => [Number(d[0]), fromEther(d[1])]),
      [4, 0]
    )
    assert.equal(fromEther(await stakingController.getStakerPrincipal(vaults[12])), 100)
    assert.equal(fromEther(await stakingController.getStakerPrincipal(vaults[13])), 100)
    assert.equal(fromEther(await stakingController.getStakerPrincipal(vaults[14])), 100)

    await strategy.setVaultDepositController(ethers.ZeroAddress)
    await expect(strategy.deposit(toEther(50), encodeVaults([]))).to.be.revertedWithCustomError(
      strategy,
      'VaultDepositControllerNotSet()'
    )
  })

  it('deposit should work correctly', async () => {
    const { adrs, strategy, token, stakingController, vaults } = await loadFixture(deployFixture)

    await strategy.deposit(toEther(50), encodeVaults([]))
    assert.equal(fromEther(await token.balanceOf(adrs.stakingController)), 50)
    assert.equal(fromEther(await stakingController.getStakerPrincipal(vaults[0])), 50)
    assert.equal(fromEther(await strategy.totalPrincipalDeposits()), 50)
    assert.equal(fromEther(await strategy.getTotalDeposits()), 50)

    await strategy.deposit(toEther(150), encodeVaults([]))
    assert.equal(fromEther(await token.balanceOf(adrs.stakingController)), 200)
    assert.equal(fromEther(await strategy.totalPrincipalDeposits()), 200)
    assert.equal(fromEther(await strategy.getTotalDeposits()), 200)

    await token.transfer(adrs.strategy, toEther(500))
    await strategy.deposit(toEther(20), encodeVaults([]))
    assert.equal(fromEther(await token.balanceOf(adrs.stakingController)), 720)
    assert.equal(fromEther(await strategy.totalPrincipalDeposits()), 720)
    assert.equal(fromEther(await strategy.getTotalDeposits()), 720)

    await stakingController.setDepositLimits(toEther(10), toEther(120))
    await strategy.deposit(toEther(80), encodeVaults([]))
    assert.equal(fromEther(await token.balanceOf(adrs.stakingController)), 800)
    assert.equal(fromEther(await stakingController.getStakerPrincipal(vaults[7])), 100)
    assert.equal(fromEther(await strategy.totalPrincipalDeposits()), 800)
    assert.equal(fromEther(await strategy.getTotalDeposits()), 800)

    await token.transfer(adrs.strategy, toEther(2000))
    await strategy.deposit(toEther(20), encodeVaults([]))
    assert.equal(fromEther(await token.balanceOf(adrs.stakingController)), 1660)
    assert.equal(fromEther(await token.balanceOf(adrs.strategy)), 0)
    assert.equal(fromEther(await strategy.totalPrincipalDeposits()), 1660)
    assert.equal(fromEther(await strategy.getTotalDeposits()), 1660)
  })

  it('withdraw should work correctly', async () => {
    const { adrs, strategy, token, stakingController, vaults, fundFlowController } =
      await loadFixture(deployFixture)

    await strategy.deposit(toEther(1200), encodeVaults([]))
    await fundFlowController.updateVaultGroups()
    await time.increase(claimPeriod)
    await fundFlowController.updateVaultGroups()
    await time.increase(claimPeriod)
    await fundFlowController.updateVaultGroups()
    await time.increase(claimPeriod)
    await fundFlowController.updateVaultGroups()
    await time.increase(claimPeriod)
    await fundFlowController.updateVaultGroups()

    await expect(
      strategy.withdraw(toEther(150), encodeVaults([5, 10]))
    ).to.be.revertedWithCustomError(strategy, 'WithdrawalFailed()')
    await expect(
      strategy.withdraw(toEther(150), encodeVaults([0, 1]))
    ).to.be.revertedWithCustomError(strategy, 'WithdrawalFailed()')

    await strategy.withdraw(toEther(150), encodeVaults([0, 5]))
    assert.equal(fromEther(await token.balanceOf(adrs.stakingController)), 1050)
    assert.equal(fromEther(await stakingController.getStakerPrincipal(vaults[0])), 0)
    assert.equal(fromEther(await stakingController.getStakerPrincipal(vaults[5])), 50)
    assert.equal(fromEther(await strategy.totalPrincipalDeposits()), 1050)
    assert.equal(fromEther(await strategy.getTotalDeposits()), 1050)
    assert.equal(fromEther(await strategy.canWithdraw()), 150)
    assert.deepEqual(
      await strategy.vaultGroups(0).then((d) => [Number(d[0]), fromEther(d[1])]),
      [5, 150]
    )

    await time.increase(claimPeriod)
    await fundFlowController.updateVaultGroups()

    await strategy.withdraw(toEther(75), encodeVaults([1, 6]))
    assert.equal(fromEther(await token.balanceOf(adrs.stakingController)), 975)
    assert.equal(fromEther(await stakingController.getStakerPrincipal(vaults[1])), 25)
    assert.equal(fromEther(await strategy.totalPrincipalDeposits()), 975)
    assert.equal(fromEther(await strategy.getTotalDeposits()), 975)
    assert.equal(fromEther(await strategy.canWithdraw()), 225)
    assert.deepEqual(
      await strategy.vaultGroups(1).then((d) => [Number(d[0]), fromEther(d[1])]),
      [1, 75]
    )

    await strategy.withdraw(toEther(120), encodeVaults([1, 6]))
    assert.equal(fromEther(await token.balanceOf(adrs.stakingController)), 850)
    assert.equal(fromEther(await token.balanceOf(adrs.strategy)), 0)
    assert.equal(fromEther(await stakingController.getStakerPrincipal(vaults[1])), 0)
    assert.equal(fromEther(await stakingController.getStakerPrincipal(vaults[6])), 0)
    assert.equal(fromEther(await strategy.totalPrincipalDeposits()), 850)
    assert.equal(fromEther(await strategy.getTotalDeposits()), 850)
    assert.equal(fromEther(await strategy.canWithdraw()), 100)
    assert.deepEqual(
      await strategy.vaultGroups(1).then((d) => [Number(d[0]), fromEther(d[1])]),
      [6, 200]
    )

    await expect(
      strategy.withdraw(toEther(101), encodeVaults([6, 11]))
    ).to.be.revertedWithCustomError(strategy, 'WithdrawalFailed()')

    await time.increase(claimPeriod)

    await expect(strategy.withdraw(toEther(20), encodeVaults([6]))).to.be.revertedWithCustomError(
      strategy,
      'WithdrawalFailed()'
    )

    await fundFlowController.updateVaultGroups()

    await strategy.withdraw(toEther(200), encodeVaults([2, 7]))
    assert.equal(fromEther(await token.balanceOf(adrs.stakingController)), 650)
    assert.equal(fromEther(await stakingController.getStakerPrincipal(vaults[2])), 0)
    assert.equal(fromEther(await stakingController.getStakerPrincipal(vaults[7])), 0)
    assert.equal(fromEther(await strategy.totalPrincipalDeposits()), 650)
    assert.equal(fromEther(await strategy.getTotalDeposits()), 650)
    assert.equal(fromEther(await strategy.canWithdraw()), 0)
    assert.deepEqual(
      await strategy.vaultGroups(2).then((d) => [Number(d[0]), fromEther(d[1])]),
      [7, 200]
    )
  })

  it('depositChange should work correctly', async () => {
    const { adrs, strategy, token, rewardsController, vaults } = await loadFixture(deployFixture)

    await strategy.deposit(toEther(300), encodeVaults([]))

    assert.equal(fromEther(await strategy.getDepositChange()), 0)

    await rewardsController.setReward(vaults[0], toEther(100))
    assert.equal(fromEther(await strategy.getDepositChange()), 100)

    await rewardsController.setReward(vaults[1], toEther(50))
    assert.equal(fromEther(await strategy.getDepositChange()), 150)

    await token.transfer(adrs.strategy, toEther(50))
    assert.equal(fromEther(await strategy.getDepositChange()), 200)

    await rewardsController.setReward(vaults[0], toEther(60))
    assert.equal(fromEther(await strategy.getDepositChange()), 160)

    await strategy.updateDeposits('0x')
    await rewardsController.setReward(vaults[0], toEther(50))
    assert.equal(fromEther(await strategy.getDepositChange()), -10)
  })

  it('updateDeposits should work correctly', async () => {
    const { accounts, adrs, strategy, token, rewardsController, vaults } = await loadFixture(
      deployFixture
    )

    await strategy.deposit(toEther(300), encodeVaults([]))

    await strategy.updateDeposits('0x')
    assert.equal(fromEther(await strategy.getTotalDeposits()), 300)
    assert.equal(fromEther(await strategy.getDepositChange()), 0)

    await rewardsController.setReward(vaults[0], toEther(10))
    await strategy.updateDeposits('0x')
    assert.equal(fromEther(await strategy.getTotalDeposits()), 310)
    assert.equal(fromEther(await strategy.getDepositChange()), 0)

    await rewardsController.setReward(vaults[1], toEther(5))
    await strategy.updateDeposits('0x')
    assert.equal(fromEther(await strategy.getTotalDeposits()), 315)
    assert.equal(fromEther(await strategy.getDepositChange()), 0)

    let initialBalance = await token.balanceOf(accounts[0])
    await token.transfer(adrs.strategy, toEther(20))
    await strategy.updateDeposits('0x')
    assert.equal(fromEther(await strategy.getTotalDeposits()), 315)
    assert.equal(fromEther(await strategy.getDepositChange()), 0)
    assert.equal(fromEther(initialBalance - (await token.balanceOf(accounts[0]))), 0)

    await rewardsController.setReward(vaults[1], toEther(0))
    await strategy.updateDeposits('0x')
    assert.equal(fromEther(await strategy.getTotalDeposits()), 310)
    assert.equal(fromEther(await strategy.getDepositChange()), 0)
  })

  it('fees should be properly calculated in updateDeposits', async () => {
    const { accounts, adrs, strategy, token, rewardsController, vaults } = await loadFixture(
      deployFixture
    )

    await strategy.deposit(toEther(300), encodeVaults([]))

    await rewardsController.setReward(vaults[0], toEther(100))
    await strategy.addFeeBypassUpdate(accounts[3], 1000)
    let data = await strategy.updateDeposits.staticCall('0x')

    assert.equal(fromEther(data.depositChange), 100)
    assert.equal(data.receivers[0], accounts[4])
    assert.equal(data.receivers[1], accounts[3])
    assert.equal(fromEther(data.amounts[0]), 5)
    assert.equal(fromEther(data.amounts[1]), 10)

    await token.transfer(adrs.strategy, toEther(100))
    data = await strategy.updateDeposits.staticCall('0x')

    assert.equal(fromEther(data.depositChange), 200)
    assert.equal(data.receivers[0], accounts[4])
    assert.equal(data.receivers[1], accounts[3])
    assert.equal(fromEther(data.amounts[0]), 10)
    assert.equal(fromEther(data.amounts[1]), 20)

    await strategy.updateDeposits('0x')
    await rewardsController.setReward(vaults[0], toEther(50))
    data = await strategy.updateDeposits.staticCall('0x')

    assert.equal(fromEther(data.depositChange), -50)
    assert.deepEqual(data.receivers, [])
    assert.deepEqual(data.amounts, [])
  })

  it('getMinDeposits should work correctly', async () => {
    const { strategy, rewardsController, vaults } = await loadFixture(deployFixture)

    await strategy.deposit(toEther(100), encodeVaults([]))
    assert.equal(fromEther(await strategy.getMinDeposits()), 100)

    await rewardsController.setReward(vaults[0], toEther(50))
    await strategy.updateDeposits('0x')
    assert.equal(fromEther(await strategy.getMinDeposits()), 150)
  })

  it('getMaxDeposits should work correctly', async () => {
    const { strategy, stakingController, rewardsController, vaults } = await loadFixture(
      deployFixture
    )

    assert.equal(fromEther(await strategy.getMaxDeposits()), 1500)

    await strategy.deposit(toEther(100), encodeVaults([]))
    assert.equal(fromEther(await strategy.getMaxDeposits()), 1500)

    await rewardsController.setReward(vaults[1], toEther(100))
    assert.equal(fromEther(await strategy.getMaxDeposits()), 1500)

    await strategy.updateDeposits('0x')
    assert.equal(fromEther(await strategy.getMaxDeposits()), 1600)

    await stakingController.setMaxPoolSize(toEther(1000))
    assert.equal(fromEther(await strategy.getMaxDeposits()), 1010)
  })

  it('deployVault should work correctly', async () => {
    const { accounts, adrs, strategy } = await loadFixture(deployFixture)

    let newVaultImplementation = (await deployImplementation('OperatorVault')) as string
    await strategy.setVaultImplementation(newVaultImplementation)
    let vaultInterface = (await ethers.getContractFactory('OperatorVault')).interface as Interface

    for (let i = 1; i < 5; i++) {
      await strategy.deployVault(
        vaultInterface.encodeFunctionData('initialize', [
          adrs.token,
          adrs.strategy,
          adrs.stakingController,
          adrs.rewardsController,
          accounts[0],
          accounts[i],
          accounts[0],
        ])
      )
    }

    let vaults = await strategy.getVaults()

    for (let i = 1; i < 5; i++) {
      let vault = (await ethers.getContractAt('OperatorVault', vaults[14 + i])) as OperatorVault
      assert.equal(await vault.operator(), accounts[i])
    }
  })

  it('upgradeVaults should work correctly', async () => {
    const { strategy, vaults } = await loadFixture(deployFixture)

    let vaultInterface = (await ethers.getContractFactory('CommunityVaultV2Mock'))
      .interface as Interface

    let newVaultImplementation = (await deployImplementation('CommunityVaultV2Mock')) as string
    await strategy.setVaultImplementation(newVaultImplementation)

    await strategy.upgradeVaults([0, 1, 2, 3, 4], ['0x', '0x', '0x', '0x', '0x'])
    for (let i = 0; i < 5; i++) {
      let vault = (await ethers.getContractAt(
        'CommunityVaultV2Mock',
        vaults[i]
      )) as CommunityVaultV2Mock
      assert.equal(await vault.isUpgraded(), true)
    }

    await strategy.upgradeVaults(
      [5, 6, 7, 8, 9],
      [
        vaultInterface.encodeFunctionData('initializeV2', [5]),
        vaultInterface.encodeFunctionData('initializeV2', [6]),
        vaultInterface.encodeFunctionData('initializeV2', [7]),
        vaultInterface.encodeFunctionData('initializeV2', [8]),
        vaultInterface.encodeFunctionData('initializeV2', [9]),
      ]
    )
    for (let i = 5; i < 10; i++) {
      let vault = (await ethers.getContractAt(
        'CommunityVaultV2Mock',
        vaults[i]
      )) as CommunityVaultV2Mock
      assert.equal(await vault.isUpgraded(), true)
      assert.equal(Number(await vault.getVersion()), i)
    }
  })

  it('setVaultImplementation should work correctly', async () => {
    const { strategy } = await loadFixture(deployFixture)

    let newVaultImplementation = (await deployImplementation('OperatorVault')) as string
    await strategy.setVaultImplementation(newVaultImplementation)
    assert.equal(await strategy.vaultImplementation(), newVaultImplementation)
  })

  it('setWithdrawalIndexes should work correctly', async () => {
    const { strategy } = await loadFixture(deployFixture)

    await strategy.setWithdrawalIndexes([5, 6, 7, 8, 9])
    await expect(strategy.setWithdrawalIndexes([0, 1, 2, 3, 5])).to.be.revertedWithCustomError(
      strategy,
      'InvalidWithdrawalIndexes()'
    )
  })
  //@audit Finding Vulnerability in VaultDepositController: Delegatecall Failures in Deposit and Withdraw Functions Do Not Revert as Expected, Indirectly Putting Funds at Risk
  it('should revert deposit if VaultDepositController is not set', async () => {
    const { strategy, token } = await loadFixture(deployFixture)

    console.log('Setting VaultDepositController to zero address')
    await strategy.setVaultDepositController(ethers.ZeroAddress)

    console.log('Attempting to deposit with VaultDepositController not set')
    await expect(strategy.deposit(toEther(50), encodeVaults([]))).to.be.revertedWithCustomError(
      strategy,
      'VaultDepositControllerNotSet()'
    )
    console.log('Deposit reverted as expected')
  })

  it('should revert withdraw if VaultDepositController is not set', async () => {
    const { strategy } = await loadFixture(deployFixture)

    console.log('Setting VaultDepositController to zero address')
    await strategy.setVaultDepositController(ethers.ZeroAddress)

    console.log('Attempting to withdraw with VaultDepositController not set')
    await expect(strategy.withdraw(toEther(50), encodeVaults([]))).to.be.revertedWithCustomError(
      strategy,
      'VaultDepositControllerNotSet()'
    )
    console.log('Withdraw reverted as expected')
  })

  it('should revert deposit if delegatecall fails', async () => {
    const { strategy, token } = await loadFixture(deployFixture)
    const depositAmount = toEther(50)

    console.log(
      'Setting VaultDepositController to an invalid address to simulate delegatecall failure'
    )
    await strategy.setVaultDepositController('0x000000000000000000000000000000000000dEaD')

    console.log(`Attempting to deposit ${depositAmount.toString()} ETH with failing delegatecall`)
    try {
      const initialBalance = await ethers.provider.getBalance(await strategy.getAddress())
      console.log(`Initial ETH balance of strategy: ${initialBalance.toString()}`)

      await strategy.deposit(depositAmount, encodeVaults([]))

      const finalBalance = await ethers.provider.getBalance(await strategy.getAddress())
      console.log(`Final ETH balance of strategy: ${finalBalance.toString()}`)
      console.log(`Deposit of ${depositAmount.toString()} ETH did not revert as expected`)
    } catch (error) {
      console.log(`Deposit of ${depositAmount.toString()} ETH reverted with error:`, error)
      if (error instanceof Error) {
        console.log('Error message:', error.message)
        console.log('Error stack:', error.stack)
      }
      await expect(Promise.reject(error)).to.be.revertedWithCustomError(strategy, 'DepositFailed()')
    }
  })

  it('should revert withdraw if delegatecall fails', async () => {
    const { strategy } = await loadFixture(deployFixture)
    const withdrawAmount = toEther(50)

    console.log(
      'Setting VaultDepositController to an invalid address to simulate delegatecall failure'
    )
    await strategy.setVaultDepositController('0x000000000000000000000000000000000000dEaD')

    console.log(`Attempting to withdraw ${withdrawAmount.toString()} ETH with failing delegatecall`)
    try {
      const initialBalance = await ethers.provider.getBalance(await strategy.getAddress())
      console.log(`Initial ETH balance of strategy: ${initialBalance.toString()}`)

      await strategy.withdraw(withdrawAmount, encodeVaults([]))

      const finalBalance = await ethers.provider.getBalance(await strategy.getAddress())
      console.log(`Final ETH balance of strategy: ${finalBalance.toString()}`)
      console.log(`Withdraw of ${withdrawAmount.toString()} ETH did not revert as expected`)
    } catch (error) {
      console.log(`Withdraw of ${withdrawAmount.toString()} ETH reverted with error:`, error)
      if (error instanceof Error) {
        console.log('Error message:', error.message)
        console.log('Error stack:', error.stack)
        await expect(Promise.reject(error)).to.be.revertedWithCustomError(
          strategy,
          'WithdrawalFailed()'
        )
      } else {
        console.log('Unknown error:', error)
        await expect(Promise.reject(new Error('Unknown error'))).to.be.revertedWithCustomError(
          strategy,
          'WithdrawalFailed()'
        )
      }
    }
  })
  //@audit
  it('should revert deposit if VaultDepositController is not set', async () => {
    const { strategy, token } = await loadFixture(deployFixture)

    console.log('Setting VaultDepositController to zero address')
    await strategy.setVaultDepositController(ethers.ZeroAddress)

    console.log('Attempting to deposit with VaultDepositController not set')
    await expect(strategy.deposit(toEther(50), encodeVaults([]))).to.be.revertedWithCustomError(
      strategy,
      'VaultDepositControllerNotSet()'
    )
    console.log('Deposit reverted as expected')
  })

  it('should revert withdraw if VaultDepositController is not set', async () => {
    const { strategy } = await loadFixture(deployFixture)

    console.log('Setting VaultDepositController to zero address')
    await strategy.setVaultDepositController(ethers.ZeroAddress)

    console.log('Attempting to withdraw with VaultDepositController not set')
    await expect(strategy.withdraw(toEther(50), encodeVaults([]))).to.be.revertedWithCustomError(
      strategy,
      'VaultDepositControllerNotSet()'
    )
    console.log('Withdraw reverted as expected')
  })

  it('should revert deposit if delegatecall fails', async () => {
    const { strategy, token } = await loadFixture(deployFixture)

    console.log(
      'Setting VaultDepositController to an invalid address to simulate delegatecall failure'
    )
    await strategy.setVaultDepositController('0x000000000000000000000000000000000000dEaD')

    console.log('Attempting to deposit with failing delegatecall')
    try {
      await strategy.deposit(toEther(50), encodeVaults([]))
      console.log('Deposit did not revert as expected')
    } catch (error) {
      console.log('Deposit reverted with error:', error)
      if (error instanceof Error) {
        console.log('Error message:', error.message)
        console.log('Error stack:', error.stack)
      }
      await expect(Promise.reject(error)).to.be.revertedWithCustomError(strategy, 'DepositFailed()')
    }
  })

  it('should revert withdraw if delegatecall fails', async () => {
    const { strategy } = await loadFixture(deployFixture)

    console.log(
      'Setting VaultDepositController to an invalid address to simulate delegatecall failure'
    )
    await strategy.setVaultDepositController('0x000000000000000000000000000000000000dEaD')

    console.log('Attempting to withdraw with failing delegatecall')
    try {
      await strategy.withdraw(toEther(50), encodeVaults([]))
      console.log('Withdraw did not revert as expected')
    } catch (error) {
      console.log('Withdraw reverted with error:', error)
      if (error instanceof Error) {
        console.log('Error message:', error.message)
        console.log('Error stack:', error.stack)
      }
      await expect(Promise.reject(error)).to.be.revertedWithCustomError(
        strategy,
        'WithdrawalFailed()'
      )
    }
  })
  //@audit
  it('should handle deposit limits correctly in _depositToVaults', async () => {
    const { adrs, strategy, token, stakingController, vaults } = await loadFixture(deployFixture)

    // Set up initial conditions
    await token.transfer(adrs.strategy, toEther(1000))
    await strategy.deposit(toEther(500), encodeVaults([]))

    // Log initial balances and deposits
    console.log(
      'Initial balance of stakingController:',
      fromEther(await token.balanceOf(adrs.stakingController))
    )
    console.log(
      'Initial totalPrincipalDeposits:',
      fromEther(await strategy.totalPrincipalDeposits())
    )
    console.log('Initial totalDeposits:', fromEther(await strategy.getTotalDeposits()))

    // Set deposit limits
    const minDepositLimit = toEther(10)
    const maxDepositLimit = toEther(120)
    await stakingController.setDepositLimits(minDepositLimit, maxDepositLimit)

    // Log deposit limits
    console.log(
      'Deposit limits set: minDepositLimit =',
      fromEther(minDepositLimit),
      ', maxDepositLimit =',
      fromEther(maxDepositLimit)
    )

    // Attempt to deposit an amount below the minimum limit
    try {
      await strategy.deposit(toEther(5), encodeVaults([]))
    } catch (error) {
      if (error instanceof Error) {
        console.log('Error when depositing below minimum limit:', error.message)
      } else {
        console.log('Unknown error when depositing below minimum limit:', error)
      }
    }

    // Attempt to deposit an amount above the maximum limit
    try {
      await strategy.deposit(toEther(200), encodeVaults([]))
    } catch (error) {
      if (error instanceof Error) {
        console.log('Error when depositing above maximum limit:', error.message)
      } else {
        console.log('Unknown error when depositing above maximum limit:', error)
      }
    }

    // Deposit an amount within the limits
    await strategy.deposit(toEther(50), encodeVaults([]))
    console.log(
      'Balance of stakingController after deposit within limits:',
      fromEther(await token.balanceOf(adrs.stakingController))
    )
    console.log(
      'TotalPrincipalDeposits after deposit within limits:',
      fromEther(await strategy.totalPrincipalDeposits())
    )
    console.log(
      'TotalDeposits after deposit within limits:',
      fromEther(await strategy.getTotalDeposits())
    )

    // Manipulate the deposit limits and test again
    await stakingController.setDepositLimits(toEther(20), toEther(100))
    console.log(
      'New deposit limits set: minDepositLimit =',
      fromEther(toEther(20)),
      ', maxDepositLimit =',
      fromEther(toEther(100))
    )

    // Attempt to deposit an amount below the new minimum limit
    try {
      await strategy.deposit(toEther(15), encodeVaults([]))
    } catch (error) {
      if (error instanceof Error) {
        console.log('Error when depositing below new minimum limit:', error.message)
      } else {
        console.log('Unknown error when depositing below new minimum limit:', error)
      }
    }

    // Attempt to deposit an amount above the new maximum limit
    try {
      await strategy.deposit(toEther(150), encodeVaults([]))
    } catch (error) {
      if (error instanceof Error) {
        console.log('Error when depositing above new maximum limit:', error.message)
      } else {
        console.log('Unknown error when depositing above new maximum limit:', error)
      }
    }

    // Deposit an amount within the new limits
    await strategy.deposit(toEther(80), encodeVaults([]))
    console.log(
      'Balance of stakingController after deposit within new limits:',
      fromEther(await token.balanceOf(adrs.stakingController))
    )
    console.log(
      'TotalPrincipalDeposits after deposit within new limits:',
      fromEther(await strategy.totalPrincipalDeposits())
    )
    console.log(
      'TotalDeposits after deposit within new limits:',
      fromEther(await strategy.getTotalDeposits())
    )

    // Assertions
    assert.equal(
      fromEther(await token.balanceOf(adrs.stakingController)),
      370,
      'Total deposits should be updated correctly'
    )
    assert.equal(
      fromEther(await strategy.totalPrincipalDeposits()),
      630,
      'Total principal deposits should be updated correctly'
    )
    assert.equal(
      fromEther(await strategy.getTotalDeposits()),
      630,
      'Total deposits should be updated correctly'
    )
  })
  //@audit new
})
