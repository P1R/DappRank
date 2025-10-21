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

<div>
  <input type="file" on:change={(e) => (file = e.target.files[0])} />
  <button on:click={uploadToIPFS} disabled={!heliaInstance || !file}>
    Upload to IPFS
  </button>
  {#if cid}
    <p>File uploaded! CID: {cid.toString()}</p>
  {/if}
</div>
