# Uso de IA en DappRank

Documento de atribución del uso de herramientas de IA en este proyecto, de acuerdo con las reglas del hackathon (Atribución, Involucramiento, Spec-Driven Development).

---

## Modelo de trabajo (cómo se usó la IA)

**El equipo dirige; la IA ejecuta bajo esa dirección.**

- **El equipo** define los requisitos, toma las decisiones técnicas y estratégicas, aprueba los diseños, despliega en testnet con sus claves y valida los resultados con la wallet real.
- **La IA** (Claude Code / DeepSeek en Zed) implementa el código siguiendo esas decisiones, propone alternativas cuando se le pide y documenta su trabajo.

Este documento atribuye **ambos lados**: qué implementó la IA y qué decidió/validó el equipo. La dirección del equipo está evidenciada en los artefactos de planificación del repo: [`ETHOnline2026_Strategy.md`](./ETHOnline2026_Strategy.md) y el bloque de propuesta en [`src-sc/DappsManager.sol`](./src-sc/DappsManager.sol) (L28-129), que documentan el diseño antes de la implementación.

---

## `src/components/DappRankList.svelte`

### Mejoras UI/UX (IA asistida)

**Decisión del equipo:** rediseñar el ranking con prioridad móvil, mantener la identidad visual neon existente y eliminar la sección IPFS (correspondía a otro proyecto). El equipo definió el alcance, aprobó la paleta semántica y los umbrales de los tiers.

**Implementación de la IA (bajo esa dirección):**

- Ordenamiento del ranking por rating real (antes era por orden de llegada).
- Badges de rating y de status con color semántico (verde/ámbar/rojo/cian).
- Barra "Community backing" usando `weight_total_sum` (dato que el contrato ya devolvía pero se descartaba).
- Contador global "Total DRNK Burned".
- Estado vacío ("No dApps loaded yet").
- Limpieza de caracteres nulos (`stripNulls`) en nombres/status.

**Validación del equipo:** revisión final de accesibilidad (WCAG AA) y build (`bun run build`).

---

## Bug de versiones de librerías y conexión al contrato

### Contexto

Tras actualizar dependencias, el botón **Buy Tokens** fallaba con:

```
Transaction failed: Cannot read properties of null (reading 'buyDRNK')
```

### Diagnóstico (IA asistida)

**Decisión del equipo:** investigar el error antes de tocar código y fijar versiones exactas para evitar regresiones. El equipo reportó el síntoma desde la wallet real y validó el fix en testnet.

**Investigación de la IA (bajo esa dirección):**

- Se verificó que la API de `ethers` v6 (`Contract`, `BrowserProvider`, `getSigner`) es correcta y que el ABI compilado contiene `buyDRNK` y `drnk`.
- Se confirmó que la reactividad de `$state` en archivos `.svelte.js` funciona entre módulos (WalletConnector muta, GetDRNK lee) tanto en svelte 5.41.0 como en 5.57.0.

### Solución aplicada

- **`package.json`**: se fijaron las versiones exactas instaladas en local (se quitaron los `^`) para que otra persona no instale versiones flotantes y evitar regresiones:
  - `svelte 5.41.0`, `ethers 6.15.0`, `vite 7.1.10`, `@sveltejs/vite-plugin-svelte 6.2.1`, `tailwindcss 4.3.3`, `@tailwindcss/vite 4.3.3`, `@sveltejs/adapter-static 3.0.10`.
- **`src/components/GetDRNK.svelte`** y **`src/components/Vote4Dapp.svelte`**: se añadieron guardas para mostrar un mensaje claro si el contrato no está conectado, en lugar del error confuso.

### Actualización a las últimas versiones (2026-09-10)

**Decisión del equipo:** actualizar a las últimas versiones disponibles y verificar compatibilidad antes de continuar.

**Implementación de la IA (bajo esa dirección):**

