<script>
  import { onMount } from 'svelte';
  import { getHelia } from '../lib/helia.js';
  import { helia } from '../stores/helia.js';

  let file;
  let cid;
  let heliaInstance;

  onMount(async () => {
    heliaInstance = await getHelia();
  });

  async function uploadToIPFS() {
    if (file && $helia) {
      const fileBytes = new Uint8Array(await file.arrayBuffer());
      cid = await $helia.fs.addBytes(fileBytes);
      console.log('Uploaded to IPFS with CID:', cid.toString());
    }
  }
</script>

<div>
  <input type="file" on:change={(e) => (file = e.target.files[0])} />
  <button on:click={uploadToIPFS} disabled={!$helia || !file}>
    Upload to IPFS
  </button>

  {#if cid}
    <p>File uploaded! CID: {cid.toString()}</p>
  {/if}
</div>
