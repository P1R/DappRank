<script>
  import { ethVars } from '../lib/ethers.svelte.js';
  import { toUtf8String, formatUnits } from 'ethers';
  import { MorphIcon } from 'morphicons/svelte';
  import { Trophy, Gauge, Flame, TrendingUp, Coins, Star, CircleCheck } from 'lucide';

  const STATUS_TIER = {
    Active: 'high',
    Submitted: 'neutral',
    Expired: 'mid',
    Banned: 'low'
  };

  const TIER_LABEL = { high: 'Trusted', mid: 'Mixed', low: 'Risky', neutral: 'Neutral' };
  const TIER_TEXT_CLASS = {
    high: 'text-trust-high',
    mid: 'text-trust-mid',
    low: 'text-trust-low',
    neutral: 'text-trust-neutral'
  };
  const TIER_BADGE_CLASS = {
    high: 'tier-badge-high',
    mid: 'tier-badge-mid',
    low: 'tier-badge-low',
    neutral: 'tier-badge-neutral'
  };
  const TIER_GRADIENT = {
    high: 'linear-gradient(90deg, var(--color-trust-high), var(--color-neon-cyan))',
    mid: 'linear-gradient(90deg, var(--color-trust-mid), var(--color-neon-pink))',
    low: 'linear-gradient(90deg, var(--color-trust-low), var(--color-neon-pink))',
    neutral: 'linear-gradient(90deg, var(--color-trust-neutral), var(--color-neon-pink))'
  };

  function ratingTier(rating) {
    if (rating >= 80) return 'high';
    if (rating >= 50) return 'mid';
    return 'low';
  }

  function stripNulls(str) {
    return str ? str.replace(/\0/g, '') : str;
  }

  let rawData = $derived(ethVars.dappsList.map((dapp) => {
    const rating = parseInt(dapp.rate) || 0;
    const status = dapp.status ? stripNulls(toUtf8String(dapp.status)) : 'Unknown';
    return {
      name: dapp.name ? stripNulls(toUtf8String(dapp.name)) : 'Unknown DApp',
      url: dapp.cid ? `https://ipfs.io/ipfs/${dapp.cid}` : '#',
      rating,
      tier: ratingTier(rating),
      tokensDonated: Number(formatUnits(dapp.balance ?? 0, 18)) || 0,
      tokensBurned: Number(formatUnits(dapp.burned ?? 0, 18)) || 0,
      owner: dapp.owner,
      status,
      statusTier: STATUS_TIER[status] || 'neutral',
      weightTotalSum: Number(dapp.weight_total_sum) || 0
    };
  }));

  let maxWeightTotal = $derived(Math.max(1, ...rawData.map((d) => d.weightTotalSum)));

  let data = $derived(
    [...rawData]
      .sort((a, b) => b.rating - a.rating)
      .map((item, index) => ({
        ...item,
        rank: index + 1,
        consensusPct: Math.round((item.weightTotalSum / maxWeightTotal) * 100)
      }))
  );

  let totalBurned = $derived(rawData.reduce((sum, d) => sum + d.tokensBurned, 0));
</script>

