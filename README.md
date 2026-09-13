# DappRank

Status Deployet at Sepolia:

[DappRank Website dnsLink](https://dapprank.decentralizedscience.org)

[ipns](https://gateway-mx.decentralizedscience.org/ipns/dapprank.decentralizedscience.org/)

IPFS CID: bafybeidzfwsyugg4yxp46t6ag7ikjz43kh6oqgkxh2h5p2qynzjey4tipu

Dapps contract address is: [0x6b0EB389DD4B3ad4E9a28f56f971735aD2A85baD](https://sepolia.etherscan.io/address/0x6b0EB389DD4B3ad4E9a28f56f971735aD2A85baD)

DRNK Token contract address is: [0x9549A8CcaB9fF25Cf5061bFBC5188Baed0615B60](https://sepolia.etherscan.io/address/0x9549A8CcaB9fF25Cf5061bFBC5188Baed0615B60)

## ETHOnline 2026 — The Graph Prize Submission

**Prize:** 🤖 Best AI Tooling or AI Use Case with The Graph — **Continuity pool** ($5,000)

**Live subgraph endpoint:** [https://api.studio.thegraph.com/query/1760241/dapprank/v0.0.2](https://api.studio.thegraph.com/query/1760241/dapprank/v0.0.2)

**Demo video:** [link to 2–4 min video](<>)

### Qualification checklist

| Requirement                            | Where it's met                                                                                                                                                 |
| -------------------------------------- | -------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| The Graph as load-bearing data source  | `subgraph/` indexes `DappsManager` events; frontend and AI agent read from it                                                                                  |
| Live data from a Graph provider        | Subgraph deployed on Subgraph Studio (Sepolia) — queryable live, no mocked data                                                                                |
| Meaningful work with the data          | [`skills/dapprank-subgraph/SKILL.md`](./skills/dapprank-subgraph/SKILL.md) — natural-language interface with reasoning (whale analysis, deflationary pressure) |
| Open-source with clear README/SKILL.md | This README + the agent skill                                                                                                                                  |
| Public repo + demo video               | This repo + video link above                                                                                                                                   |

### Pre-existing Code (before hackathon)

- DappRank contracts (`src-sc/DappsManager.sol`, `src-sc/DRNK.sol`) — SRWV ranking + DRNK token
- Frontend (Svelte) — ranking UI, wallet connect, vote/buy/register modals
- Contract test suite (`test/DappsManager.t.sol`)

### New Work (during hackathon)

- **The Graph events** integrated into `DappsManager.sol` — 8 events (`DappRegistered`, `DappApproved`, `DappBanned`, `VoteCast`, `TokensBurned`, `DappCashOut`, `DappRemoved`, `DappCIDUpdated`)
- **Subgraph** (`subgraph/`) — schema, AssemblyScript mapping, manifest; deployed to Subgraph Studio
- **Frontend subgraph integration** — ranking reads from The Graph with contract fallback (`src/lib/subgraph.svelte.js`)
- **Bug fixes** — `dappCashOut` balance accounting; DRNK emission inflation (see [`FIX_MULTIPLIER.md`](./FIX_MULTIPLIER.md))
- **AI Agent Skill** ([`skills/dapprank-subgraph/SKILL.md`](./skills/dapprank-subgraph/SKILL.md)) — natural-language interface to live ranking data

### How judges can run it

```bash
# 1. Query the live subgraph (no key needed)
curl -s -X POST "https://api.studio.thegraph.com/query/1760241/dapprank/v0.0.2" \
  -H "Content-Type: application/json" \
  -d '{"query":"{ dapps(orderBy: rate, orderDirection: desc) { name status rate } }"}'

# 2. Run the contract tests (validates the events the subgraph consumes)
forge test

# 3. Build the subgraph
cd subgraph && bun run codegen && bun run build

# 4. Use the AI agent skill (any MCP client)
#    Point your agent at skills/dapprank-subgraph/SKILL.md and ask:
#    "Which dapp has the highest rating?"
```

The DappRank DeFi model introduces a revolutionary decentralized ranking system
for dapps using a novel voting mechanism called Square Root Weighted Voting
(SRWV). This system addresses the critical issue of whale manipulation in
decentralized governance while establishing the foundation for an
"ultrasound money model" that aims to decrease token supply over time,
similar to how Ethereum's supply decreases through the "ultrasound money"
concept.

![Use Case Diagram of DappRank](./models/use_case.svg)

Img 1. Shows Use Case of DappRank

The SRWV model provides a mathematically sound solution for decentralized
governance while aligning with the ultrasound money model's deflationary goals.
By implementing the square root function for voting power calculation, DappRank
achieves:

- Fairer distribution of governance influence
- Protection against whale manipulation
- Sustainable tokenomics through supply reduction mechanisms [2][3]

## Square Root Weighted Voting (SRWV) Mathematical Formalization

The SRWV system in DappRank implements a mathematically rigorous approach to
decentralized governance. The core mechanism is defined by the following
equations:

### Voting Power Calculation

$$
W_i = \sqrt{T_i}
$$

Where:

- $W_i$: Fan weight (voting power) of voter $i$
- $T_i$: Tokens staked by voter $i$ [2]

This equation ensures voting power grows sublinearly with token holdings, reducing the influence of large stakeholders [2].

### Final Dapp Rating Calculation

$$
D_r = \frac{S_{vw}}{S_{wt}} = \frac{\sum_{i} (V_i \times \sqrt{T_i})}{\sum_{i} \sqrt{T_i}}
$$

Where:

- $D_r$: Final rating of dApp $D$
- $V_i$: Vote rate assigned by voter $i$ (0 < $V_i$ ≤ 100)
- $S_{vw}$: Sum of weighted votes $\sum_{i} (V_i \times \sqrt{T_i})$
- $S_{wt}$: Sum of total weights $\sum_{i} \sqrt{T_i}$ [2]

### Implementation Context

1. **Fan Weight Execution**: The `voteDapp` function in `DappsManager.sol` calculates fan weight using `Math.sqrt(_amount, Math.Rounding.Ceil)` to approximate $ \sqrt{T_i} $ [2]
2. **Weighted Vote Aggregation**: The contract maintains running totals:
   - `dapp.weight_votes_sum += (vote.vote_rate * vote.fan_weight)`
   - `dapp.weight_total_sum += vote.fan_weight` [2]
3. **Rating Finalization**: The final dApp rating is computed as `dapp.rate = dapp.weight_votes_sum / dapp.weight_total_sum` [2]

## Test Validation [3]

The test suite in `DappsManager.t.sol` provides empirical validation:

- For 5 test users with dynamic voting amounts, the system correctly calculates:
  - `weight_votes_sum = 6,380,084,467,978`
  - `weight_total_sum = 106,138,700,962`
  - Final rating `rate = 60` (calculated as $ 6,380,084,467,978 / 106,138,700,962 $) [3]

## Ultrasound Money Model Integration

The SRWV mechanism directly supports the ultrasound money model through:

1. **Deflationary Burning**: A portion of voting tokens is burned during reward distribution [2]
2. **Supply Control**: Token supply reduction via:
   - Listing fees burned during dApp registration
   - Voting rewards partially burned [2]
3. **Dynamic Equilibrium**: The square root function ensures token utility remains balanced between governance power and scarcity [2]

## Security and Governance Implications

1. **Whale Resistance**: The mathematical properties of $ \sqrt{T_i} $ create diminishing returns for large token holders:
   - 1,000 tokens = 31.6 votes
   - 10,000 tokens = 100 votes [2]
2. **Equity Preservation**: Small token holders maintain proportional influence relative to large stakeholders
3. **Game-Theoretic Stability**: The system creates natural disincentives for vote manipulation through its mathematical structure [2]

## [WhitePaper](./WP.md)

![Sequence Diagram of the Voting Process](./models/demo.svg)

Img 2. Shows Sequence Diagram of the Voting Process

which also includes a Demo test process to understand the Voting and other procedures.

## AI Agent Skill

[`skills/dapprank-subgraph/SKILL.md`](./skills/dapprank-subgraph/SKILL.md) is an
agent skill that lets any AI assistant (Claude, Cursor, Zed, etc.) answer
natural-language questions about the live DappRank ranking — ratings, votes,
DRNK burns, deflationary pressure, and whale analysis — by querying the
subgraph on The Graph protocol. Judges and teammates can run it directly.

## Install requirements

- bun
- foundry
- git

> Note: tested on linux

## Install

```shell
# --recurse-submodules trae lib/openzeppelin-contracts (necesario para forge build)
$ git clone --recurse-submodules https://github.com/P1R/DappRank.git
```

> Si ya clonaste sin submodules: `git submodule update --init`

```shell
$ cd DappRank
```

install frontend requirements

```shell
$ bun install
```

configura el entorno (variables públicas, sin llaves privadas)

```shell
$ cp envexample .env
#   Editar con:
#   VITE_SMARTCONTRACTADDRS="0x6b0EB389DD4B3ad4E9a28f56f971735aD2A85baD"
#   VITE_SUBGRAPH_URL="https://api.studio.thegraph.com/query/1760241/dapprank/v0.0.2"
#   VITE_DAPPRANK_ENS_DOMAIN="dapprank.eth"
#   VITE_ENS_REGISTRAR_ADDRESS="0xb43c137FbeCf425Ef4E294C9b3dAfE5319c3c389"
```

## Frontend Development & Deployment

run the development mode

```shell
$ bun run dev --open
```

build para producción (genera los ABIs con forge + compila el frontend)

```shell
$ bun run build    # → dist/
```

to host the site use either fleek, piñata or nft.storage — sube **solo la
carpeta `dist/`** (los JSON de `out/` y `broadcast/` son intermedios de
compilación, no se suben).

> ⚠️ **Los contratos ya están desplegados en Sepolia** (DappsManager,
> subregistry ENSv2 y helper de registro automático). Para desplegar el sitio
> **no hace falta ejecutar ningún script on-chain ni tener llaves privadas** —
> solo `bun run build` y subir `dist/` a IPFS. Los scripts de `script/` son
> solo para el equipo (requieren `PRIVATE_KEY`).

## Foundry Usage

### Build

```shell
$ forge build
```

### Test

```shell
$ forge test
```

## Smart Contracts Deployment testing

use tmux or in an alternative shell run anvil

```shell
$ anvil --host 0.0.0.0
```

source the .env which contains the deployment variables
for further information check the [envexample](./envexample) file

```shell
$ source .env
```

execute the deployment script

```shell
$ forge script script/DappsManager.s.sol:DappsManagerScript  --rpc-url $PROVIDER_URL --private-key $PK0 --broadcast
```

execute the DemoTest script which will add some demo dapps to the blockchain set in the .env
and retrive them also it will mint some tokens for specified accounts for playing with it:

```shell
$ forge script script/DemoTest.s.sol:DemoTestScript  --rpc-url $PROVIDER_URL --private-key $PK0 --broadcast
```

## References

1. [DRNK](./src-sc/DRNK.sol)
2. [DappsManager](./src-sc/DappsManager.sol)
3. [Demo test](./test/DappsManager.t.sol)
4. https://ethereum.stackexchange.com/questions/87451/solidity-error-struct-containing-a-nested-mapping-cannot-be-constructed

## The Graph Integration (ETHOnline 2026)

DappRank usa [The Graph](https://thegraph.com) como columna vertebral de datos:
un subgraph indexa los eventos de `DappsManager.sol` en Sepolia y alimenta tanto
el ranking del frontend como un agente IA (Subgraph MCP) para análisis en
lenguaje natural.

### Estado

- [x] Eventos integrados y desplegados en `DappsManager.sol` (2026-09-13)
- [x] Proyecto subgraph en [`subgraph/`](./subgraph/README.md)
- [x] Frontend preparado para leer del subgraph con fallback al contrato (`src/lib/subgraph.svelte.js`)
- [x] Contrato redeployado en Sepolia con eventos (`0x6b0EB389DD4B3ad4E9a28f56f971735aD2A85baD`)
- [x] Subgraph desplegado en Subgraph Studio (`1760241`, v0.0.2)
- [x] AI Agent Skill creado ([`skills/dapprank-subgraph/SKILL.md`](./skills/dapprank-subgraph/SKILL.md))
- [ ] Demo video (2–4 min)

### Contrato

`DappsManager.sol` emite los eventos `DappRegistered`, `DappApproved`,
`DappBanned`, `VoteCast`, `TokensBurned`, `DappCashOut`, `DappRemoved` y
`DappCIDUpdated`. `VoteCast` incluye `amount` para que el subgraph calcule el
delta de balance. `dappCashOut()` descuenta `dapp.balance` (contabilidad en
sync). También se corrigió la emisión inflacionaria de DRNK (el `multiplier`
de los fans se inicializa en `1`, ver [`FIX_MULTIPLIER.md`](./FIX_MULTIPLIER.md)).

### Subgraph

Ver [`subgraph/README.md`](./subgraph/README.md) para el despliegue. El
frontend consulta el endpoint vía `VITE_SUBGRAPH_URL` (ver `envexample`); si no
está disponible, cae a lecturas directas del contrato.

### Agente IA

El [Subgraph MCP](https://thegraph.com/docs/en/subgraphs/tooling/subgraph-mcp/introduction/)
permite consultar el subgraph en lenguaje natural: rankings, tendencias de
quema, presión deflacionaria, etc. Configurar con el endpoint del subgraph
desplegado.

## ENS Integration (ETHOnline 2026)

DappRank integra [ENSv2](https://docs.ens.domains/ensv2/overview) (beta en
Sepolia) para dar a cada dApp una identidad legible: `<dappname>.dapprank.eth`.
El contrato guarda nombres `bytes32` opacos; ENSv2 los convierte en nombres
humanos resolubles on-chain.

### Estado

- [x] Capa de resolución ENSv2 en el frontend (`src/lib/ens.svelte.js`) — `namehash`, `dnsEncode`, `resolveTextRecord`, `resolveAddr`, `attachEnsNames`
- [x] Ranking muestra nombres ENS con badge "ENSv2" y fallback a `bytes32` (`src/components/DappRankList.svelte`)
- [x] Script de setup on-chain (`script/EnsSetup.s.sol`) — subregistry + subnames + records
- [x] `dapprank.eth` registrado en ENSv2 (Sepolia) — owner `0x934a406B7CAB0D8cB3aD201f0cdcA6a7855F43b0` (2026-09-13)
- [x] Subnames `<dappname>.dapprank.eth` registrados (desci, search, nethunters, deca) — subregistry `0x1677CAc3620C9E55D60228b4000D2820CC246179`
- [x] **Registro automático**: al registrar una dApp en la app, se crea su subname ENSv2 automáticamente vía `DappRankEnsRegistrar` (`0xb43c137FbeCf425Ef4E294C9b3dAfE5319c3c389`) — una sola transacción, sin intervención humana

### Cómo funciona

1. **Resolución**: el frontend llama a `UniversalResolverV2`
   (`0xeEeEEEeE14D718C2B47D9923Deab1335E144EeEe`, entry point canónico de
   ENSv2 en Sepolia) con el nombre DNS-encoded y el selector de `text()`/
   `addr()`. Si el subname existe, muestra el nombre ENS y el record
   `dapprank.cid`; si no, cae al `bytes32`.
2. **On-chain**: `script/EnsSetup.s.sol` despliega un `UserRegistry`
   (subregistry) para `dapprank.eth` vía `VerifiableFactory`, lo conecta al
   nombre (`setSubregistry` + `setParent`), y registra un subname por dApp con
   su `PermissionedResolver` (records `dapprank.cid` y `addr` precargados en
   `initialize()`).
3. **Registro automático**: cuando un usuario registra una dApp en la app
   (`RegisterDappModal.svelte`), después de `registerDapp()` el frontend llama
   a [`DappRankEnsRegistrar`](./src-sc/DappRankEnsRegistrar.sol)
   (`0xb43c137FbeCf425Ef4E294C9b3dAfE5319c3c389`) — una sola transacción que
   despliega el resolver del subname y lo registra en el subregistry. Sin
   consola ni intervención humana. Si falla (label con `.`, subname ya
   existente), la dApp igual queda registrada en el contrato (best-effort).

### Pasos para el equipo (requieren wallet + USDC en Sepolia)

> 📋 Guía paso a paso para el equipo: [`docs/ENS_SETUP_GUIDE.md`](./docs/ENS_SETUP_GUIDE.md)

**Enlaces útiles:**

- [ENS Explorer v2 (registrar dominio, red Sepolia)](https://explorer.ens.dev) — ⚠️ no usar `app.ens.domains` (ese es mainnet/ENSv1)
- [ENS App v2 (alternativa, red Sepolia)](https://app.ens.dev)
- [Faucet ETH de Alchemy (Sepolia)](https://sepoliafaucet.com) · [Infura](https://www.infura.io/faucet/sepolia) · [Chainlink](https://faucets.chain.link/sepolia)
- [Faucet USDC de Circle (Sepolia)](https://faucet.circle.com) — o mint directo del MockUSDC (`0x768f42455a2d082e23ceef7d51e5787c82d67a39`, función `mint`, 6 decimales)
- [Docs ENSv2](https://docs.ens.domains/ensv2/overview)
- [Página del premio ENS (ETHOnline 2026)](https://ethglobal.com/events/ethonline2026/prizes/ens)

> ⚠️ **Si `dapprank.eth` ya está registrado en Sepolia por otra cuenta** (es
> una testnet: cualquiera puede registrar cualquier nombre con USDC de prueba),
> no importa para el premio — solo usa otro nombre libre. Configúralo en dos
> lugares y listo:
>
> ```bash
> # script/EnsSetup.s.sol -> se lee de env (default "dapprank")
> export ENS_DOMAIN="dapprankapp"
>
> # frontend -> .env
> VITE_DAPPRANK_ENS_DOMAIN="dapprankapp.eth"
> ```

```bash
# 1. Registrar <dominio>.eth en el ENS Explorer v2 (red Sepolia, pago en USDC)
#    https://explorer.ens.dev  (NO app.ens.domains — ese es mainnet)

# 2. Ejecutar el setup on-chain (subregistry + subnames + records)
source .env
export ENS_DOMAIN="dapprankapp"   # o el nombre libre que registraste
forge script script/EnsSetup.s.sol:EnsSetupScript \
  --rpc-url $SEPOLIA_RPC_URL --private-key $PK0 --broadcast

# Alternativa con ens-cli (oficial de ENS):
#   ens register dapprankapp.eth --chain sepolia
#   ens subregistry deploy dapprankapp.eth --chain sepolia
#   ens subregistry set dapprankapp.eth --chain sepolia
#   ens subname create desci.dapprankapp.eth --chain sepolia
```

### Verificación

```bash
# El subname debe resolver el record dapprank.cid
curl -s -X POST "https://ethereum-sepolia-rpc.publicnode.com" \
  -H "Content-Type: application/json" \
  -d '{"jsonrpc":"2.0","method":"eth_call","params":[{"to":"0xeEeEEEeE14D718C2B47D9923Deab1335E144EeEe","data":"0x"}],"id":1}'
# O simplemente abrir la app: el ranking muestra desci.dapprank.eth con badge ENSv2
```

### Direcciones ENSv2 Sepolia (canonical, deployment 2026-07-30 — verificado on-chain)

> Fuente: https://docs.ens.domains/learn/deployments/ (el doc del repo
> `contracts-v2/docs/addresses/sepolia.md` quedó desactualizado en 2026-06-29).

| Contrato                         | Dirección                                    |
| -------------------------------- | -------------------------------------------- |
| UpgradableUniversalResolverProxy | `0xeEeEEEeE14D718C2B47D9923Deab1335E144EeEe` |
| ETHRegistry                      | `0xBDC85dD5b15D7ecb354cd7cb6f2c50b4f2c4F0E2` |
| UserRegistryImpl                 | `0x624a25d67B59D587752EbEc8DdeD8827dAe52050` |
| PermissionedResolverImpl         | `0x9EAe5C2730a7dD16BDD1DeE6421a1B91e3B0365e` |
| VerifiableFactory                | `0x10dC6333CDFe1FCEf624c6e0a8221b91804Cd7ef` |
