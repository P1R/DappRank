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


**Qué NO generó la IA (contribución del equipo):**

- La creación del archivo `.env` con `VITE_SMARTCONTRACTADDRS`.
- La decisión de usar el contrato ya desplegado en Sepolia en lugar de configurar un entorno local.
- La validación final en testnet con la wallet real.
- **Balance de tokens**: se agregó `refreshTokenBalance()` en `ethers.svelte.js` y el balance real se muestra en los modales, refrescándose al conectar la wallet, al abrir cada modal y tras cada transacción.

---

_Secciones adicionales se agregarán aquí cuando el equipo lo indique, especificando los archivos correspondientes._
