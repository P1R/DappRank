<script>
  import WalletConnector from './components/WalletConnector.svelte';
  import IPFSConnector from './components/IPFSConnector.svelte';
  import DappsData from './components/DappsData.svelte';
  import DappRankList from './components/DappRankList.svelte';

  document.addEventListener('DOMContentLoaded', function() {
      const particlesContainer = document.getElementById('particles');
      const particleCount = 50;

      for (let i = 0; i < particleCount; i++) {
          const particle = document.createElement('div');
          particle.classList.add('particle');

          // Random size
          const size = Math.random() * 10 + 2;
          particle.style.width = `${size}px`;
          particle.style.height = `${size}px`;

          // Random position
          particle.style.left = `${Math.random() * 100}%`;
          particle.style.top = `${Math.random() * 100}%`;

          // Random animation duration
          const duration = Math.random() * 20 + 10;
          particle.style.animationDuration = `${duration}s`;

          // Random delay
          const delay = Math.random() * 5;
          particle.style.animationDelay = `${delay}s`;

          particlesContainer.appendChild(particle);
      }
  });
</script>

<header>
    <div class="header-content">
        <div class="logo">
            <div class="logo-icon">
                <i class="fas fa-cube"></i>
            </div>
            <div class="logo-text">DappRank</div>
        </div>
        <div class="controls">
            <DappsData />
            <button class="btn btn-add">Add Dapp</button>
            <WalletConnector />
        </div>
    </div>
</header>

<main>
  <div class="background"></div>
  <div class="particles" id="particles"></div>
  <DappRankList />
  <hr />
  <IPFSConnector />
</main>

<style>
  main {
    font-family: sans-serif;
    text-align: center;
  }
</style>
