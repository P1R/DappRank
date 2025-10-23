<script>
  import { connectWallet } from '../lib/ethers.svelte.js';
  import { ethersVariables } from '../lib/ethers.svelte.js';

  async function handleConnectWallet() {
    if (ethersVariables.signerAddress == null) {
        const address = await connectWallet();
        if (address) {
            ethersVariables.signerAddress = address;
        }
    } else {
        ethersVariables.signerAddress = null;
    }
  }
</script>

<div>
  {#if ethersVariables.signerAddress}
    <button onclick={handleConnectWallet}>
        Disconnect {ethersVariables.signerAddress.slice(0, 6)
        + '..' + ethersVariables.signerAddress.slice(-6)}
    </button>
  {:else}
    <button onclick={handleConnectWallet}>Connect Wallet</button>
  {/if}
</div>
