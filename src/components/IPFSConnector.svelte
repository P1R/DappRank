<script>
  import { onMount } from 'svelte';
  import { getHelia } from '../lib/helia.js';

  let file;
  let cid;
  let heliaInstance;

  onMount(async () => {
    heliaInstance = await getHelia();
  });

  async function uploadToIPFS() {
    if (file && heliaInstance) {
      const fileBytes = new Uint8Array(await file.arrayBuffer());
      cid = await heliaInstance.fs.addBytes(fileBytes);
      console.log('Uploaded to IPFS with CID:', cid.toString());
    }
  }
</script>

<div class="max-w-md mx-auto my-8 p-5 rounded-lg border border-neon-cyan/30 bg-void/70 shadow-[0_0_15px_rgba(0,247,255,0.15)] flex flex-col gap-3 items-center">
  <input
    type="file"
    class="w-full text-sm text-ink file:mr-3 file:rounded-md file:border file:border-neon-cyan file:bg-void/70 file:px-3 file:py-2 file:text-neon-cyan file:cursor-pointer file:font-semibold hover:file:bg-neon-cyan/20"
    on:change={(e) => (file = e.target.files[0])}
  />
  <button class="btn-neon w-full" on:click={uploadToIPFS} disabled={!heliaInstance || !file}>
    Upload to IPFS
  </button>
  {#if cid}
    <p class="text-sm text-neon-cyan break-all text-center">File uploaded! CID: {cid.toString()}</p>
  {/if}
</div>
