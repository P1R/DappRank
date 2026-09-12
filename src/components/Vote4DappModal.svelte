<script>
    import {
        ethVars,
        refreshTokenBalance,
        refreshDappsList,
    } from "../lib/ethers.svelte.js";
    import { closeModal, modalState } from "../lib/modal.svelte.js";
    import { parseEther, formatUnits, toUtf8String, getBigInt } from "ethers";
    import { MorphIcon } from "morphicons/svelte";
    import { ThumbsUp } from "lucide";
    import NeonSelect from "./NeonSelect.svelte";

    /** @param {string} str @returns {string} */
    function stripNulls(str) {
        return str ? str.replace(/\0/g, "") : str;
    }

    /** Integer square root (floor) — matches the contract's Math.sqrt semantics. */
    /** @param {bigint} n @returns {bigint} */
    function isqrt(n) {
        if (n < 2n) return n;
        let x = n;
        let y = (x + 1n) / 2n;
        while (y < x) {
            x = y;
            y = (x + n / x) / 2n;
        }
        return x;
    }

    /** Square root rounded up — same as Math.sqrt(_amount, Math.Rounding.Ceil). */
    /** @param {bigint} n @returns {bigint} */
    function sqrtCeil(n) {
        const r = isqrt(n);
        return r * r === n ? r : r + 1n;
    }

    /** @type {Record<string, string>} */
    const TIER_TEXT_CLASS = {
        high: "text-trust-high",
        mid: "text-trust-mid",
        low: "text-trust-low",
    };

    // State variables
    let amount = $state(0);
    let rate = $state(50); // Default vote rate
    // Raw bytes32 name of the dapp to vote on (pre-filled from the card).
    let dappName = $state(modalState.selectedDapp ?? "");
    let isVoting = $state(false);
    let transactionStatus = $state("");
    let error = $state("");
    /** @type {HTMLInputElement | null} */
    let amountInput;

    // Human-readable options for the dropdown, keyed by the raw bytes32 name
    // so the value passed to the contract matches exactly what's on-chain.
    // Only Active dapps can receive votes, so non-active ones are filtered out.
    let dappOptions = $derived(
        ethVars.dappsList
            .filter(
                (d) =>
                    d.status && stripNulls(toUtf8String(d.status)) === "Active",
            )
            .map((d) => ({
                value: d.name,
                label: stripNulls(toUtf8String(d.name)),
            })),
    );

    // The dapp currently selected in the dropdown (raw bytes32 match).
    let selectedDapp = $derived(
        ethVars.dappsList.find((d) => d.name === dappName),
    );

    // Live preview: fan weight √amount + simulated rating using the same
    // SRWV formula as the contract (weight_votes_sum + Vi·√Ti) / (weight_total_sum + √Ti).
    let preview = $derived(buildPreview());

    /** @returns {{ fanWeightDisplay: string, currentRate: string, newRate: string, tierClass: string } | null} */
    function buildPreview() {
        if (!selectedDapp || amount <= 0) return null;
        let amountWei;
        try {
            amountWei = parseEther(amount.toString());
        } catch {
            return null;
        }
        const fanWeight = sqrtCeil(amountWei);
        const wvs = BigInt(selectedDapp.weight_votes_sum);
        const wts = BigInt(selectedDapp.weight_total_sum);
        const currentRate = wts === 0n ? 0n : wvs / wts;
        const newRate = (wvs + getBigInt(rate) * fanWeight) / (wts + fanWeight);
        const newRateNum = Number(newRate);
        const tier =
            newRateNum >= 80 ? "high" : newRateNum >= 50 ? "mid" : "low";
        return {
            // fanWeight = √(amountWei) = √(amount_tokens · 1e18) = √amount_tokens · 1e9,
            // so formatUnits(fanWeight, 9) is exactly √amount in tokens.
            fanWeightDisplay: Number(formatUnits(fanWeight, 9)).toLocaleString(
                undefined,
                { maximumFractionDigits: 4 },
            ),
            currentRate: currentRate.toString(),
            newRate: newRate.toString(),
            tierClass: TIER_TEXT_CLASS[tier],
        };
    }

    $effect(() => {
        if (ethVars.signerAddress) {
            refreshTokenBalance();
        }
        // The dapp is pre-selected from the card, so focus lands on the amount.
        setTimeout(() => amountInput?.focus(), 50);
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

            // dappName is already the raw bytes32 name from the contract, so it
            // is passed through unchanged (no re-encoding).

            // _amount must be in the token's smallest unit (18 decimals, like ETH),
            // so convert the DRNK amount with parseEther instead of a raw integer.
            const amountWei = parseEther(amount.toString());

            if (ethVars.tokenContract === null) {
                throw new Error(
                    "Token contract not connected. Reconnect your wallet.",
                );
            }

            // Pre-flight checks — the contract reverts silently on several
            // conditions, so validate them here and show a clear message
            // before any transaction is sent.
            const balance = await ethVars.tokenContract.balanceOf(
                ethVars.signerAddress,
            );
            if (balance === 0n) {
                error =
                    "No tienes DRNK. Compra tokens con “Buy Tokens” (o recibe un airdrop) antes de votar.";
                return;
            }
            if (balance < amountWei) {
                error = `Saldo insuficiente: tienes ${formatUnits(balance, ethVars.tokenDecimals)} DRNK.`;
                return;
            }
            // Fan status — the contract only lets active fans vote. A fan is
            // registered when they buy DRNK or receive an airdrop, and stays
            // active for 4 weeks after their last mint/vote.
            const fanInfo = await ethVars.contract.getFanInfo(
                ethVars.signerAddress,
            );
            const fanExpires = fanInfo[0];
            const fanMultiplier = fanInfo[1];
            const topUpExpires = await ethVars.contract.topUpExpires();
            const now = BigInt(Math.floor(Date.now() / 1000));
            const topUpOpen = topUpExpires > now;

            if (fanExpires === 0n && fanMultiplier === 0n) {
                // Never registered as a fan (e.g. tokens received via transfer).
                error = topUpOpen
                    ? "No estás registrado como fan. Compra DRNK con “Buy Tokens” para activar tu cuenta de fan."
                    : "No estás registrado como fan y la ventana de compra ya expiró. Contacta al admin para recibir un airdrop.";
                return;
            }
            if (fanExpires <= now) {
                error = topUpOpen
                    ? "Tu estatus de fan expiró. Compra DRNK para reactivarlo."
                    : "Tu estatus de fan expiró y la ventana de compra ya cerró. Contacta al admin para recibir un airdrop.";
                return;
            }
            const dappActive =
                await ethVars.contract.DappNameIsActive(dappName);
            if (!dappActive) {
                error = "Esta dApp no está activa actualmente.";
                return;
            }

            // voteDapp spends the user's DRNK via transferFrom, so the DappsManager
            // contract must first be approved (allowance). This mirrors the approve
            // step in test/DappsManager.t.sol::testVote4Dapp.
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
                dappName, // _name (raw bytes32)
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
            <label for="dapp-name" class="field-label">Dapp:</label>
            <NeonSelect
                id="dapp-name"
                bind:value={dappName}
                options={dappOptions}
                placeholder="Select a dapp…"
            />
        </div>

        <div class="field-group">
            <label for="vote-amount" class="field-label">Amount (DRNK):</label>
            <input
                id="vote-amount"
                bind:this={amountInput}
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

        {#if preview}
            <div
                class="rounded-md border border-neon-cyan/30 bg-neon-cyan/10 p-3"
                role="status"
                aria-live="polite"
            >
                <div class="flex items-center justify-between text-sm">
                    <span class="opacity-70">Poder de voto</span>
                    <span class="tabular-nums font-semibold text-neon-cyan"
                        >√{amount} = {preview.fanWeightDisplay}</span
                    >
                </div>
                <div class="mt-2 flex items-center justify-between text-sm">
                    <span class="opacity-70">Rating estimado</span>
                    <span class="tabular-nums font-semibold {preview.tierClass}"
                        >{preview.currentRate} → {preview.newRate}</span
                    >
                </div>
                <p class="mt-2 text-xs opacity-60">
                    La raíz cuadrada frena el peso de las ballenas: tu
                    influencia crece más lento que tus tokens.
                </p>
            </div>
        {/if}

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
