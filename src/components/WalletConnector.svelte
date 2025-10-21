<script>
  import { connectWallet } from '../lib/ethers.js';

  let signerAddress = $state(null);

  async function handleConnectWallet() {
    const address = await connectWallet();
    if (address) {
      signerAddress = address;
    }
  }
</script>

<div>
  {#if signerAddress}
    <p>Connected: {signerAddress}</p>
  {:else}
    <button onclick={handleConnectWallet}>Connect Wallet</button>
  {/if}
</div>
