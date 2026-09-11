<script>
  import WalletConnector from './components/WalletConnector.svelte';
  import DappsData from './components/DappsData.svelte';
  import DappRankList from './components/DappRankList.svelte';
  import GetDRNK from './components/GetDRNK.svelte';
  import Vote4Dapp from './components/Vote4Dapp.svelte';
  import RegisterDapp from './components/RegisterDapp.svelte';
  import { MorphIcon } from 'morphicons/svelte';
  import { Menu, X } from 'lucide';

  let menuOpen = $state(false);

  function toggleMenu() {
    menuOpen = !menuOpen;
  }

  function closeMenu() {
    menuOpen = false;
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

<a href="#main-content" class="skip-link">Skip to main content</a>

<header class="sticky top-0 z-[100] border-b-2 border-neon-cyan bg-void/80 px-4 py-3 shadow-[0_0_20px_rgba(0,247,255,0.3)] sm:px-6 lg:px-10">
  <div class="mx-auto flex max-w-[1400px] items-center justify-between gap-3">
    <div class="flex items-center gap-3" aria-label="DappRank home">
      <svg class="h-8 w-8 shrink-0 text-neon-pink drop-shadow-[0_0_6px_#ff00cc]" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" aria-hidden="true">
        <path d="M12 2 2 7l10 5 10-5-10-5Z" />
        <path d="M2 17l10 5 10-5" />
        <path d="M2 12l10 5 10-5" />
      </svg>
      <span class="bg-gradient-to-r from-neon-cyan to-neon-pink bg-clip-text text-2xl font-extrabold text-transparent drop-shadow-[0_0_10px_rgba(0,247,255,0.5)]">
        DappRank
      </span>
    </div>

    <!-- Desktop controls -->
    <nav class="hidden flex-wrap items-center justify-end gap-2 md:flex" aria-label="Primary">
      <Vote4Dapp />
      <GetDRNK />
      <DappsData />
      <RegisterDapp />
      <WalletConnector />
    </nav>

    <!-- Mobile menu toggle -->
    <button
      class="btn-icon md:hidden"
      onclick={toggleMenu}
      aria-expanded={menuOpen}
      aria-controls="mobile-menu"
      aria-label={menuOpen ? 'Close menu' : 'Open menu'}
    >
      <MorphIcon icon={menuOpen ? X : Menu} spring="snappy" reducedMotion="user" />
    </button>
  </div>

  <!-- Mobile controls -->
  {#if menuOpen}
    <nav
      id="mobile-menu"
      class="mx-auto mt-3 flex max-w-[1400px] flex-col items-stretch gap-2 md:hidden"
      aria-label="Mobile"
    >
      <Vote4Dapp />
      <GetDRNK />
      <DappsData />
      <RegisterDapp />
      <WalletConnector />
    </nav>
  {/if}
</header>

<main id="main-content" class="relative text-center">
  <div class="bg-scene"></div>
  <div class="particles" id="particles"></div>
  <DappRankList />
</main>
