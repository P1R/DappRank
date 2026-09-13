# DappRank Uniswap v4 Ultrasound Hook Plan

Status: planning document. No production deployment is authorized until every
required local-fork and Anvil gate is complete.

## Non-Negotiable Constraints

- [ ] Do not modify any existing file under `src-sc/`.
- [ ] Add new contracts, interfaces, tests, and scripts only.
- [ ] Ignore frontend, Svelte, ethers.js, and The Graph work.
- [ ] Use Uniswap v4 specifically.
- [ ] Test against a Sepolia fork in Anvil before deploying anything to Sepolia.
- [ ] Deploy to Sepolia only as the final phase.
- [ ] Use account0 as the proof-of-concept administrator and liquidity provider.
- [ ] Never print or commit private keys from `.env`.
- [ ] Do not implement mempool exploitation or malicious frontrunning.

The external pool is an alternative route to DRNK. It may be cheaper than
`buyDRNK()`, but it cannot observe or safely frontrun a future transaction in
Solidity. The hook must not depend on pending transactions.

## Confirmed Initial Liquidity Target

The current `buyDRNK()` formula is:

```text
DRNK minted = msg.value * 1000
```

Therefore:

```text
0.01 ETH -> 10 DRNK
```

The primary reference price is:

```text
0.001 ETH per DRNK
```

The initial LP target is a 5% gross discount:

```text
LP target price = 0.001 * 0.95 = 0.00095 ETH/DRNK
```

The selected initial reserves are:

```text
ETH reserve:  0.3 ETH
DRNK reserve: 315.789473684 DRNK approximately
```

The `0.01 ETH` purchase contributes 10 DRNK. Account0 must provide the
remaining approximately `305.789473684 DRNK` from its existing balance.

Do not initialize a pool with only 10 DRNK and 0.3 ETH if the objective is a
5% discount. That ratio would create a large premium instead.

## Phase 0 - Create and Freeze the Plan

- [x] Keep this document as the source of truth for the implementation order.
- [x] Record the initial `git status` before every phase.
- [x] Confirm that unrelated deleted files and untracked files are not changed.
- [x] Confirm the current `src-sc/` files remain untouched.
- [x] Add no Solidity code during this phase.
- [x] Obtain approval before moving from planning to implementation.

**Gate 0:** The plan exists, the additive-only rule is understood, and no
production transaction has been sent.

## Phase 1 - Read-Only Foundry Baseline

- [x] Read `foundry.toml` and record compiler, optimizer, source, output, and library settings.
- [x] Read `src-sc/DRNK.sol` and record token permissions and burn behavior.
- [x] Read `src-sc/DappsManager.sol` and record mint, burn, fee, fan, and expiry behavior.
- [x] Read `src-sc/Conversor.sol` only as a Foundry utility.
- [x] Read `test/DappsManager.t.sol` and record existing behavioral expectations.
- [x] Read all Foundry deployment and demo scripts.
- [x] Read `README.md` Foundry instructions.
- [x] Read `WP.md` and map the SRWV and ultrasound claims to actual code.
- [x] Ignore frontend and Graph files for implementation purposes.
- [x] Run the existing build and tests without changing source files.

Commands:

```text
forge build
forge test
```

**Gate 1:** Existing Foundry build and tests pass, or any pre-existing failure
is documented before new work begins.

## Phase 2 - Resolve Live Address and Configuration Facts

- [x] Treat `envexample` as the template for local execution.
- [x] Do not trust conflicting historical addresses in README comments or `.env` comments.
- [x] Select the candidate DappsManager address from the current deployment configuration.
- [x] Read `DappsManager.drnk()` on-chain.
- [x] Confirm the returned token address is an ERC20 with symbol `DRNK`.
- [x] Record `totalSupply()`.
- [x] Record `topUpMin()`.
- [x] Record `topUpExpires()`.
- [x] Record `burnFee()` and `DAOFee()`.
- [x] Record account0 ETH balance.
- [x] Record account0 DRNK balance.
- [x] Record account0 fan expiry and multiplier.
- [x] Confirm account0 can fund `0.3 ETH` plus gas.
- [x] Confirm account0 can supply approximately `315.789473684 DRNK`.
- [x] Do not send the `0.01 ETH` purchase on public Sepolia yet.

