<script>
    import {
        ethVars,
        connectWallet,
        connectContract,
        connectTokenContract,
        refreshDappsList,
        refreshTokenBalance,
    } from "../lib/ethers.svelte.js";
    import { closeModal } from "../lib/modal.svelte.js";
    import { registerEnsSubname } from "../lib/ens.svelte.js";
    import { t } from "../lib/i18n.svelte.js";
    import { encodeBytes32String, parseEther, formatEther } from "ethers";

    // State variables
    let dappName = $state("");
    let cid = $state("");
    let isRegistering = $state(false);
    let transactionStatus = $state("");
    let error = $state("");
    let listingFeeWei = $state(null); // cached from the contract
    let bonusWei = $state(null); // welcome bonus minted to the registrant

    // Contract state: name must fit in a bytes32 (max 32 bytes)
    const NAME_MAX_LENGTH = 32;
    // Fallback in case the contract is not reachable yet (1e13 wei = 0.00001 ETH)
    const FALLBACK_LISTING_FEE = parseEther("0.00001");

    /** @type {HTMLInputElement | null} */
    let nameInput = $state(null);
    /** @type {HTMLButtonElement | null} */
    let connectButton = $state(null);

    $effect(() => {
        if (ethVars.signerAddress) {
            refreshTokenBalance();
        }
        loadContractFees();
        setTimeout(() => (nameInput ?? connectButton)?.focus(), 50);
    });

    async function loadContractFees() {
        if (ethVars.contract === null) {
            listingFeeWei = null;
            bonusWei = null;
            return;
        }
        try {
            listingFeeWei = await ethVars.contract.listingFee();
        } catch (e) {
            listingFeeWei = null;
        }
        try {
            bonusWei = await ethVars.contract.bonus();
        } catch (e) {
            bonusWei = null;
        }
    }

    function displayListingFee() {
        if (listingFeeWei === null) return "0.00001";
        return formatEther(listingFeeWei);
    }

    function displayBonus() {
        if (bonusWei === null) return null;
        return formatEther(bonusWei * 10n); // registerDapp mints 10 * bonus
    }

    /** @param {string} value @returns {boolean} */
    function isValidCid(value) {
        // CIDv0: base58, 46 chars, starts with "Qm"
        const v0 = /^Qm[1-9A-HJ-NP-Za-km-z]{44}$/;
        // CIDv1: base32, starts with "b" (e.g. bafy...)
        const v1 = /^b[a-z2-7]{58,59}$/i;
        return v0.test(value) || v1.test(value);
    }

    function validate() {
        if (!dappName.trim()) return t("register.nameRequired");
        if (dappName.length > NAME_MAX_LENGTH) {
            return t("register.nameTooLong", { max: NAME_MAX_LENGTH });
        }
        if (!cid.trim()) return t("register.cidRequired");
        if (!isValidCid(cid.trim())) {
            return t("register.cidInvalid");
        }
        return null;
    }

    async function connectWalletFirst() {
        ethVars.isLoading = true;
        error = "";
        const address = await connectWallet();
        if (address) {
            ethVars.signerAddress = address;
            const contract = await connectContract();
            if (contract) {
                ethVars.contract = contract;
                ethVars.tokenContractAddress = await contract.drnk();
                ethVars.tokenContract = await connectTokenContract();
                await refreshTokenBalance();
                await loadContractFees();
            }
        } else {
            error = t("register.walletCancelled");
        }
        ethVars.isLoading = false;
    }

    async function registerDapp() {
        const validationError = validate();
        if (validationError) {
            error = validationError;
            return;
        }
        if (ethVars.contract === null) {
            error = t("register.connectFirst");
            return;
        }

        try {
            isRegistering = true;
            transactionStatus = t("common.transactionProcessing");
            error = "";

            // Convert the dapp name to bytes32 for the contract call
            const nameBytes32 = encodeBytes32String(dappName.trim());
            const fee = listingFeeWei ?? FALLBACK_LISTING_FEE;

            // registerDapp is payable: it requires msg.value >= listingFee
            const tx = await ethVars.contract.registerDapp(
                nameBytes32,
                cid.trim(),
                { value: fee, gasLimit: 1000000 },
            );
            const receipt = await tx.wait();
            console.log(receipt);

            // ENSv2: crea <label>.dapprank.eth automáticamente (best-effort).
            // Si falla (label con '.', subname ya existe, etc.) el registro de
            // la dApp en el contrato NO se ve afectado.
            if (ethVars.signer && ethVars.signerAddress) {
                const ens = await registerEnsSubname(
                    dappName.trim(),
                    ethVars.signerAddress,
                    cid.trim(),
                    ethVars.signer,
                );
                if (!ens.ok) {
                    console.warn(
                        "ENSv2 subname no creado (la dApp sí quedó registrada):",
                        ens.reason,
                    );
                }
            }

            await refreshDappsList();
            await refreshTokenBalance();
            transactionStatus = t("register.success");

            setTimeout(() => {
                closeModal();
                transactionStatus = "";
                error = "";
                dappName = "";
                cid = "";
            }, 2000);
        } catch (err) {
            error = friendlyError(err);
            transactionStatus = "";
        } finally {
            isRegistering = false;
        }
    }

    /** @param {unknown} err @returns {string} */
    function friendlyError(err) {
        const msg = err instanceof Error ? err.message : String(err);
        if (/DappNameExists|already exists|name is taken/i.test(msg)) {
            return t("register.exists");
        }
        if (/listing fee uncovered|listing fee/i.test(msg)) {
            return t("register.feeUncovered");
        }
        if (/user rejected|denied|rejected/i.test(msg)) {
            return t("register.rejected");
        }
        if (/insufficient funds|insufficient/i.test(msg)) {
            return t("register.insufficientFunds");
        }
        return t("register.failed", { message: msg });
    }
