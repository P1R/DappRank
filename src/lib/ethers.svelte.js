import { ethers } from 'ethers';

const DappsManagerABI = [
  "function registerDapp(bytes32 name, string cid) external payable",
  "function approveDapp(bytes32 name) external",
  "function banDapp(bytes32 name) external",
  "function dappCashOut(bytes32 name, uint256 amount) external",
  "function buyDRNK() external payable",
  "function demoAirdrop(address[] actors) external",
  "function getAllDapps() external view returns (bytes32[] memory)",
  "function getDapp(bytes32 name) external view returns (bytes memory)"
];

const contractAddress = import.meta.env.VITE_SMARTCONTRACTADDRS;

let provider = null;
let signer = null;
let signerAddress = null;
let contractStatus = false;
let contract = null;


export async function connectWallet() {
  if (typeof window.ethereum === 'undefined') {
    alert('Please install a Web3 wallet like MetaMask.');
    return;
  }

  try {
    const browserProvider = new ethers.BrowserProvider(window.ethereum);
    const newSigner = await browserProvider.getSigner();
    provider = browserProvider;
    signer = newSigner;
    signerAddress = await newSigner.getAddress();
    return signerAddress;
  } catch (error) {
    console.error('User rejected the request:', error);
    return null;
  }
}

// async function connectContract() {
//   if (typeof window.ethereum === 'undefined') {
//     throw new Error('Please install a Web3 wallet like MetaMask.');
//   }
//
//   try {
//     provider = new ethers.BrowserProvider(window.ethereum);
//     signer = await provider.getSigner();
//     contract = new ethers.Contract(contractAddress, DappsManagerABI, signer);
//     return contract;
//   } catch (error) {
//     console.error('Failed to connect contract:', error);
//     throw error;
//   }
// }
//
// // Register a new dapp
// export async function registerDapp(name, cid, value) {
//   if (!contract) {
//     throw new Error('Contract not connected');
//   }
//
//   try {
//     const tx = await contract.registerDapp(name, cid, { value });
//     await tx.wait();
//     return tx;
//   } catch (error) {
//     console.error('Failed to register dapp:', error);
//     throw error;
//   }
// }

export let ethersVariables = $state({
    provider,
    signer,
    signerAddress,
    contractStatus,
    contractAddress
});