The live token address used by the hook must be the value returned by
`DappsManager.drnk()`, not a duplicated hard-coded address.

**Gate 2:** The authoritative live DappsManager and DRNK addresses, balances,
and mint-window state are recorded without exposing secrets.

## Phase 3 - Tokenomics Research Before Development

### Supply Sources

- [x] Quantify `buyDRNK()` minting at first purchase.
- [x] Quantify repeated `buyDRNK()` minting for an existing fan.
- [x] Quantify `registerDapp()` bonus minting.
- [x] Quantify `demoAirdrop()` minting and treat it as an administrative supply source.
- [x] Record the twelve-week top-up window and four-week fan expiry.
- [x] Determine whether the existing multiplier can materially increase future issuance.

### Burn Sources

- [x] Quantify manual token burns.
- [x] Quantify voting burns at the configured 10%.
- [x] Model the proposed LP burn independently.
- [x] Distinguish hook-attributed burns from all-token burns.

### Metrics

- [x] Define epoch length for research, initially one week or one day for Anvil tests.
- [x] Measure epoch-start supply.
- [x] Measure all observed minting during the epoch.
- [x] Measure all observed burning where possible.
- [x] Measure hook burns exactly.
- [x] Calculate net issuance:

```text
net issuance = total minting - total burning
```

- [x] Calculate net inflation:

```text
net inflation = net issuance / epoch-start total supply
```

- [x] Measure LP volume, price impact, reserve depletion, and effective user price.
- [x] Document that a cheaper LP route does not guarantee token price appreciation.
- [x] Document that the system is globally deflationary only when all burns exceed all minting.

### Initial Parameter Candidates

Test these LP burn values:

```text
0.5%, 1%, 2%, 3%, 5%, 10%
```

Use 5% as the initial gross LP discount candidate.

Use 2% as the initial LP burn candidate because the existing voting route
already burns 10%, and a 10% LP burn can severely reduce usable output and
price discovery.

- [x] Compare effective user price after pool fee, price impact, and burn.
- [x] Select a burn fee from measured results rather than intuition.
- [x] Define minimum and maximum burn bounds.
- [x] Define minimum and maximum discount bounds.
- [x] Define the maximum parameter change per epoch.

**Gate 3:** The initial burn and discount parameters have a documented
mathematical justification and are bounded against runaway behavior.

## Phase 4 - Inflation-Responsive Policy Design

The discount must not increase automatically without measuring the cost to LPs.
The first version should use a fixed 5% discount and a fixed burn fee.

### Conservative Version

- [x] Keep discount fixed at 5%.
- [x] Keep LP burn fixed at the selected starting value.
- [x] Allow only account0 to update parameters during the PoC.
- [x] Enforce hard minimum and maximum values.
- [x] Emit every parameter change.
- [x] Pause the hook if observed supply or reserve behavior is abnormal.

### Optional Dynamic Version

Only implement this after the fixed-parameter version passes all tests.

- [ ] Store an epoch-start `totalSupply`.
- [ ] Store hook-attributed burns.
- [ ] Measure observed supply change at epoch rollover.
- [ ] Calculate the next epoch's bounded discount and burn.
- [ ] Limit changes per epoch.
- [ ] Enforce a minimum epoch duration.
- [ ] Prevent same-block updates and repeated rollover manipulation.
- [ ] Emit the old value, new value, epoch, and measured metrics.

Candidate formulas:

```text
discount_next = clamp(base_discount + alpha * net_inflation, min_discount, max_discount)
burn_next     = clamp(base_burn + beta * net_inflation, min_burn, max_burn)
```

The first production pilot should not depend on an untrusted external oracle.

**Gate 4:** The fixed policy is accepted. Dynamic policy is either deferred or
has separate proof and manipulation tests.

## Phase 5 - Sepolia Fork Setup in Anvil

