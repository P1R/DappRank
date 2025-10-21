<script>
  import WalletConnector from './components/WalletConnector.svelte';
  import IPFSUploader from './components/IPFSUploader.svelte';
</script>

<main>
  <h1>Svelte + Helia + Ethers.js on IPFS</h1>
  <WalletConnector />
  <hr />
  <IPFSUploader />
</main>

<style>
  main {
    font-family: sans-serif;
    text-align: center;
  }
</style>