- `svelte 5.57.0`, `ethers 6.17.0`, `vite 8.2.2`, `@sveltejs/vite-plugin-svelte 7.3.0`, `tailwindcss 4.3.3`, `@tailwindcss/vite 4.3.3`, `@sveltejs/adapter-static 3.0.10`.
- Se validó la compatibilidad de peer dependencies (`@sveltejs/vite-plugin-svelte 7.3.0` exige `vite ^8` y `svelte ^5.46.4`; `@tailwindcss/vite 4.3.3` soporta `vite ^8`).
- `bun run build` compila sin errores y el dev server arranca correctamente.
- Se verificó que la API de `ethers 6.17.0` (`Contract`, `buyDRNK`, `drnk`, `voteDapp`, `balanceOf`, `symbol`, `decimals`) sigue disponible y que `$state` en `.svelte.js` se compila a `$.proxy` correctamente.

**Contribución del equipo:**

- La creación del archivo `.env` con `VITE_SMARTCONTRACTADDRS`.
- La decisión de usar el contrato ya desplegado en Sepolia en lugar de configurar un entorno local.
- La validación final en testnet con la wallet real.
- **Balance de tokens**: el equipo pidió mostrar el balance real en los modales; se agregó `refreshTokenBalance()` en `ethers.svelte.js` y el balance se refresca al conectar la wallet, al abrir cada modal y tras cada transacción.

---

## Cambios estéticos UI/UX (2026-09-11)

### Contexto

**Decisión del equipo:** rediseñar la interfaz con enfoque **mobile-first** y mejoras de accesibilidad, manteniendo la identidad visual existente.

### Implementación de la IA (bajo esa dirección)

- **`src/app.css`**: tokens de tema en `@theme`, botones con targets táctiles de 44px, modales tipo _bottom sheet_ en móvil (centrados en desktop), anillo de foco visible (`:focus-visible`), soporte `prefers-reduced-motion` y _skip link_.
- **`src/App.svelte`**: navegación semántica (`<nav>`), menú móvil accesible (`aria-expanded`/`aria-controls`) y _skip link_ a `#main-content`.
- **`src/components/*`**: `role="dialog"`, `aria-modal`, `aria-labelledby`, `tabindex="-1"`, cierre con `Escape`, foco inicial en el primer campo, `role="status"`/`role="alert"` para feedback.
- **`src/components/DappRankList.svelte`**: tarjetas semánticas (`<article>`/`<h2>`), enlaces descriptivos y regiones live.

### Herramientas usadas

- **UX MCP Server** (análisis de accesibilidad WCAG AA, contraste, responsive, wireframes, microcopy, microinteracciones y heurísticas de usabilidad).
- Repo: https://github.com/elsahafy/ux-mcp-server
- **morphicons** (bindings Svelte 5) + **lucide** (datos de iconos): iconos reactivos con física de resorte y `reducedMotion="user"`.

**Validación del equipo:** revisión de accesibilidad y aprobación del resultado visual.

---

## Correcciones y mejoras (2026-09-11)

### Refactor de modales

**Decisión del equipo:** centralizar los modales en la raíz de la app para evitar bugs de posicionamiento y mejorar la accesibilidad.

**Implementación de la IA (bajo esa dirección):**

- **`src/lib/modal.svelte.js`** (nuevo): estado compartido del modal (`openModal`/`closeModal`).
- **`src/App.svelte`**: los modales se renderizan en la **raíz** (fuera del header), evitando que `transform`/`filter`/`backdrop-filter` de un ancestro rompan el `position: fixed`. Añade cierre con `Escape`, _focus trap_ (Tab) y cierre del menú móvil al abrir un modal.
- **`src/components/{Vote4Dapp,GetDRNK,RegisterDapp}.svelte`**: quedan como botones que abren el modal.
- **`src/components/*Modal.svelte`** (nuevos): contienen el formulario de cada acción.

### Tipado (JSDoc, sin `any`)

- **`src/lib/ethers.svelte.js`**: typedefs `EthVarsState`/`DappInfo`; `contract`/`tokenContract` tipados como `ethers.Contract | null`; `return null` en guards; guards de null en `getDappInfoForName`.
- **`src/globals.d.ts`** (nuevo): declara `window.ethereum` (EIP-1193).
- **`src/components/*Modal.svelte`** y **`DappRankList.svelte`**: refs `bind:this` tipados, parámetros tipados, `Record<Tier, string>` para los mapas de tier.