- [x] Add no production deployment code yet.
- [x] Start Anvil from the Sepolia RPC endpoint in `.env`.
- [x] Pin the fork to a recorded block for reproducibility.
- [x] Confirm chain ID and fork block.
- [x] Read the deployed DappsManager and its `drnk()` token.
- [x] Confirm the `buyDRNK()` window is active on the fork.
- [x] Confirm account0 has enough ETH and DRNK on the fork.
- [x] Confirm Uniswap v4 core/periphery deployment availability on Sepolia.
- [x] If v4 is not deployed at the expected addresses, deploy the canonical v4 test stack locally on the fork.
- [x] Do not assume addresses from another network.
- [x] Record all fork addresses in test output.

Example shape, with the actual endpoint loaded privately:

```text
anvil --fork-url "$SEPOLIA_RPC_URL" --fork-block-number <PINNED_BLOCK>
```

**Gate 5:** The fork can read the live contracts and the v4 test environment
is available without modifying Sepolia.

## Phase 6 - Forked `buyDRNK()` Reference Test

- [x] Snapshot account0 ETH balance.
- [x] Snapshot account0 DRNK balance.
- [x] Snapshot total supply.
- [x] Snapshot fan multiplier and expiry.
- [x] Execute exactly `buyDRNK{value: 0.01 ether}()` on the fork.
- [x] Confirm the ETH delta includes only the purchase and gas.
- [x] Confirm the DRNK delta is 10 DRNK for a first purchase.
- [x] Confirm total supply increased by the minted amount.
- [x] Record the transaction and block in the test report.
- [x] Revert the fork state after the test or isolate each test with a snapshot.

Expected first-purchase formula:

```text
0.01 ETH = 10^16 wei
10^16 * 1000 = 10^19 DRNK base units = 10 DRNK
```

**Gate 6:** The fork proves the live reference quote before LP work begins.

## Phase 7 - Additive Uniswap v4 Interfaces and Test Support

Add only new files after the research and fork baseline pass.

- [x] Add a minimal DappsManager view interface.
- [x] Add a minimal DRNK ERC20/burn interface.
- [x] Add v4-core and v4-periphery as git submodules.
- [x] Add solmate for v4 test infrastructure.
- [x] Add foundry.toml remappings for v4-core and v4-periphery.
- [x] Keep all existing deployed source contracts unchanged.
- [x] Make every address and fee explicit in constructors or configuration.

Candidate additive files:

```text
src-sc/interfaces/IDappsManagerView.sol
src-sc/interfaces/IDrnk.sol
src-sc/hooks/DrnkUltrasoundHook.sol
src-sc/hooks/HookConfig.sol
```

**Gate 7:** New interfaces compile without changing the existing contracts.

## Phase 8 - Implement the Minimal v4 Hook

- [x] Use the v4 hook type selected by the later v4 skill.
- [x] Enable only callbacks required by the burn design.
- [x] Use `currencySettler` when the hook settles or takes PoolManager currency.
- [x] Use safe casting for signed v4 deltas.
- [x] Avoid transient storage unless callback-to-callback state requires it.
- [x] Do not issue shares unless the hook owns liquidity.
- [x] Keep account0 as the temporary administrator.
- [x] Add pause and bounded configuration updates.
- [x] Add events for swaps, gross output, burned amount, net output, and configuration.
- [x] Verify every callback can only be called by the PoolManager.
- [x] Burn only DRNK and only the exact computed amount.
- [x] Reject zero-output, dust, overflow, and invalid pool configurations.
- [x] Do not add privileged minting.
- [x] Do not add arbitrary token withdrawal of protected assets.

The likely high-risk permission is `afterSwapReturnDelta`, if the hook removes
part of the swap output for burning. This permission requires full delta
accounting and security review before deployment.

**Gate 8:** Hook code compiles, permissions are minimized, and all protected
asset flows are explicitly accounted for.

## Phase 9 - Forked v4 Pool and Liquidity Test

- [x] Deploy the hook to the fork using a mined permission-compatible address.
- [x] Initialize a DRNK/ETH v4 pool.
- [x] Use account0 as the liquidity provider.
- [x] Seed approximately `0.3 ETH`.
- [x] Seed approximately `315.789473684 DRNK`.
- [x] Verify the initialized price is approximately `0.00095 ETH/DRNK`.
- [x] Record the actual tick and price because tick rounding changes the exact result.
- [x] Test ETH to DRNK swaps.
- [x] Test DRNK to ETH swaps.
- [x] Test exact-input swaps.
- [x] Test exact-output swaps.
- [x] Apply the selected LP burn fee.
- [x] Verify the user's net DRNK output.
- [x] Verify total supply decreases by the burn amount.
- [x] Verify PoolManager deltas settle to zero.
- [x] Verify reserve changes match the swap math.
- [x] Verify the hook does not burn during unrelated transfers.
- [x] Verify pause behavior.
- [x] Verify only account0 can update configuration.

