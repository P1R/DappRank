<script>
  import { signerAddress } from '../stores/ethers.js';
  import { connectWallet } from '../lib/ethers.js';
</script>

<div>
  {#if $signerAddress}
    <p>Connected: {$signerAddress}</p>
  {:else}
    <button on:click={connectWallet}>Connect Wallet</button>
  {/if}
</div>