{#if ethVars.isLoading}
  <div
    class="mx-auto my-12 max-w-md rounded-xl border border-neon-cyan/20 bg-void/60 p-8 text-center shadow-[0_0_15px_rgba(0,247,255,0.15)]"
    role="status"
    aria-live="polite"
  >
    <div class="mx-auto mb-4 h-10 w-10 animate-spin rounded-full border-4 border-neon-cyan/30 border-t-neon-cyan"></div>
    <p class="text-lg font-semibold text-neon-cyan">Loading ranking…</p>
    <p class="mt-1 text-sm opacity-80">Fetching the latest data from the contract.</p>
  </div>
{:else if data.length > 0}
  <div class="mx-auto max-w-[1400px] px-4 pt-6 sm:px-6">
    <div class="mx-auto flex w-fit items-center gap-2 rounded-full border border-neon-pink/40 bg-neon-pink/10 px-5 py-2 text-sm font-semibold text-neon-pink shadow-[0_0_15px_rgba(255,0,204,0.25)]">
      <span aria-hidden="true">🔥</span>
      <span>Total DRNK Burned:</span>
      <span class="text-base font-bold tabular-nums">{totalBurned.toLocaleString(undefined, { maximumFractionDigits: 2 })}</span>
    </div>
  </div>

  <div class="grid grid-cols-1 gap-6 p-4 sm:grid-cols-2 sm:p-6 xl:grid-cols-3 max-w-[1400px] mx-auto">
    {#each data as item}
    <article class="group relative overflow-hidden rounded-xl border border-neon-cyan/30 bg-void/70 p-5 shadow-[0_0_15px_rgba(0,247,255,0.2)] transition-all duration-300 hover:-translate-y-1 hover:border-neon-pink/50 hover:shadow-[0_0_20px_rgba(0,247,255,0.4)]">
      <div class="absolute inset-x-0 top-0 h-[3px] animate-[gradientSlide_3s_linear_infinite] bg-gradient-to-r from-[#00ffcc] via-[#ff00ff] to-[#00ffcc] bg-[length:200%_200%]"></div>

      <div class="flex flex-col gap-2 border-b border-neon-cyan/20 pb-2.5 mb-4 sm:flex-row sm:items-center sm:justify-between">
        <div class="flex items-center gap-2 text-2xl font-bold text-neon-pink drop-shadow-[0_0_8px_rgba(255,0,255,0.5)]">
          <MorphIcon icon={item.rank <= 3 ? Trophy : CircleCheck} spring="snappy" reducedMotion="user" aria-hidden="true" />
          #{item.rank}
        </div>
        <h2 class="text-lg text-neon-cyan drop-shadow-[0_0_5px_rgba(0,247,255,0.5)] sm:text-right">{item.name}</h2>
      </div>

      <div class="mt-1 break-all text-sm text-neon-pink">
        <a href={item.url} class="underline decoration-dotted hover:decoration-solid" aria-label={`Open ${item.name} on IPFS`}>{item.url}</a>
      </div>

      <div class="my-5 grid grid-cols-1 gap-3 sm:grid-cols-3">
        <div class="rounded-lg border border-neon-cyan/20 bg-black/30 p-3.5 text-center transition-all duration-300 hover:scale-105 hover:bg-neon-cyan/10">
          <div class="text-3xl font-bold {TIER_TEXT_CLASS[item.tier]} drop-shadow-[0_0_10px_currentColor]">{item.rating}</div>
          <div class="mt-1 flex items-center justify-center gap-1 text-sm opacity-80">
            <MorphIcon icon={Gauge} class="h-4 w-4" aria-hidden="true" />
            RATING
          </div>
          <div class="mt-2 flex justify-center">
            <span class={TIER_BADGE_CLASS[item.tier]}>
              <span class="h-1.5 w-1.5 rounded-full bg-current" aria-hidden="true"></span>
              {TIER_LABEL[item.tier]}
            </span>
          </div>
        </div>
        <div class="rounded-lg border border-neon-cyan/20 bg-black/30 p-3.5 text-center transition-all duration-300 hover:scale-105 hover:bg-neon-cyan/10">
          <div class="text-2xl font-bold text-neon-cyan drop-shadow-[0_0_8px_rgba(0,247,255,0.5)]">{item.tokensDonated}</div>
          <div class="mt-1 flex items-center justify-center gap-1 text-sm opacity-80">
            <MorphIcon icon={Coins} class="h-4 w-4" aria-hidden="true" />
            DONATED
          </div>
        </div>
        <div class="rounded-lg border border-neon-cyan/20 bg-black/30 p-3.5 text-center transition-all duration-300 hover:scale-105 hover:bg-neon-cyan/10">
          <div class="text-2xl font-bold text-neon-cyan drop-shadow-[0_0_8px_rgba(0,247,255,0.5)]">{item.tokensBurned}</div>
          <div class="mt-1 flex items-center justify-center gap-1 text-sm opacity-80">
            <MorphIcon icon={Flame} class="h-4 w-4" aria-hidden="true" />
            BURNED
          </div>
        </div>
      </div>

      <div class="relative my-4 h-2.5 overflow-hidden rounded-full bg-black/30">
        <div
          class="relative h-full rounded-full"
          style="width: {item.rating}%; background: {TIER_GRADIENT[item.tier]};"
        >
          <div class="absolute inset-0 animate-[shine_3s_infinite] bg-gradient-to-r from-transparent via-white/20 to-transparent"></div>
        </div>
      </div>

      <div class="mb-1 flex items-center justify-between text-xs opacity-80">
        <span class="flex items-center gap-1">
          <MorphIcon icon={TrendingUp} class="h-3.5 w-3.5" aria-hidden="true" />
          Community backing
        </span>
        <span class="font-semibold text-neon-cyan">{item.consensusPct}%</span>
      </div>
      <div class="relative mb-4 h-1.5 overflow-hidden rounded-full bg-black/30">
        <div
          class="h-full rounded-full bg-gradient-to-r from-[#00ffcc] to-[#ff00ff]"
          style="width: {item.consensusPct}%"
        ></div>
      </div>

      <div class="mt-4 flex flex-wrap items-center gap-2">
        <span class="neon-tag">Owner: {item.owner.slice(0, 6)}...{item.owner.slice(-4)}</span>
        <span class={TIER_BADGE_CLASS[item.statusTier]}>
          <span class="h-1.5 w-1.5 rounded-full bg-current" aria-hidden="true"></span>
          {item.status}
        </span>
      </div>
    </article>
    {/each}
  </div>
{:else}
  <div class="mx-auto my-12 max-w-md rounded-xl border border-neon-cyan/20 bg-void/60 p-8 text-center shadow-[0_0_15px_rgba(0,247,255,0.15)]">
    <p class="mb-2 text-lg font-semibold text-neon-cyan">No dApps loaded yet</p>
    <p class="text-sm opacity-80">Connect your wallet and click “Refresh” to load the current ranking from the contract.</p>
  </div>
{/if}
