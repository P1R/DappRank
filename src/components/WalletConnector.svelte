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
    <button onclick={handleConnectWallet}>
        Disconnect {ethVars.signerAddress.slice(0, 6)
        + '..' + ethVars.signerAddress.slice(-6)}
    </button>
  {:else}
    <button onclick={handleConnectWallet}>Connect Wallet</button>
  {/if}
</div>