### Mejora UX

- **`src/components/WalletConnector.svelte`**: estado de carga visible (morph a `LoaderCircle` girando + "Connecting…", botón deshabilitado, `aria-busy`) y `isLoading` siempre reseteado con `finally`.

---

## Integración con The Graph — propuesta (2026-09-12)

### Contexto

Preparación de la integración de The Graph según la estrategia ETHOnline 2026 (premio The Graph — Best AI Tooling/AI Use Case). **El equipo** definió la estrategia en [`ETHOnline2026_Strategy.md`](./ETHOnline2026_Strategy.md) y decidió que los eventos quedaran como **propuesta pendiente de aprobación** — no se modificaría el comportamiento on-chain sin su OK. La IA preparó la propuesta técnica bajo esa dirección.

### Propuesta en contratos (PENDIENTE DE APROBACIÓN)

- **`src-sc/DappsManager.sol`**: propuesta de 8 eventos (`DappRegistered`, `DappApproved`, `DappBanned`, `VoteCast`, `TokensBurned`, `DappCashOut`, `DappRemoved`, `DappCIDUpdated`) con sus `emit` en las funciones correspondientes, **todo comentado** (no activo). `VoteCast` incluye `amount` (desviación de la estrategia) para que el subgraph calcule el delta de balance. También se propuso corregir `dappCashOut()` para que descuente `dapp.balance` (inconsistencia pre-existente). El bloque de propuesta en el contrato documenta el diseño y las decisiones.
- **`test/DappsManager.t.sol`**: 7 tests con `vm.expectEmit` preparados pero **comentados** (se activan junto con los eventos).

### Infraestructura de soporte (lista para cuando se apruebe)

- **`subgraph/`** (nuevo): `subgraph.yaml`, `schema.graphql` (entidades `Dapp`, `Vote`, `GlobalStat`), `src/mapping.ts` (handlers AssemblyScript), ABI compilado, `package.json`, `tsconfig.json` y `README.md` con instrucciones de despliegue.
- **`src/lib/subgraph.svelte.js`** (nuevo): capa GraphQL para consultar el subgraph (`querySubgraph`, `fetchDappsFromSubgraph`, `fetchGlobalStat`), mapeando al mismo shape `DappInfo` del contrato.
- **`src/lib/ethers.svelte.js`**: `refreshDappsList()` prioriza el subgraph (público, sin wallet) con fallback a lecturas del contrato; nuevo estado `dataSource`.
- **`src/components/InvestorInsights.svelte`** (nuevo): métricas globales del subgraph (dapps, votos, DRNK quemado, balance) y top dapps deflacionarias, con indicador "Indexed live by The Graph".
- **`src/App.svelte`**: se monta `InvestorInsights` sobre el ranking.

### Decisiones del equipo (no de la IA)

- Mantener los eventos como propuesta pendiente de aprobación.
- Aprobar (posteriormente) la propuesta de eventos y las desviaciones (VoteCast con `amount`, fix de balance en cashout, eventos `DappRemoved`/`DappCIDUpdated`).
- El redeploy del contrato en Sepolia y el despliegue del subgraph a Subgraph Studio (requieren claves privadas / cuenta del equipo).
- La configuración del Subgraph MCP en su cliente de IA.

---

## Integración con The Graph — implementación y despliegue (2026-09-12/13)

### Contexto

El equipo **aprobó la propuesta** de la sección anterior y **desplegó el contrato** en Sepolia con su clave privada. Bajo esa dirección, la IA implementó los eventos, corrigió bugs, desplegó el subgraph en Subgraph Studio y preparó el skill de agente para el premio.

### Decisiones del equipo (dirigieron esta fase)

