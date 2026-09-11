<script>
  import { connectWallet, connectContract, connectTokenContract, refreshTokenBalance, refreshDappsList } from '../lib/ethers.svelte.js';
  import { ethVars } from '../lib/ethers.svelte.js';

  async function handleConnectWallet() {
    if (ethVars.signerAddress == null) {
        ethVars.isLoading = true;
        const address = await connectWallet();
        if (address) {
            ethVars.signerAddress = address;
            await handleConnectcontract();
            await refreshDappsList();
        } else {
            ethVars.isLoading = false;
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
            await refreshTokenBalance();
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
    <button class="btn-neon font-mono" onclick={handleConnectWallet}>
        {ethVars.signerAddress.slice(0, 6)
        + '..' + ethVars.signerAddress.slice(-6)}
    </button>
  {:else}
    <button class="btn-neon" onclick={handleConnectWallet}>Connect Wallet</button>
  {/if}
</div>
