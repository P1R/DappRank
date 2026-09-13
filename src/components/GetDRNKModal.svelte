<script>
    import { ethVars, refreshTokenBalance } from "../lib/ethers.svelte.js";
    import { closeModal } from "../lib/modal.svelte.js";
    import { t } from "../lib/i18n.svelte.js";
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
            error = t("common.validAmount");
            return;
        }

        if (ethVars.contract === null) {
            error = t("buy.connectFirst");
            return;
        }

        try {
            isBuying = true;
            transactionStatus = t("common.transactionProcessing");

            let tx = await ethVars.contract.buyDRNK({
                value: parseEther(amount.toString()),
            });
            let receipt = await tx.wait();

            console.log(receipt);
            await refreshTokenBalance();
            transactionStatus = t("buy.success");
        } catch (err) {
            const e = /** @type {Error} */ (err);
            error = t("common.transactionFailed", { message: e.message });
            transactionStatus = "";
        } finally {
            isBuying = false;
        }
    }
</script>

<div class="modal-header">
    <h3 id="buy-tokens-title">{t("buy.title")}</h3>
    <button
        class="modal-close"
        onclick={closeModal}
        aria-label={t("common.close")}>×</button
    >
</div>

<div class="modal-body">
    <div class="balance-info">
        {#if ethVars.signerAddress}
            <p>
                {t("common.yourBalance", {
                    balance:
                        ethVars.tokenBalance === null
                            ? "—"
                            : formatUnits(
                                  ethVars.tokenBalance,
                                  ethVars.tokenDecimals,
                              ),
                    symbol: ethVars.tokenSymbol,
                })}
            </p>
        {:else}
            <p>{t("common.connectToSeeBalance")}</p>
        {/if}
    </div>

    <div class="field-group">
        <label for="token-amount" class="field-label">{t("buy.amount")}</label>
        <input
            id="token-amount"
            bind:this={amountInput}
            type="number"
            min="0.01"
            step="0.01"
            bind:value={amount}
            placeholder={t("common.enterAmount")}
            class="field-input"
        />
    </div>

    <button
        class="btn-neon w-full py-3 text-base"
        onclick={buyTokens}
        disabled={isBuying || amount <= 0}
    >
        {isBuying ? t("common.processing") : t("action.buyTokens")}
    </button>

    {#if transactionStatus}
        <p class="status-msg" role="status">{transactionStatus}</p>
    {/if}

    {#if error}
        <p class="error-msg" role="alert">{error}</p>
    {/if}
</div>
