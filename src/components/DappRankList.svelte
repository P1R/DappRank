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

<div class="container">
  {#each data as item}
    <div class="ranking-card">
      <div class="card-header">
        <div class="rank">#{item.rank}</div>
        <div class="dapp-name">{item.name}</div>
      </div>
      <div class="dapp-url"><a href={item.url}>{item.url}</a></div>
      <div class="stats">
        <div class="stat-box">
          <div class="stat-value">{item.rating}</div>
          <div class="stat-label">RATING</div>
        </div>
        <div class="stat-box">
          <div class="stat-value">{item.tokensDonated}</div>
          <div class="stat-label">TOKENS DONATED</div>
        </div>
        <div class="stat-box">
          <div class="stat-value">{item.tokensBurned}</div>
          <div class="stat-label">BURNED</div>
        </div>
      </div>
      <div class="rating-bar">
        <div class="rating-fill" style="--rating-width: {item.rating}%"></div>
      </div>
      <div class="tags">
        <span class="tag">Owner: {item.owner.slice(0, 6)}...{item.owner.slice(-4)}</span>
        <span class="tag">Status: {item.status}</span>
      </div>
    </div>
  {/each}
</div>

<style>
  /* Main container */
  .container {
    max-width: 1200px;
    margin: 30px auto;
    padding: 20px;
  }

  /* Ranking card */
  .ranking-card {
    background: rgba(10, 10, 30, 0.7);
    border: 1px solid rgba(0, 255, 204, 0.3);
    border-radius: 10px;
    padding: 20px;
    margin-bottom: 20px;
    box-shadow: 0 0 15px rgba(0, 255, 204, 0.2);
    transition: all 0.3s ease;
    position: relative;
    overflow: hidden;
  }

  .ranking-card:hover {
    transform: translateY(-5px);
    box-shadow: 0 0 20px rgba(0, 255, 204, 0.4);
    border-color: rgba(255, 0, 255, 0.5);
  }

  .ranking-card::before {
    content: '';
    position: absolute;
    top: 0;
    left: 0;
    width: 100%;
    height: 3px;
    background: linear-gradient(90deg, #00ffcc, #ff00ff, #00ffcc);
    animation: gradient 3s linear infinite;
    background-size: 200% 200%;
  }

  .card-header {
    display: flex;
    justify-content: space-between;
    align-items: center;
    margin-bottom: 15px;
    padding-bottom: 10px;
    border-bottom: 1px solid rgba(0, 255, 204, 0.2);
  }

  .rank {
    font-size: 2rem;
    font-weight: bold;
    color: #ff00ff;
    text-shadow: 0 0 10px rgba(255, 0, 255, 0.7);
  }

  .dapp-name {
    font-size: 1.5rem;
    color: #00ffcc;
    text-shadow: 0 0 5px rgba(0, 255, 204, 0.7);
  }

  .dapp-url {
    color: #ff00ff;
    font-size: 0.9rem;
    margin-top: 5px;
    word-break: break-all;
  }

  .stats {
    display: flex;
    justify-content: space-between;
    margin: 20px 0;
  }

  .stat-box {
    background: rgba(0, 0, 0, 0.3);
    border: 1px solid rgba(0, 255, 204, 0.2);
    border-radius: 8px;
    padding: 15px;
    text-align: center;
    flex: 1;
    margin: 0 10px;
    transition: all 0.3s ease;
  }

  .stat-box:hover {
    background: rgba(0, 255, 204, 0.1);
    transform: scale(1.05);
  }

  .stat-value {
    font-size: 2rem;
    font-weight: bold;
    color: #00ffcc;
    text-shadow: 0 0 10px rgba(0, 255, 204, 0.7);
  }

  .stat-label {
    font-size: 0.9rem;
    opacity: 0.8;
  }

  .rating-bar {
    height: 10px;
    background: rgba(0, 0, 0, 0.3);
    border-radius: 5px;
    margin: 15px 0;
    overflow: hidden;
    position: relative;
  }

  .rating-fill {
    height: 100%;
    background: linear-gradient(90deg, #00ffcc, #ff00ff);
    border-radius: 5px;
    width: var(--rating-width);
    animation: fill 2s ease-in-out;
  }

  .rating-fill::after {
    content: '';
    position: absolute;
    top: 0;
    left: 0;
    right: 0;
    bottom: 0;
    background: linear-gradient(90deg, transparent, rgba(255, 255, 255, 0.2), transparent);
    animation: shine 3s infinite;
  }

  .tags {
    display: flex;
    flex-wrap: wrap;
    gap: 10px;
    margin-top: 15px;
  }

  .tag {
    background: rgba(0, 255, 204, 0.1);
    border: 1px solid rgba(0, 255, 204, 0.3);
    border-radius: 20px;
    padding: 5px 15px;
    font-size: 0.8rem;
    color: #00ffcc;
  }

  /* Responsive design */
  @media (max-width: 768px) {
    .stats {
      flex-direction: column;
    }

    .stat-box {
      margin: 5px 0;
    }

    .card-header {
      flex-direction: column;
      align-items: flex-start;
    }

    .dapp-name {
      margin-top: 10px;
    }
  }
</style>
