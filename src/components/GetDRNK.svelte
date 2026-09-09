<script>
  import { ethVars } from '../lib/ethers.svelte.js';
  import { parseEther } from 'ethers';

    // State variables
    let showPopup = false;
    let amount = 0;
    let isBuying = false;
    let transactionStatus = '';
    let error = '';
    let tokenSymbol = '';
    let tokenBalance = 0;

    async function buyTokens() {
        //tokenBalance = await ethVars.tokenContract.balanceOf(ethVars.signerAddress);

        if (amount <= 0) {
            error = 'Please enter a valid amount';
            return;
        }

        try {
            isBuying = true;
            transactionStatus = 'Processing transaction...';


            let tx = await ethVars.contract.buyDRNK({
                value: parseEther(amount.toString())
            });
            receipt = await tx.wait();

            console.log(receipt);
            //if(receipt) {
            //    showPopup = false;
            //    transactionStatus = '';
            //    error = '';
            //    amount = 0;
            //}

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
</script>

<div class="relative inline-block">
    <button class="btn-neon text-base" on:click={() => showPopup = true}>
        Buy Tokens
    </button>

    {#if showPopup}
        <div class="modal-overlay" on:click={closePopup} role="presentation">
            <div class="modal-content w-full max-w-sm" on:click={(e) => e.stopPropagation()} role="presentation">
                <div class="modal-header">
                    <h3>Buy Tokens</h3>
                    <button class="modal-close" on:click={closePopup}>×</button>
                </div>

                <div class="modal-body">
                    <div class="balance-info">
                        <p>Your Balance: {tokenBalance} {tokenSymbol}</p>
                    </div>

                    <div class="field-group">
                        <label for="token-amount" class="field-label">Amount (ETH):</label>
                        <input
                            id="token-amount"
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
                        <p class="status-msg">{transactionStatus}</p>
                    {/if}

                    {#if error}
                        <p class="error-msg">{error}</p>
                    {/if}
                </div>
            </div>
        </div>
    {/if}
</div>
