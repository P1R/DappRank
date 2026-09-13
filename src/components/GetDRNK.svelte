<script>
    import { openModal } from "../lib/modal.svelte.js";
    import { ethVars, refreshTokenBalance } from "../lib/ethers.svelte.js";
    import { t } from "../lib/i18n.svelte.js";
    import { MorphIcon } from "morphicons/svelte";
    import { Coins } from "lucide";

    async function handleOpen() {
        if (ethVars.signerAddress) {
            await refreshTokenBalance();
        }
        openModal("buy");
    }
</script>

<button class="btn-neon" on:click={handleOpen}>
    <MorphIcon
        icon={Coins}
        spring="snappy"
        reducedMotion="user"
        aria-hidden="true"
    />
    {t("action.buyTokens")}
</button>
