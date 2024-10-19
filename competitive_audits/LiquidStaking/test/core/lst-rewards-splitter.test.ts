import { toEther, deploy, getAccounts, setupToken, fromEther } from '../utils/helpers'
import { LSTMock, LSTRewardsSplitterController } from '../../typechain-types'
import { assert, expect } from 'chai'
import { loadFixture } from '@nomicfoundation/hardhat-toolbox/network-helpers'
import { ethers } from 'hardhat'

describe('LSTRewardsSplitter', () => {
  async function deployFixture() {
    const { accounts, signers } = await getAccounts()

    const token = (await deploy('LSTMock', ['Token', 'TKN', 100000000])) as LSTMock
    await setupToken(token, accounts)

    const controller = (await deploy('LSTRewardsSplitterController', [
      token.target,
      toEther(100),
    ])) as LSTRewardsSplitterController

    await controller.addSplitter(accounts[0], [
      { receiver: accounts[5], basisPoints: 1000 },
      { receiver: accounts[6], basisPoints: 2000 },
    ])
    await controller.addSplitter(accounts[1], [
      { receiver: accounts[7], basisPoints: 2000 },
      { receiver: accounts[8], basisPoints: 4000 },
    ])

    const splitter0 = await ethers.getContractAt(
      'LSTRewardsSplitter',
      await controller.splitters(accounts[0])
    )
    const splitter1 = await ethers.getContractAt(
      'LSTRewardsSplitter',
      await controller.splitters(accounts[1])
    )

    return { signers, accounts, token, controller, splitter0, splitter1 }
  }

  it('onTokenTransfer should work correctly', async () => {
    const { signers, accounts, controller, token, splitter0, splitter1 } = await loadFixture(
      deployFixture
    )

    await expect(
      controller.onTokenTransfer(accounts[0], toEther(100), '0x')
    ).to.be.revertedWithCustomError(controller, 'InvalidToken()')
    await expect(
      token.connect(signers[2]).transferAndCall(controller.target, toEther(100), '0x')
    ).to.be.revertedWithCustomError(controller, 'SenderNotAuthorized()')

    await token.transferAndCall(controller.target, toEther(100), '0x')
    await token.connect(signers[1]).transferAndCall(controller.target, toEther(200), '0x')

    assert.equal(fromEther(await splitter0.principalDeposits()), 100)
    assert.equal(fromEther(await token.balanceOf(splitter0.target)), 100)

    assert.equal(fromEther(await splitter1.principalDeposits()), 200)
    assert.equal(fromEther(await token.balanceOf(splitter1.target)), 200)
  })

  it('withdraw should work correctly', async () => {
    const { signers, accounts, controller, token, splitter0, splitter1 } = await loadFixture(
      deployFixture
    )

    await token.transferAndCall(controller.target, toEther(100), '0x')
    await token.connect(signers[1]).transferAndCall(controller.target, toEther(200), '0x')

    await expect(
      controller.connect(signers[2]).withdraw(toEther(100))
    ).to.be.revertedWithCustomError(controller, 'SenderNotAuthorized()')
    await expect(controller.withdraw(toEther(101))).to.be.reverted

    let acc0Balance = await token.balanceOf(accounts[0])
    let acc1Balance = await token.balanceOf(accounts[1])

    await controller.withdraw(toEther(100))
    await controller.connect(signers[1]).withdraw(toEther(50))

    assert.equal(fromEther(await splitter0.principalDeposits()), 0)
    assert.equal(fromEther(await token.balanceOf(splitter0.target)), 0)
    assert.equal(fromEther((await token.balanceOf(accounts[0])) - acc0Balance), 100)

    assert.equal(fromEther(await splitter1.principalDeposits()), 150)
    assert.equal(fromEther(await token.balanceOf(splitter1.target)), 150)
    assert.equal(fromEther((await token.balanceOf(accounts[1])) - acc1Balance), 50)
  })

  it('checkUpkeep should work correctly', async () => {
    const { controller, token, splitter0, splitter1 } = await loadFixture(deployFixture)

    await token.transfer(splitter0.target, toEther(90))
    await token.transfer(splitter1.target, toEther(80))
    assert.deepEqual(await controller.checkUpkeep('0x'), [
      false,
      ethers.AbiCoder.defaultAbiCoder().encode(['bool[]'], [[false, false]]),
    ])

    await token.transfer(splitter1.target, toEther(20))
    assert.deepEqual(await controller.checkUpkeep('0x'), [
      true,
      ethers.AbiCoder.defaultAbiCoder().encode(['bool[]'], [[false, true]]),
    ])

    await token.transfer(splitter0.target, toEther(10))
    assert.deepEqual(await controller.checkUpkeep('0x'), [
      true,
      ethers.AbiCoder.defaultAbiCoder().encode(['bool[]'], [[true, true]]),
    ])

    await controller.performUpkeep(
      ethers.AbiCoder.defaultAbiCoder().encode(['bool[]'], [[true, true]])
    )
    assert.deepEqual(await controller.checkUpkeep('0x'), [
      false,
      ethers.AbiCoder.defaultAbiCoder().encode(['bool[]'], [[false, false]]),
    ])

    await token.setMultiplierBasisPoints(5000)
    assert.deepEqual(await controller.checkUpkeep('0x'), [
      true,
      ethers.AbiCoder.defaultAbiCoder().encode(['bool[]'], [[true, true]]),
    ])
  })

  it('performUpkeep should work correctly', async () => {
    const { signers, accounts, controller, token, splitter0, splitter1 } = await loadFixture(
      deployFixture
    )

    await token.transferAndCall(controller.target, toEther(100), '0x')
    await token.connect(signers[1]).transferAndCall(controller.target, toEther(200), '0x')
    await token.transfer(splitter0.target, toEther(100))
    await token.transfer(splitter1.target, toEther(80))

    await expect(
      controller.performUpkeep(
        ethers.AbiCoder.defaultAbiCoder().encode(['bool[]'], [[false, false]])
      )
    ).to.be.revertedWithCustomError(controller, 'InvalidPerformData()')
    await expect(
      controller.performUpkeep(ethers.AbiCoder.defaultAbiCoder().encode(['bool[]'], [[true, true]]))
    ).to.be.revertedWithCustomError(splitter0, 'InsufficientRewards()')

    await controller.performUpkeep(
      ethers.AbiCoder.defaultAbiCoder().encode(['bool[]'], [[true, false]])
    )

    assert.equal(fromEther(await splitter0.principalDeposits()), 170)
    assert.equal(fromEther(await token.balanceOf(splitter0.target)), 170)
    assert.equal(fromEther(await token.balanceOf(accounts[5])), 10)
    assert.equal(fromEther(await token.balanceOf(accounts[6])), 20)
    assert.equal(fromEther(await splitter1.principalDeposits()), 200)
    assert.equal(fromEther(await token.balanceOf(splitter1.target)), 280)
    assert.equal(fromEther(await token.balanceOf(accounts[7])), 0)
    assert.equal(fromEther(await token.balanceOf(accounts[8])), 0)

    await token.transfer(splitter0.target, toEther(200))
    await token.transfer(splitter1.target, toEther(20))

    await controller.performUpkeep(
      ethers.AbiCoder.defaultAbiCoder().encode(['bool[]'], [[true, true]])
    )

    assert.equal(fromEther(await splitter0.principalDeposits()), 310)
    assert.equal(fromEther(await token.balanceOf(splitter0.target)), 310)
    assert.equal(fromEther(await token.balanceOf(accounts[5])), 30)
    assert.equal(fromEther(await token.balanceOf(accounts[6])), 60)
    assert.equal(fromEther(await splitter1.principalDeposits()), 240)
    assert.equal(fromEther(await token.balanceOf(splitter1.target)), 240)
    assert.equal(fromEther(await token.balanceOf(accounts[7])), 20)
    assert.equal(fromEther(await token.balanceOf(accounts[8])), 40)

    await token.setMultiplierBasisPoints(1000)
    await controller.performUpkeep(
      ethers.AbiCoder.defaultAbiCoder().encode(['bool[]'], [[true, true]])
    )

    assert.equal(fromEther(await splitter0.principalDeposits()), 31)
    assert.equal(fromEther(await token.balanceOf(splitter0.target)), 31)
    assert.equal(fromEther(await token.balanceOf(accounts[5])), 3)
    assert.equal(fromEther(await token.balanceOf(accounts[6])), 6)
    assert.equal(fromEther(await splitter1.principalDeposits()), 24)
    assert.equal(fromEther(await token.balanceOf(splitter1.target)), 24)
    assert.equal(fromEther(await token.balanceOf(accounts[7])), 2)
    assert.equal(fromEther(await token.balanceOf(accounts[8])), 4)
  })

  it('splitRewards should work correctly', async () => {
    const { accounts, controller, token, splitter0 } = await loadFixture(deployFixture)

    await token.transferAndCall(controller.target, toEther(100), '0x')

    await expect(splitter0.splitRewards()).to.be.revertedWithCustomError(
      splitter0,
      'InsufficientRewards()'
    )

    await token.transfer(splitter0.target, toEther(100))
    await splitter0.splitRewards()

    assert.equal(fromEther(await splitter0.principalDeposits()), 170)
    assert.equal(fromEther(await token.balanceOf(splitter0.target)), 170)
    assert.equal(fromEther(await token.balanceOf(accounts[5])), 10)
    assert.equal(fromEther(await token.balanceOf(accounts[6])), 20)

    await token.setMultiplierBasisPoints(2000)
    await splitter0.splitRewards()

    assert.equal(fromEther(await splitter0.principalDeposits()), 34)
    assert.equal(fromEther(await token.balanceOf(splitter0.target)), 34)
    assert.equal(fromEther(await token.balanceOf(accounts[5])), 2)
    assert.equal(fromEther(await token.balanceOf(accounts[6])), 4)
  })

  it('should be able to add splitter', async () => {
    const { accounts, controller, token, splitter0 } = await loadFixture(deployFixture)

    await expect(
      controller.addSplitter(accounts[0], [
        { receiver: accounts[7], basisPoints: 100 },
        { receiver: accounts[8], basisPoints: 500 },
      ])
    ).to.be.revertedWithCustomError(controller, 'SplitterAlreadyExists()')

    await controller.addSplitter(accounts[2], [
      { receiver: accounts[9], basisPoints: 100 },
      { receiver: accounts[10], basisPoints: 500 },
    ])

    assert.deepEqual(await controller.getAccounts(), [accounts[0], accounts[1], accounts[2]])

    assert.equal(await splitter0.controller(), controller.target)
    assert.equal(await splitter0.lst(), token.target)
    assert.deepEqual(await splitter0.getFees(), [
      [accounts[5], 1000n],
      [accounts[6], 2000n],
    ])

    let splitter = await ethers.getContractAt(
      'LSTRewardsSplitter',
      await controller.splitters(accounts[2])
    )
    assert.equal(await splitter.controller(), controller.target)
    assert.equal(await splitter.lst(), token.target)
    assert.deepEqual(await splitter.getFees(), [
      [accounts[9], 100n],
      [accounts[10], 500n],
    ])
  })

  it('should be able to remove splitter', async () => {
    const { accounts, controller, token, splitter1 } = await loadFixture(deployFixture)

    await controller.removeSplitter(accounts[0])

    await expect(controller.removeSplitter(accounts[0])).to.be.revertedWithCustomError(
      controller,
      'SplitterNotFound()'
    )

    assert.deepEqual(await controller.getAccounts(), [accounts[1]])

    assert.equal(await controller.splitters(accounts[0]), ethers.ZeroAddress)

    assert.equal(await splitter1.controller(), controller.target)
    assert.equal(await splitter1.lst(), token.target)
    assert.deepEqual(await splitter1.getFees(), [
      [accounts[7], 2000n],
      [accounts[8], 4000n],
    ])
  })
  // //@audit
  // //@audit
  // it('checkUpkeep should work correctly2', async () => {
  //   const { controller, token, splitter0, splitter1 } = await loadFixture(deployFixture)

  //   // Case 1: No new rewards, should return false
  //   await token.transfer(splitter0.target, toEther(90))
  //   await token.transfer(splitter1.target, toEther(80))
  //   assert.deepEqual(await controller.checkUpkeep('0x'), [
  //     false,
  //     ethers.AbiCoder.defaultAbiCoder().encode(['bool[]'], [[false, false]]),
  //   ])

  //   // Case 2: New rewards less than reward threshold, should return false
  //   await token.transfer(splitter1.target, toEther(20))
  //   assert.deepEqual(await controller.checkUpkeep('0x'), [
  //     true,
  //     ethers.AbiCoder.defaultAbiCoder().encode(['bool[]'], [[false, true]]),
  //   ])

  //   // Case 3: New rewards equal to reward threshold, should return true
  //   await token.transfer(splitter0.target, toEther(10))
  //   assert.deepEqual(await controller.checkUpkeep('0x'), [
  //     true,
  //     ethers.AbiCoder.defaultAbiCoder().encode(['bool[]'], [[true, true]]),
  //   ])

  //   // Perform upkeep
  //   await controller.performUpkeep(
  //     ethers.AbiCoder.defaultAbiCoder().encode(['bool[]'], [[true, true]])
  //   )
  //   assert.deepEqual(await controller.checkUpkeep('0x'), [
  //     false,
  //     ethers.AbiCoder.defaultAbiCoder().encode(['bool[]'], [[false, false]]),
  //   ])

  //   // Case 4: Change reward threshold and check again
  //   await token.setMultiplierBasisPoints(5000)
  //   assert.deepEqual(await controller.checkUpkeep('0x'), [
  //     true,
  //     ethers.AbiCoder.defaultAbiCoder().encode(['bool[]'], [[true, true]]),
  //   ])

  //   // Case 5: New rewards greater than reward threshold, should return true
  //   await token.transfer(splitter0.target, toEther(100))

  //   console.log('After transfer:')
  //   console.log('splitter0 balance:', fromEther(await token.balanceOf(splitter0.target)))
  //   console.log('splitter1 balance:', fromEther(await token.balanceOf(splitter1.target)))
  //   console.log('principalDeposits:', fromEther(await splitter0.principalDeposits()))
  //   console.log('controller balance:', fromEther(await token.balanceOf(controller.target)))
  //   const checkUpkeepResult = await controller.checkUpkeep('0x')
  //   console.log('checkUpkeep result:', checkUpkeepResult)

  //   // Additional debugging logs
  //   const controllerBalance = await token.balanceOf(controller.target)
  //   const principalDeposits = await splitter0.principalDeposits()
  //   const newRewards = controllerBalance - principalDeposits
  //   const rewardThreshold = await controller.rewardThreshold()
  //   console.log('controllerBalance:', fromEther(controllerBalance))
  //   console.log('principalDeposits:', fromEther(principalDeposits))
  //   console.log('newRewards:', fromEther(newRewards))
  //   console.log('rewardThreshold:', fromEther(rewardThreshold))

  //   // Juster forventede resultater basert på korrekt logikk
  //   const expectedNewRewards = controllerBalance - principalDeposits
  //   assert.deepEqual(checkUpkeepResult, [
  //     expectedNewRewards >= rewardThreshold,
  //     ethers.AbiCoder.defaultAbiCoder().encode(
  //       ['bool[]'],
  //       [[expectedNewRewards >= rewardThreshold, expectedNewRewards >= rewardThreshold]]
  //     ),
  //   ])

  //   // Change reward threshold and validate
  //   await token.setMultiplierBasisPoints(20000)
  //   assert.deepEqual(await controller.checkUpkeep('0x'), [
  //     false,
  //     ethers.AbiCoder.defaultAbiCoder().encode(['bool[]'], [[false, false]]),
  //   ])
  // })

  //@audit
  // it('performUpkeep should work correctly', async () => {
  //   const { signers, accounts, controller, token, splitter0, splitter1 } = await loadFixture(
  //     deployFixture
  //   )

  //   await token.transferAndCall(controller.target, toEther(100), '0x')
  //   await token.connect(signers[1]).transferAndCall(controller.target, toEther(200), '0x')
  //   await token.transfer(splitter0.target, toEther(100))
  //   await token.transfer(splitter1.target, toEther(80))

  //   // Edge Case 1: No rewards
  //   await expect(
  //     controller.performUpkeep(
  //       ethers.AbiCoder.defaultAbiCoder().encode(['bool[]'], [[false, false]])
  //     )
  //   ).to.be.revertedWithCustomError(controller, 'InvalidPerformData()')

  //   // Edge Case 2: Rewards below threshold
  //   await expect(
  //     controller.performUpkeep(ethers.AbiCoder.defaultAbiCoder().encode(['bool[]'], [[true, true]]))
  //   ).to.be.revertedWithCustomError(splitter0, 'InsufficientRewards()')

  //   await controller.performUpkeep(
  //     ethers.AbiCoder.defaultAbiCoder().encode(['bool[]'], [[true, false]])
  //   )

  //   assert.equal(fromEther(await splitter0.principalDeposits()), 170)
  //   assert.equal(fromEther(await token.balanceOf(splitter0.target)), 170)
  //   assert.equal(fromEther(await token.balanceOf(accounts[5])), 10)
  //   assert.equal(fromEther(await token.balanceOf(accounts[6])), 20)
  //   assert.equal(fromEther(await splitter1.principalDeposits()), 200)
  //   assert.equal(fromEther(await token.balanceOf(splitter1.target)), 280)
  //   assert.equal(fromEther(await token.balanceOf(accounts[7])), 0)
  //   assert.equal(fromEther(await token.balanceOf(accounts[8])), 0)

  //   await token.transfer(splitter0.target, toEther(200))
  //   await token.transfer(splitter1.target, toEther(20))

  //   await controller.performUpkeep(
  //     ethers.AbiCoder.defaultAbiCoder().encode(['bool[]'], [[true, true]])
  //   )

  //   assert.equal(fromEther(await splitter0.principalDeposits()), 310)
  //   assert.equal(fromEther(await token.balanceOf(splitter0.target)), 310)
  //   assert.equal(fromEther(await token.balanceOf(accounts[5])), 30)
  //   assert.equal(fromEther(await token.balanceOf(accounts[6])), 60)
  //   assert.equal(fromEther(await splitter1.principalDeposits()), 240)
  //   assert.equal(fromEther(await token.balanceOf(splitter1.target)), 240)
  //   assert.equal(fromEther(await token.balanceOf(accounts[7])), 20)
  //   assert.equal(fromEther(await token.balanceOf(accounts[8])), 40)

  //   // @audit Edge Case 3: Rewards exactly at threshold
  //   await token.setMultiplierBasisPoints(1000)
  //   await controller.performUpkeep(
  //     ethers.AbiCoder.defaultAbiCoder().encode(['bool[]'], [[true, true]])
  //   )

  //   assert.equal(fromEther(await splitter0.principalDeposits()), 31)
  //   assert.equal(fromEther(await token.balanceOf(splitter0.target)), 31)
  //   assert.equal(fromEther(await token.balanceOf(accounts[5])), 3)
  //   assert.equal(fromEther(await token.balanceOf(accounts[6])), 6)
  //   assert.equal(fromEther(await splitter1.principalDeposits()), 24)
  //   assert.equal(fromEther(await token.balanceOf(splitter1.target)), 24)
  //   assert.equal(fromEther(await token.balanceOf(accounts[7])), 2)
  //   assert.equal(fromEther(await token.balanceOf(accounts[8])), 4)

  //   // @audit Edge Case 4: Large rewards
  //   console.log('Before large rewards transfer:')
  //   console.log('splitter0 principalDeposits:', fromEther(await splitter0.principalDeposits()))
  //   console.log('splitter0 balance:', fromEther(await token.balanceOf(splitter0.target)))
  //   console.log('splitter1 principalDeposits:', fromEther(await splitter1.principalDeposits()))
  //   console.log('splitter1 balance:', fromEther(await token.balanceOf(splitter1.target)))

  //   await token.transfer(splitter0.target, toEther(1000))
  //   await token.transfer(splitter1.target, toEther(1000))

  //   console.log('Before performUpkeep:')
  //   console.log('splitter0 principalDeposits:', fromEther(await splitter0.principalDeposits()))
  //   console.log('splitter0 balance:', fromEther(await token.balanceOf(splitter0.target)))
  //   console.log('splitter1 principalDeposits:', fromEther(await splitter1.principalDeposits()))
  //   console.log('splitter1 balance:', fromEther(await token.balanceOf(splitter1.target)))
  //   console.log('controller balance:', fromEther(await token.balanceOf(controller.target)))

  //   await controller.performUpkeep(
  //     ethers.AbiCoder.defaultAbiCoder().encode(['bool[]'], [[true, true]])
  //   )

  //   console.log('After performUpkeep:')
  //   console.log('splitter0 principalDeposits:', fromEther(await splitter0.principalDeposits()))
  //   console.log('splitter0 balance:', fromEther(await token.balanceOf(splitter0.target)))
  //   console.log('splitter1 principalDeposits:', fromEther(await splitter1.principalDeposits()))
  //   console.log('splitter1 balance:', fromEther(await token.balanceOf(splitter1.target)))
  //   console.log('controller balance:', fromEther(await token.balanceOf(controller.target)))

  //   assert.equal(fromEther(await splitter0.principalDeposits()), 1031) // Corrected assertion
  //   assert.equal(fromEther(await token.balanceOf(splitter0.target)), 1031)
  //   assert.equal(fromEther(await token.balanceOf(accounts[5])), 130)
  //   assert.equal(fromEther(await token.balanceOf(accounts[6])), 260)
  //   assert.equal(fromEther(await splitter1.principalDeposits()), 1024)
  //   assert.equal(fromEther(await token.balanceOf(splitter1.target)), 1024)
  //   assert.equal(fromEther(await token.balanceOf(accounts[7])), 120)
  //   assert.equal(fromEther(await token.balanceOf(accounts[8])), 240)

  //   // @audit Edge Case 5: Rewards below threshold after changing threshold
  //   await token.setMultiplierBasisPoints(1000)
  //   await controller.performUpkeep(
  //     ethers.AbiCoder.defaultAbiCoder().encode(['bool[]'], [[true, true]])
  //   )

  //   assert.equal(fromEther(await splitter0.principalDeposits()), 131)
  //   assert.equal(fromEther(await token.balanceOf(splitter0.target)), 131)
  //   assert.equal(fromEther(await token.balanceOf(accounts[5])), 13)
  //   assert.equal(fromEther(await token.balanceOf(accounts[6])), 26)
  //   assert.equal(fromEther(await splitter1.principalDeposits()), 124)
  //   assert.equal(fromEther(await token.balanceOf(splitter1.target)), 124)
  //   assert.equal(fromEther(await token.balanceOf(accounts[7])), 12)
  //   assert.equal(fromEther(await token.balanceOf(accounts[8])), 24)

  //   // @audit Edge Case 6: Negative rewards
  //   await token.transfer(splitter0.target, toEther(100))
  //   await token.transfer(splitter1.target, toEther(100))

  //   await controller.performUpkeep(
  //     ethers.AbiCoder.defaultAbiCoder().encode(['bool[]'], [[true, true]])
  //   )

  //   assert.equal(fromEther(await splitter0.principalDeposits()), 231)
  //   assert.equal(fromEther(await token.balanceOf(splitter0.target)), 231)
  //   assert.equal(fromEther(await token.balanceOf(accounts[5])), 23)
  //   assert.equal(fromEther(await token.balanceOf(accounts[6])), 46)
  //   assert.equal(fromEther(await splitter1.principalDeposits()), 224)
  //   assert.equal(fromEther(await token.balanceOf(splitter1.target)), 224)
  //   assert.equal(fromEther(await token.balanceOf(accounts[7])), 22)
  //   assert.equal(fromEther(await token.balanceOf(accounts[8])), 44)
  // })

  //@audit
  // it('splitRewards should work correctly', async () => {
  //   const { accounts, controller, token, splitter0 } = await loadFixture(deployFixture)

  //   await token.transferAndCall(controller.target, toEther(100), '0x')

  //   await expect(splitter0.splitRewards()).to.be.revertedWithCustomError(
  //     splitter0,
  //     'InsufficientRewards()'
  //   )

  //   await token.transfer(splitter0.target, toEther(100))
  //   await splitter0.splitRewards()

  //   assert.equal(fromEther(await splitter0.principalDeposits()), 170)
  //   assert.equal(fromEther(await token.balanceOf(splitter0.target)), 170)
  //   assert.equal(fromEther(await token.balanceOf(accounts[5])), 10)
  //   assert.equal(fromEther(await token.balanceOf(accounts[6])), 20)

  //   await token.setMultiplierBasisPoints(2000)
  //   await splitter0.splitRewards()

  //   assert.equal(fromEther(await splitter0.principalDeposits()), 34)
  //   assert.equal(fromEther(await token.balanceOf(splitter0.target)), 34)
  //   assert.equal(fromEther(await token.balanceOf(accounts[5])), 2)
  //   assert.equal(fromEther(await token.balanceOf(accounts[6])), 4)

  //   //@audit Test for potential exploitation
  //   console.log('Before large rewards transfer:')
  //   console.log('splitter0 principalDeposits:', fromEther(await splitter0.principalDeposits()))
  //   console.log('splitter0 balance:', fromEther(await token.balanceOf(splitter0.target)))

  //   await token.transfer(splitter0.target, toEther(1000))

  //   console.log('Before splitRewards:')
  //   console.log('splitter0 principalDeposits:', fromEther(await splitter0.principalDeposits()))
  //   console.log('splitter0 balance:', fromEther(await token.balanceOf(splitter0.target)))

  //   await splitter0.splitRewards()

  //   console.log('After splitRewards:')
  //   console.log('splitter0 principalDeposits:', fromEther(await splitter0.principalDeposits()))
  //   console.log('splitter0 balance:', fromEther(await token.balanceOf(splitter0.target)))

  //   assert.equal(fromEther(await splitter0.principalDeposits()), 1034)
  //   assert.equal(fromEther(await token.balanceOf(splitter0.target)), 1034)
  //   assert.equal(fromEther(await token.balanceOf(accounts[5])), 102)
  //   assert.equal(fromEther(await token.balanceOf(accounts[6])), 204)
  // })

  //@audit
  //@audit
})
