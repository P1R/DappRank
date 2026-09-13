# DappRank × ENSv2 — Guía de setup para el equipo

> **Objetivo:** registrar el namespace `dapprank.eth` en ENSv2 (Sepolia) para que
> cada dApp del ranking tenga un nombre legible (`<dappname>.dapprank.eth`) y
> resuelva en la UI. Esto completa la integración del **premio ENS — Best
> Integration of ENSv2 into an Existing Project (Continuity)**.
>
> **Tiempo estimado:** 30–45 min. **Costo:** solo gas de Sepolia + USDC de
> testnet (sin valor real).

---

## 0. Qué necesitas antes de empezar

| Requisito                   | Detalle                                                                         |
| --------------------------- | ------------------------------------------------------------------------------- |
| Wallet (MetaMask o similar) | Conectada a **Sepolia**                                                         |
| USDC en Sepolia             | Para pagar el registro del dominio. Ver sección **0.1** (faucet o mint directo) |
| ETH en Sepolia              | Para el gas de las transacciones. Ver sección **0.1** (faucets)                 |
| Foundry instalado           | `forge --version` debe responder                                                |
| Repo clonado                | `git clone https://github.com/P1R/DappRank.git && cd DappRank`                  |

> ⚠️ **Importante:** la wallet que registre el dominio debe ser la **misma**
> que firme el script del paso 2 (o el script debe usar la clave privada de esa
> wallet). Si usas otra, el script fallará con permisos.

### 0.1 Conseguir fondos de prueba (Sepolia)

Todo es dinero falso de testnet — no cuesta nada real.

**ETH (para gas):**

