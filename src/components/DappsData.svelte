<script>
  import { toUtf8String } from 'ethers';
  import { ethVars } from '../lib/ethers.svelte.js';
  async function getDappNames() {
    if (ethVars.contract) {
        let dappsListNames = await ethVars.contract.getAllDappNames();
        //console.log("dappsNames:", dappNames);

        // Ill keep it for proof of concept later its just a hackathon :O
        //
        // Convert bytes32 to string using ethers.js
        //const dappNames = dappsListNames.map((name) => {
        //    return toUtf8String(name);
        //});
        //console.log("dappsNames str:", dappNames);
        //dappNames.forEach((name, index) => {
        //        console.log(`Dapp ${index}: ${name}`);
        //});
        //const dapp1 = await getDappInfoForName(dappsListNames[0]);
        //console.log("dapp1 info:", dapp1);

        ethVars.dappsList = await dappsListNames.reduce(async (accPromise, name) => {
          const acc = await accPromise;
          const info = await getDappInfoForName(name);
          if (info) {
            acc.push(info);
          }
           return acc;
          }, Promise.resolve([])
        );
        console.log("dappsAllData:", $state.snapshot(ethVars.dappsList));
    }
  }

  async function getDappInfoForName(dappName) {
    try {
      const info = await ethVars.contract.getDappInfo(dappName);
      return {
        name: dappName,
        cid: info.cid,
        rate: info.rate.toString(), // Convert to string for better handling
        weight_votes_sum: info.weight_votes_sum.toString(),
        weight_total_sum: info.weight_total_sum.toString(),
        balance: info.balance.toString(),
        burned: info.burned.toString(),
        owner: info.owner,
        status: info.status
      };
    } catch (error) {
      console.error(`Error getting info for dapp ${dappName}:`, error);
      return null;
    }
  }
</script>

<div>
    <button class="btn" onclick={getDappNames}>Refresh</button>
</div>

<style>
  .btn {
      padding: 10px 20px;
      background: rgba(10, 10, 26, 0.7);
      border: 1px solid #00f7ff;
      color: #00f7ff;
      border-radius: 4px;
      cursor: pointer;
      font-weight: 600;
      transition: all 0.3s ease;
      box-shadow: 0 0 10px rgba(0, 247, 255, 0.3);
  }

  .btn:hover {
      background: rgba(0, 247, 255, 0.2);
      box-shadow: 0 0 15px rgba(0, 247, 255, 0.5);
      transform: translateY(-2px);
  }
</style>
