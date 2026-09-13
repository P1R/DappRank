<script>
    import { t } from "../lib/i18n.svelte.js";
</script>

<footer class="mx-auto mt-12 max-w-350 border-t border-neon-cyan/20 py-10">
    <div class="grid gap-8 md:grid-cols-3">
        <div>
            <div class="flex items-center gap-2">
                <svg
                    class="h-7 w-7 shrink-0 text-neon-cyan"
                    viewBox="0 0 24 24"
                    fill="none"
                    stroke="currentColor"
                    stroke-width="2"
                    stroke-linecap="round"
                    stroke-linejoin="round"
                    aria-hidden="true"
                >
                    <path d="M12 2 2 7l10 5 10-5-10-5Z" />
                    <path d="M2 17l10 5 10-5" />
                    <path d="M2 12l10 5 10-5" />
                </svg>
                <span
                    class="bg-linear-to-r from-neon-cyan to-neon-pink bg-clip-text text-xl font-extrabold text-transparent"
                >
                    DappRank
                </span>
            </div>
            <p class="mt-2 text-sm opacity-70">{t("footer.tagline")}</p>
        </div>

        <nav aria-label={t("footer.about")}>
            <h2 class="text-sm font-semibold text-neon-cyan">
                {t("footer.about")}
            </h2>
            <ul class="mt-2 space-y-1.5 text-sm">
                <li>
                    <a
                        class="text-ink/80 transition-colors duration-150 hover:text-neon-cyan"
                        href="https://github.com/P1R/DappRank/blob/main/WP.md"
                        target="_blank"
                        rel="noreferrer"
                        >{t("footer.whitepaper")}</a
                    >
                </li>
                <li>
                    <a
                        class="text-ink/80 transition-colors duration-150 hover:text-neon-cyan"
                        href="https://github.com/P1R/DappRank/tree/main/docs"
                        target="_blank"
                        rel="noreferrer"
                        >{t("footer.docs")}</a
                    >
                </li>
                <li>
                    <a
                        class="text-ink/80 transition-colors duration-150 hover:text-neon-cyan"
                        href="https://github.com/P1R/DappRank"
                        target="_blank"
                        rel="noreferrer"
                        >{t("footer.source")}</a
                    >
                </li>
            </ul>
        </nav>

        <div>
            <h2 class="text-sm font-semibold text-neon-cyan">
                {t("footer.contracts")}
            </h2>
            <ul class="mt-2 space-y-1.5 text-xs font-mono">
                <li>
                    <a
                        class="text-ink/80 transition-colors duration-150 hover:text-neon-cyan"
                        href="https://sepolia.etherscan.io/address/0x6b0EB389DD4B3ad4E9a28f56f971735aD2A85baD"
                        target="_blank"
                        rel="noreferrer"
                        >{t("footer.dappsManager")} · 0x6b0E…85baD</a
                    >
                </li>
                <li>
                    <a
                        class="text-ink/80 transition-colors duration-150 hover:text-neon-cyan"
                        href="https://sepolia.etherscan.io/address/0x9549A8CcaB9fF25Cf5061bFBC5188Baed0615B60"
                        target="_blank"
                        rel="noreferrer"
                        >{t("footer.drnk")} · 0x9549…15B60</a
                    >
                </li>
            </ul>
            <h2 class="mt-4 text-sm font-semibold text-neon-cyan">
                {t("footer.subgraph")}
            </h2>
            <p class="mt-1 text-xs opacity-70">{t("footer.liveEndpoint")}</p>
            <a
                class="mt-1 block break-all text-xs text-neon-cyan/80 transition-colors duration-150 hover:text-neon-cyan"
                href="https://api.studio.thegraph.com/query/1760241/dapprank/v0.0.2"
                target="_blank"
                rel="noreferrer"
                >api.studio.thegraph.com/query/1760241/dapprank/v0.0.2</a
            >
        </div>
    </div>

    <p class="mt-8 text-center text-xs opacity-60">{t("footer.builtFor")}</p>
</footer>
