<script>
  import { refreshDappsList } from '../lib/ethers.svelte.js';
  import { ethVars } from '../lib/ethers.svelte.js';
  import { MorphIcon } from 'morphicons/svelte';
  import { RefreshCw, LoaderCircle } from 'lucide';
</script>

<div>
  <button
    class="btn-neon"
    onclick={refreshDappsList}
    disabled={ethVars.isLoading}
    aria-label="Refresh ranking"
  >
    <MorphIcon icon={ethVars.isLoading ? LoaderCircle : RefreshCw} spring="snappy" reducedMotion="user" aria-hidden="true" />
    Refresh
  </button>
</div>
