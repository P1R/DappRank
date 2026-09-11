<script>
    import {
        connectWallet,
        connectContract,
        connectTokenContract,
        refreshTokenBalance,
        refreshDappsList,
    } from "../lib/ethers.svelte.js";
    import { ethVars } from "../lib/ethers.svelte.js";
    import { MorphIcon } from "morphicons/svelte";
    import { Wallet, WalletCards, LoaderCircle } from "lucide";

    async function handleConnectWallet() {
        if (ethVars.signerAddress == null) {
            ethVars.isLoading = true;
            try {
                const address = await connectWallet();
                if (address) {
                    ethVars.signerAddress = address;
                    await handleConnectcontract();
                    await refreshDappsList();
                }
            } finally {
                // Always clear the loading state, even if a step fails or is rejected.
                ethVars.isLoading = false;
            }
        } else {
            // Disconnect: clear all wallet/contract state so the UI resets.
            ethVars.signerAddress = null;
            ethVars.contract = null;
            ethVars.tokenContract = null;
            ethVars.tokenContractAddress = null;
            ethVars.dappsList = [];
            ethVars.tokenBalance = null;
            ethVars.isLoading = false;
        }
    }

    async function handleConnectcontract() {
        if (ethVars.contract == null) {
            const contract = await connectContract();
            if (contract) {
                ethVars.contract = contract;
                ethVars.tokenContractAddress = await contract.drnk();
                ethVars.tokenContract = await connectTokenContract();
                await refreshTokenBalance();
            }
        }
    }
</script>

<div>
    {#if ethVars.signerAddress}
        <button
            class="btn-neon font-mono"
            onclick={handleConnectWallet}
            aria-label={`Disconnect wallet ${ethVars.signerAddress.slice(0, 6)}...${ethVars.signerAddress.slice(-6)}`}
        >
            <MorphIcon
                icon={WalletCards}
                spring="snappy"
                reducedMotion="user"
                aria-hidden="true"
            />
            {ethVars.signerAddress.slice(0, 6)}
            + '..' + {ethVars.signerAddress.slice(-6)}
        </button>
    {:else}
        <button
            class="btn-neon"
            onclick={handleConnectWallet}
            disabled={ethVars.isLoading}
            aria-busy={ethVars.isLoading}
        >
            {#if ethVars.isLoading}
                <MorphIcon
                    icon={LoaderCircle}
                    class="animate-spin"
                    spring="snappy"
                    reducedMotion="user"
                    aria-hidden="true"
                />
                Connecting…
            {:else}
                <MorphIcon
                    icon={Wallet}
                    spring="snappy"
                    reducedMotion="user"
                    aria-hidden="true"
                />
                Connect Wallet
            {/if}
        </button>
    {/if}
</div>
