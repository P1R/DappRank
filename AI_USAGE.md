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

*Secciones adicionales se agregarán aquí cuando el equipo lo indique, especificando los archivos correspondientes.*