- **Aprobar** la propuesta de eventos y el fix del multiplier.
- **Detectar el bug de emisión astronómica** desde sus pruebas en testnet ("con 0.05 Sepolia me da miles de millones") — el equipo identificó el síntoma que llevó al fix.
- **Redeployar el contrato** en Sepolia con los eventos y verificar en Etherscan.
- **Desplegar el subgraph** a Subgraph Studio con su Deploy Key.
- **Decidir no publicar** a la red descentralizada (Arbitrum One) por el costo de gas/GRT y mantener el subgraph desplegado en Studio para el hackathon.
- **Elegir el pool Continuity** para el premio de The Graph.

### Implementación de la IA (bajo esa dirección)

**Contratos:**

- **`src-sc/DappsManager.sol`**: se activaron los 8 eventos con sus `emit` en las funciones correspondientes. `VoteCast` incluye `amount` (desviación aprobada).
- **`src-sc/DappsManager.sol`**: se corrigió `dappCashOut()` para que descuente `dapp.balance` (contabilidad en sync con el subgraph).
- **`test/DappsManager.t.sol`**: se activó `testEventsEmitted` (8 eventos verificados con `vm.expectEmit` filtrando por emisor, ya que el token emite `Transfer`/`Approval` durante las mismas llamadas). 14/14 tests pasan.
- **`subgraph/abis/DappsManager.json`**: ABI regenerado con los eventos.

**Bug de emisión astronómica de DRNK (multiplier):**

- **`src-sc/DappsManager.sol`**: se corrigió `_mint()` — el `multiplier` de un fan nuevo se inicializaba con `bonus` (1000e18) en vez de `1`, lo que hacía que `buyDRNK` minteara cantidades astronómicas en la 2ª compra (`bonus × value × 1000`). Evidencia on-chain: `totalSupply ≈ 1e21 DRNK`.
- **`test/DappsManager.t.sol`**: nuevo `testBuyTwiceNoInflation` (regresión).
- **`FIX_MULTIPLIER.md`** (nuevo): argumentación del fix y su impacto en el modelo matemático SRWV (no afecta el rating; restaura la escasez del modelo deflacionario).

**Frontend:**

- **`src/lib/subgraph.svelte.js`**: fix del fallback — el endpoint del subgraph respondía `{"message":"Not found"}` con HTTP 200, que el código interpretaba como "éxito con datos vacíos", bloqueando el fallback al contrato. Ahora un response sin `data` lanza error y cae a lecturas del contrato.
- **Dirección del contrato actualizada** a `0x6b0EB389DD4B3ad4E9a28f56f971735aD2A85baD` en `.env`, `src/lib/ethers.svelte.js`, `envexample`, `README.md`.
- **`package.json`**: `build` ahora ejecuta `forge build && vite build` para regenerar los ABIs (`out/`) antes de compilar el front (npm 11 ya no ejecuta los hooks `pre/post` automáticamente).
- **`dist/`**: reconstruido con la dirección y el subgraph correctos.

**Subgraph:**

- **`subgraph/docker-compose.yml`** (nuevo): stack local graph-node + IPFS + Postgres para probar sin Studio. Se resolvieron: imagen amd64 en Mac ARM (`platform: linux/amd64`), variable `ethereum` (minúscula, formato `<red>:<url>`), y `postgres:16` (con `postgres:14` fallaba con `deployment_schemas does not exist`).
- **Subgraph desplegado en Subgraph Studio** (ID `1760241`, v0.0.2) por el equipo con su Deploy Key. Endpoint público: `https://api.studio.thegraph.com/query/1760241/dapprank/v0.0.2`.
- **`subgraph/subgraph.yaml`**: `source.address` y `startBlock: 11692630` actualizados al contrato con eventos.

**AI Agent Skill (requisito del premio):**

- **`skills/dapprank-subgraph/SKILL.md`** (nuevo) + `references/` (schema, queries, architecture): skill de agente que permite responder en lenguaje natural sobre el ranking live (ratings, votos, quemas, deflación, whale analysis) consultando el subgraph. Formato basado en el repo oficial `graphprotocol/subgraphs-skills` (frontmatter YAML + secciones + references).
- **`README.md`**: sección "ETHOnline 2026 — The Graph Prize Submission" con el checklist de requisitos oficiales, documentación pre-existente vs nuevo trabajo (regla Continuity) e instrucciones para que los jueces lo ejecuten.
- **`subgraph/tsconfig.json`**: fix del `extends` (ruta `tsconfig-base.json`).

