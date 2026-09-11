<script>
    import {
        ethVars,
        refreshTokenBalance,
        refreshDappsList,
    } from "../lib/ethers.svelte.js";
    import { closeModal } from "../lib/modal.svelte.js";
    import {
        parseEther,
        formatUnits,
        encodeBytes32String,
        getBigInt,
    } from "ethers";
    import { MorphIcon } from "morphicons/svelte";
    import { ThumbsUp } from "lucide";

    // State variables
    let amount = $state(0);
    let rate = $state(50); // Default vote rate
    let dappName = $state(""); // Manual dapp name input
    let isVoting = $state(false);
    let transactionStatus = $state("");
    let error = $state("");
    /** @type {HTMLInputElement | null} */
    let dappNameInput;

    $effect(() => {
        if (ethVars.signerAddress) {
            refreshTokenBalance();
        }
        setTimeout(() => dappNameInput?.focus(), 50);
    });

    async function voteDapp() {
        if (amount <= 0 || !dappName) {
            error = "Please enter a valid amount and dapp name";
            return;
        }

        if (rate < 1 || rate > 100) {
            error = "Vote rate must be between 1 and 100";
            return;
        }

        if (ethVars.contract === null) {
            error = "Please connect your wallet first to vote.";
            return;
        }

        try {
            isVoting = true;
            transactionStatus = "Processing transaction...";

            // Convert string dapp name to bytes32 for contract call
            const dappNameBytes32 = encodeBytes32String(dappName);

            // _amount must be in the token's smallest unit (18 decimals, like ETH),
            // so convert the DRNK amount with parseEther instead of a raw integer.
            const amountWei = parseEther(amount.toString());

            // voteDapp spends the user's DRNK via transferFrom, so the DappsManager
            // contract must first be approved (allowance). This mirrors the approve
            // step in test/DappsManager.t.sol::testVote4Dapp.
            if (ethVars.tokenContract === null) {
                throw new Error(
                    "Token contract not connected. Reconnect your wallet.",
                );
            }
            const allowance = await ethVars.tokenContract.allowance(
                ethVars.signerAddress,
                ethVars.contractAddress,
            );
            if (allowance < amountWei) {
                transactionStatus = "Approving DRNK spend...";
                const approval = await ethVars.tokenContract.approve(
                    ethVars.contractAddress,
                    amountWei,
                );
                await approval.wait();
                transactionStatus = "Processing transaction...";
            }

            // Call the voteDapp function
            const tx = await ethVars.contract.voteDapp(
                dappNameBytes32, // _name (converted to bytes32)
                amountWei, // _amount (DRNK in wei units)
                getBigInt(rate), // _rate
                { gasLimit: 1000000 }, // overrides
            );

            const receipt = await tx.wait();
            console.log(receipt);

            await refreshTokenBalance();
            await refreshDappsList();
            transactionStatus = "Vote submitted successfully!";

            // Reset form after successful vote
            setTimeout(() => {
                closeModal();
                transactionStatus = "";
                error = "";
                amount = 0;
                rate = 50;
                dappName = "";
            }, 2000);
        } catch (err) {
            const e = /** @type {Error} */ (err);
            error = "Transaction failed: " + e.message;
            transactionStatus = "";
        } finally {
            isVoting = false;
        }
    }
</script>

<div class="modal-header">
    <h3 id="vote-dapp-title">Vote on Dapps</h3>
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

    <div class="flex flex-col gap-4">
        <div class="field-group">
            <label for="dapp-name" class="field-label">Dapp Name:</label>
            <input
                id="dapp-name"
                bind:this={dappNameInput}
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
            <label for="vote-rate" class="field-label">Vote Rate (1-100):</label
            >
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
            onclick={voteDapp}
            disabled={isVoting || amount <= 0 || !dappName}
        >
            {isVoting ? "Processing..." : "Submit Vote"}
        </button>

        {#if transactionStatus}
            <p class="status-msg" role="status">{transactionStatus}</p>
        {/if}

        {#if error}
            <p class="error-msg" role="alert">{error}</p>
        {/if}
    </div>
</div>
