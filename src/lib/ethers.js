import { ethers } from 'ethers';
import { provider, signer, signerAddress } from '../stores/ethers.js';

export async function connectWallet() {
  if (typeof window.ethereum !== 'undefined') {
    try {
      const browserProvider = new ethers.BrowserProvider(window.ethereum);
      const newSigner = await browserProvider.getSigner();

      provider.set(browserProvider);
      signer.set(newSigner);
      signerAddress.set(await newSigner.getAddress());

    } catch (error) {
      console.error("User rejected the request.");
    }
  } else {
    alert('Please install a web3 wallet like MetaMask.');
  }
}
