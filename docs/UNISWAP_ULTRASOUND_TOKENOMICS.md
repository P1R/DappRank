# DappRank DRNK Tokenomics Research

## Current Supply Summary (Sepolia Live, Sep 13 2026)

| Metric | Value |
|---|---|
| Total supply | 44,913 DRNK |
| DappsManager balance | 792 DRNK |
| ACC0 balance | 39,900 DRNK |
| Other balances | ~4,221 DRNK |
| topUpExpires | Aug 5, 2026 (expired) |
| burnFee | 10% (1000 bp) |
| DAOFee | 1% (100 bp) |
| listingFee | 1e13 wei |
| bonus | 1000e18 |

## Minting Sources

1. **buyDRNK()**: `multiplier * msg.value * 1000` DRNK
   - First buy: `msg.value * 1000`
   - Repeated buy: `multiplier * msg.value * 1000`
   - multiplier = 1 for all fans (voting increments it, but starts at 1)
   - Active only when `block.timestamp <= topUpExpires`
   - Currently expired

2. **registerDapp()**: `10 * bonus` = 10,000 DRNK per registration
   - Requires `msg.value >= listingFee`

3. **demoAirdrop()**: `bonus` = 1,000 DRNK per actor
   - Admin-only

## Burn Sources

1. **voteDapp()**: `burnFee / 10_000` of voted amount
   - With burnFee=1000: 10% of each vote is burned
   - Reported in test: 100e18 vote produces 10e18 burned

2. **burn()**: Any user can burn with allowance
   - Used in testBurnTestUsersTokens

## LP Hook Burn (Proposed)

The proposed LP hook will burn a percentage of each swap output.
Starting candidate: 2% (200 bp).

## Effective Price Comparison

### buyDRNK() reference (0.01 ETH)

```text
Output: 10 DRNK
Effective price: 0.001 ETH/DRNK
No burn on purchase
```

### LP Pool with 2% burn (0.01 ETH equivalent swap)

```text
Gross pool output at 5% discount: 10.5263 DRNK
After 2% hook burn: 10.3158 DRNK
Effective price: 0.001 * 0.95 = 0.00095 ETH/DRNK (before pool fee)
```

Note: Uniswap pool fee (typically 0.3% or 1%) reduces output further.

## Deflation Argument

For the system to be globally deflationary:

```text
Total burns per period > Total mints per period
```

Current burns occur only during voting (10% of vote amount).
Minting occurs during buyDRNK, registerDapp, and demoAirdrop.

The LP hook adds a new burn source that fires on every LP swap.
This increases deflationary pressure specifically from LP activity,
but does not make the system globally deflationary unless:
- LP volume generates more burns than all mint sources combined.

## Recommended Initial Parameters

| Parameter | Value | Justification |
|---|---|---|
| LP discount | 5% | Provides incentive vs buyDRNK() |
| LP burn | 2% (200 bp) | Moderate burn; voting already burns 10% |
| LP pool fee | 0.3% (3000) | Standard Uniswap fee |
| Max discount | 15% | Hard cap |
| Min discount | 0% | Floor |
| Max LP burn | 5% (500 bp) | Bounded increase |
| Min LP burn | 0.5% (50 bp) | Bounded decrease |

## Inflation-Responsive Strategy

### Conservative (Recommended for PoC)

- Fixed discount: 5%
- Fixed burn: 2%
- Manual parameter updates by account0 admin
- No oracle dependency

### Dynamic (Future, requires more testing)

```text
discount_next = clamp(base_discount + alpha * net_inflation, min_discount, max_discount)
burn_next     = clamp(base_burn + beta * net_inflation, min_burn, max_burn)
```

Where:
- `alpha` and `beta` are governance-tuned coefficients
- `net_inflation = (total_minting - total_burning) / epoch_start_supply`
- Hard caps on both parameters
- Minimum epoch duration
- No same-block manipulation

## Key Risk: buyDRNK() Window is Expired

The top-up window expired Aug 5, 2026. This means:
- New users cannot buy DRNK through the original minting path
- The LP pool becomes the only active route for acquiring DRNK
- This actually makes the LP more deflationary since buyDRNK minting stops
- However, the original buyDRNK() remains as a comparison baseline

For fork tests: use `vm.warp()` to set time before expiry.
