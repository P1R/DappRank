import { encodeBytes32String } from "ethers";

// The Graph endpoint for the DappRank subgraph (Subgraph Studio).
// Set VITE_SUBGRAPH_URL in .env once the subgraph is deployed.
// Format: https://api.studio.thegraph.com/query/<SLUG>/<VERSION>
const SUBGRAPH_URL =
  import.meta.env.VITE_SUBGRAPH_URL ||
  "https://api.studio.thegraph.com/query/0/dapprank/0.0.1";

/**
 * Generic GraphQL query against the DappRank subgraph.
 * @param {string} query
 * @param {Record<string, unknown>} [variables]
 * @returns {Promise<any>}
 */
export async function querySubgraph(query, variables = {}) {
  const res = await fetch(SUBGRAPH_URL, {
    method: "POST",
    headers: { "Content-Type": "application/json" },
    body: JSON.stringify({ query, variables }),
  });
  if (!res.ok) {
    throw new Error(`Subgraph request failed (HTTP ${res.status})`);
  }
  const json = await res.json();
  if (json.errors && json.errors.length > 0) {
    throw new Error(`Subgraph query error: ${json.errors[0].message}`);
  }
  return json.data;
}

const DAPPS_QUERY = `
  query Dapps {
    dapps(orderBy: rate, orderDirection: desc) {
      id
      name
      cid
      owner
      status
      rate
      weightVotesSum
      weightTotalSum
      balance
      burned
      createdAt
      updatedAt
    }
    globalStat(id: "global") {
      totalDapps
      totalVotes
      totalBurned
      totalBalance
    }
  }
`;

/** @typedef {object} SubgraphDapp
 * @property {string} id
 * @property {string} name
 * @property {string | null} cid
 * @property {string} owner
 * @property {string} status
 * @property {string} rate
 * @property {string} weightVotesSum
 * @property {string} weightTotalSum
 * @property {string} balance
 * @property {string} burned
 * @property {string} createdAt
 * @property {string} updatedAt
 */

/**
 * Fetch dapps + global stats from the subgraph, mapped to the same DappInfo
 * shape the contract returns (name/status as raw bytes32) so components work
 * unchanged regardless of the data source.
 * @returns {Promise<{ dapps: import("./ethers.svelte.js").DappInfo[], globalStat: object | null }>}
 */
export async function fetchDappsFromSubgraph() {
  const data = await querySubgraph(DAPPS_QUERY);
  /** @type {SubgraphDapp[]} */
  const rawDapps = data?.dapps ?? [];
  const dapps = rawDapps.map((d) => ({
    // The subgraph id IS the raw bytes32 name (hex) — identical to what the
    // contract returns, so voteDapp() calls keep working.
    name: d.id,
    nameStr: d.name,
    cid: d.cid ?? "",
    rate: d.rate,
    weight_votes_sum: d.weightVotesSum,
    weight_total_sum: d.weightTotalSum,
    balance: d.balance,
    burned: d.burned,
    owner: d.owner,
    // Status as bytes32 so toUtf8String() consumers keep working.
    status: encodeBytes32String(d.status),
  }));
  return { dapps, globalStat: data?.globalStat ?? null };
}

/**
 * Fetch the global stats entity (total dapps, votes, burned, balance).
 * @returns {Promise<object | null>}
 */
export async function fetchGlobalStat() {
  const data = await querySubgraph(`
    query GlobalStat {
      globalStat(id: "global") {
        totalDapps
        totalVotes
        totalBurned
        totalBalance
      }
    }
  `);
  return data?.globalStat ?? null;
}
