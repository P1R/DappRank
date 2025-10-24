<script>
  import { connectWallet, connectContract, connectTokenContract } from '../lib/ethers.svelte.js';
  import { ethVars } from '../lib/ethers.svelte.js';

  async function handleConnectWallet() {
    if (ethVars.signerAddress == null) {
        const address = await connectWallet();
        if (address) {
            ethVars.signerAddress = address;
            await handleConnectcontract();
        }
    } else {
        ethVars.signerAddress = null;
    }
  }

  async function handleConnectcontract() {
    if (ethVars.contract == null) {
        const contract = await connectContract();
        if (contract) {
            ethVars.contract = contract;
            ethVars.tokenContractAddress = await contract.drnk();
            //console.log("conected contract on address:", ethVars.contractAddress);
            //console.log("token address:", ethVars.tokenContractAddress);
            ethVars.tokenContract = await connectTokenContract();
            //const symbol = await ethVars.tokenContract.symbol();
            //console.log("token symbol:", symbol);
        }
    } else {
        ethVars.contract = null;
    }
  }
</script>

<div>
  {#if ethVars.signerAddress}
    <button class="btn" onclick={handleConnectWallet}>
        {ethVars.signerAddress.slice(0, 6)
        + '..' + ethVars.signerAddress.slice(-6)}
    </button>
  {:else}
    <button class="btn" onclick={handleConnectWallet}>Connect Wallet</button>
  {/if}
</div>

<style>
  .btn {
      padding: 10px 20px;
      background: rgba(10, 10, 26, 0.7);
      border: 1px solid #00f7ff;
      color: #00f7ff;
      border-radius: 4px;
      cursor: pointer;
      font-weight: 600;
      transition: all 0.3s ease;
      box-shadow: 0 0 10px rgba(0, 247, 255, 0.3);
  }

  .btn:hover {
      background: rgba(0, 247, 255, 0.2);
      box-shadow: 0 0 15px rgba(0, 247, 255, 0.5);
      transform: translateY(-2px);
  }
</style>
