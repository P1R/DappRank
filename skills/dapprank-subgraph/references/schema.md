# DappRank Subgraph — GraphQL Schema

The full schema as defined in `subgraph/schema.graphql`.

```graphql
type Dapp @entity {
  # id = raw bytes32 name (hex), e.g. 0x64657363692e6f726700...
  id: Bytes!
  name: String!
  cid: String
  owner: Bytes!
  status: String! # Submitted | Active | Expired | Banned
  rate: BigInt! # Dr = weighted average rating (0-100)
  weightVotesSum: BigInt! # sum(Vi x sqrt(Ti))
  weightTotalSum: BigInt! # sum(sqrt(Ti))
  balance: BigInt! # DRNK held for this dapp (net of burn + DAO fee)
  burned: BigInt! # DRNK burned for this dapp
  votes: [Vote!]! @derivedFrom(field: "dapp")
  createdAt: BigInt!
  updatedAt: BigInt!
}

type Vote @entity {
  id: ID! # tx hash + log index
  dapp: Dapp!
  voter: Bytes!
  voteRate: BigInt! # Vi (1-100)
  fanWeight: BigInt! # Wi = sqrt(Ti)
  timestamp: BigInt!
  blockNumber: BigInt!
}

type GlobalStat @entity {
  id: ID! # "global"
  totalDapps: Int!
  totalVotes: BigInt!
  totalBurned: BigInt!
  totalBalance: BigInt!
}
```

## Field semantics

| Entity | Field | Meaning |
|--------|-------|---------|
| Dapp | `rate` | $D_r = \sum(V_i \times \sqrt{T_i}) / \sum\sqrt{T_i}$ — the SRWV rating |
| Dapp | `balance` | Net DRNK held: votes received − burn (10%) − DAO fee (1%) − cashouts |
| Dapp | `burned` | Cumulative DRNK burned for this dapp (deflationary pressure) |
| Vote | `fanWeight` | $W_i = \sqrt{T_i}$ with `Math.sqrt(amount, Rounding.Ceil)` |
| GlobalStat | `totalBurned` | Sum of all `TokensBurned` events — the "ultrasound money" metric |

## Notes

- `id` of `Dapp` is the **raw bytes32 name** (hex) — identical to what the
  contract's `getAllDappNames()` returns, so frontend `voteDapp()` calls keep
  working whether data comes from the subgraph or the contract.
- `BigInt` values are returned as strings by the GraphQL API.
- `status` is a string (`Submitted`/`Active`/`Expired`/`Banned`), mapped from
  the contract's `Status` enum.
