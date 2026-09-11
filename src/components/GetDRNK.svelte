<script>
  import { ethVars, refreshTokenBalance } from '../lib/ethers.svelte.js';
  import { parseEther, formatUnits } from 'ethers';
  import { MorphIcon } from 'morphicons/svelte';
  import { Coins, DollarSign } from 'lucide';

    // State variables
    let showPopup = false;
    let amount = 0;
    let isBuying = false;
    let transactionStatus = '';
    let error = '';
    let amountInput;

    async function buyTokens() {
        if (amount <= 0) {
            error = 'Please enter a valid amount';
            return;
        }

        if (ethVars.contract === null) {
            error = 'Please connect your wallet first to buy tokens.';
            return;
        }

        try {
            isBuying = true;
            transactionStatus = 'Processing transaction...';

            let tx = await ethVars.contract.buyDRNK({
                value: parseEther(amount.toString())
            });
            let receipt = await tx.wait();

            console.log(receipt);
            await refreshTokenBalance();
            transactionStatus = 'Purchase successful!';

        } catch (err) {
            error = 'Transaction failed: ' + err.message;
            transactionStatus = '';
        } finally {
            isBuying = false;
        }
    }

    // Close popup
    function closePopup() {
        showPopup = false;
        transactionStatus = '';
        error = '';
        amount = 0;
    }

    // Open popup and refresh the token balance if a wallet is connected
    async function openPopup() {
        if (ethVars.signerAddress) {
            await refreshTokenBalance();
        }
        showPopup = true;
        setTimeout(() => amountInput?.focus(), 50);
    }

    function handleKeydown(e) {
        if (e.key === 'Escape') closePopup();
    }
</script>

<div class="relative inline-block">
    <button class="btn-neon" on:click={openPopup}>
        <MorphIcon icon={Coins} spring="snappy" reducedMotion="user" aria-hidden="true" />
        Buy Tokens
    </button>

    {#if showPopup}
        <div
            class="modal-overlay"
            on:click={closePopup}
            on:keydown={handleKeydown}
            role="presentation"
        >
            <div
                class="modal-content"
                on:click={(e) => e.stopPropagation()}
                on:keydown={handleKeydown}
                role="dialog"
                aria-modal="true"
                aria-labelledby="buy-tokens-title"
                tabindex="-1"
            >
                <div class="modal-header">
                    <h3 id="buy-tokens-title">Buy Tokens</h3>
                    <button class="modal-close" on:click={closePopup} aria-label="Close">×</button>
                </div>

                <div class="modal-body">
                    <div class="balance-info">
                        {#if ethVars.signerAddress}
                            <p>Your Balance: {ethVars.tokenBalance === null ? '—' : formatUnits(ethVars.tokenBalance, ethVars.tokenDecimals)} {ethVars.tokenSymbol}</p>
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
                        on:click={buyTokens}
                        disabled={isBuying || amount <= 0}
                    >
                        {isBuying ? 'Processing...' : 'Buy Tokens'}
                    </button>

                    {#if transactionStatus}
                        <p class="status-msg" role="status">{transactionStatus}</p>
                    {/if}

                    {#if error}
                        <p class="error-msg" role="alert">{error}</p>
                    {/if}
                </div>
            </div>
        </div>
    {/if}
</div>