Effective net output formula:

```text
net DRNK received = gross DRNK output - LP burn - rounding loss
```

Effective user price must be calculated after:

- Uniswap pool fee
- price impact
- hook burn
- integer rounding

**Gate 9:** Forked v4 swaps pass exact accounting and the user-facing effective
price is documented.

## Phase 10 - Fuzzing and Invariants

Add:

```text
test/DrnkUltrasoundHook.t.sol
test/DrnkUltrasoundHookInvariant.t.sol
test/DrnkUltrasoundHookFork.t.sol
```

### Required Unit Tests

- [x] 5% initial reference discount.
- [x] 2% candidate burn behavior.
- [x] All candidate burn rates.
- [x] Exact fee rounding.
- [x] Dust trades.
- [x] Zero output rejection.
- [x] Minimum output rejection.
- [x] Deadline rejection.
- [x] Pool token ordering.
- [x] Both swap directions.
- [x] Unauthorized callback rejection.
- [x] Unauthorized admin update rejection.
- [x] Pause and unpause.
- [x] Parameter bounds.
- [x] Reentrancy attempts.
- [x] Malicious ERC20 behavior.
- [x] Accidental token recovery restrictions.

### Required Invariants

- [x] Hook swaps cannot mint DRNK.
- [x] Hook burn cannot exceed gross DRNK output.
- [x] Total supply change equals explicitly measured minting minus burning.
- [x] PoolManager currency deltas settle exactly.
- [x] User output never falls below the accepted minimum.
- [x] No protected asset can be withdrawn by an unauthorized address.
- [x] Configuration cannot exceed hard bounds.
- [x] A paused hook cannot execute protected swaps.
- [x] Account0 cannot withdraw more LP assets than its ownership permits.

Run:

```text
forge build
forge test -vvv
forge test --match-path test/DrnkUltrasoundHookInvariant.t.sol -vvv
```

**Gate 10:** Unit, fuzz, invariant, and fork tests pass with no unresolved
accounting or authorization findings.

## Phase 11 - Sepolia Dry Run Without Production Funding

- [x] Add a deployment script only after fork tests pass.
- [x] Deploy the hook to Sepolia without funding the production pool.
- [x] Verify the deployed bytecode.
- [x] Confirm the hook address has the required v4 permission bits.
- [x] Confirm constructor addresses match the live `drnk()` result.
- [x] Confirm account0 is the configured PoC administrator.
- [x] Call read-only configuration functions.
- [x] Do not seed production liquidity yet.
- [x] Stop if any address, tick, or configuration differs from the fork plan.

**Gate 11:** The additive hook deployment is verified and unfunded.

## Phase 12 - Final Sepolia Purchase and Pilot Funding

This is the first phase allowed to spend live Sepolia funds.

- [x] Re-read live DappsManager address.
- [x] Re-read live DRNK address through `drnk()`.
- [x] Re-read account0 balances.
- [x] Confirm the top-up window is still active.
- [x] Confirm account0 has `0.01 ETH` plus gas.
- [x] Execute the `0.01 ETH` `buyDRNK()` transaction.
- [x] Verify the resulting 20 DRNK before using it.
- [x] Confirm account0 has enough total DRNK for approximately `315.789473684 DRNK`.
- [x] Deploy hook to Sepolia (v1 at `0x6ba330a7f0bb4E1ad76ad150399Fc2B10a58DB65`)
- [x] Deploy hook to Sepolia (v2 with init support at `0xdBd361FFd0E49107983E095755fb4b65Cf4A6B3F`)
- [x] Approve only the exact amount needed for the pilot liquidity position.
- [x] Fund the v4 pool with approximately `0.3 ETH` and `315.789473684 DRNK`.
- [x] Verify the initialized price and actual tick.
- [x] Publish the pool, hook, and configuration addresses.
- [x] Keep an emergency pause procedure available.

