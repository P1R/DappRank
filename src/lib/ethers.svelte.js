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
  isLoading: false,
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

// Reload the full dapps list from the DappsManager contract.
// Shared so any component can trigger a refresh (e.g. after connecting
// the wallet or after a successful vote) and the reactive view updates.
export async function refreshDappsList() {
  if (ethVars.contract === null) {
    ethVars.dappsList = [];
    return;
  }
  ethVars.isLoading = true;
  try {
    const dappsListNames = await ethVars.contract.getAllDappNames();
    const dapps = [];
    for (const name of dappsListNames) {
      const info = await getDappInfoForName(name);
      if (info) {
        dapps.push(info);
      }
    }
    ethVars.dappsList = dapps;
  } catch (error) {
    console.error("Failed to refresh dapps list:", error);
  } finally {
    ethVars.isLoading = false;
  }
}

async function getDappInfoForName(dappName) {
  try {
    const info = await ethVars.contract.getDappInfo(dappName);
    return {
      name: dappName,
      cid: info.cid,
      rate: info.rate.toString(), // Convert to string for better handling
      weight_votes_sum: info.weight_votes_sum.toString(),
      weight_total_sum: info.weight_total_sum.toString(),
      balance: info.balance.toString(),
      burned: info.burned.toString(),
      owner: info.owner,
      status: info.status,
    };
  } catch (error) {
    console.error(`Error getting info for dapp ${dappName}:`, error);
    return null;
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
