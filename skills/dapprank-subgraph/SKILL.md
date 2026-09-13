---
name: dapprank-subgraph
description: This skill should be used when the user asks about DappRank dapp rankings, ratings, votes, DRNK token burns, deflationary pressure, whale manipulation, or wants to query the DappRank subgraph on The Graph protocol. It provides the live endpoint, GraphQL schema, query patterns, and reasoning guidance for the DappRank Square Root Weighted Voting (SRWV) ranking system.
version: 1.0.0
---

# DappRank Subgraph Skill

Expert knowledge for querying and reasoning over the DappRank subgraph — a
decentralized dapp ranking system indexed by The Graph. This skill lets an AI
agent answer natural-language questions about live on-chain ranking data.

## Overview

DappRank is a DeFi ranking system where fans vote on dapps using DRNK tokens.
Voting power uses **Square Root Weighted Voting (SRWV)**: $W_i = \sqrt{T_i}$,
so whale influence grows sublinearly with tokens staked. The final rating is
$D_r = \frac{\sum (V_i \times \sqrt{T_i})}{\sum \sqrt{T_i}}$.

The subgraph indexes the `DappsManager` contract events on **Sepolia testnet**
and exposes three entities: `Dapp`, `Vote`, and `GlobalStat`.

> **ENSv2 names (ETHOnline 2026):** every dapp also has a human-readable
> identity on ENSv2 (Sepolia): `<name>.dapprank.eth`. The frontend resolves
> these via `UniversalResolverV2` (`src/lib/ens.svelte.js`) and reads the
> `dapprank.cid` text record. When answering questions, prefer referring to
> dapps by their ENS name (e.g. `desci.dapprank.eth`).

## Live Endpoint

```
https://api.studio.thegraph.com/query/1760241/dapprank/v0.0.2
```

The endpoint is **public** — no API key needed for queries. It serves live data
indexed from the deployed contract (`0x6b0EB389DD4B3ad4E9a28f56f971735aD2A85baD`).

### Quick test

```bash
curl -s -X POST "https://api.studio.thegraph.com/query/1760241/dapprank/v0.0.2" \
  -H "Content-Type: application/json" \
  -d '{"query":"{ dapps { id name status rate } }"}'
```

## Schema

### Dapp

| Field                     | Type   | Description                                      |
| ------------------------- | ------ | ------------------------------------------------ |
| `id`                      | Bytes  | Raw bytes32 name (hex) — also the entity id      |
| `name`                    | String | Human-readable dapp name                         |
| `cid`                     | String | IPFS CID of the dapp metadata                    |
| `owner`                   | Bytes  | Owner address                                    |
| `status`                  | String | `Submitted` \| `Active` \| `Expired` \| `Banned` |
| `rate`                    | BigInt | Weighted rating (0–100)                          |
| `weightVotesSum`          | BigInt | $\sum (V_i \times \sqrt{T_i})$                   |
| `weightTotalSum`          | BigInt | $\sum \sqrt{T_i}$                                |
| `balance`                 | BigInt | DRNK held for the dapp (net of burn + DAO fee)   |
| `burned`                  | BigInt | DRNK burned for the dapp                         |
| `createdAt` / `updatedAt` | BigInt | Block timestamps                                 |

### Vote

| Field                       | Type   | Description            |
| --------------------------- | ------ | ---------------------- |
| `id`                        | ID     | tx hash + log index    |
| `dapp`                      | Dapp   | The voted dapp         |
| `voter`                     | Bytes  | Voter address          |
| `voteRate`                  | BigInt | $V_i$ (1–100)          |
| `fanWeight`                 | BigInt | $W_i = \sqrt{T_i}$     |
| `timestamp` / `blockNumber` | BigInt | When the vote happened |

### GlobalStat

| Field          | Type   | Description              |
| -------------- | ------ | ------------------------ |
| `totalDapps`   | Int    | Number of dapps          |
| `totalVotes`   | BigInt | Total votes cast         |
| `totalBurned`  | BigInt | Total DRNK burned        |
| `totalBalance` | BigInt | Total DRNK held by dapps |

## Query Patterns

### Top dapps by rating

```graphql
{
  dapps(orderBy: rate, orderDirection: desc) {
    id
    name
    status
    rate
    balance
    burned
  }
}
```

### Active dapps with votes

```graphql
{
  dapps(where: { status: "Active" }) {
    name
    rate
    weightTotalSum
    votes {
      voter
      voteRate
      fanWeight
    }
  }
}
```

### Deflationary pressure (total burned)

```graphql
{
  globalStat(id: "global") {
    totalDapps
    totalVotes
    totalBurned
    totalBalance
  }
}
```

### Vote history for a dapp

```graphql
{
  dapps(where: { name: "desci.org" }) {
    name
    rate
    votes(orderBy: timestamp, orderDirection: desc) {
      voter
      voteRate
      fanWeight
      timestamp
    }
  }
}
```

> Nota: el campo `name` del subgraph es el bytes32 del contrato convertido a
> string (ej. `desci.org`). El nombre ENSv2 (`desci.dapprank.eth`) es una capa
> de resolución aparte — no reemplaza el `name` del subgraph.

## Reasoning Patterns (meaningful work)

The skill is not just about printing query results — it enables analysis:

| Question                             | Approach                                                                                                          |
| ------------------------------------ | ----------------------------------------------------------------------------------------------------------------- |
| "Which dapp has the highest rating?" | Query `dapps(orderBy: rate, desc)` → take first                                                                   |
| "What is the ENS name of dapp X?"    | `<label>.dapprank.eth`; resolve records via `UniversalResolverV2` (see `src/lib/ens.svelte.js`)                   |
| "Is a dapp being whale-manipulated?" | Compare `fanWeight` distribution across votes; SRWV dampens whales, so a single huge `fanWeight` vote is a signal |
| "What is the deflationary pressure?" | `globalStat.totalBurned` / `totalSupply` ratio                                                                    |
| "Which dapps are growing?"           | Join `VoteCast` + `TokensBurned` over time (rate + burned deltas)                                                 |
| "How did dapp X's rating evolve?"    | Query `votes` ordered by timestamp, recompute rating at each step                                                 |

## Testing & Verification

### Verify the subgraph is live

```bash
# Should return data (not empty)
curl -s -X POST "https://api.studio.thegraph.com/query/1760241/dapprank/v0.0.2" \
  -H "Content-Type: application/json" \
  -d '{"query":"{ globalStat(id: \"global\") { totalDapps totalVotes totalBurned } }"}'
```

### Contract tests (source of truth for event logic)

The subgraph mapping mirrors the contract's accounting. The contract test suite
validates the events the subgraph consumes:

```bash
forge test   # test/DappsManager.t.sol — includes testEventsEmitted
```

### Subgraph build

```bash
cd subgraph
bun run codegen   # generate types from schema + ABIs
bun run build     # compile the mapping
```

## References

- [`references/schema.md`](./references/schema.md) — full GraphQL schema
- [`references/queries.md`](./references/queries.md) — more query examples
- [`references/architecture.md`](./references/architecture.md) — how the data flows (contract → subgraph → agent)
