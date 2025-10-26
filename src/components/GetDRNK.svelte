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

<div class="token-buyer">
    <button class="buy-button" on:click={() => showPopup = true}>
        Buy Tokens
    </button>

    {#if showPopup}
        <div class="popup-overlay" on:click={closePopup}>
            <div class="popup-content" on:click={(e) => e.stopPropagation()}>
                <div class="popup-header">
                    <h3>Buy Tokens</h3>
                    <button class="close-button" on:click={closePopup}>×</button>
                </div>

                <div class="popup-body">
                    <div class="balance-info">
                        <p>Your Balance: {tokenBalance} {tokenSymbol}</p>
                    </div>

                    <div class="amount-input">
                        <label for="token-amount">Amount (ETH):</label>
                        <input
                            id="token-amount"
                            type="number"
                            min="0.01"
                            step="0.01"
                            bind:value={amount}
                            placeholder="Enter amount"
                        />
                    </div>

                    <button
                        class="buy-token-button"
                        on:click={buyTokens}
                        disabled={isBuying || amount <= 0}
                    >
                        {isBuying ? 'Processing...' : 'Buy Tokens'}
                    </button>

                    {#if transactionStatus}
                        <p class="status">{transactionStatus}</p>
                    {/if}

                    {#if error}
                        <p class="error">{error}</p>
                    {/if}
                </div>
            </div>
        </div>
    {/if}
</div>

<style>
    .token-buyer {
        position: relative;
        display: inline-block;
    }

    .buy-button {
        padding: 10px 20px;
        background-color: #007bff;
        color: white;
        border: none;
        border-radius: 4px;
        cursor: pointer;
        font-size: 16px;
    }

    .buy-button:hover {
        background-color: #0056b3;
    }

    .popup-overlay {
        position: fixed;
        top: 0;
        left: 0;
        width: 100%;
        height: 100%;
        background-color: rgba(0, 0, 0, 0.5);
        display: flex;
        justify-content: center;
        align-items: center;
        z-index: 1000;
    }

    .popup-content {
        background-color: white;
        border-radius: 8px;
        box-shadow: 0 4px 6px rgba(0, 0, 0, 0.1);
        width: 90%;
        max-width: 400px;
        max-height: 90vh;
        overflow-y: auto;
        position: relative;
    }

    .popup-header {
        display: flex;
        justify-content: space-between;
        align-items: center;
        padding: 20px 20px 0 20px;
        border-bottom: 1px solid #eee;
    }

    .popup-header h3 {
        margin: 0;
        color: #333;
    }

    .close-button {
        background: none;
        border: none;
        font-size: 24px;
        cursor: pointer;
        color: #999;
        padding: 0;
        width: 30px;
        height: 30px;
        display: flex;
        align-items: center;
        justify-content: center;
    }

    .close-button:hover {
        color: #333;
    }

    .popup-body {
        padding: 20px;
    }

    .balance-info {
        margin-bottom: 20px;
        padding: 10px;
        background-color: #f8f9fa;
        border-radius: 4px;
        text-align: center;
    }

    .amount-input {
        margin-bottom: 20px;
    }

    .amount-input label {
        display: block;
        margin-bottom: 5px;
        font-weight: bold;
        color: #333;
    }

    .amount-input input {
        width: 100%;
        padding: 10px;
        border: 1px solid #ccc;
        border-radius: 4px;
        box-sizing: border-box;
    }

    .buy-token-button {
        width: 100%;
        padding: 12px;
        background-color: #28a745;
        color: white;
        border: none;
        border-radius: 4px;
        cursor: pointer;
        font-size: 16px;
        font-weight: bold;
    }

    .buy-token-button:hover:not(:disabled) {
        background-color: #218838;
    }

    .buy-token-button:disabled {
        background-color: #6c757d;
        cursor: not-allowed;
    }

    .status {
        color: green;
        text-align: center;
        margin: 10px 0;
    }

    .error {
        color: red;
        text-align: center;
        margin: 10px 0;
    }

    /* Responsive design */
    @media (max-width: 480px) {
        .popup-content {
            margin: 10px;
        }

        .popup-body {
            padding: 15px;
        }
    }
</style>

