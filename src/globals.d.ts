import type { Eip1193Provider } from "ethers";

declare global {
  interface Window {
    /** Injected by Web3 wallets (e.g. MetaMask) via EIP-1193. */
    ethereum?: Eip1193Provider;
  }
}

export {};
