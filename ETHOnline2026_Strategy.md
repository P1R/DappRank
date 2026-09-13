# DappRank — ETHOnline 2026 Continuity Track Strategy

> **Generated:** September 6, 2026
> **Purpose:** Standalone reference for any AI or human to understand the full context of DappRank, the ETHOnline 2026 hackathon, and the optimal prize strategy for the Continuity Track — without needing to re-read source files or re-fetch hackathon pages.

---

## Table of Contents

1. [Project Overview: DappRank](#1-project-overview-dapprank)
2. [Hackathon Context: ETHOnline 2026](#2-hackathon-context-ethonline-2026)
3. [Continuity Track Rules](#3-continuity-track-rules)
4. [Complete Sponsor Prize Analysis](#4-complete-sponsor-prize-analysis)
5. [Technical Complexity Assessment](#5-technical-complexity-assessment-based-on-documentation-research)
6. [Optimal Prize Strategy](#6-optimal-prize-strategy)
7. [Implementation Plan (Refined)](#7-implementation-plan-refined)
8. [Submission Requirements](#8-submission-requirements)
9. [Appendix: Source Code Map](#9-appendix-source-code-map)

---

## 1. Project Overview: DappRank

### What is DappRank?

DappRank is a **decentralized ranking system for dApps** using a novel voting mechanism called **Square Root Weighted Voting (SRWV)**. It combines:

- A **deflationary token model** (ultrasound money concept)
- A **fair governance system** resistant to whale manipulation
- **IPFS integration** for decentralized content storage

### Core Innovation: Square Root Weighted Voting (SRWV)

The SRWV system calculates voting power as the **square root of staked tokens**:

```
W_i = sqrt(T_i)
```

Where:

- `W_i`: Fan weight (voting power) of voter `i`
- `T_i`: Tokens staked by voter `i`

The final dApp rating is:

```
D_r = (sum(V_i * sqrt(T_i))) / (sum(sqrt(T_i)))
```

This ensures voting power grows **sublinearly** with token holdings, preventing whale domination:

- 100 tokens → 10 votes
- 10,000 tokens → 100 votes (not 10,000)
- 1,000,000 tokens → 1,000 votes (not 1,000,000)

### Deployed Contracts (Sepolia)

| Contract         | Address                                      | Description                                       |
| ---------------- | -------------------------------------------- | ------------------------------------------------- |
| **DappsManager** | `0x6b0EB389DD4B3ad4E9a28f56f971735aD2A85baD` | Main contract: voting, dapp registration, rewards |
| **DRNK Token**   | `0x9549A8CcaB9fF25Cf5061bFBC5188Baed0615B60` | ERC20 with burn, permit, votes capabilities       |

### Tech Stack

| Layer               | Technology                                     | Details                                               |
| ------------------- | ---------------------------------------------- | ----------------------------------------------------- |
| **Smart Contracts** | Solidity ^0.8.30 + Foundry                     | `DappsManager.sol`, `DRNK.sol`, `Conversor.sol`       |
| **Frontend**        | Svelte 5 + Vite                                | Wallet connection, voting UI, token buying, dApp list |
| **Blockchain**      | Ethereum Sepolia                               | Testnet deployment                                    |
| **Storage**         | IPFS via Helia                                 | Decentralized file storage for dApp content           |
| **Web3 Library**    | ethers.js v6                                   | Contract interactions                                 |
| **Dependencies**    | OpenZeppelin (AccessControl, ERC20), Forge Std | Smart contract libraries                              |

### Smart Contract Architecture

#### `DappsManager.sol` — Main Contract

**Roles:**

- `DEFAULT_ADMIN_ROLE`: Full admin control
- `DAO_ROLE`: DAO governance operations

**Core Data Structures:**

```solidity
struct Dapp {
    string cid;           // IPFS content identifier
    uint256 rate;         // Final rating (Dr)
    uint256 weight_votes_sum;   // Sum(Vi x sqrt(Ti))
    uint256 weight_total_sum;   // Sum(sqrt(Ti))
    uint256 balance;      // Accumulated token balance
    uint256 burned;       // Total tokens burned
    address owner;        // Dapp owner address
    Status status;        // Submitted, Active, Expired, Banned
    mapping(address => Vote) votes;
}

struct Vote {
    uint256 vote_rate;    // Vi (0-100)
    uint256 fan_weight;   // Wi = sqrt(Ti)
    uint256 timestamp;
}

struct Fan {
    uint256 multiplier;
    uint256 expires;
}
```

**Key Functions:**

- `registerDapp(bytes32 name, string memory cid)` — Register a dApp (payable listing fee)
- `voteDapp(bytes32 name, uint256 amount, uint256 rate)` — Vote on a dApp (SRWV applied)
- `approveDapp(bytes32 name)` / `banDapp(bytes32 name)` — Admin moderation
- `dappCashOut(bytes32 name, uint256 amount)` — Owner withdraws rewards
- `buyDRNK()` — Purchase DRNK tokens with ETH
- `burn(uint256 amount)` — Burn DRNK tokens
- `getDappInfo(bytes32 name)` — Get dApp details
- `getAllDappNames()` / `getAllFans()` — List all dApps/fans

**Fee Structure:**

- `listingFee`: Fixed price to register a dApp
- `DAOFee`: % (in basis points) taken on cashouts for DAO treasury
- `burnFee`: % (in basis points) burned on each vote (ultrasound money)

#### `DRNK.sol` — Token Contract

- ERC20 + ERC20Burnable + ERC20Permit + ERC20Votes + AccessControl
- `MINTER_ROLE` for minting (granted to DappsManager)
- Used for governance voting power

#### `Conversor.sol` — Utility Library

- `stringToBytes32(string)` / `bytes32ToString(bytes32)` — Type conversion helpers

### Frontend Components (Svelte 5)

| Component         | File                                    | Purpose                         |
| ----------------- | --------------------------------------- | ------------------------------- |
| `WalletConnector` | `src/components/WalletConnector.svelte` | MetaMask connection             |
| `DappRankList`    | `src/components/DappRankList.svelte`    | Display ranked dApps            |
| `DappsData`       | `src/components/DappsData.svelte`       | Refresh dApp data from contract |
| `Vote4Dapp`       | `src/components/Vote4Dapp.svelte`       | Voting UI popup                 |
| `GetDRNK`         | `src/components/GetDRNK.svelte`         | Buy DRNK tokens popup           |
| `IPFSConnector`   | `src/components/IPFSConnector.svelte`   | Upload files to IPFS            |

### State Management (`src/lib/ethers.svelte.js`)

Uses Svelte 5 `$state` runes for reactive state:

- `ethVars`: provider, signer, signerAddress, contract, tokenContract, dappsList

---

## 2. Hackathon Context: ETHOnline 2026

### Event Details

| Item                    | Info                                               |
| ----------------------- | -------------------------------------------------- |
| **Event**               | ETHOnline 2026                                     |
| **Organizer**           | ETHGlobal                                          |
| **Submission Deadline** | Sunday, September 13, 2026 at 12:00 pm EDT         |
| **Staking**             | Participants stake ETH (returned after submission) |
| **Team Size**           | Up to 5 people                                     |
| **Demo Video**          | 2-4 minutes (mandatory, 720p minimum)              |
| **Judging**             | Async (partner prizes) + Live (finalist)           |
| **Max Partner Prizes**  | 3 selections (multi-track partners count as 1)     |

### Judging Criteria

| Criterion                | Weight                                                         |
| ------------------------ | -------------------------------------------------------------- |
| **Technicality**         | How complex is the problem? How sophisticated is the solution? |
| **Originality**          | New idea or creative solution to an existing problem?          |
| **Practicality**         | How complete and functional? Could it be used today?           |
| **Usability (UI/UX/DX)** | How intuitive is the project?                                  |
| **WOW Factor**           | Lasting impression, unique elements                            |

### Key Rules

- **Continuity Track**: Can build on existing open-source codebase
- **Must document** pre-existing work vs. new work (git history)
- **AI tools permitted** but must document usage
- **Version control required** — no single large commits

---

## 3. Continuity Track Rules

### What is the Continuity Track?

The Continuity Track allows participants to **extend an existing open-source project** or **ship a new feature on an existing product**, rather than starting from scratch.

### Requirements

1. **Pre-existing code is allowed** — the project can have code written before the hackathon
2. **New work must be clearly documented** — README must separate what existed before from what is new
3. **Git history matters** — commit history should show work done during the event
4. **Only work done during the event is judged** — polish and bug fixes alone won't qualify
5. **Demo video required** — 2-4 minutes focusing on the new work

### Eligibility for Partner Prizes

- Continuity Track participants are eligible for **specific Continuity-designated prizes**
- Some partners have separate "From Scratch" and "Continuity" pools
- Must select the correct pool when submitting

### Documentation Requirements

```
## Pre-existing Code (before hackathon)
- [List what existed before]

## New Work (during hackathon)
- [List what was built during the event]
```

---

## 4. Complete Sponsor Prize Analysis

### Overview: All Sponsors

| Sponsor      | Total Pool | # of Tracks                                  | Continuity Track?                  |
| ------------ | ---------- | -------------------------------------------- | ---------------------------------- |
| The Graph    | $15,000    | 2 (Composable + AI)                          | ✅ AI Use Case (Continuity)        |
| Hedera       | $15,000    | 3 (AI Payments + Open Source + Tokenization) | ✅ Continuity ($1,000)             |
| Arc (Circle) | $10,000    | 4 (DeFi + Agentic + Continuity + Launch)     | ✅ Best DeFi/Agentic + Launch      |
| World        | $7,000     | 2 (AgentKit + Selfie Check)                  | ✅ AgentKit Continuity             |
| 1inch        | $7,000     | 2 (Aqua App + Continuity)                    | ✅ Aqua App (Continuity)           |
| ENS          | $5,000     | 2 (ENSv2 + Integration)                      | ✅ Integration into Existing       |
| Uniswap      | $5,000     | 2 (Stack + Continuity)                       | ✅ Stack Contribution (Continuity) |
| Ledger       | $5,000     | 2 (AI Agents + Continuity)                   | ✅ Continuity                      |
| Privy        | $5,000     | 2 (B2B + Financial Flow)                     | ❌ No Continuity track             |
| Chainlink    | $3,000     | 2 (Confidential + Upgrade)                   | ✅ Best Upgrade (Continuity)       |
| Bazantic     | $3,000     | 3 (Help Agent + Recipe + Agentify)           | ✅ Help an Agent (Continuity)      |

### Detailed Prize Breakdown (Continuity Tracks Only)

#### 🥇 The Graph — Best AI Tooling/AI Use Case (Continuity)

- **Prize Pool:** $5,000
- **1st Place:** $2,500 | **2nd:** $1,500 | **3rd:** $1,000
- **Requirements:**
  - Use The Graph as load-bearing part of project
  - Consume live data from a Graph provider (Subgraph Studio or The Graph Market)
  - Do meaningful work with data (reasoning, decisions, automation, natural-language interface)
  - Open-source code with README or SKILL.md
  - Demo video 2-4 minutes
- **Resources:** Subgraph MCP, Subgraph SKILLs, Substreams SKILLs
- **Fit for DappRank:** ✅ EXCELLENT — Subgraph indexes dApp data, AI Agent provides investor insights

#### 🥇 Arc (Circle) — Best DeFi or Agentic Application (Continuity)

- **Prize:** $1,666 (1st place)
- **Requirements:**
  - Meaningful use of Arc and USDC
  - Advanced programmable money flows
  - Functional MVP + architecture diagram
  - Registered as Continuity Project
- **Fit for DappRank:** ✅ HIGH — USDC listing fees, treasury dashboard

#### 🥇 Arc (Circle) — Launch on Arc Testnet & Push to Mainnet (Continuity)

- **Prize:** $1,500 (1st place)
- **Requirements:**
  - Add working Arc integration to existing project
  - Deployed or deployment-ready on Arc mainnet by September 30
  - Functional MVP + architecture diagram
- **Fit for DappRank:** ✅ HIGH — Deploy DappRank on Arc as additional settlement layer

> **Note:** Arc has 2 Continuity tracks. Since they are the same sponsor, they count as **1 selection** in the submission form, but you can win both.

#### 🥇 World — AgentKit Continuity

- **Prize Pool:** $3,500 (up to 3 teams receive $1,166 each)
- **Requirements:**
  - Uses AgentKit meaningfully
  - Shows working app
  - Registers/resolves agents through AgentBook
  - Uses World ID Sandbox App
  - Includes feedback document on docs, portal, sandbox
- **Fit for DappRank:** ✅ MEDIUM — Could verify human investors vs. bots, but not core to tracking

#### 🥇 1inch — Build an Aqua App (Continuity)

- **Prize:** $1,500 (1st) | $500 (2nd)
- **Requirements:**
  - Official Aqua/SwapVM contracts used
  - On-chain execution of token transfers
  - Proper git commit history
- **Fit for DappRank:** ❌ LOW — Aqua is about self-custodial liquidity pools, unrelated to dApp ranking

#### 🥇 ENS — Best Integration of ENSv2 into an Existing Project (Continuity)

- **Prize:** $500 (1st)
- **Requirements:**
  - Integration uses ENSv2 on Sepolia
  - Targets existing project's testnet deployment
  - Clear how ENSv2 improves the project
- **Fit for DappRank:** ✅ MEDIUM — Replace bytes32 dApp names with ENS names, but limited scope

#### 🥇 Uniswap — Best Uniswap Stack Contribution (Continuity)

- **Prize:** $1,000 (1st) | $1,000 (2nd)
- **Requirements:**
  - Build on/integrate Uniswap stack (API, AMM v2/v3/v4, CCA)
  - Public GitHub repo + FEEDBACK.md + Uniswap feedback form
- **Fit for DappRank:** ✅ MEDIUM — Could add DRNK liquidity pool on Uniswap, but tangential

#### 🥇 Ledger — Continuity

- **Prize:** $1,000 (1st) | $500 (2nd)
- **Requirements:**
  - Extend existing project with Ledger Agent Stack
  - Add hardware signer, Key Ring, or device confirmation
- **Fit for DappRank:** ✅ MEDIUM — Hardware security for DAO admin actions, but not investor-facing

#### 🥇 Chainlink — Best Chainlink-Powered Upgrade (Continuity)

- **Prize:** $500 (1st)
- **Requirements:**
  - Integrate Chainlink service directly in smart contract logic or on-chain workflows
  - Must contribute to a state change on blockchain (not just display data)
  - Demonstrate how upgrade improves the project
  - Use CRE instead of deprecated Functions/Automation
- **Fit for DappRank:** ✅ HIGH — Price Feeds for USD valuation, CRE for confidential investor strategies

#### 🥇 Bazantic — Help an Agent Use Your Hackathon Project (Continuity)

- **Prize:** Up to 2 teams receive $500 each
- **Requirements:**
  - Create x402/MPP Gateway in Bazantic
  - Create a Recipe explaining when/why/how to use the service
  - Show improvement with Recipe vs. without
  - Demo video
- **Fit for DappRank:** ✅ MEDIUM — Agent API gateway for DappRank data, but $500 max

#### 🥇 Hedera — Continuity

- **Prize:** $1,000 (1st)
- **Requirements:**
  - Project must have been built for previous hackathon or exist on Hedera
  - Demonstrate substantive new work
- **Fit for DappRank:** ❌ LOW — DappRank is on Ethereum/Sepolia, not Hedera. Porting would be major effort.

---

## 5. Technical Complexity Assessment (Based on Documentation Research)

> **Research Date:** September 6, 2026
> **Methodology:** Each partner's official documentation, SDK references, GitHub repos, and quickstart guides were consulted to assess real implementation complexity, dependencies, risks, and fit for DappRank.

---

### 5.1 The Graph — Complexity: MEDIUM-HIGH

#### Documentation Sources Consulted

- [Subgraph MCP Introduction](https://thegraph.com/docs/en/subgraphs/tooling/subgraph-mcp/introduction/) — MCP server for natural-language Subgraph queries
- [Subgraphs SKILLs (GitHub)](https://github.com/graphprotocol/subgraphs-skills) — Claude Code plugin for subgraph development
- [Substreams SKILLs (GitHub)](https://github.com/streamingfast/substreams-skills) — Agent skills for Substreams (Ethereum, SQL, sinks, testing, deployment)

#### What It Does

- **Subgraph MCP**: An MCP-compatible server that translates natural language prompts into Subgraph queries. Integrates with Claude, Cline, Cursor. Can search subgraphs, inspect GraphQL schemas, run queries, retrieve 30-day query volumes.
- **Subgraphs SKILLs**: Claude Code plugin with 3 skills: `subgraph-dev` (schema design, manifest config, AssemblyScript mappings, composition), `subgraph-optimization` (performance, pruning, indexing), `subgraph-testing` (Matchstick, linter, CI/CD).
- **Substreams SKILLs**: 9 skills covering: dev, Ethereum, Solana, SQL, sink, sink-deploy-local, hosted-sink, The Graph Market API, testing.

#### Implementation Steps

1. Create `subgraph.yaml` manifest with DappsManager contract address on Sepolia
2. Define `schema.graphql` with entities: Dapp, Vote, GlobalStat
3. Write AssemblyScript mappings for events: `DappRegistered`, `DappApproved`, `DappBanned`, `VoteCast` (may need to add event emission to contract)
4. Deploy to Subgraph Studio (free, live data required)
5. Install Subgraph MCP server and configure with deployed subgraph
6. Build AI agent using MCP tools for natural-language queries
7. Optionally create SKILLs for reusable DappRank analysis

#### Dependencies

- `graph-cli` (npm) for subgraph deployment
- `@graphprotocol/graph-ts` for AssemblyScript mappings
- Subgraph MCP server (open source)
- Claude Code or compatible MCP client for AI agent

#### Risks & Considerations

- **Event emission**: `DappsManager.sol` does NOT currently emit events for votes. May need to add `event VoteCast(...)` to the contract and redeploy. This is a significant consideration.
- **Live data requirement**: Subgraph must consume live data from a Graph provider. Mocked/static data disqualifies.
- **Composition requirement**: The "Best Use of Composable Products" track ($5,000) requires composing 2+ Graph products OR building on standardized schema. The "AI Use Case" Continuity track ($2,500) does NOT require composition — just using The Graph as load-bearing data source.
- **SKILLs already exist**: Subgraphs SKILLs and Substreams SKILLs are pre-built. We can use them directly rather than building from scratch.

#### Estimated Time

- Subgraph creation + deploy: 1-2 days
- AI Agent + MCP integration: 1-2 days
- SKILLs creation (optional): 1 day

---

### 5.2 Arc / Circle — Complexity: MEDIUM

#### Documentation Sources Consulted

- [Arc Docs (llms.txt)](https://docs.arc.io/llms.txt) — Full documentation index
- [Arc App Kit](https://docs.arc.io/app-kit) — SDK for Bridge, Swap, Send, Unified Balance
- [Circle Agent Stack Starter Kits (GitHub)](https://github.com/circlefin/agent-stack-starter-kits) — 6 framework kits (LangChain, Claude Agent SDK, Mastra, OpenAI Agents, Vercel AI, Google ADK)
- [Arc EVM Differences](https://docs.arc.io/arc/references/evm-differences.md) — Key differences from standard EVM

#### What It Does

- **Arc Network**: Purpose-built L1 from Circle. EVM-compatible (Osaka baseline) with key differences:
  - **USDC is the native gas token** (not ETH). 18 decimals natively.
  - **Sub-second deterministic finality** — no need to wait for confirmations.
  - **Stable fee design** — predictable gas fees in USD terms.
  - **Opt-in privacy** — confidential transactions with selective disclosure.
- **App Kit**: `@circle-fin/app-kit` npm package. Single SDK for Bridge (cross-chain USDC via CCTP), Swap (same-chain), Send (wallet-to-wallet), Unified Balance (chain-abstracted USDC balance).
- **Agent Stack Starter Kits**: 6 framework-specific kits that wire Circle Agent Stack (wallets, nanopayments, marketplace) into popular AI frameworks. Uses `circle` CLI + skills installed from disk.

#### Implementation Steps

**For "Best DeFi/Agentic Application" ($1,666):**

1. Deploy DappsManager.sol on Arc Testnet (EVM-compatible, minor adjustments for USDC gas)
2. Modify listing fees to accept USDC (or keep ETH-equivalent using Arc's native USDC)
3. Integrate Circle App Kit for USDC payment flows
4. Build Treasury Dashboard showing USDC balances
5. Optionally integrate Agent Stack for autonomous agent payments

**For "Launch on Arc Testnet & Push to Mainnet" ($1,500):**

1. Deploy contracts on Arc Testnet
2. Verify contracts on Arcscan (block explorer)
3. Document mainnet deployment readiness
4. Must be deployment-ready on Arc mainnet by September 30

#### Dependencies

- `@circle-fin/app-kit` (npm)
- `@circle-fin/adapter-viem-v2` or `ethers` adapter
- `@circle-fin/cli` (Circle CLI) for Agent Stack
- Arc Testnet RPC endpoint
- Circle account for faucet tokens

#### Risks & Considerations

- **EVM differences**: USDC is gas token (not ETH). Contracts that use `msg.value` or transfer ETH need modification. `DappsManager.sol` uses `msg.value` for `buyDRNK()` and `registerDapp()` — these would need to accept USDC instead.
- **Mainnet deadline**: Arc mainnet launch is required by Sept 30 for the Launch prize. If mainnet isn't available by then, this prize may not be winnable.
- **Arc is testnet-only currently** — no mainnet available yet. Check status before committing.
- **Agent Stack requires learning**: The starter kits are well-documented but require understanding Circle CLI, skills system, and approval gates.
- **High prize value**: Combined $3,166 makes this the highest-value target.

#### Estimated Time

- Contract deployment on Arc Testnet: 0.5 day
- USDC integration + fee modification: 1 day
- Treasury Dashboard: 1 day
- Agent Stack integration (optional): 1-2 days

---

### 5.3 Chainlink — Complexity: LOW (Price Feeds) / HIGH (CRE)

#### Documentation Sources Consulted

- [CRE Docs](https://docs.chain.link/cre) — Chainlink Runtime Environment overview
- [Hello Confidential Workflows](https://docs.chain.link/cre-templates/hello-confidential-workflows) — Confidential workflow quickstart template
- [CRE Templates (GitHub)](https://github.com/smartcontractkit/cre-templates) — AI Audit Firewall, Automated Liquidation Protection, Portfolio Rebalancing
- [Chainlink Data Feeds](https://docs.chain.link/data-feeds) — Price Feeds documentation

#### What It Does

- **Price Feeds**: Decentralized oracle network providing asset prices on-chain. Simple integration via `AggregatorV3Interface`. Proxy contract pattern with upgradability. Heartbeat + deviation threshold updates. Available on most EVM chains including Sepolia.
- **CRE (Chainlink Runtime Environment)**: All-in-one orchestration layer for institutional-grade smart contracts. Build workflows in Go or TypeScript, compile to WASM, deploy to Decentralized Oracle Network (DON).
- **Confidential Workflows (Private Beta)**: Execute sensitive logic inside TEE (AWS Nitro). Secrets fetched inside enclave via Vault DON. Requires enrollment through Chainlink account team.

#### Implementation Steps

**For Price Feeds ($500 — Best Chainlink-Powered Upgrade):**

1. Identify relevant Price Feed proxy addresses on Sepolia (ETH/USD, etc.)
2. Create a consumer contract or frontend integration using `AggregatorV3Interface`
3. Display USD values for: DRNK token price, dApp balances, burned tokens, listing fees
4. Must contribute to a **state change on blockchain** (not just display data in frontend)

**For CRE Confidential Workflows (optional):**

1. Install CRE CLI (`curl -sSL https://app.chain.link/cre/install.sh | bash`)
2. Create CRE account at app.chain.link/cre/discover
3. Build workflow using `cre init --template=hello-confidential-workflows-ts`
4. Requires private beta enrollment for confidential features

#### Dependencies

- `@chainlink/contracts` (npm) for Price Feed interfaces
- `cre` CLI for CRE workflows
- Go or Node.js/bun for workflow development

#### Risks & Considerations

- **Price Feeds are simple but must cause state change**: The Chainlink Continuity prize requires the integration to contribute to a **state change on a blockchain**. Simply displaying data in a frontend is NOT sufficient. Need to write a smart contract that uses Price Feed data to modify state (e.g., dynamic fee calculation based on USD value).
- **CRE Confidential Workflows is private beta**: Requires enrollment through Chainlink account team. May not be accessible during hackathon.
- **Low effort, decent prize**: $500 for a few hours of work is good value.
- **Sepolia has Price Feeds**: ETH/USD feed available on Sepolia for testing.

#### Estimated Time

- Price Feed smart contract integration: 0.5 day
- Frontend USD display: 0.5 day
- CRE workflow (if accessible): 1-2 days

---

### 5.4 World (AgentKit) — Complexity: MEDIUM

#### Documentation Sources Consulted

- [AgentKit Integration Guide](https://docs.world.org/agents/agent-kit/integrate) — Quickstart with Hono, x402, AgentBook

#### What It Does

- **AgentKit**: x402 extension that distinguishes human-backed agents from bots/scripts. npm package `@worldcoin/agentkit`.
- **Flow**: Register agent wallet in AgentBook → Wrap x402 calls with `agentkit.fetch` → Wire hooks-based server with free-trial mode → Verify human backing.
- **Supports**: World Chain + Base for payments. AgentBook lookup always on World Chain.

#### Fit for DappRank

- Could verify that investors using the AI agent are real humans
- Adds friction to the investor experience (requires World App verification)
- Not core to the "continuous tracking" value proposition
- Prize is $1,166 (shared among up to 3 teams)

#### Estimated Time: 1-2 days

---

### 5.5 ENS (ENSv2) — Complexity: LOW-MEDIUM

#### Documentation Sources Consulted

- [ENSv2 Overview](https://docs.ens.domains/ensv2/overview) — Hierarchical registries, Enhanced Access Control, Permissioned Resolvers

#### What It Does

- **ENSv2**: Upgraded ENS with hierarchical registries, role-based permissions (replacing Name Wrapper fuses), per-account Permissioned Resolvers, record aliasing.
- **Deployed on Sepolia** — same testnet as DappRank.

#### Fit for DappRank

- Replace `bytes32` dApp names with human-readable ENS names
- Use Permissioned Registry for subname management
- Nice UX improvement but limited scope
- Prize is only $500

#### Estimated Time: 1 day

---

### 5.6 Uniswap — Complexity: MEDIUM

#### Documentation Sources Consulted

- [Uniswap Docs](https://developers.uniswap.org/docs) — API, v4 hooks, SDKs, Uniswap AI

#### What It Does

- Uniswap API for swaps, v4 hooks for custom pool logic, SDKs for integration
- Uniswap AI skills for agent-based development

#### Fit for DappRank

- Could create a DRNK liquidity pool on Uniswap
- Could use Uniswap API to swap DRNK for other tokens
- Tangential to ranking/tracking — would feel forced
- Prize is $1,000 (1st place)

#### Estimated Time: 1-2 days

---

### 5.7 Ledger — Complexity: MEDIUM-HIGH

#### Documentation Sources Consulted

- [Ledger × ETHOnline 2026](https://developers.ledger.com/ethonline) — Track details, DMK skills, Wallet CLI, Key Ring

#### What It Does

- **DMK Skills**: Teach agents to wire Ledger signer into apps
- **Wallet CLI**: Drive Ledger apps from terminal
- **Key Ring CLI**: Encrypt secrets under Ledger seed keys

#### Fit for DappRank

- Add Ledger hardware signer for DAO admin operations
- Use Key Ring for secure key management
- Not investor-facing — more about operational security
- Prize is $1,000 (1st place)

#### Estimated Time: 2-3 days

---

### 5.8 Bazantic — Complexity: LOW-MEDIUM

#### Documentation Sources Consulted

- [Bazantic](https://bazantic.com) — x402/MPP Gateway, MCP Server, Recipes

#### What It Does

- Create x402/MPP Gateway for APIs
- Deploy MCP Server
- Create Recipes explaining when/why/how to use services

#### Fit for DappRank

- Expose DappRank data as agent-consumable API
- Create Recipes for investor analysis
- Prize is $500 (up to 2 teams)

#### Estimated Time: 1 day

---

### 5.9 Complexity Summary Matrix

| Partner          | Complexity  | Effort (Days) | Risk Level | Prize (1st) | $/Day Ratio | Fit Score (1-10) |
| ---------------- | ----------- | ------------- | ---------- | ----------- | ----------- | ---------------- |
| **Arc (Circle)** | MEDIUM      | 3-4           | Medium     | $3,166      | ~$791/day   | 9                |
| **The Graph**    | MEDIUM-HIGH | 3-4           | Medium     | $2,500      | ~$625/day   | 10               |
| **Chainlink**    | LOW         | 1             | Low        | $500        | ~$500/day   | 8                |
| World            | MEDIUM      | 1-2           | Low        | $1,166      | ~$583/day   | 5                |
| Uniswap          | MEDIUM      | 1-2           | Low        | $1,000      | ~$500/day   | 4                |
| Ledger           | MEDIUM-HIGH | 2-3           | Medium     | $1,000      | ~$333/day   | 4                |
| ENS              | LOW-MEDIUM  | 1             | Low        | $500        | ~$500/day   | 5                |
| Bazantic         | LOW-MEDIUM  | 1             | Low        | $500        | ~$500/day   | 6                |

> **Key Insight (revisado 2026-09-13):** The Graph + Uniswap + ENS es la nueva combinación óptima por tiempo. The Graph ya está completo; Uniswap aporta utilidad real al token con el mejor ratio $/día restante; ENS es la integración de menor esfuerzo con valor UX directo. Arc se descarta por los cambios USDC en el contrato + deploy en Arc testnet/mainnet; Chainlink se descarta en favor de ENS (mismo premio, menos esfuerzo, valor UX directo).

---

## 6. Optimal Prize Strategy

### Recommended Combination: The Graph + Uniswap + ENS

> **Revisado 2026-09-13:** cambio de estrategia por tiempo. Se descartan Arc (requiere
> modificar el contrato para USDC + deploy en Arc testnet + mainnet-ready antes del
> Sept 30) y Chainlink (mismo premio que ENS con más esfuerzo). The Graph ya está
> implementado y desplegado.

| #   | Sponsor       | Track(s)                                | 1st Place  | Effort      | Strategic Value                      |
| --- | ------------- | --------------------------------------- | ---------- | ----------- | ------------------------------------ |
| 1   | **The Graph** | Best AI Tooling/AI Use Case (Cont.)     | **$2,500** | Medium-High | Core investor tracking (YA COMPLETO) |
| 2   | **Uniswap**   | Best Uniswap Stack Contribution (Cont.) | **$1,000** | Medium      | Liquidez DRNK + swap in-app          |
| 3   | **ENS**       | Best Integration of ENSv2 (Cont.)       | **$500**   | Low         | Nombres legibles para dApps          |
|     | **TOTAL**     |                                         | **$4,000** |             |                                      |

### Why This Combination?

#### 1. The Graph ($2,500) — The Heart of Continuous Tracking (COMPLETO)

- **Subgraph** indexes all DappRank events (votes, registrations, burns, cashouts) in real-time
- **AI Agent** via Subgraph MCP enables natural-language investor queries
- **SKILLs** make the analysis reusable for other developers
- Perfect alignment with "investor continuous tracking" goal
- The Graph is already on Ethereum = zero migration friction
- **Estado: implementado y desplegado** (subgraph v0.0.2 en Subgraph Studio) — solo falta el demo video

#### 2. Uniswap ($1,000) — Token Utility & Liquidity

- **DRNK liquidity pool** on Uniswap gives the token real market value
- **In-app swap** via Uniswap SDK lets users buy/sell DRNK without leaving DappRank
- Completes the tokenomics loop: earn DRNK by voting → swap it on Uniswap
- Highest remaining $/day ratio among the feasible options
- Requires public repo + `FEEDBACK.md` + Uniswap feedback form

#### 3. ENS ($500) — Human-Readable dApp Names

- Replace opaque `bytes32` dApp identifiers with **ENSv2 names on Sepolia** (same testnet as DappRank)
- **Permissioned Registry** for subname management (e.g., `dappname.dapprank.eth`)
- Direct UX improvement: readable names in ranking, votes, and agent queries
- Lowest effort of all options (1 day) with visible value for judges

### Why NOT Other Combinations?

| Rejected Combo                  | Total  | Why Not?                                                                                                                                                              |
| ------------------------------- | ------ | --------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| The Graph + Arc + Chainlink     | $6,166 | Arc exige modificar el contrato para USDC + deploy en Arc testnet + mainnet-ready antes del Sept 30. Demasiado tiempo/riesgo para los días restantes                  |
| The Graph + Uniswap + Chainlink | $4,000 | Mismo total que con ENS, pero ENS es menos esfuerzo (1 día) y mejora la UX directamente (nombres legibles). Chainlink requiere contrato nuevo + deploy + state change |
| The Graph + Arc + Uniswap       | $6,666 | Arc sigue siendo el bloqueante de tiempo (USDC + testnet + mainnet)                                                                                                   |
| The Graph + Arc + ENS           | $4,000 | Mismo total, pero Uniswap aporta utilidad real al token (liquidez/swap) que ENS no cubre                                                                              |
| The Graph + Arc + World         | $6,832 | World requiere AgentKit + feedback docs + Sandbox testing. Alto esfuerzo y la verificación humana no es core al tracking                                              |

### Architecture Diagram

```mermaid
graph TB
    subgraph "Preexisting — DappRank Core"
        SC[Smart Contracts<br/>DappsManager.sol + DRNK.sol<br/>Sepolia: 0x6b0EB...48957]
        FE[Frontend Svelte 5<br/>Wallet, Voting, Token Buy]
    end

    subgraph "New — The Graph ($2,500) — COMPLETO"
        SUBG[Subgraph<br/>Indexes: votes, ratings,<br/>burns, cashouts, registrations]
        AI_AGENT[AI Agent<br/>Natural language queries<br/>for investors]
        SKILLS[SKILLs<br/>track_dapp, alert,<br/>compare, report]
    end

    subgraph "New — Uniswap ($1,000)"
        POOL[DRNK Liquidity Pool<br/>Uniswap v3]
        SWAP[Swap DRNK<br/>Uniswap SDK/API]
    end

    subgraph "New — ENS ($500)"
        ENSV2[ENSv2 on Sepolia<br/>Human-readable dApp names]
        SUBNAMES[Subnames via<br/>Permissioned Registry]
    end

    SC -->|Events| SUBG
    SUBG -->|GraphQL| AI_AGENT
    SUBG -->|Ranking| FE
    AI_AGENT -->|Alerts/Reports| FE
    POOL -->|Liquidity| SC
    SWAP -->|Buy/Sell DRNK| FE
    ENSV2 -->|Resolve names| FE
    ENSV2 -->|bytes32 → name| SC
```

### Narrative for Judges

> **"DappRank is a decentralized dApp ranking platform using Square Root Weighted Voting. For ETHOnline 2026, we transformed it into a complete investor intelligence platform:"**
>
> 1. **The Graph Subgraph** indexes all on-chain activity in real-time, powering an **AI Agent** that investors query in natural language
> 2. **Uniswap** gives DRNK real market utility — a liquidity pool and in-app swaps complete the tokenomics loop (vote → earn DRNK → swap)
> 3. **ENSv2** replaces opaque bytes32 identifiers with human-readable dApp names on Sepolia, improving UX across ranking, votes, and agent queries**

---

## 6. Implementation Plan (Refined)

### Key Technical Decisions Based on Documentation Research

> **Revisado 2026-09-13:** se eliminan Arc y Chainlink por tiempo. Nueva combinación: The Graph (completo) + Uniswap + ENS.

#### The Graph: Subgraph + AI Agent (Not Substreams) — COMPLETO

- **Decision**: Build a standard Subgraph + Subgraph MCP, NOT Substreams
- **Rationale**: Substreams requires Rust modules and protobuf schemas — significantly more complex. The Subgraph MCP already provides natural-language querying capabilities. The Continuity AI track ($2,500) does NOT require composition of multiple Graph products.
- **Status**: Eventos desplegados en Sepolia, subgraph v0.0.2 en Subgraph Studio, skill de agente creado. Pendiente: demo video.

#### Uniswap: DRNK Pool + SDK Swap (Not v4 Hooks)

- **Decision**: Create a DRNK liquidity pool on Uniswap v3 and integrate swaps via the Uniswap SDK/API. Skip v4 hooks (custom pool logic) unless time permits.
- **Rationale**: The prize requires "building on/integrating the Uniswap stack" — a pool + SDK swap satisfies this with the least complexity. v4 hooks would add custom logic but also significant testing overhead.
- **Requirements**: Public GitHub repo + `FEEDBACK.md` + Uniswap feedback form.
- **Approach**: Deploy DRNK/WETH (or DRNK/USDC) pool on Sepolia, add a "Swap DRNK" action in the frontend using the Uniswap SDK.

#### ENS: ENSv2 Name Resolution (Not Full Registry Migration)

- **Decision**: Integrate ENSv2 on Sepolia to resolve/display dApp names as human-readable ENS names. Do NOT migrate the contract's `bytes32` storage to ENS.
- **Rationale**: The prize requires "integration uses ENSv2 on Sepolia" targeting the existing testnet deployment. A resolver layer (contract or frontend) that maps `bytes32` → ENS name satisfies this without a risky storage migration.
- **Approach**: Register subnames under a DappRank ENSv2 domain (e.g., `dapprank.eth`), resolve them in the frontend and in the AI agent queries.

---

### Timeline (Revised — The Graph done, 2-3 days remaining)

| Day       | Focus               | Sponsor | Deliverables                                                                                    |
| --------- | ------------------- | ------- | ----------------------------------------------------------------------------------------------- |
| **Day 1** | Uniswap Pool + SDK  | Uniswap | Deploy DRNK pool on Sepolia (v3). Integrate Uniswap SDK swap in frontend. Write `FEEDBACK.md`   |
| **Day 2** | ENSv2 Integration   | ENS     | Register DappRank ENSv2 domain + subnames on Sepolia. Resolve names in frontend + agent queries |
| **Day 3** | Polish + Submission | All     | README with pre-existing/new split (Graph, Uniswap, ENS). Record 2-4 min demo video. Submit     |

---

### Detailed Implementation Notes

#### The Graph: Subgraph Development

**Step 1: Add events to DappsManager.sol**

Add these events to the existing contract:

```solidity
event DappRegistered(bytes32 indexed name, address indexed owner, string cid);
event DappApproved(bytes32 indexed name);
event DappBanned(bytes32 indexed name);
event VoteCast(bytes32 indexed dapp, address indexed voter, uint256 voteRate, uint256 fanWeight, uint256 timestamp);
event TokensBurned(bytes32 indexed dapp, uint256 amount);
event DappCashOut(bytes32 indexed dapp, address indexed owner, uint256 amount);
```

Emit these events in the corresponding functions (`registerDapp`, `approveDapp`, `banDapp`, `voteDapp`, `burn`, `dappCashOut`).

**Step 2: Create subgraph.yaml**

```yaml
specVersion: 1.0.0
schema:
  file: ./schema.graphql
dataSources:
  - kind: ethereum
    name: DappsManager
    network: sepolia
    source:
      address: "0x6b0EB389DD4B3ad4E9a28f56f971735aD2A85baD"
      abi: DappsManager
      startBlock: <deployment-block>
    mapping:
      kind: ethereum/events
      apiVersion: 0.0.7
      language: wasm/assemblyscript
      entities:
        - Dapp
        - Vote
        - GlobalStat
      abis:
        - name: DappsManager
          file: ./abis/DappsManager.json
      eventHandlers:
        - event: DappRegistered(bytes32 indexed,address,string)
          handler: handleDappRegistered
        - event: DappApproved(bytes32 indexed)
          handler: handleDappApproved
        - event: DappBanned(bytes32 indexed)
          handler: handleDappBanned
        - event: VoteCast(bytes32 indexed,address indexed,uint256,uint256,uint256)
          handler: handleVoteCast
        - event: TokensBurned(bytes32 indexed,uint256)
          handler: handleTokensBurned
        - event: DappCashOut(bytes32 indexed,address indexed,uint256)
          handler: handleDappCashOut
      file: ./src/mapping.ts
```

**Step 3: Schema (schema.graphql)**

```graphql
type Dapp @entity {
  id: Bytes!
  name: String!
  cid: String
  owner: Bytes!
  status: String!
  rate: BigInt!
  weightVotesSum: BigInt!
  weightTotalSum: BigInt!
  balance: BigInt!
  burned: BigInt!
  votes: [Vote!]! @derivedFrom(field: "dapp")
  createdAt: BigInt!
  updatedAt: BigInt!
}

type Vote @entity {
  id: ID!
  dapp: Dapp!
  voter: Bytes!
  voteRate: BigInt!
  fanWeight: BigInt!
  timestamp: BigInt!
  blockNumber: BigInt!
}

type GlobalStat @entity {
  id: ID!
  totalDapps: Int!
  totalVotes: BigInt!
  totalBurned: BigInt!
  totalBalance: BigInt!
}
```

**Step 4: AI Agent with Subgraph MCP**

Install and configure the Subgraph MCP server:

```bash
# Clone and run the Subgraph MCP server
git clone https://github.com/graphprotocol/subgraph-mcp-server
cd subgraph-mcp-server
npm install
# Configure with your deployed subgraph endpoint
```

The MCP server exposes these tools:

- `search_subgraphs(keyword)` — Find relevant subgraphs
- `get_schema(subgraph_id)` — Inspect GraphQL schema
- `query_subgraph(subgraph_id, query)` — Run GraphQL queries
- `get_query_volume(subgraph_id)` — 30-day query volume

**Step 5: SKILLs (Optional Enhancement)**

Create reusable SKILLs following the Subgraphs SKILLs format:

- `dapprank-investor/SKILL.md` — How to query DappRank data for investor analysis
- Include example queries for: performance tracking, alerts, comparisons

---

#### Uniswap: DRNK Pool + SDK Swap

**Step 1: Deploy DRNK Liquidity Pool (Sepolia)**

- Use Uniswap v3 on Sepolia (deployed addresses via the Uniswap Deployments repo).
- Pool: DRNK/WETH (or DRNK/USDC if a USDC faucet is available on Sepolia).
- Provide initial liquidity via the `NonfungiblePositionManager` (mint position) or a simpler v2-style pool if v3 tooling is too heavy.

**Step 2: Frontend Swap (Uniswap SDK)**

```bash
npm install @uniswap/sdk-core @uniswap/v3-sdk
```

- Add a "Swap DRNK" action in `GetDRNK.svelte` / `DappRankList.svelte`:
  - Fetch quotes via the Uniswap API (`https://api.uniswap.org/v1/quote`)
  - Execute the swap with the user's wallet (router contract on Sepolia)
- Show DRNK price in the UI (from the pool's current `sqrtPriceX96`)

**Step 3: FEEDBACK.md (requisito del premio)**

- Create `FEEDBACK.md` documenting the Uniswap integration experience
- Submit the Uniswap feedback form (link in the Uniswap track page)

---

#### ENS: ENSv2 Name Resolution

> **Estado 2026-09-13:** pasos 2 y 3 implementados. Pendiente del equipo: registrar
> `dapprank.eth` en ENSv2 (Sepolia) y ejecutar `script/EnsSetup.s.sol`.

**Step 1: Register DappRank domain + subnames (Sepolia) — PENDIENTE (equipo)**

- ENSv2 is deployed on Sepolia. Register a domain (e.g., `dapprank.eth`) and subnames per dApp (`<dappname>.dapprank.eth`).
- Use the ENSv2 Permissioned Registry for subname management (role-based, replaces Name Wrapper fuses).
- **Script listo**: `script/EnsSetup.s.sol` despliega el subregistry (UserRegistry vía VerifiableFactory), lo conecta al nombre y registra subnames con sus PermissionedResolvers (records `dapprank.cid` + `addr` precargados). Alternativa: `ens-cli`.

**Step 2: Resolve names in the frontend — IMPLEMENTADO**

- `src/lib/ens.svelte.js`: `namehash`, `dnsEncode`, `dappEnsName`, `resolveTextRecord`, `resolveAddr`, `attachEnsNames` — resuelve vía `UpgradableUniversalResolverProxy` (`0xeEeE…EeEe`) con fallback a RPC público de Sepolia.
- `src/components/DappRankList.svelte` muestra el nombre ENS con badge "ENSv2" y fallback al `bytes32`.
- `src/lib/ethers.svelte.js`: `refreshDappsList()` enriquece la lista (no bloquea).

**Step 3: Agent queries — IMPLEMENTADO**

- `skills/dapprank-subgraph/SKILL.md` referencias dApps por nombre ENS (`<label>.dapprank.eth`).

---

### Risk Mitigation

| Risk                                     | Probability | Impact | Mitigation                                                                                   |
| ---------------------------------------- | ----------- | ------ | -------------------------------------------------------------------------------------------- |
| Uniswap pool deployment fails on Sepolia | Medium      | Medium | Use a v2-style pool or provide liquidity via the position manager. Test on local anvil first |
| ENSv2 subname registration friction      | Low         | Low    | Register only the main domain + a few demo subnames. Fallback: resolve names off-chain       |
| Subgraph indexing takes too long         | Low         | Medium | Use `startBlock` parameter to index from recent block. Test with small data first            |
| Time running out                         | Medium      | High   | Prioritize: The Graph (done) > Uniswap pool+swap > ENS resolution. Drop swap UI if needed    |

---

### Fallback Plan (If Time is Limited)

If only 1-2 days are available:

| Priority | Sponsor   | Minimum Viable Deliverable                             | Time    |
| -------- | --------- | ------------------------------------------------------ | ------- |
| **P0**   | The Graph | Subgraph deployed + AI Agent (COMPLETO) — solo video   | 0.5 day |
| **P1**   | Uniswap   | DRNK pool deployed + FEEDBACK.md (swap UI opcional)    | 1 day   |
| **P2**   | ENS       | Domain + subnames registrados + resolución en frontend | 0.5 day |

This still qualifies for all 3 prizes with a coherent submission.

---

## 7. Submission Requirements

### Hacker Dashboard Submission

1. **Project Title:** DappRank — Decentralized dApp Ranking & Investor Intelligence
2. **Description:** A decentralized ranking system for dApps using Square Root Weighted Voting (SRWV), enhanced with real-time data indexing, AI-powered investor analytics, DRNK liquidity on Uniswap, and human-readable dApp names via ENSv2.
3. **GitHub Repository:** Link to public repo
4. **Demo Video:** 2-4 minutes, 720p minimum

### README Structure

```markdown
# DappRank

## Pre-existing Code (before ETHOnline 2026)

- Smart contracts: DappsManager.sol, DRNK.sol, Conversor.sol
  - SRWV voting mechanism, dApp registration, token economics
  - Deployed on Ethereum Sepolia
- Frontend: Svelte 5 with wallet connection, voting UI, token buying
- IPFS integration via Helia

## New Work (during ETHOnline 2026)

### The Graph Integration

- Subgraph indexing all DappRank events (votes, registrations, burns)
- AI Agent using Subgraph MCP for natural language investor queries
- SKILLs for reusable DappRank analysis

### Uniswap Integration

- DRNK liquidity pool on Uniswap (Sepolia)
- In-app swap via Uniswap SDK/API
- FEEDBACK.md documenting the integration

### ENS Integration

- ENSv2 domain + subnames for dApp names (Sepolia)
- Human-readable names in ranking, votes, and agent queries
```

### Demo Video Script (2-4 minutes)

1. **0:00-0:30** — Intro: What is DappRank? SRWV voting, existing deployment
2. **0:30-1:30** — The Graph Subgraph: Show real-time data indexing, query examples
3. **1:30-2:30** — AI Agent: Natural language queries, investor insights, alerts
4. **2:30-3:00** — Uniswap: DRNK pool, in-app swap, token utility
5. **3:00-3:30** — ENS: Human-readable dApp names via ENSv2
6. **3:30-4:00** — Summary: Architecture, WOW factor, future roadmap

### Partner Prize Selection (Max 3)

In the submission form, select:

1. **The Graph** → Best AI Tooling or AI Use Case with The Graph (Continuity)
2. **Uniswap** → Best Uniswap Stack Contribution (Continuity)
3. **ENS** → Best Integration of ENSv2 into an Existing Project (Continuity)

---

## 8. Appendix: Source Code Map

### Smart Contracts (`src-sc/`)

| File               | Lines | Purpose                                                 |
| ------------------ | ----- | ------------------------------------------------------- |
| `DappsManager.sol` | ~349  | Main contract: voting, dApp management, token economics |
| `DRNK.sol`         | ~34   | ERC20 token with burn, permit, votes, access control    |
| `Conversor.sol`    | ~29   | bytes32/string conversion utilities                     |

### Frontend (`src/`)

| File                                | Purpose                                                |
| ----------------------------------- | ------------------------------------------------------ |
| `App.svelte`                        | Main layout, particle effects, component orchestration |
| `main.js`                           | Svelte mount point                                     |
| `app.css`                           | Global styles                                          |
| `lib/ethers.svelte.js`              | Web3 connection, contract state management             |
| `lib/helia.js`                      | IPFS/Helia initialization                              |
| `components/WalletConnector.svelte` | MetaMask wallet connection button                      |
| `components/DappRankList.svelte`    | Ranked dApp cards display                              |
| `components/DappsData.svelte`       | Refresh dApp data from contract                        |
| `components/Vote4Dapp.svelte`       | Voting popup UI                                        |
| `components/GetDRNK.svelte`         | Token purchase popup UI                                |
| `components/IPFSConnector.svelte`   | File upload to IPFS                                    |

### Scripts & Tests

| File                        | Purpose                         |
| --------------------------- | ------------------------------- |
| `script/DappsManager.s.sol` | Deployment script               |
| `script/DemoTest.s.sol`     | Demo data population script     |
| `test/DappsManager.t.sol`   | Test suite for voting mechanics |

### Configuration

| File               | Key Variables                                                                       |
| ------------------ | ----------------------------------------------------------------------------------- |
| `envexample`       | PROVIDER_URL, PK0-9, LISTINGFEE, BURNINGFEE, DAOFEE, BONUS, VITE_SMARTCONTRACTADDRS |
| `package.json`     | Dependencies: ethers v6, helia, svelte 5, vite 7                                    |
| `foundry.toml`     | Foundry configuration                                                               |
| `svelte.config.js` | Svelte adapter-static config                                                        |
| `vite.config.js`   | Vite build config                                                                   |

---

## Key URLs & Resources

| Resource                        | URL                                                                                 |
| ------------------------------- | ----------------------------------------------------------------------------------- |
| DappRank Website                | https://dapprank.decentralizedscience.org                                           |
| DappRank IPNS                   | https://gateway-mx.decentralizedscience.org/ipns/dapprank.decentralizedscience.org/ |
| DappsManager Contract (Sepolia) | https://sepolia.etherscan.io/address/0x6b0EB389DD4B3ad4E9a28f56f971735aD2A85baD     |
| DRNK Token (Sepolia)            | https://sepolia.etherscan.io/address/0x9549A8CcaB9fF25Cf5061bFBC5188Baed0615B60     |
| ETHOnline 2026 Prizes           | https://ethglobal.com/events/ethonline2026/prizes                                   |
| ETHOnline 2026 Info             | https://ethglobal.com/events/ethonline2026/info/start                               |
| ETHOnline 2026 Details          | https://ethglobal.com/events/ethonline2026/info/details                             |
| ETHOnline 2026 Resources        | https://ethglobal.com/events/ethonline2026/info/resources                           |
| The Graph Subgraph MCP          | https://thegraph.com/docs/en/subgraphs/tooling/subgraph-mcp/introduction/           |
| The Graph SKILLs                | https://github.com/graphprotocol/subgraphs-skills                                   |
| Substreams SKILLs               | https://github.com/streamingfast/substreams-skills                                  |
| Uniswap Docs                    | https://developers.uniswap.org/docs                                                 |
| Uniswap Deployments (Sepolia)   | https://github.com/Uniswap/deployments-v3                                           |
| ENSv2 Docs                      | https://docs.ens.domains/ensv2/overview                                             |
| Arc Docs                        | https://docs.arc.io/                                                                |
| Circle Agent Stack              | https://github.com/circlefin/agent-stack-starter-kits                               |
| Chainlink CRE Docs              | https://docs.chain.link/cre                                                         |
| Chainlink Price Feeds           | https://docs.chain.link/data-feeds                                                  |
| Bazantic                        | https://bazantic.com                                                                |

---

> **Note to future readers:** This document contains the complete context needed to understand DappRank's participation in ETHOnline 2026's Continuity Track. The optimal strategy (revisada 2026-09-13 por tiempo) es **The Graph ($2,500) + Uniswap ($1,000) + ENS ($500)** para un total potencial de **$4,000**, enfocada en transformar DappRank en una plataforma de inteligencia para inversores con indexación de datos en tiempo real, analítica con IA, utilidad de token vía Uniswap y nombres legibles vía ENSv2.
