import { ethers } from "ethers";
import compiledDappsManager from "../../out/DappsManager.sol/DappsManager.json";
import compiledTokenContract from "../../out/DRNK.sol/DappRank.json";

// The DappsManager contract is already deployed on Sepolia testnet.
// Fall back to the deployed address when no VITE_SMARTCONTRACTADDRS is provided (e.g. no .env).
const contractAddress =
  import.meta.env.VITE_SMARTCONTRACTADDRS ||
  "0xD60DC0805f44d10cAc6594f1a501c67929448957";
const DappsManagerABI = compiledDappsManager.abi;
const tokenContractABI = compiledTokenContract.abi;

export const ethVars = $state({
  provider: null,
  signer: null,
  signerAddress: null,
  contractAddress: contractAddress,
  contract: null,
  tokenContract: null,
  tokenContractAddress: null,
  dappsList: [],
  tokenBalance: null,
  tokenSymbol: "DRNK",
  tokenDecimals: 18,
});

export async function connectWallet() {
  if (typeof window.ethereum === "undefined") {
    alert("Please install a Web3 wallet like MetaMask.");
    return;
  }

  try {
    const browserProvider = new ethers.BrowserProvider(window.ethereum);
    const newSigner = await browserProvider.getSigner();
    const address = await newSigner.getAddress();
    // Update the reactive object
    ethVars.provider = browserProvider;
    ethVars.signer = newSigner;
    ethVars.signerAddress = address;
    return address;
  } catch (error) {
    console.error("User rejected the request:", error);
    return null;
  }
}

export async function connectContract() {
  if (typeof window.ethereum === "undefined") {
    alert("Please install a Web3 wallet like MetaMask.");
    return;
  }
  if (ethVars.contractAddress === null) {
    alert("Error reading smart contract address, verify the chain or .env");
    return;
  }
  if (ethVars.signer === null) {
    alert("ensure there is a signer by connecting the wallet");
    return;
  }

  try {
    ethVars.contract = new ethers.Contract(
      ethVars.contractAddress,
      DappsManagerABI,
      ethVars.signer,
    );
    return ethVars.contract;
  } catch (error) {
    console.error("Failed to connect contract:", error);
    throw error;
  }
}

export async function connectTokenContract() {
  if (typeof window.ethereum === "undefined") {
    alert("Please install a Web3 wallet like MetaMask.");
    return;
  }
  if (ethVars.contract === null) {
    alert("Error reading smart contract address, verify the chain or .env");
    return;
  }
  if (ethVars.signer === null) {
    alert("ensure there is a signer by connecting the wallet");
    return;
  }
  if (ethVars.tokenContractAddress === null) {
    try {
      ethVars.tokenContractAddress = await ethVars.contract.drnk();
    } catch (error) {
      console.error("Failed to get token contract address:", error);
      throw error;
    }
  }

  try {
    ethVars.tokenContract = new ethers.Contract(
      ethVars.tokenContractAddress,
      tokenContractABI,
      ethVars.signer,
    );
    await refreshTokenBalance();
    return ethVars.tokenContract;
  } catch (error) {
    console.error("Failed to connect contract:", error);
    throw error;
  }
}

// Refresh the connected wallet's DRNK token balance and symbol.
export async function refreshTokenBalance() {
  if (ethVars.tokenContract === null || ethVars.signerAddress === null) {
    ethVars.tokenBalance = null;
    return;
  }
  try {
    const balance = await ethVars.tokenContract.balanceOf(
      ethVars.signerAddress,
    );
    ethVars.tokenBalance = balance;
    try {
      ethVars.tokenSymbol = await ethVars.tokenContract.symbol();
    } catch (e) {
      // symbol() is optional; keep the default if it fails
    }
  } catch (error) {
    console.error("Failed to get token balance:", error);
    ethVars.tokenBalance = null;
  }
}
