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

<div class="relative inline-block">
    <button class="btn-neon text-base" on:click={() => showPopup = true}>
        Vote on Dapps
    </button>

    {#if showPopup}
        <div class="modal-overlay" on:click={closePopup} role="presentation">
            <div class="modal-content w-full max-w-sm" on:click={(e) => e.stopPropagation()} role="presentation">
                <div class="modal-header">
                    <h3>Vote on Dapps</h3>
                    <button class="modal-close" on:click={closePopup}>×</button>
                </div>

                <div class="modal-body">
                    <div class="balance-info">
                        <p>Your Balance: {tokenBalance} {tokenSymbol}</p>
                    </div>

                    <div class="flex flex-col gap-4">
                        <div class="field-group">
                            <label for="dapp-name" class="field-label">Dapp Name:</label>
                            <input
                                id="dapp-name"
                                type="text"
                                bind:value={dappName}
                                placeholder="Enter dapp name"
                                class="field-input"
                            />
                        </div>

                        <div class="field-group">
                            <label for="vote-amount" class="field-label">Amount (DRNK):</label>
                            <input
                                id="vote-amount"
                                type="number"
                                min="0.01"
                                step="0.01"
                                bind:value={amount}
                                placeholder="Enter amount"
                                class="field-input"
                            />
                        </div>

                        <div class="field-group">
                            <label for="vote-rate" class="field-label">Vote Rate (1-100):</label>
                            <input
                                id="vote-rate"
                                type="range"
                                min="1"
                                max="100"
                                bind:value={rate}
                                class="field-slider"
                            />
                            <div class="text-center font-semibold text-neon-cyan mt-1">
                                <span>{rate}</span>
                            </div>
                        </div>

                        <button
                            class="btn-neon w-full py-3 text-base"
                            on:click={voteDapp}
                            disabled={isVoting || amount <= 0 || !dappName}
                        >
                            {isVoting ? 'Processing...' : 'Submit Vote'}
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
        </div>
    {/if}
</div>
