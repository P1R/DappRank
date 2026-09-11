# Uso de IA en DappRank

Documento de atribución del uso de herramientas de IA en este proyecto, de acuerdo con las reglas del hackathon (Atribución, Involucramiento, Spec-Driven Development).

---

## `src/components/DappRankList.svelte`

### Mejoras UI/UX (IA asistida)

El agente de IA (Claude Code en Zed) generó el código de esta fase, **dirigido por el equipo** mediante un plan de diseño priorizado. El equipo definió el alcance, aprobó la paleta semántica y validó el resultado con herramientas de accesibilidad (WCAG AA) y build (`bun run build`).

**Qué generó la IA en este archivo:**

- Ordenamiento del ranking por rating real (antes era por orden de llegada).
- Badges de rating y de status con color semántico (verde/ámbar/rojo/cian).
- Barra "Community backing" usando `weight_total_sum` (dato que el contrato ya devolvía pero se descartaba).
- Contador global "Total DRNK Burned".
- Estado vacío ("No dApps loaded yet").
- Limpieza de caracteres nulos (`stripNulls`) en nombres/status.

**Qué NO generó la IA (contribución del equipo):**

- La decisión de eliminar la sección IPFS (correspondía a otro proyecto).
- La elección de mantener la identidad visual neon existente.
- Los umbrales de la paleta semántica.
- La revisión final de accesibilidad y build.

---

## Bug de versiones de librerías y conexión al contrato

### Contexto

Tras actualizar dependencias, el botón **Buy Tokens** fallaba con:

```
Transaction failed: Cannot read properties of null (reading 'buyDRNK')
```

### Diagnóstico (IA asistida)

El agente de IA (DeepSeek en Zed) investigó el problema de forma dirigida por el equipo:

- Se verificó que la API de `ethers` v6 (`Contract`, `BrowserProvider`, `getSigner`) es correcta y que el ABI compilado contiene `buyDRNK` y `drnk`.
- Se confirmó que la reactividad de `$state` en archivos `.svelte.js` funciona entre módulos (WalletConnector muta, GetDRNK lee) tanto en svelte 5.41.0 como en 5.57.0.

### Solución aplicada

- **`package.json`**: se fijaron las versiones exactas instaladas en local (se quitaron los `^`) para que otra persona no instale versiones flotantes y evitar regresiones:
  - `svelte 5.41.0`, `ethers 6.15.0`, `vite 7.1.10`, `@sveltejs/vite-plugin-svelte 6.2.1`, `tailwindcss 4.3.3`, `@tailwindcss/vite 4.3.3`, `@sveltejs/adapter-static 3.0.10`.
- **`src/components/GetDRNK.svelte`** y **`src/components/Vote4Dapp.svelte`**: se añadieron guardas para mostrar un mensaje claro si el contrato no está conectado, en lugar del error confuso.

### Actualización a las últimas versiones (2026-09-10)

Posteriormente se actualizó el proyecto a las últimas versiones disponibles a la fecha, verificando compatibilidad y build:

- `svelte 5.57.0`, `ethers 6.17.0`, `vite 8.2.2`, `@sveltejs/vite-plugin-svelte 7.3.0`, `tailwindcss 4.3.3`, `@tailwindcss/vite 4.3.3`, `@sveltejs/adapter-static 3.0.10`.
- Se validó la compatibilidad de peer dependencies (`@sveltejs/vite-plugin-svelte 7.3.0` exige `vite ^8` y `svelte ^5.46.4`; `@tailwindcss/vite 4.3.3` soporta `vite ^8`).
- `bun run build` compila sin errores y el dev server arranca correctamente.
- Se verificó que la API de `ethers 6.17.0` (`Contract`, `buyDRNK`, `drnk`, `voteDapp`, `balanceOf`, `symbol`, `decimals`) sigue disponible y que `$state` en `.svelte.js` se compila a `$.proxy` correctamente.

**Qué NO generó la IA (contribución del equipo):**

- La creación del archivo `.env` con `VITE_SMARTCONTRACTADDRS`.
- La decisión de usar el contrato ya desplegado en Sepolia en lugar de configurar un entorno local.
- La validación final en testnet con la wallet real.
- **Balance de tokens**: se agregó `refreshTokenBalance()` en `ethers.svelte.js` y el balance real se muestra en los modales, refrescándose al conectar la wallet, al abrir cada modal y tras cada transacción.

---

## Cambios estéticos UI/UX (2026-09-11)

### Contexto

El agente de IA (DeepSeek en Zed) rediseñó la interfaz con enfoque **mobile-first** y mejoras de accesibilidad, dirigido por el equipo.

### Cambios estéticos

- **`src/app.css`**: tokens de tema en `@theme`, botones con targets táctiles de 44px, modales tipo _bottom sheet_ en móvil (centrados en desktop), anillo de foco visible (`:focus-visible`), soporte `prefers-reduced-motion` y _skip link_.
- **`src/App.svelte`**: navegación semántica (`<nav>`), menú móvil accesible (`aria-expanded`/`aria-controls`) y _skip link_ a `#main-content`.
- **`src/components/*`**: `role="dialog"`, `aria-modal`, `aria-labelledby`, `tabindex="-1"`, cierre con `Escape`, foco inicial en el primer campo, `role="status"`/`role="alert"` para feedback.
- **`src/components/DappRankList.svelte`**: tarjetas semánticas (`<article>`/`<h2>`), enlaces descriptivos y regiones live.

### Servicio MCP usado

- **UX MCP Server** (análisis de accesibilidad WCAG AA, contraste, responsive, wireframes, microcopy, microinteracciones y heurísticas de usabilidad).
- Repo: https://github.com/elsahafy/ux-mcp-server

### Librería de iconos

- **morphicons** (bindings Svelte 5) + **lucide** (datos de iconos): iconos reactivos con física de resorte y `reducedMotion="user"`.

---

## Correcciones y mejoras (2026-09-11)

### Refactor de modales

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

_Secciones adicionales se agregarán aquí cuando el equipo lo indique, especificando los archivos correspondientes._
