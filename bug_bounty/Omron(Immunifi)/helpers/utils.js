import { ethers } from "hardhat";

/**
 * Signs the provided message with the provided wallet
 * @param ethers.Wallet} wallet The wallet to sign with
 * @param {string} message The message to be signed
 * @returns Unpacked signature
 */
const signMessage = async (wallet, message) => {
  const signature = await wallet.signMessage(message);

  return ethers.Signature.from(signature);
};

/**
 * Gets balances of all provided addresses
 * @param {string[]} addresses A list of addresses to get balances for
 * @param {ethers.Contract} erc20 An ERC20 contract instance
 * @returns A list of balances returned from contract calls
 */
const getBalances = (addresses, erc20) =>
  Promise.all(addresses.map((address) => erc20.balanceOf(address)));

/**
 * Fetches the native token balance for each of the provided addresses
 * @param {string[]} addresses A list of addresses to check balances on
 * @returns BigInt[] of balances
 */
const getEthBalances = (accounts) =>
  Promise.all(
    accounts.map((account) =>
      BigInt(ethers.getDefaultProvider().getBalance(account))
    )
  );

/**
 * Generates a random hex value of the provided length
 * @param {number} length The length of the random hex string
 * @returns A random hex string as long as {length}
 */
const randomHex = (length) =>
  ethers.hexlify(ethers.randomBytes(Math.min((length - 2) / 2)));

export { getBalances, getEthBalances, randomHex, signMessage };
