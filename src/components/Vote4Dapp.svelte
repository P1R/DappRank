<script>
  import { openModal } from '../lib/modal.svelte.js';
  import { ethVars, refreshTokenBalance } from '../lib/ethers.svelte.js';
  import { MorphIcon } from 'morphicons/svelte';
  import { Vote } from 'lucide';

  async function handleOpen() {
    if (ethVars.signerAddress) {
      await refreshTokenBalance();
    }
    openModal('vote');
  }
</script>

<button class="btn-neon" on:click={handleOpen}>
  <MorphIcon icon={Vote} spring="snappy" reducedMotion="user" aria-hidden="true" />
  Vote on Dapps
</button>
