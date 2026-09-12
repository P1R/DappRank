# DappRank Subgraph

Subgraph para [The Graph](https://thegraph.com) que indexa los eventos de
`DappsManager.sol` en Sepolia. Es la columna vertebral de datos de DappRank:
el frontend lee el ranking desde aquí y el agente IA (Subgraph MCP) hace
razonamiento en lenguaje natural sobre los datos indexados.

## Entidades

| Entidad      | Descripción                                                                 |
| ------------ | --------------------------------------------------------------------------- |
| `Dapp`       | Una dApp registrada: rating SRWV, balance, burned, estado, owner, CID       |
| `Vote`       | Un voto individual: votante, `voteRate` (Vi), `fanWeight` (√Ti), timestamp  |
| `GlobalStat` | Métricas globales: total dapps, votos, DRNK quemado, balance total          |

## Eventos indexados

`DappRegistered`, `DappApproved`, `DappBanned`, `VoteCast`, `TokensBurned`,
`DappCashOut`, `DappRemoved`, `DappCIDUpdated` — todos emitidos por el contrato
`DappsManager.sol` (integrados en 2026-09-12).

> Nota: `VoteCast` incluye `amount` (desviación de la estrategia) para que el
> mapping pueda calcular el delta de balance. `burnFee` (1000 bp) y `DAOFee`
> (100 bp) son constantes de despliegue (sin setters), por lo que el mapping
> las usa como constantes.

## Requisitos

- Node.js 18+ / bun
- Una cuenta en [Subgraph Studio](https://thegraph.com/studio/) con un subgraph
  creado (slug `dapprank` o el que uses)
- El contrato **redeployado** en Sepolia con eventos (el despliegue actual
  `0xD60DC0805f44d10cAc6594f1a501c67929448957` NO emite eventos)

## Pasos de despliegue

```bash
# 1. Compilar el contrato y copiar el ABI (ya hecho, pero repetir si cambia)
cd ..
forge build
cp out/DappsManager.sol/DappsManager.json subgraph/abis/DappsManager.json
cd subgraph

# 2. Instalar dependencias
bun install   # o: npm install

# 3. Configurar subgraph.yaml
#    - source.address  -> dirección del NUEVO contrato en Sepolia
#    - source.startBlock -> bloque de despliegue (para indexado rápido)

# 4. Generar tipos + compilar
bun run codegen
bun run build

# 5. Autenticar y desplegar a Subgraph Studio
graph auth --studio <DEPLOY_KEY>
bun run deploy   # despliega el slug "dapprank"
```

## Consumir el subgraph

Endpoint de Subgraph Studio (formato):

```
https://api.studio.thegraph.com/query/<SLUG>/<VERSION>
```

Ejemplo de query:

```graphql
{
  dapps(orderBy: rate, orderDirection: desc) {
    id
    name
    status
    rate
    weightTotalSum
    balance
    burned
  }
  globalStat(id: "global") {
    totalDapps
    totalVotes
    totalBurned
  }
}
```

El frontend lee este endpoint vía `src/lib/subgraph.svelte.js`
(variable de entorno `VITE_SUBGRAPH_URL`), con fallback a lecturas directas del
contrato si el subgraph no está disponible.

## Agente IA (Subgraph MCP)

1. Clona y ejecuta el servidor MCP:
   ```bash
   git clone https://github.com/graphprotocol/subgraph-mcp-server
   cd subgraph-mcp-server
   npm install
   ```
2. Configúralo con el endpoint del subgraph desplegado.
3. Herramientas disponibles: `search_subgraphs`, `get_schema`, `query_subgraph`,
   `get_query_volume`.

Preguntas de ejemplo para el agente:

- "¿Qué dapp tiene el rating más alto?"
- "¿Qué dapp ha quemado más DRNK esta semana?"
- "¿Cómo ha evolucionado el rating de dapp X?"
- "¿Cuál es la presión deflacionaria total de DRNK?"

## Desarrollo local (opcional)

Con un nodo local de The Graph (graph-node + IPFS):

```bash
bun run create-local
bun run deploy-local
```