### Validación del equipo

- Verificación del contrato desplegado en Etherscan (eventos + fixes).
- Pruebas en testnet con la wallet real (comprar, votar, listar dapps).
- Aprobación del skill y de la sección de submission del README.
- Grabación del demo video (pendiente).

---

## Integración con ENSv2 — implementación (2026-09-13)

### Contexto

Cambio de estrategia por tiempo (ver `ETHOnline2026_Strategy.md`): la
combinación de premios pasa a **The Graph + Uniswap + ENS**. **El equipo**
decidió implementar ENS primero y definió el alcance: capa de resolución
ENSv2 en el frontend + setup on-chain del namespace `dapprank.eth`, sin migrar
el storage `bytes32` del contrato.

### Decisiones del equipo (dirigieron esta fase)

- Cambiar la estrategia de premios (Arc/Chainlink → Uniswap/ENS) por tiempo.
- Implementar ENSv2 como capa de resolución (no migración de storage).
- Registrar `dapprank.eth` en ENSv2 (Sepolia) con su wallet — **pendiente**.
- Ejecutar `script/EnsSetup.s.sol` con su clave privada — **pendiente**.

### Implementación de la IA (bajo esa dirección)

**Frontend (resolución ENSv2):**

- **`src/lib/ens.svelte.js`** (nuevo): `namehash`, `dnsEncode`, `dappEnsName`,
  `resolveTextRecord`, `resolveAddr` y `attachEnsNames`. Resuelve
  `<dappname>.dapprank.eth` vía `UpgradableUniversalResolverProxy`
  (`0xeEeE…EeEe`, entry point canónico de ENSv2 en Sepolia) con fallback a RPC
  público de Sepolia si no hay wallet conectada. Direcciones canónicas
  verificadas contra `contracts-v2/docs/addresses/sepolia.md`.
- **`src/lib/ethers.svelte.js`**: `refreshDappsList()` enriquece la lista con
  nombres ENS (no bloquea el refresh); typedef `DappInfo` ampliado con
  `ensName`/`ensResolved`/`ensCid`.
- **`src/components/DappRankList.svelte`**: muestra el nombre ENS con badge
  "ENSv2" cuando el subname resuelve; fallback al `bytes32`.

**On-chain (setup del namespace):**

- **`script/EnsSetup.s.sol`** (nuevo): despliega un `UserRegistry` (subregistry)
  para `dapprank.eth` vía `VerifiableFactory` (salt determinista, mismo que
  `ens-cli`), lo conecta (`ETHRegistry.setSubregistry` + `setParent`), y
  registra un subname por dApp con su `PermissionedResolver` (records
  `dapprank.cid` y `addr` precargados en `initialize()`). Interfaces mínimas
  verificadas contra el repo `ensdomains/contracts-v2`.

**Docs:**

- **`README.md`**: sección "ENS Integration (ETHOnline 2026)" con estado,
  pasos para el equipo y direcciones canónicas.
- **`envexample`**: vars `VITE_ENSV2_RESOLVER`, `VITE_DAPPRANK_ENS_DOMAIN`,
  `ENS_DAPPS`.
- **`skills/dapprank-subgraph/SKILL.md`**: referencias a nombres ENSv2 en
  queries y razonamiento.

### Validación

- `forge build` compila (incluye `script/EnsSetup.s.sol`).
- `bun run build` compila el frontend sin errores.
- **Pendiente del equipo**: registrar `dapprank.eth` en ENSv2 (Sepolia) y
  ejecutar el script de setup para que los subnames resuelvan en la UI.

---

## Mejora de interfaz: contexto, i18n ES/EN y paleta sobria (2026-09-13)

### Contexto