- [Alchemy Sepolia faucet](https://sepoliafaucet.com) — 0.5 ETH/día
- [Infura Sepolia faucet](https://www.infura.io/faucet/sepolia)
- [Chainlink Sepolia faucet](https://faucets.chain.link/sepolia)

**USDC (para pagar el registro del dominio):**

Opción A — **mint directo del MockUSDC** (lo más rápido, sin faucet): el
contrato de prueba de ENSv2 acepta un USDC libremente minteable. Míntate el
que quieras (6 decimales, como el USDC real):

```bash
# MockUSDC en Sepolia: 0xd3322b29a7bdee707d1684676f149bf41aa3422f
# 1000 USDC = 1000 * 10^6 = 1000000000
cast send 0xd3322b29a7bdee707d1684676f149bf41aa3422f \
  "mint(address,uint256)" $TU_DIRECCION 1000000000 \
  --rpc-url $SEPOLIA_RPC_URL --private-key $PRIVATE_KEY
```

Opción B — **faucet oficial de Circle**: [faucet.circle.com](https://faucet.circle.com)
(red Sepolia, token USDC).

> El registro anual de un nombre `.eth` en Sepolia cuesta unos pocos USDC de
> prueba (el precio lo fija el `StandardRentPriceOracle` de ENSv2).

---

## 1. Registrar tu dominio en ENSv2 (Sepolia)

> ⚠️ **No uses `app.ens.domains`** — ese es el app de **mainnet** (ENSv1, dinero
> real). ENSv2 solo existe en **Sepolia** y sus apps de testnet son:
>
> - **Explorer** (para power users): **https://explorer.ens.dev**
> - **App** (flujo más simple): **https://app.ens.dev**
>
> Ambas están en Sepolia. Si tu wallet no está en Sepolia, te pedirán cambiarla.

1. Abre **https://explorer.ens.dev** (o `app.ens.dev`) y conecta tu wallet.
2. Cambia la red a **Sepolia** (la app te lo pedirá).
3. Busca el nombre que quieras (ej. **`dapprank`**) en el buscador:
   - Si dice **Available** → regístralo.
   - Si dice **Registered** (ya lo tiene otra persona) → **no pasa nada**, es
     una testnet: elige otro nombre libre (ej. `dapprankapp`, `dapprankdao`,
     `dapprankrank`). El premio no exige un nombre específico.
4. Haz clic en **Register** y sigue el flujo (2 transacciones: commit + reveal,
   con ~60s de espera entre ambas). El pago se hace en **USDC** — aprueba el
   token cuando lo pida.
5. Al terminar, verifica que el nombre aparece como tuyo en el Explorer
   (pestaña del nombre).

> 💡 **Anota el nombre que registraste** — lo necesitas en el paso 2 como
> `ENS_DOMAIN` y en el frontend como `VITE_DAPPRANK_ENS_DOMAIN`.

---

## 2. Ejecutar el setup on-chain

El script `script/EnsSetup.s.sol` hace todo lo demás automáticamente:

1. Despliega un **UserRegistry** (subregistry) para `dapprank.eth` vía la
   `VerifiableFactory` de ENSv2 (dirección determinista).
2. Lo conecta al nombre (`ETHRegistry.setSubregistry` + `setParent`).
3. Por cada dApp demo registra un subname `<label>.dapprank.eth` con su
   **PermissionedResolver**, precargando los records:
   - `addr` → owner de la dApp
   - `dapprank.cid` → CID IPFS de la dApp

### 2.1 Configura el `.env`

```bash
cp envexample .env
```

Edita `.env` y asegúrate de que estas variables estén correctas:

```bash
SEPOLIA_RPC_URL="https://eth-sepolia.g.alchemy.com/v2/TU_API_KEY"
PRIVATE_KEY="la_clave_privada_de_la_wallet_que_registro_dapprank.eth"
```

> ⚠️ `PRIVATE_KEY` debe ser la clave de la **misma cuenta** que registró el
> dominio en el paso 1. Nunca compartas este archivo ni lo subas al repo.

### 2.2 Compila y ejecuta

```bash
forge build

source .env

# El nombre que registraste en el paso 1 (default: dapprank)
export ENS_DOMAIN="dapprankapp"

forge script script/EnsSetup.s.sol:EnsSetupScript \
  --rpc-url $SEPOLIA_RPC_URL \
  --private-key $PRIVATE_KEY \
  --broadcast
```

### 2.3 Salida esperada

```
dapprank.eth tokenId: <número>
Subregistry (UserRegistry): 0x...
Subregistry conectado a dapprank.eth
Subname registrado: desci.dapprank.eth
  owner: 0x...
  resolver: 0x...
  dapprank.cid: bafybeidt6pwzf2n3q7gab6axfyh2bqhkobawtdbnrpgasfex4geqahcjsa
Subname registrado: search.dapprank.eth
...
```

### 2.4 Personalizar las dApps (opcional)

Por defecto registra las 4 dApps demo (`desci`, `search`, `nethunters`,
`deca`) con los CIDs de `envexample`. Para cambiarlas:

```bash
export ENS_DAPPS="mydapp:0xTuDireccion:cid_ipfs,otra:0xOtraDireccion:cid2"
forge script script/EnsSetup.s.sol:EnsSetupScript \
  --rpc-url $SEPOLIA_RPC_URL --private-key $PRIVATE_KEY --broadcast
```

Formato: `label:owner:cid` separados por coma. `owner` o `cid` vacíos usan
defaults (owner = tu wallet, sin record de CID).

---

## 3. Verificar

### 3.1 En la app

```bash
bun install
# En .env: VITE_DAPPRANK_ENS_DOMAIN="dapprankapp.eth" (el nombre que registraste)
bun run dev --open
```

Conecta la wallet y refresca el ranking: cada dApp debe mostrar su nombre ENS
(`desci.dapprankapp.eth`) con un badge **ENSv2**. Si ves el nombre en `bytes32`
(hex), el subname no está registrado o la resolución falló.

### 3.2 On-chain (sin UI)

```bash
# El subname debe existir en el subregistry de dapprank.eth
cast call 0x67b728a792e789a8978b30cF1b3b641f19354b43 \
  "getSubregistry(string)(address)" "dapprank" \
  --rpc-url $SEPOLIA_RPC_URL

# Resolver el record dapprank.cid de desci.dapprank.eth vía UniversalResolverV2
# (0xeEeEEEeE14D718C2B47D9923Deab1335E144EeEe)
```

### 3.3 En el Explorer

Abre https://explorer.ens.dev, busca `desci.dapprank.eth` y verifica que
aparece con su owner, resolver y records.

---

## 4. Alternativa: `ens-cli` (oficial de ENS)

Si prefieres la CLI oficial de ENS en vez del script de Foundry:

```bash
# Instalar
git clone https://github.com/ensdomains/ens-cli && cd ens-cli && npm install

# Registrar el dominio (commit-reveal, pago en USDC)
ens register dapprank.eth --chain sepolia

# Crear el subregistry y conectarlo al nombre
ens subregistry deploy dapprank.eth --chain sepolia
ens subregistry set dapprank.eth --chain sepolia

# Crear subnames
ens subname create desci.dapprank.eth --chain sepolia
ens subname create search.dapprank.eth --chain sepolia
```

> El script de Foundry del repo hace exactamente esto + precarga los records
> (`dapprank.cid`, `addr`) en un solo comando, así que es la vía recomendada.

---

## 5. Troubleshooting

| Error / síntoma                                           | Causa probable                                           | Solución                                                                                                                               |
| --------------------------------------------------------- | -------------------------------------------------------- | -------------------------------------------------------------------------------------------------------------------------------------- |
| `<dominio>.eth no esta registrado en ENSv2 (Sepolia)`     | El dominio no se registró, o se registró con otra cuenta | Completa el paso 1 con la misma wallet que firma el script                                                                             |
| `CallerNotAdmin` / revert de permisos en `setSubregistry` | La cuenta que firma no es el owner del dominio           | Usa `PRIVATE_KEY` de la cuenta que registró el dominio                                                                                 |
| `LabelAlreadyRegistered`                                  | El subname ya existe (script corrido antes)              | Es idempotente por diseño parcial: los subnames ya creados fallan; usa labels nuevos o borra los existentes                            |
| La UI muestra hex en vez del nombre ENS                   | Subname no registrado o RPC público caído                | Verifica con el paso 3.2; el frontend cae a `bytes32` como fallback                                                                    |
| Sin USDC para registrar                                   | No tienes USDC de prueba                                 | Mint directo del MockUSDC (`0xd3322b29a7bdee707d1684676f149bf41aa3422f`, función `mint`) o faucet de Circle: https://faucet.circle.com |

---

## 6. Referencias

- Direcciones canónicas ENSv2 Sepolia: `contracts/docs/addresses/sepolia.md` en
  [ensdomains/contracts-v2](https://github.com/ensdomains/contracts-v2)
- Docs ENSv2: https://docs.ens.domains/ensv2/overview
- Página del premio ENS (ETHOnline 2026): https://ethglobal.com/events/ethonline2026/prizes/ens
- Código de la integración: `src/lib/ens.svelte.js`, `script/EnsSetup.s.sol`,
  sección "ENS Integration" del `README.md`
