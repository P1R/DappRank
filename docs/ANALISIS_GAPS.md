# DappRank — Análisis de huecos y áreas de oportunidad

> ## 📦 HISTÓRICO (2026-09-06)
>
> **Documento de planificación conservado como evidencia del proceso.** Los
> huecos identificados aquí fueron abordados durante el hackathon (eventos de
> The Graph, subgraph, skill de agente, fixes). **No actuar sobre este documento**
> — consultar el estado actual en `README.md` y `AI_USAGE.md`.

> Revisión del proyecto (contratos en `src-sc/`, frontend en `src/`, tests y docs de estrategia).
> El proyecto está bien documentado y tiene una base sólida, pero hay varios huecos reales.
> Ordenados por prioridad.

---

## 🔴 1. Seguridad y bugs en el contrato (lo más urgente)

### `dappCashOut` permite drenar fondos de otras dApps — `src-sc/DappsManager.sol:269`

El contrato guarda el DRNK de **todas** las dApps en un único saldo. `dappCashOut` solo valida `owner` y `status`, pero **no comprueba que `_amount <= dapp.balance`**. Un owner podría retirar más de lo que su dApp tiene, robando el saldo de las demás. Es una vulnerabilidad real.

### `voteDapp` permite inflar el peso votando repetidamente — `src-sc/DappsManager.sol:232`

El `Vote` se guarda por votante (`dapp.votes[msg.sender]`), pero `weight_votes_sum` y `weight_total_sum` **se acumulan** en cada llamada. Un usuario puede votar N veces y sumar su `√T` N veces, rompiendo el modelo anti-ballena del SRWV. Falta un chequeo tipo "solo un voto activo por votante" (restar el voto anterior antes de sumar el nuevo).

### Otros huecos del contrato

- `rateDapp()` está vacío (`:186`) — dead code que conviene eliminar o implementar.
- `DAOAddrss = msg.sender` hardcodeado en el constructor (`:92`) — el propio código lo marca como "temporal patch".
- Los fees (`listingFee`, `DAOFee`, `burnFee`) se fijan en el constructor y **no son actualizables** → no hay gobernanza del modelo "ultrasound" que promete el whitepaper.
- `expiredDapp` está comentado (`:173`) → el estado `Expired` nunca se usa en la práctica.
- `buyDRNK` es un mecanismo temporal (`topUpExpires`) que no es una venta real de tokens; en mainnet no funcionará.

---

## 🟠 2. Eventos en el contrato (bloquea las integraciones planeadas)

El contrato **no emite ningún `event`**. La estrategia (`ETHOnline2026_Strategy.md`) planea un subgraph de The Graph indexando `DappRegistered`, `VoteCast`, `TokensBurned`, etc. Sin eventos, ese subgraph no puede indexar nada sin re-deployar el contrato. Añadir eventos (`emit`) es barato y desbloquea The Graph, Chainlink y cualquier indexador.

---

## 🟡 3. Frontend — UX y robustez

- **Voto por texto libre** (`Vote4DappModal.svelte:141`) en vez de un `<select>` con las dApps ya cargadas en `ethVars.dappsList` — propenso a errores de tipeo (ya está en el plan UI/UX, Fase 2).
- **Sin botón de voto contextual** en cada card (el plan lo contempla).
- **Sin preview del poder de voto** (`√amount`) ni simulación del rating resultante — es el corazón conceptual del producto y hoy es invisible.
- **Carga N+1 sin paginación** (`ethers.svelte.js:158`): hace `getAllDappNames()` + `getDappInfo()` por cada dApp. Con muchas dApps se degrada.
- **Sin detección de red**: no verifica que el usuario esté en Sepolia; si está en otra chain, las llamadas fallan de forma confusa.
- **Gateway IPFS hardcodeado a `ipfs.io`** (`DappRankList.svelte:69`) — suele estar bloqueado en varias regiones; conviene un fallback (Cloudflare, dweb.link).

---

## 🟢 4. Build / repo (rompe el clone limpio)

`out/` está en `.gitignore` (`:4`), pero el frontend importa `../../out/DappsManager.sol/DappsManager.json` (`src/lib/ethers.svelte.js:2`). El README solo dice `bun install` + `bun run dev`, pero **un clone fresco necesita `forge build` antes**, o el build del frontend falla. Falta documentarlo (o commitear los ABIs).

---

## 🔵 5. Producto / tokenomics

- No hay mecanismo real de "ultrasound money" más allá del burn fijo en voto; el `burnFee` debería ser dinámico/gobernado.
- Sin página de detalle de dApp, búsqueda, filtros por categoría, ni historial/actividad.
- Sin multi-chain (hardcodeado a Sepolia).
- **Sin tests de frontend ni CI/CD** — `package.json` no tiene script de test.

---

## Recomendación de arranque

Los dos bugs de seguridad del contrato (punto 1) son lo único que considero bloqueante. El resto son mejoras incrementales ya parcialmente planificadas en `UI_UX_IMPROVEMENT_PLAN.md`.

**Opciones de implementación:**

1. Corregir `dappCashOut` (chequeo de saldo) y `voteDapp` (un solo voto activo) + tests en `test/DappsManager.t.sol`.
2. Añadir los `event` al contrato para desbloquear The Graph.
3. Implementar la Fase 1/2 del plan UI/UX (select de dApps, voto contextual, preview de poder de voto).
