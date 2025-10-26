<script>
  import { ethVars } from '../lib/ethers.svelte.js';
  import { parseEther, toUtf8String, formatUnits, encodeBytes32String, getBigInt } from 'ethers';

  // State variables
  let showPopup = false;
  let amount = 0;
  let rate = 50; // Default vote rate
  let dappName = ''; // Manual dapp name input
  let isVoting = false;
  let transactionStatus = '';
  let error = '';
  let tokenSymbol = '';
  let tokenBalance = 0;

  // Initialize component
  import { onMount } from 'svelte';
  onMount(async () => {
    try {
      // Initialize token info
      tokenSymbol = 'DRNK';
      // In a real implementation, you'd fetch the actual balance
      // tokenBalance = await ethVars.tokenContract.balanceOf(ethVars.signerAddress);
    } catch (err) {
      error = 'Failed to initialize: ' + err.message;
    }
  });

  async function voteDapp() {
    if (amount <= 0 || !dappName) {
      error = 'Please enter a valid amount and dapp name';
      return;
    }

    if (rate < 1 || rate > 100) {
      error = 'Vote rate must be between 1 and 100';
      return;
    }

    try {
      isVoting = true;
      transactionStatus = 'Processing transaction...';

      // Convert string dapp name to bytes32 for contract call
      const dappNameBytes32 = encodeBytes32String(dappName);

      // Call the voteDapp function
      let tx = await ethVars.contract.voteDapp(
        dappNameBytes32, // _name (converted to bytes32)
        getBigInt(amount.toString()), // _amount
        getBigInt(rate), // _rate
        options = { gasLimit: 1000000 }
      );

      const receipt = await tx.wait();
      console.log(receipt);

      transactionStatus = 'Vote submitted successfully!';

      // Reset form after successful vote
      setTimeout(() => {
        showPopup = false;
        transactionStatus = '';
        error = '';
        amount = 0;
        rate = 50;
        dappName = '';
      }, 2000);

    } catch (err) {
      error = 'Transaction failed: ' + err.message;
      transactionStatus = '';
    } finally {
      isVoting = false;
    }
  }

  // Close popup
  function closePopup() {
    showPopup = false;
    transactionStatus = '';
    error = '';
    amount = 0;
    rate = 50;
    dappName = '';
  }
</script>

<div class="token-vote">
    <button class="buy-button" on:click={() => showPopup = true}>
        Vote on Dapps
    </button>

    {#if showPopup}
        <div class="popup-overlay" on:click={closePopup}>
            <div class="popup-content" on:click={(e) => e.stopPropagation()}>
                <div class="popup-header">
                    <h3>Vote on Dapps</h3>
                    <button class="close-button" on:click={closePopup}>×</button>
                </div>

                <div class="popup-body">
                    <div class="balance-info">
                        <p>Your Balance: {tokenBalance} {tokenSymbol}</p>
                    </div>

                    <div class="vote-form">
                        <div class="form-group">
                            <label for="dapp-name">Dapp Name:</label>
                            <input
                                id="dapp-name"
                                type="text"
                                bind:value={dappName}
                                placeholder="Enter dapp name"
                                class="form-control"
                            />
                        </div>

                        <div class="form-group">
                            <label for="vote-amount">Amount (DRNK):</label>
                            <input
                                id="vote-amount"
                                type="number"
                                min="0.01"
                                step="0.01"
                                bind:value={amount}
                                placeholder="Enter amount"
                                class="form-control"
                            />
                        </div>

                        <div class="form-group">
                            <label for="vote-rate">Vote Rate (1-100):</label>
                            <input
                                id="vote-rate"
                                type="range"
                                min="1"
                                max="100"
                                bind:value={rate}
                                class="slider"
                            />
                            <div class="rate-display">
                                <span>{rate}</span>
                            </div>
                        </div>

                        <button
                            class="buy-token-button"
                            on:click={voteDapp}
                            disabled={isVoting || amount <= 0 || !dappName}
                        >
                            {isVoting ? 'Processing...' : 'Submit Vote'}
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
        </div>
    {/if}
</div>

<style>
.token-vote {
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

.vote-form {
    display: flex;
    flex-direction: column;
    gap: 15px;
}

.form-group {
    display: flex;
    flex-direction: column;
}

.form-group label {
    margin-bottom: 5px;
    font-weight: 500;
    color: #00f7ff;
}

.form-control {
    padding: 10px;
    border: 1px solid #00f7ff;
    border-radius: 4px;
    box-sizing: border-box;
    background-color: rgba(0, 0, 0, 0.3);
    color: #fff;
    font-size: 16px;
}

.form-control::placeholder {
    color: rgba(255, 255, 255, 0.5);
}

.slider {
    width: 100%;
    margin: 10px 0;
    -webkit-appearance: none;
    height: 8px;
    border-radius: 4px;
    background: rgba(0, 247, 255, 0.2);
    outline: none;
}

.slider::-webkit-slider-thumb {
    -webkit-appearance: none;
    width: 20px;
    height: 20px;
    border-radius: 50%;
    background: #00f7ff;
    cursor: pointer;
}

.rate-display {
    text-align: center;
    color: #00f7ff;
    font-weight: 600;
    margin-top: 5px;
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
