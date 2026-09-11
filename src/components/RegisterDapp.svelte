<script>
  import { openModal } from '../lib/modal.svelte.js';
  import { ethVars, refreshTokenBalance } from '../lib/ethers.svelte.js';
  import { MorphIcon } from 'morphicons/svelte';
  import { Plus } from 'lucide';

  async function handleOpen() {
    if (ethVars.signerAddress) {
      await refreshTokenBalance();
    }
    openModal('register');
  }
</script>

<button class="btn-neon-pink" on:click={handleOpen}>
  <MorphIcon icon={Plus} spring="snappy" reducedMotion="user" aria-hidden="true" />
  Add Dapp
</button>
