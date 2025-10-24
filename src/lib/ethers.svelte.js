import { ethers } from 'ethers';
import compiledDappsManager from '../../out/DappsManager.sol/DappsManager.json';
import compiledTokenContract from '../../out/DRNK.sol/DappRank.json';

const contractAddress = import.meta.env.VITE_SMARTCONTRACTADDRS;
const DappsManagerABI = compiledDappsManager.abi;
const tokenContractABI = compiledTokenContract.abi;

let provider = null;
let signer = null;
let signerAddress = null;
let contract = null;
let tokenContract = null;
let tokenContractAddress = null;
let dappsList = [];

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

 export async function connectContract() {
     if (typeof window.ethereum === 'undefined') {
         alert('Please install a Web3 wallet like MetaMask.');
         return;
     }
     if (contractAddress === null) {
         alert('Error reading smart contract address, verify the chain or .env');
         return;
     }
     if (signer === null) {
         alert('ensure there is a signer by connecting the wallet');
         return;
     }

     try {
         contract = new ethers.Contract(contractAddress, DappsManagerABI, signer);
         return contract;
     } catch (error) {
         console.error('Failed to connect contract:', error);
         throw error;
     }
 }

 export async function connectTokenContract() {
     if (typeof window.ethereum === 'undefined') {
         alert('Please install a Web3 wallet like MetaMask.');
         return;
     }
     if (contract === null) {
         alert('Error reading smart contract address, verify the chain or .env');
         return;
     }
     if (signer === null) {
         alert('ensure there is a signer by connecting the wallet');
         return;
     }
     if (tokenContractAddress === null) {
         try {
             tokenContractAddress = await contract.drnk();
         } catch (error) {
             console.error('Failed to get token contract address:', error);
             throw error;
         }
     }

     try {
         tokenContract = new ethers.Contract(tokenContractAddress, tokenContractABI, signer);
         return tokenContract;
     } catch (error) {
         console.error('Failed to connect contract:', error);
         throw error;
     }
 }

export async function listDapps() {
   if (!contract) {
     throw new Error('Contract not connected');
   }
   try {
     const tx = await contract.registerDapp(name, cid, { value });
     await tx.wait();
     return tx;
   } catch (error) {
     console.error('Failed to register dapp:', error);
     throw error;
   }
}

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

export let ethVars = $state({
    provider,
    signer,
    signerAddress,
    contractAddress,
    contract,
    tokenContract,
    tokenContractAddress,
    dappsList
});
