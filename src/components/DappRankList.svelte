<script>
    import { ethVars } from "../lib/ethers.svelte.js";
    import { openVoteModal } from "../lib/modal.svelte.js";
    import { toUtf8String, formatUnits } from "ethers";
    import { MorphIcon } from "morphicons/svelte";
    import { Trophy, Flame, CircleCheck, Vote } from "lucide";

    /** @typedef {'high' | 'mid' | 'low' | 'neutral'} Tier */

    /** @type {Record<string, Tier>} */
    const STATUS_TIER = {
        Active: "high",
        Submitted: "neutral",
        Expired: "mid",
        Banned: "low",
    };

    /** @type {Record<Tier, string>} */
    const TIER_LABEL = {
        high: "Trusted",
        mid: "Mixed",
        low: "Risky",
        neutral: "Neutral",
    };
    /** @type {Record<Tier, string>} */
    const TIER_TEXT_CLASS = {
        high: "text-trust-high",
        mid: "text-trust-mid",
        low: "text-trust-low",
        neutral: "text-trust-neutral",
    };
    /** @type {Record<Tier, string>} */
    const TIER_BADGE_CLASS = {
        high: "tier-badge-high",
        mid: "tier-badge-mid",
        low: "tier-badge-low",
        neutral: "tier-badge-neutral",
    };
    /** @type {Record<Tier, string>} */
    const TIER_GRADIENT = {
        high: "linear-gradient(90deg, var(--color-trust-high), var(--color-neon-cyan))",
        mid: "linear-gradient(90deg, var(--color-trust-mid), var(--color-neon-pink))",
        low: "linear-gradient(90deg, var(--color-trust-low), var(--color-neon-pink))",
        neutral:
            "linear-gradient(90deg, var(--color-trust-neutral), var(--color-neon-pink))",
    };

    /** @param {number} rating @returns {'high' | 'mid' | 'low'} */
    function ratingTier(rating) {
        if (rating >= 80) return "high";
        if (rating >= 50) return "mid";
        return "low";
    }

    /** @param {string} str @returns {string} */
    function stripNulls(str) {
        return str ? str.replace(/\0/g, "") : str;
    }

    let rawData = $derived(
        ethVars.dappsList.map((dapp) => {
            const rating = parseInt(dapp.rate) || 0;
            const status = dapp.status
                ? stripNulls(toUtf8String(dapp.status))
                : "Unknown";
            return {
                name: dapp.name
                    ? stripNulls(toUtf8String(dapp.name))
                    : "Unknown DApp",
                rawName: dapp.name,
                url: dapp.cid ? `https://ipfs.io/ipfs/${dapp.cid}` : "#",
                rating,
                tier: ratingTier(rating),
                tokensDonated: Number(formatUnits(dapp.balance ?? 0, 18)) || 0,
                tokensBurned: Number(formatUnits(dapp.burned ?? 0, 18)) || 0,
                owner: dapp.owner,
                status,
                statusTier: STATUS_TIER[status] || "neutral",
                weightTotalSum: Number(dapp.weight_total_sum) || 0,
            };
        }),
    );

    let maxWeightTotal = $derived(
        Math.max(1, ...rawData.map((d) => d.weightTotalSum)),
    );

    let data = $derived(
        [...rawData]
            .sort((a, b) => b.rating - a.rating)
            .map((item, index) => ({
                ...item,
                rank: index + 1,
                consensusPct: Math.round(
                    (item.weightTotalSum / maxWeightTotal) * 100,
                ),
            })),
    );

    let totalBurned = $derived(
        rawData.reduce((sum, d) => sum + d.tokensBurned, 0),
    );
</script>