</script>

<div class="modal-header">
    <h3 id="register-dapp-title">{t("register.title")}</h3>
    <button
        class="modal-close"
        onclick={closeModal}
        aria-label={t("common.close")}>×</button
    >
</div>

<div class="modal-body">
    <div
        class="rounded-md border border-neon-pink/40 bg-neon-pink/10 p-3 text-center"
    >
        <p class="text-sm font-semibold text-neon-pink">
            {t("register.listingFee", { fee: displayListingFee() })}
        </p>
        {#if displayBonus()}
            <p class="mt-1 text-xs opacity-80">
                {t("register.bonus", { bonus: displayBonus() ?? "" })}
            </p>
        {/if}
    </div>

    {#if ethVars.signerAddress}
        <div class="flex flex-col gap-4">
            <div class="field-group">
                <label for="dapp-name" class="field-label"
                    >{t("register.name")}</label
                >
                <input
                    id="dapp-name"
                    bind:this={nameInput}
                    type="text"
                    maxlength={NAME_MAX_LENGTH}
                    bind:value={dappName}
                    placeholder={t("register.namePlaceholder")}
                    class="field-input"
                    aria-describedby="dapp-name-hint"
                />
                <p id="dapp-name-hint" class="text-xs opacity-70">
                    {t("register.nameHint", {
                        count: dappName.length,
                        max: NAME_MAX_LENGTH,
                    })}
                </p>
            </div>

            <div class="field-group">
                <label for="dapp-cid" class="field-label"
                    >{t("register.cid")}</label
                >
                <input
                    id="dapp-cid"
                    type="text"
                    bind:value={cid}
                    placeholder={t("register.cidPlaceholder")}
                    class="field-input"
                    aria-describedby="dapp-cid-hint"
                />
                <p id="dapp-cid-hint" class="text-xs opacity-70">
                    {t("register.cidHint")}
                </p>
            </div>

            <button
                class="btn-neon-pink w-full py-3 text-base"
                onclick={registerDapp}
                disabled={isRegistering || !dappName.trim() || !cid.trim()}
            >
                {isRegistering
                    ? t("common.processing")
                    : t("register.forFee", { fee: displayListingFee() })}
            </button>

            {#if transactionStatus}
                <p class="status-msg" role="status">{transactionStatus}</p>
            {/if}

            {#if error}
                <p class="error-msg" role="alert">{error}</p>
            {/if}
        </div>
    {:else}
        <div class="text-center">
            <p class="text-sm text-ink/90">
                {t("register.connectToRegister")}
            </p>
            <button
                bind:this={connectButton}
                class="btn-neon w-full py-3 text-base"
                onclick={connectWalletFirst}
                disabled={ethVars.isLoading}
            >
                {ethVars.isLoading
                    ? t("common.connecting")
                    : t("common.connectWallet")}
            </button>
            {#if error}
                <p class="error-msg" role="alert">{error}</p>
            {/if}
        </div>
    {/if}
</div>
