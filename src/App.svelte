<script>
  import WalletConnector from './components/WalletConnector.svelte';
  import IPFSConnector from './components/IPFSConnector.svelte';
  import DappsData from './components/DappsData.svelte';
  import DappRankList from './components/DappRankList.svelte';
  import GetDRNK from './components/GetDRNK.svelte';
  import Vote4Dapp from './components/Vote4Dapp.svelte';

  let menuOpen = $state(false);

  function toggleMenu() {
    menuOpen = !menuOpen;
  }

  $effect(() => {
    const particlesContainer = document.getElementById('particles');
    if (!particlesContainer) return;

    particlesContainer.innerHTML = '';
    const particleCount = 50;

    for (let i = 0; i < particleCount; i++) {
      const particle = document.createElement('div');
      particle.classList.add('particle');

      const size = Math.random() * 10 + 2;
      particle.style.width = `${size}px`;
      particle.style.height = `${size}px`;

      particle.style.left = `${Math.random() * 100}%`;
      particle.style.top = `${Math.random() * 100}%`;

      const duration = Math.random() * 20 + 10;
      particle.style.animationDuration = `${duration}s`;

      const delay = Math.random() * 5;
      particle.style.animationDelay = `${delay}s`;

      particlesContainer.appendChild(particle);
    }
  });
</script>

<header class="sticky top-0 z-[100] border-b-2 border-neon-cyan bg-void/80 px-4 py-4 shadow-[0_0_20px_rgba(0,247,255,0.3)] backdrop-blur-sm sm:px-6 lg:px-10">
  <div class="mx-auto flex max-w-[1400px] items-center justify-between">
    <div class="flex items-center gap-3">
      <svg class="h-8 w-8 shrink-0 text-neon-pink drop-shadow-[0_0_6px_#ff00cc]" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" aria-hidden="true">
        <path d="M12 2 2 7l10 5 10-5-10-5Z" />
        <path d="M2 17l10 5 10-5" />
        <path d="M2 12l10 5 10-5" />
      </svg>
      <div class="bg-gradient-to-r from-neon-cyan to-neon-pink bg-clip-text text-2xl font-extrabold text-transparent drop-shadow-[0_0_10px_rgba(0,247,255,0.5)]">
        DappRank
      </div>
    </div>

    <!-- Desktop controls -->
    <div class="hidden flex-wrap items-center justify-end gap-3 md:flex">
      <Vote4Dapp />
      <GetDRNK />
      <DappsData />
      <button class="btn-neon-pink">Add Dapp</button>
      <WalletConnector />
    </div>

    <!-- Mobile menu toggle -->
    <button
      class="flex h-10 w-10 shrink-0 items-center justify-center rounded-md border border-neon-cyan text-neon-cyan md:hidden"
      onclick={toggleMenu}
      aria-expanded={menuOpen}
      aria-label="Toggle menu"
    >
      <svg class="h-5 w-5" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" aria-hidden="true">
        {#if menuOpen}
          <path d="M18 6 6 18" />
          <path d="M6 6l12 12" />
        {:else}
          <path d="M4 6h16" />
          <path d="M4 12h16" />
          <path d="M4 18h16" />
        {/if}
      </svg>
    </button>
  </div>

  <!-- Mobile controls -->
  {#if menuOpen}
    <div class="mx-auto mt-4 flex max-w-[1400px] flex-col items-stretch gap-3 md:hidden">
      <Vote4Dapp />
      <GetDRNK />
      <DappsData />
      <button class="btn-neon-pink w-full">Add Dapp</button>
      <WalletConnector />
    </div>
  {/if}
</header>

<main class="relative text-center">
  <div class="bg-scene"></div>
  <div class="particles" id="particles"></div>
  <DappRankList />
  <hr class="mx-auto my-8 max-w-[1400px] border-neon-cyan/20" />
  <IPFSConnector />
</main>
