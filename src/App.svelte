<script>
  import WalletConnector from './components/WalletConnector.svelte';
  import IPFSConnector from './components/IPFSConnector.svelte';
</script>

<main>
  <h1>Svelte + Helia + Ethers.js on IPFS</h1>
  <WalletConnector />
  <hr />
  <IPFSConnector />
</main>

<style>
  main {
    font-family: sans-serif;
    text-align: center;
  }
</style>