{#if ethVars.isLoading}
    <div
        class="mx-auto my-12 max-w-md rounded-xl border border-neon-cyan/20 bg-void/60 p-8 text-center shadow-md"
        role="status"
        aria-live="polite"
    >
        <div
            class="mx-auto mb-4 h-10 w-10 animate-spin rounded-full border-4 border-neon-cyan/30 border-t-neon-cyan"
        ></div>
        <p class="text-lg font-semibold text-neon-cyan">Loading ranking…</p>
        <p class="mt-1 text-sm opacity-80">
            Fetching the latest data from the contract.
        </p>
    </div>
{:else if data.length > 0}
    <div class="mx-auto max-w-350 pt-6">
        <div
            class="mx-auto flex w-fit max-w-full flex-wrap items-center justify-center gap-2 rounded-full border border-neon-pink/30 bg-neon-pink/10 px-5 py-2 text-sm font-semibold text-neon-pink"
        >
            <span aria-hidden="true">🔥</span>
            <span>Total DRNK Burned:</span>
            <span class="text-base font-bold tabular-nums"
                >{totalBurned.toLocaleString(undefined, {
                    maximumFractionDigits: 2,
                })}</span
            >
        </div>
    </div>

    <!-- MOBILE: cards (single column, no horizontal scroll) -->
    <div class="mx-auto grid max-w-350 grid-cols-1 gap-4 py-4 md:hidden">
        {#each data as item}
            <article class="card p-4">
                <div class="flex items-center justify-between gap-2">
                    <span
                        class="flex items-center gap-1.5 tabular-nums font-semibold {item.rank <=
                        3
                            ? 'text-neon-pink'
                            : 'text-ink/70'}"
                    >
                        {#if item.rank <= 3}
                            <MorphIcon
                                icon={Trophy}
                                class="h-4 w-4"
                                aria-hidden="true"
                            />
                        {/if}
                        #{item.rank}
                    </span>
                    <span class={TIER_BADGE_CLASS[item.statusTier]}>
                        <span
                            class="h-1.5 w-1.5 rounded-full bg-current"
                            aria-hidden="true"
                        ></span>
                        {item.status}
                    </span>
                </div>

                <h2 class="mt-2 text-lg font-semibold text-neon-cyan">
                    {item.name}
                </h2>
                <a
                    href={item.url}
                    class="block break-all text-xs opacity-60"
                    aria-label={`Open ${item.name} on IPFS`}>{item.url}</a
                >

                <div class="mt-3 flex items-center justify-between">
                    <span class="text-sm opacity-70">Rating</span>
                    <span class="flex items-center gap-2">
                        <span
                            class="tabular-nums font-semibold {TIER_TEXT_CLASS[
                                item.tier
                            ]}">{item.rating}</span
                        >
                        <span class={TIER_BADGE_CLASS[item.tier]}>
                            <span
                                class="h-1.5 w-1.5 rounded-full bg-current"
                                aria-hidden="true"
                            ></span>
                            {TIER_LABEL[item.tier]}
                        </span>
                    </span>
                </div>
                <div class="mt-1 h-2 overflow-hidden rounded-full bg-black/30">
                    <div
                        class="h-full rounded-full"
                        style="width: {item.rating}%; background: {TIER_GRADIENT[
                            item.tier
                        ]};"
                    ></div>
                </div>

                <div class="mt-3 grid grid-cols-2 gap-3">
                    <div
                        class="flex flex-col items-center rounded-md border border-neon-cyan/20 bg-black/20 px-3 py-2"
                    >
                        <div
                            class="text-sm tabular-nums font-semibold text-ink/90"
                        >
                            {item.tokensDonated}
                        </div>
                        <div class="text-xs opacity-60">Donated</div>
                    </div>
                    <div
                        class="flex flex-col items-center rounded-md border border-neon-cyan/20 bg-black/20 px-3 py-2"
                    >
                        <div
                            class="flex items-center gap-1 text-sm tabular-nums font-semibold text-ink/90"
                        >
                            <MorphIcon
                                icon={Flame}
                                class="h-3.5 w-3.5"
                                aria-hidden="true"
                            />
                            {item.tokensBurned}
                        </div>
                        <div class="text-xs opacity-60">Burned</div>
                    </div>
                </div>

                <div
                    class="mt-3 flex items-center justify-between text-xs opacity-70"
                >
                    <span>Community backing</span>
                    <span class="tabular-nums font-semibold text-neon-cyan"
                        >{item.consensusPct}%</span
                    >
                </div>
                <div
                    class="mt-1 h-1.5 overflow-hidden rounded-full bg-black/30"
                >
                    <div
                        class="h-full rounded-full bg-linear-to-r from-neon-cyan to-neon-pink"
                        style="width: {item.consensusPct}%"
                    ></div>
                </div>

                <div class="mt-3 text-xs opacity-60">
                    Owner: {item.owner.slice(0, 6)}...{item.owner.slice(-4)}
                </div>

                <button
                    class="btn-neon mt-3 w-full py-2 text-sm"
                    onclick={() => openVoteModal(item.rawName)}
                >
                    <MorphIcon icon={Vote} class="h-4 w-4" aria-hidden="true" />
                    Vote
                </button>
            </article>
        {/each}
    </div>

    <!-- DESKTOP: table (same columns, no reflow) -->
    <div class="mx-auto max-w-350 table-scroll py-4 hidden md:block">
        <table class="w-full border-collapse text-left">
            <caption class="sr-only"
                >Ranking de dApps por rating de la comunidad</caption
            >
            <thead>
                <tr
                    class="border-b border-neon-cyan/25 text-xs uppercase tracking-wide text-neon-cyan/70"
                >
                    <th scope="col" class="px-3 py-3 font-semibold">Rank</th>
                    <th scope="col" class="px-3 py-3 font-semibold">Dapp</th>
                    <th scope="col" class="px-3 py-3 font-semibold">Rating</th>
                    <th scope="col" class="px-3 py-3 text-right font-semibold"
                        >Donated</th
                    >
                    <th scope="col" class="px-3 py-3 text-right font-semibold"
                        >Burned</th
                    >
                    <th scope="col" class="px-3 py-3 text-right font-semibold"
                        >Backing</th
                    >
                    <th scope="col" class="px-3 py-3 font-semibold">Status</th>
                    <th scope="col" class="px-3 py-3 font-semibold">Vote</th>
                </tr>
            </thead>
            <tbody>
                {#each data as item}
                    <tr
                        class="border-b border-neon-cyan/10 transition-colors duration-200 hover:bg-neon-cyan/5"
                    >
                        <td class="px-3 py-3 whitespace-nowrap">
                            <span
                                class="flex items-center gap-1.5 tabular-nums {item.rank <=
                                3
                                    ? 'font-semibold text-neon-pink'
                                    : 'text-ink/70'}"
                            >
                                {#if item.rank <= 3}
                                    <MorphIcon
                                        icon={Trophy}
                                        class="h-4 w-4"
                                        aria-hidden="true"
                                    />
                                {/if}
                                {item.rank}
                            </span>
                        </td>
                        <td class="px-3 py-3">
                            <div class="font-medium text-neon-cyan">
                                {item.name}
                            </div>
                            <div class="break-all text-xs opacity-60">
                                <a
                                    href={item.url}
                                    class="hover:opacity-100"
                                    aria-label={`Open ${item.name} on IPFS`}
                                    >{item.url}</a
                                >
                            </div>
                        </td>
                        <td class="px-3 py-3 whitespace-nowrap">
                            <div class="flex items-center gap-2">
                                <span
                                    class="tabular-nums font-semibold {TIER_TEXT_CLASS[
                                        item.tier
                                    ]}">{item.rating}</span
                                >
                                <span class={TIER_BADGE_CLASS[item.tier]}>
                                    <span
                                        class="h-1.5 w-1.5 rounded-full bg-current"
                                        aria-hidden="true"
                                    ></span>
                                    {TIER_LABEL[item.tier]}
                                </span>
                            </div>
                            <div
                                class="mt-1 h-1.5 overflow-hidden rounded-full bg-black/30"
                            >
                                <div
                                    class="h-full rounded-full"
                                    style="width: {item.rating}%; background: {TIER_GRADIENT[
                                        item.tier
                                    ]};"
                                ></div>
                            </div>
                        </td>
                        <td
                            class="px-3 py-3 text-right tabular-nums text-ink/90"
                            >{item.tokensDonated}</td
                        >
                        <td
                            class="px-3 py-3 text-right tabular-nums text-ink/90"
                            >{item.tokensBurned}</td
                        >
                        <td
                            class="px-3 py-3 text-right tabular-nums text-ink/90"
                            >{item.consensusPct}%</td
                        >
                        <td class="px-3 py-3 whitespace-nowrap">
                            <span class={TIER_BADGE_CLASS[item.statusTier]}>
                                <span
                                    class="h-1.5 w-1.5 rounded-full bg-current"
                                    aria-hidden="true"
                                ></span>
                                {item.status}
                            </span>
                        </td>
                        <td class="px-3 py-3 whitespace-nowrap">
                            <button
                                class="btn-neon px-3 py-1.5 text-xs"
                                onclick={() => openVoteModal(item.rawName)}
                            >
                                Vote
                            </button>
                        </td>
                    </tr>
                {/each}
            </tbody>
        </table>
    </div>
{:else}
    <div
        class="mx-auto my-12 max-w-md rounded-xl border border-neon-cyan/20 bg-void/60 p-8 text-center shadow-md"
    >
        <p class="mb-2 text-lg font-semibold text-neon-cyan">
            No dApps loaded yet
        </p>
        <p class="text-sm opacity-80">
            Connect your wallet and click “Refresh” to load the current ranking
            from the contract.
        </p>
    </div>
{/if}
