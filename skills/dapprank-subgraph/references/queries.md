# DappRank Subgraph — Example Queries

All queries hit the public endpoint:

```
https://api.studio.thegraph.com/query/1760241/dapprank/v0.0.2
```

## curl helper

```bash
Q() { curl -s -X POST "https://api.studio.thegraph.com/query/1760241/dapprank/v0.0.2" \
  -H "Content-Type: application/json" -d "{\"query\":\"$1\"}"; }
```

## Rankings

```bash
# Full ranking by rating (desc)
Q '{ dapps(orderBy: rate, orderDirection: desc) { name status rate balance burned } }'

# Top 3 by burned (deflation leaders)
Q '{ dapps(orderBy: burned, orderDirection: desc, first: 3) { name burned } }'

# Only active dapps
Q '{ dapps(where: { status: "Active" }) { name rate } }'
```

## Global stats

```bash
Q '{ globalStat(id: "global") { totalDapps totalVotes totalBurned totalBalance } }'
```

## Votes

```bash
# All votes for a dapp, newest first
Q '{ dapps(where: { name: "desci.org" }) { name rate votes(orderBy: timestamp, orderDirection: desc) { voter voteRate fanWeight timestamp } } }'

# Count votes per dapp
Q '{ dapps { name votes { id } } }'
```

## Reasoning examples

### "Which dapp has the highest rating?"
```graphql
{ dapps(orderBy: rate, orderDirection: desc, first: 1) { name rate } }
```

### "How much DRNK has been burned in total?"
```graphql
{ globalStat(id: "global") { totalBurned } }
```

### "Is there whale manipulation on dapp X?"
Compare the `fanWeight` distribution. SRWV means a whale staking 100x more
tokens only gets 10x voting weight. A vote with `fanWeight` far above the
median is a whale signal:

```graphql
{ dapps(where: { name: "desci.org" }) { votes { voter fanWeight } } }
```

### "What is the deflationary pressure of DRNK?"
```graphql
{ globalStat(id: "global") { totalBurned totalBalance } }
```
`totalBurned / (totalBurned + totalBalance)` approximates the burned fraction
of circulating DRNK held in the system.

### "Which dapps are growing in activity?"
Compare `updatedAt` and `burned` deltas between two queries, or join votes with
burned amounts over time:

```graphql
{ dapps(orderBy: updatedAt, orderDirection: desc) { name rate burned updatedAt } }
```
