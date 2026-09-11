<script>
    import { ethVars, refreshTokenBalance } from "../lib/ethers.svelte.js";
    import { closeModal } from "../lib/modal.svelte.js";
    import { parseEther, formatUnits } from "ethers";

    // State variables
    let amount = $state(0);
    let isBuying = $state(false);
    let transactionStatus = $state("");
    let error = $state("");
    /** @type {HTMLInputElement | null} */
    let amountInput;

    $effect(() => {
        if (ethVars.signerAddress) {
            refreshTokenBalance();
        }
        setTimeout(() => amountInput?.focus(), 50);
    });

    async function buyTokens() {
        if (amount <= 0) {
            error = "Please enter a valid amount";
            return;
        }

        if (ethVars.contract === null) {
            error = "Please connect your wallet first to buy tokens.";
            return;
        }

        try {
            isBuying = true;
            transactionStatus = "Processing transaction...";

            let tx = await ethVars.contract.buyDRNK({
                value: parseEther(amount.toString()),
            });
            let receipt = await tx.wait();

            console.log(receipt);
            await refreshTokenBalance();
            transactionStatus = "Purchase successful!";
        } catch (err) {
            const e = /** @type {Error} */ (err);
            error = "Transaction failed: " + e.message;
            transactionStatus = "";
        } finally {
            isBuying = false;
        }
    }
</script>

<div class="modal-header">
    <h3 id="buy-tokens-title">Buy Tokens</h3>
    <button class="modal-close" onclick={closeModal} aria-label="Close"
        >×</button
    >
</div>

<div class="modal-body">
    <div class="balance-info">
        {#if ethVars.signerAddress}
            <p>
                Your Balance: {ethVars.tokenBalance === null
                    ? "—"
                    : formatUnits(ethVars.tokenBalance, ethVars.tokenDecimals)}
                {ethVars.tokenSymbol}
            </p>
        {:else}
            <p>Connect your wallet to see your balance</p>
        {/if}
    </div>

    <div class="field-group">
        <label for="token-amount" class="field-label">Amount (ETH):</label>
        <input
            id="token-amount"
            bind:this={amountInput}
            type="number"
            min="0.01"
            step="0.01"
            bind:value={amount}
            placeholder="Enter amount"
            class="field-input"
        />
    </div>

    <button
        class="btn-neon w-full py-3 text-base"
        onclick={buyTokens}
        disabled={isBuying || amount <= 0}
    >
        {isBuying ? "Processing..." : "Buy Tokens"}
    </button>

    {#if transactionStatus}
        <p class="status-msg" role="status">{transactionStatus}</p>
    {/if}

    {#if error}
        <p class="error-msg" role="alert">{error}</p>
    {/if}
</div>
