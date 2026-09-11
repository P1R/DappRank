<script>
  import { openModal } from '../lib/modal.svelte.js';
  import { ethVars, refreshTokenBalance } from '../lib/ethers.svelte.js';
  import { MorphIcon } from 'morphicons/svelte';
  import { Coins } from 'lucide';

  async function handleOpen() {
    if (ethVars.signerAddress) {
      await refreshTokenBalance();
    }
    openModal('buy');
  }
</script>

<button class="btn-neon" on:click={handleOpen}>
  <MorphIcon icon={Coins} spring="snappy" reducedMotion="user" aria-hidden="true" />
  Buy Tokens
</button>
