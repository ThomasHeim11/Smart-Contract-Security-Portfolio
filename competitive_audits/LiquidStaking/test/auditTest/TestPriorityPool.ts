import { expect } from 'chai'
import { ethers } from 'hardhat'
import {
  PriorityPool,
  ERC20Mock,
  StakingPoolMock,
  SDLPoolMock,
  WithdrawalPoolMock,
} from '../typechain'

describe('PriorityPool', function () {
  let priorityPool: PriorityPool
  let token: ERC20Mock
  let stakingPool: StakingPoolMock
  let sdlPool: SDLPoolMock
  let withdrawalPool: WithdrawalPoolMock
  let owner: any
  let addr1: any
  let addr2: any

  beforeEach(async function () {
    ;[owner, addr1, addr2] = await ethers.getSigners()

    const ERC20Mock = await ethers.getContractFactory('ERC20Mock')
    token = await ERC20Mock.deploy('Mock Token', 'MTK', 18)
    await token.deployed()

    const StakingPoolMock = await ethers.getContractFactory('StakingPoolMock')
    stakingPool = await StakingPoolMock.deploy()
    await stakingPool.deployed()

    const SDLPoolMock = await ethers.getContractFactory('SDLPoolMock')
    sdlPool = await SDLPoolMock.deploy()
    await sdlPool.deployed()

    const WithdrawalPoolMock = await ethers.getContractFactory('WithdrawalPoolMock')
    withdrawalPool = await WithdrawalPoolMock.deploy()
    await withdrawalPool.deployed()

    const PriorityPool = await ethers.getContractFactory('PriorityPool')
    priorityPool = await PriorityPool.deploy()
    await priorityPool.deployed()

    await priorityPool.initialize(token.address, stakingPool.address, sdlPool.address, 100, 1000)
  })

  describe('Initialization', function () {
    it('Should initialize correctly', async function () {
      expect(await priorityPool.token()).to.equal(token.address)
      expect(await priorityPool.stakingPool()).to.equal(stakingPool.address)
      expect(await priorityPool.sdlPool()).to.equal(sdlPool.address)
      expect(await priorityPool.queueDepositMin()).to.equal(100)
      expect(await priorityPool.queueDepositMax()).to.equal(1000)
    })
  })

  describe('Deposits', function () {
    it('Should deposit tokens correctly', async function () {
      await token.mint(addr1.address, 1000)
      await token.connect(addr1).approve(priorityPool.address, 1000)

      await priorityPool.connect(addr1).deposit(500, true, [])
      expect(await token.balanceOf(priorityPool.address)).to.equal(500)
    })

    it('Should queue tokens if necessary', async function () {
      await token.mint(addr1.address, 1000)
      await token.connect(addr1).approve(priorityPool.address, 1000)

      await priorityPool.connect(addr1).deposit(1500, true, [])
      expect(await token.balanceOf(priorityPool.address)).to.equal(1500)
    })
  })

  describe('Withdrawals', function () {
    it('Should withdraw tokens correctly', async function () {
      await token.mint(addr1.address, 1000)
      await token.connect(addr1).approve(priorityPool.address, 1000)

      await priorityPool.connect(addr1).deposit(500, true, [])
      await priorityPool.connect(addr1).withdraw(200, 500, 0, [], true, false)

      expect(await token.balanceOf(addr1.address)).to.equal(700)
    })

    it('Should prevent unauthorized transfers', async function () {
      await token.mint(addr1.address, 1000)
      await token.connect(addr1).approve(priorityPool.address, 1000)

      await priorityPool.connect(addr1).deposit(500, true, [])
      await expect(
        priorityPool.connect(addr2).withdraw(200, 500, 0, [], true, false)
      ).to.be.revertedWith('SenderNotAuthorized')
    })
  })

  describe('Edge Cases', function () {
    it('Should revert on zero deposit', async function () {
      await expect(priorityPool.connect(addr1).deposit(0, true, [])).to.be.revertedWith(
        'InvalidAmount'
      )
    })

    it('Should revert on zero withdrawal', async function () {
      await expect(
        priorityPool.connect(addr1).withdraw(0, 500, 0, [], true, false)
      ).to.be.revertedWith('InvalidAmount')
    })

    it('Should revert on exceeding deposit limits', async function () {
      await token.mint(addr1.address, 2000)
      await token.connect(addr1).approve(priorityPool.address, 2000)

      await expect(priorityPool.connect(addr1).deposit(2000, true, [])).to.be.revertedWith(
        'InsufficientDepositRoom'
      )
    })
  })
})
