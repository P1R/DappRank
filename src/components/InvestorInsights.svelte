<script>
    import { onMount } from "svelte";
    import { querySubgraph } from "../lib/subgraph.svelte.js";
    import { formatUnits } from "ethers";
    import { MorphIcon } from "morphicons/svelte";
    import { Boxes, Vote, Flame, Wallet, Database, LoaderCircle } from "lucide";

    /** @typedef {object} GlobalStat
     * @property {number} totalDapps
     * @property {string} totalVotes
     * @property {string} totalBurned
     * @property {string} totalBalance
     */
    /** @typedef {object} TopBurnedDapp
     * @property {string} id
     * @property {string} name
     * @property {string} burned
     */

    /** @type {GlobalStat | null} */
    let stats = $state(null);
    /** @type {TopBurnedDapp[]} */
    let topBurned = $state([]);
    let isLoading = $state(true);
    let error = $state("");

    onMount(async () => {
        try {
            const data = await querySubgraph(`
                query Insights {
                    globalStat(id: "global") {
                        totalDapps
                        totalVotes
                        totalBurned
                        totalBalance
                    }
                    dapps(orderBy: burned, orderDirection: desc, first: 3) {
                        id
                        name
                        burned
                    }
                }
            `);
            stats = data?.globalStat ?? null;
            topBurned = data?.dapps ?? [];
        } catch (e) {
            error = /** @type {Error} */ (e).message;
        } finally {
            isLoading = false;
        }
    });

    /** @param {string | null | undefined} v @returns {string} */
    function fmt(v) {
        if (v == null) return "—";
        return Number(formatUnits(v, 18)).toLocaleString(undefined, {
            maximumFractionDigits: 2,
        });
    }
</script>

{#if isLoading}
    <div
        class="mx-auto mt-6 flex max-w-350 items-center justify-center gap-2 text-sm text-neon-cyan/70"
        role="status"
    >
        <MorphIcon
            icon={LoaderCircle}
            class="h-4 w-4 animate-spin"
            aria-hidden="true"
        />
        Loading on-chain insights…
    </div>
{:else if error}
    <div
        class="mx-auto mt-6 max-w-350 rounded-xl border border-neon-pink/30 bg-neon-pink/5 px-4 py-3 text-sm text-neon-pink/80"
        role="status"
    >
        Insights no disponibles: {error}
    </div>
{:else if stats}
    <section class="mx-auto mt-6 max-w-350" aria-label="Investor insights">
        <div class="grid grid-cols-2 gap-3 md:grid-cols-4">
            <div class="card p-3 text-left">
                <div class="flex items-center gap-1.5 text-xs opacity-60">
                    <MorphIcon
                        icon={Boxes}
                        class="h-3.5 w-3.5"
                        aria-hidden="true"
                    />
                    Dapps
                </div>
                <div class="mt-1 text-xl font-bold tabular-nums text-neon-cyan">
                    {stats.totalDapps}
                </div>
            </div>
            <div class="card p-3 text-left">
                <div class="flex items-center gap-1.5 text-xs opacity-60">
                    <MorphIcon
                        icon={Vote}
                        class="h-3.5 w-3.5"
                        aria-hidden="true"
                    />
                    Votes
                </div>
                <div class="mt-1 text-xl font-bold tabular-nums text-neon-cyan">
                    {fmt(stats.totalVotes)}
                </div>
            </div>
            <div class="card p-3 text-left">
                <div class="flex items-center gap-1.5 text-xs opacity-60">
                    <MorphIcon
                        icon={Flame}
                        class="h-3.5 w-3.5"
                        aria-hidden="true"
                    />
                    DRNK burned
                </div>
                <div class="mt-1 text-xl font-bold tabular-nums text-neon-pink">
                    {fmt(stats.totalBurned)}
                </div>
            </div>
            <div class="card p-3 text-left">
                <div class="flex items-center gap-1.5 text-xs opacity-60">
                    <MorphIcon
                        icon={Wallet}
                        class="h-3.5 w-3.5"
                        aria-hidden="true"
                    />
                    DRNK held
                </div>
                <div class="mt-1 text-xl font-bold tabular-nums text-neon-cyan">
                    {fmt(stats.totalBalance)}
                </div>
            </div>
        </div>

        {#if topBurned.length > 0}
            <div class="card mt-3 p-4 text-left">
                <h2 class="text-sm font-semibold text-neon-cyan">
                    Top deflationary dapps
                </h2>
                <ul class="mt-2 divide-y divide-neon-cyan/10">
                    {#each topBurned as d (d.id)}
                        <li
                            class="flex items-center justify-between py-1.5 text-sm"
                        >
                            <span class="opacity-80">{d.name}</span>
                            <span
                                class="tabular-nums font-semibold text-neon-pink"
                            >
                                {fmt(d.burned)} DRNK
                            </span>
                        </li>
                    {/each}
                </ul>
            </div>
        {/if}

        <p
            class="mt-3 flex items-center justify-center gap-1.5 text-xs opacity-50"
        >
            <MorphIcon icon={Database} class="h-3.5 w-3.5" aria-hidden="true" />
            Indexed live by The Graph
        </p>
    </section>
{/if}