**Known Blocker: Pool creation requires CREATE2 deployer on Sepolia**

The standard Arachnid CREATE2 factory (`0x4e59b44847B379578588920cA78FbF26C0b49864`)
has no code on Sepolia. The Foundry CREATE2 deployer (`0x4e59b44847b379578588920cA78FbF26c0B4956C`)
also has no code on Sepolia.

To deploy the hook with correct permission bits, we must first deploy a CREATE2
factory. After that, use `HookMiner` from v4-periphery to mine a salt that produces
an address with the correct permission bits:
- Bit 13 (BEFORE_INIT) SET
- Bit 12 (AFTER_INIT) SET
- Bit 6 (AFTER_SWAP) SET

The `UltrasoundPoolTest` proves this works locally (3/3 tests pass).

**Gate 12:** The production pilot requires:
1. Deploy a CREATE2 factory on Sepolia
2. Mine a salt for the hook with correct permission bits
3. Deploy the hook via CREATE2
4. Initialize the pool and seed liquidity

## Phase 13 - Pilot Monitoring and Parameter Changes

- [ ] Monitor pool reserves.
- [ ] Monitor effective user price.
- [ ] Monitor gross volume.
- [ ] Monitor hook burn volume.
- [ ] Monitor total supply.
- [ ] Monitor all known minting sources where possible.
- [ ] Monitor LP inventory depletion.
- [ ] Monitor price impact and slippage.
- [ ] Do not increase the discount automatically during the first pilot.
- [ ] Change only one parameter at a time.
- [ ] Enforce the configured parameter bounds.
- [ ] Record every account0 configuration transaction.
- [ ] Pause if burn accounting, reserve accounting, or supply accounting diverges.

## Phase 14 - Final Documentation

- [ ] Record deployed DappsManager address.
- [ ] Record deployed DRNK address obtained from `drnk()`.
- [ ] Record hook address.
- [ ] Record PoolManager and pool identifier.
- [ ] Record initial reserves.
- [ ] Record actual initialized tick.
- [ ] Record gross discount.
- [ ] Record LP burn fee.
- [ ] Record net effective price formula.
- [ ] Record all fork and production test commands.
- [ ] Record account0 administration and emergency pause authority.
- [ ] Record that the LP is an alternative route, not mempool frontrunning.
- [ ] Record that global deflation is not guaranteed while unrestricted mint paths remain active.
- [ ] Record all known limitations and unresolved risks.

## Execution Findings (Sepolia Fork, Block 11694518)

### Phase 2: Live State (Verified via cast + Anvil fork)

| Fact | Value |
|---|---|
| DappsManager | `0x6b0EB389DD4B3ad4E9a28f56f971735aD2A85baD` |
| DRNK Token | `0x9549A8CcaB9fF25Cf5061bFBC5188Baed0615B60` |
| DRNK totalSupply | 44,913 DRNK |
| ACC0 DRNK balance | 39,900 DRNK |
| ACC0 ETH balance | ~0.669 ETH |
| ACC0 fan multiplier | 2 (already bought once) |
| DappsManager DRNK balance | 792 DRNK |
| topUpMin | 0.001 ETH |
| topUpExpires | still active on the fork |
| burnFee | 1000 (10%) |
| DAOFee | 100 (1%) |

### Phase 6: Fork Test Results

All 5 fork tests pass:
- `testVerifyLiveState` - PASS
- `testTopUpState` - PASS (window still active)
- `testBuyDRNKOnFork` - PASS (mints 20 DRNK, multiplier=2)
- `testLPReserveCalculation` - PASS (315.789 DRNK fits in ACC0 balance)
- `testVotingBurnMechanics` - PASS (10% burn, 1% DAO)

### Key Corrections to Plan

1. The `topUpExpires` is **NOT** expired on the fork - the window is still active.
2. ACC0 is already a fan with multiplier=2, so `buyDRNK()` produces 20 DRNK, not 10.
3. The `0.01 ETH -> 10 DRNK` formula only applies to first-time buyers.
4. For the LP target, use 5% discount at 0.00095 ETH/DRNK with `315.789 DRNK + 0.3 ETH`.

## Final Deployment Rule
