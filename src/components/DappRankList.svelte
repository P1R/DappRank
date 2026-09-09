<script>
  import { ethVars } from '../lib/ethers.svelte.js';
  import { toUtf8String, formatUnits } from 'ethers';

  // ToDo Must order them before
  //  const sortedDapps = [...DappsList].sort((a, b) => {
  //  const rateA = parseInt(a.rate) || 0;
  //  const rateB = parseInt(b.rate) || 0;
  //  return rateB - rateA; // Descending order
  //});

  //// Initialize data array
  let data = $derived(ethVars.dappsList.map((dapp, index) => ({
      rank: index + 1, // Assign rank based on sorted position
      name: dapp.name ? toUtf8String(dapp.name) : 'Unknown DApp',
      url: dapp.cid ? `https://ipfs.io/ipfs/${dapp.cid}` : '#',
      rating: parseInt(dapp.rate) || 0,
      tokensDonated: formatUnits(dapp.balance, 18) || 0,
      tokensBurned: formatUnits(dapp.burned, 18) || 0,
      owner: dapp.owner,
      status: dapp.status ? toUtf8String(dapp.status) : 'Unknown',
      tags: ['DApp', 'Web3'] // You can customize tags based on dapp properties
    })));
  //let data = $derived(ethVars.dappsList);
  $effect(() => {
      console.log("updated data", $state.snapshot(data));
  });
</script>

<div class="grid grid-cols-1 gap-6 p-4 sm:grid-cols-2 sm:p-6 xl:grid-cols-3 max-w-[1400px] mx-auto">
  {#each data as item}
    <div class="group relative overflow-hidden rounded-xl border border-neon-cyan/30 bg-void/70 p-5 shadow-[0_0_15px_rgba(0,247,255,0.2)] transition-all duration-300 hover:-translate-y-1 hover:border-neon-pink/50 hover:shadow-[0_0_20px_rgba(0,247,255,0.4)]">
      <div class="absolute inset-x-0 top-0 h-[3px] animate-[gradientSlide_3s_linear_infinite] bg-gradient-to-r from-[#00ffcc] via-[#ff00ff] to-[#00ffcc] bg-[length:200%_200%]"></div>

      <div class="flex flex-col gap-2 border-b border-neon-cyan/20 pb-2.5 mb-4 sm:flex-row sm:items-center sm:justify-between">
        <div class="text-2xl font-bold text-neon-pink drop-shadow-[0_0_8px_rgba(255,0,255,0.5)]">#{item.rank}</div>
        <div class="text-lg text-neon-cyan drop-shadow-[0_0_5px_rgba(0,247,255,0.5)] sm:text-right">{item.name}</div>
      </div>

      <div class="mt-1 break-all text-sm text-neon-pink">
        <a href={item.url}>{item.url}</a>
      </div>

      <div class="my-5 grid grid-cols-1 gap-3 sm:grid-cols-3">
        <div class="rounded-lg border border-neon-cyan/20 bg-black/30 p-3.5 text-center transition-all duration-300 hover:scale-105 hover:bg-neon-cyan/10">
          <div class="text-2xl font-bold text-neon-cyan drop-shadow-[0_0_8px_rgba(0,247,255,0.5)]">{item.rating}</div>
          <div class="text-sm opacity-80">RATING</div>
        </div>
        <div class="rounded-lg border border-neon-cyan/20 bg-black/30 p-3.5 text-center transition-all duration-300 hover:scale-105 hover:bg-neon-cyan/10">
          <div class="text-2xl font-bold text-neon-cyan drop-shadow-[0_0_8px_rgba(0,247,255,0.5)]">{item.tokensDonated}</div>
          <div class="text-sm opacity-80">TOKENS DONATED</div>
        </div>
        <div class="rounded-lg border border-neon-cyan/20 bg-black/30 p-3.5 text-center transition-all duration-300 hover:scale-105 hover:bg-neon-cyan/10">
          <div class="text-2xl font-bold text-neon-cyan drop-shadow-[0_0_8px_rgba(0,247,255,0.5)]">{item.tokensBurned}</div>
          <div class="text-sm opacity-80">BURNED</div>
        </div>
      </div>

      <div class="relative my-4 h-2.5 overflow-hidden rounded-full bg-black/30">
        <div
          class="relative h-full rounded-full bg-gradient-to-r from-[#00ffcc] to-[#ff00ff]"
          style="width: {item.rating}%"
        >
          <div class="absolute inset-0 animate-[shine_3s_infinite] bg-gradient-to-r from-transparent via-white/20 to-transparent"></div>
        </div>
      </div>

      <div class="mt-4 flex flex-wrap gap-2">
        <span class="neon-tag">Owner: {item.owner.slice(0, 6)}...{item.owner.slice(-4)}</span>
        <span class="neon-tag">Status: {item.status}</span>
      </div>
    </div>
  {/each}
</div>
