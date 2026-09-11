<script>
  import { refreshDappsList } from '../lib/ethers.svelte.js';
</script>

<div>
    <button class="btn-neon" onclick={refreshDappsList}>Refresh</button>
</div>