El equipo pidió hacer el proyecto más llamativo y mejorar la experiencia de
usuario, señalando que la página se veía "vacía". La IA propuso un plan
priorizado: (1) dar contexto al producto (hero + how it works + footer),
(2) i18n ES/EN, (3) búsqueda/filtros, (4) detalle de dApp, (5) activity feed,
(6) gráficas y (7) skeletons de carga. El equipo aprobó los **paquetes 1 y 2**
y la dirección visual sobria tipo ultrasound.money, dejando el resto para
iteraciones futuras.

### Decisiones del equipo (dirigieron esta fase)

- Aprobar el paquete 1 (hero + how it works + footer) y el paquete 2
  (i18n ES/EN con toggle en el header).
- Cambiar la estética neon/cyberpunk por una **paleta sobria esmeralda/teal**
  inspirada en ultrasound.money (manteniendo los nombres de tokens `neon-*`
  para no tocar los componentes).
- Idioma por defecto **EN** (jueces del hackathon), con toggle a ES que
  persiste en localStorage.
- Enlazar whitepaper/docs al repo de GitHub (el build estático de Vite no
  incluye los `.md` del repo).

### Implementación de la IA (bajo esa dirección)

**i18n (paquete 2):**

- **`src/lib/i18n.svelte.js`** (nuevo): diccionario EN/ES (~150 claves) con
  `t(key, params)`, `setLocale()` y persistencia en localStorage. Aplica el
  atributo `lang` dinámico a `<html>`. Sin dependencias — encaja con el estilo
  del proyecto (libs hechas a mano como `modal.svelte.js`).
- **`src/components/LangToggle.svelte`** (nuevo): selector 🌐 EN/ES en el
  header, mismo patrón de menú que `ThemeToggle`.
- **Todos los componentes con textos** migrados a `t()`: `App.svelte`,
  `DappRankList.svelte` (incluye los labels de tier vía `$derived` para que
  reaccionen al cambio de idioma), `InvestorInsights.svelte`, los 3 modales
  (`Vote4DappModal`, `GetDRNKModal`, `RegisterDappModal` — incluidos los
  mensajes de error que estaban en español), botones del header (`GetDRNK`,
  `DappsData`, `RegisterDapp`, `WalletConnector`) y `ThemeToggle`.

**Contexto de producto (paquete 1):**

- **`src/components/Hero.svelte`** (nuevo): hero con badge "Live on Sepolia ·
  Indexed by The Graph", tagline, subtítulo explicando SRWV y CTAs (Vote now,
  Register your dApp, Read the whitepaper). Debajo, "How it works" en 3 pasos
  y "Why DappRank" con 3 tarjetas (Anti-whale, Ultrasound money, On-chain
  transparency).
- **`src/components/Footer.svelte`** (nuevo): tagline, links al whitepaper/
  docs/código, direcciones de los contratos en Sepolia (con Etherscan),
  endpoint del subgraph y crédito "Built for ETHOnline 2026 · The Graph Prize".

**Paleta sobria (dirección visual):**

- **`src/app.css`**: la paleta por defecto pasa de cian `#00f7ff`/magenta
  `#ff00cc` sobre azul a **esmeralda/teal** (`#2dd4bf`, rosa suave `#f472b6`)
  sobre verde-negro `#0a0f0d`. Los temas Light y Dark quedan como variantes
  sobrias de la misma paleta (valores oscurecidos para mantener WCAG AA).
- **`src/lib/theme.svelte.js`**: label del tema "Neon" → "Emerald" (los ids
  `original`/`light`/`dark` no cambian).
- **`index.html`**: favicon en teal y título "DappRank — Decentralized dApp
  Ranking".

### Validación

- `bun run build` (forge + vite) sin errores.
- Diagnostics del proyecto: 0 errores (se corrigió el tipado de `setLocale` y
  el export de `$state` reasignado, que Svelte 5 no permite — se usa un objeto
  `i18n` mutado, mismo patrón que `modalState`/`currentTheme`).
- Smoke test: `vite preview` sirve la página; las cadenas EN/ES están en el
  bundle compilado y la paleta teal reemplazó al cian neón en el CSS.
- **Pendiente del equipo**: revisar visualmente en navegador (desktop + móvil)
  y decidir si el idioma por defecto debe ser ES en lugar de EN.
