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
    background: rgba(10, 10, 26, 0.7);
    border: 1px solid #00f7ff;
    color: #00f7ff;
    border-radius: 4px;
    cursor: pointer;
    font-weight: 600;
    transition: all 0.3s ease;
    box-shadow: 0 0 10px rgba(0, 247, 255, 0.3);
    font-size: 16px;
}

.buy-button:hover {
    background: rgba(0, 247, 255, 0.2);
    box-shadow: 0 0 15px rgba(0, 247, 255, 0.5);
    transform: translateY(-2px);
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
    background-color: rgba(10, 10, 26, 0.95);
    border-radius: 8px;
    box-shadow: 0 0 20px rgba(0, 247, 255, 0.3);
    width: 90%;
    max-width: 400px;
    max-height: 90vh;
    overflow-y: auto;
    position: relative;
    border: 1px solid #00f7ff;
    backdrop-filter: blur(10px);
}

.popup-header {
    display: flex;
    justify-content: space-between;
    align-items: center;
    padding: 20px 20px 0 20px;
    border-bottom: 1px solid #00f7ff;
}

.popup-header h3 {
    margin: 0;
    color: #00f7ff;
    font-weight: 600;
}

.close-button {
    background: none;
    border: none;
    font-size: 24px;
    cursor: pointer;
    color: #00f7ff;
    padding: 0;
    width: 30px;
    height: 30px;
    display: flex;
    align-items: center;
    justify-content: center;
    transition: all 0.3s ease;
}

.close-button:hover {
    color: #fff;
    transform: scale(1.1);
}

.popup-body {
    padding: 20px;
}

.balance-info {
    margin-bottom: 20px;
    padding: 10px;
    background-color: rgba(0, 247, 255, 0.1);
    border-radius: 4px;
    text-align: center;
    border: 1px solid rgba(0, 247, 255, 0.3);
}

.balance-info p {
    margin: 0;
    color: #00f7ff;
    font-weight: 500;
}

.amount-input {
    margin-bottom: 20px;
}

.amount-input label {
    display: block;
    margin-bottom: 5px;
    font-weight: 500;
    color: #00f7ff;
}

.amount-input input {
    width: 100%;
    padding: 10px;
    border: 1px solid #00f7ff;
    border-radius: 4px;
    box-sizing: border-box;
    background-color: rgba(0, 0, 0, 0.3);
    color: #fff;
    font-size: 16px;
}

.amount-input input::placeholder {
    color: rgba(255, 255, 255, 0.5);
}

.buy-token-button {
    width: 100%;
    padding: 12px;
    background: rgba(0, 247, 255, 0.2);
    color: #00f7ff;
    border: 1px solid #00f7ff;
    border-radius: 4px;
    cursor: pointer;
    font-size: 16px;
    font-weight: 600;
    transition: all 0.3s ease;
    box-shadow: 0 0 10px rgba(0, 247, 255, 0.3);
}

.buy-token-button:hover:not(:disabled) {
    background: rgba(0, 247, 255, 0.3);
    box-shadow: 0 0 15px rgba(0, 247, 255, 0.5);
    transform: translateY(-2px);
}

.buy-token-button:disabled {
    background: rgba(10, 10, 26, 0.5);
    border-color: rgba(0, 247, 255, 0.3);
    color: rgba(0, 247, 255, 0.5);
    cursor: not-allowed;
    box-shadow: none;
    transform: none;
}

.status {
    color: #28a745;
    text-align: center;
    margin: 10px 0;
    font-weight: 500;
}

.error {
    color: #dc3545;
    text-align: center;
    margin: 10px 0;
    font-weight: 500;
}

/* Responsive design */
@media (max-width: 480px) {
    .popup-content {
        margin: 10px;
        border-radius: 6px;
    }

    .popup-body {
        padding: 15px;
    }

    .buy-button {
        padding: 8px 16px;
        font-size: 14px;
    }

    .buy-token-button {
        padding: 10px;
        font-size: 14px;
    }
}
</style>

