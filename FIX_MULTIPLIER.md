# DappRank — Bugs & Fixes

Registro de bugs corregidos durante el desarrollo, con causa raíz, evidencia
(tests/contrato) y estado. **Todos los bugs listados están resueltos y
verificados en el contrato desplegado** (`0x6b0EB389DD4B3ad4E9a28f56f971735aD2A85baD`)
y en la UI. No intentar corregirlos — conservar como registro histórico.

---

## Fix 1 — Inflación de emisión de DRNK por `multiplier` inicializado con `bonus`

**Fecha:** 2026-09-12
**Archivo afectado:** `src-sc/DappsManager.sol` — `_mint()`
**Estado: ✅ RESUELTO y desplegado** (contrato `0x6b0EB389...`, verificado on-chain)

---

## 1. Resumen del bug

Al crear un fan nuevo, el contrato inicializaba el `multiplier` del fan con el
valor de `bonus` en lugar de `1`:

```solidity
// ANTES (bug)
fansIndex[to] = Fan(bonus, block.timestamp + 4 weeks);

// DESPUÉS (fix)
fansIndex[to] = Fan(1, block.timestamp + 4 weeks);
```

La struct `Fan` es `{ uint256 multiplier; uint256 expires; }`, por lo que el
primer campo (`multiplier`) quedaba con `bonus = 1000e18` (1000 DRNK en wei).

### Cadena causal

`buyDRNK()` mintea para un fan existente:

```solidity
_mint(msg.sender, fansIndex[msg.sender].multiplier * msg.value * 1000);
```

Con `multiplier = bonus = 1000e18`, la segunda compra de cualquier fan minteaba:

```
mint = bonus × msg.value × 1000
     = 1000e18 × 0.05e18 × 1000      (0.05 ETH en Sepolia)
     = 5e39 wei
     = 5,000,000,000,000,000,000,000 DRNK   (5 sextillones)
```

### Evidencia on-chain

El `totalSupply()` del token desplegado en Sepolia
(`0x9772986A2d4cAD7023C7Fb04990dd66D1fB23420`) es
`~1e39 wei ≈ 1e21 DRNK` (1 sextillón), consistente con una compra del mínimo
(0.001 ETH) por un fan existente:

```
mint = 1000e18 × 0.001e18 × 1000 = 1e39 wei = 1e21 DRNK
```

## 2. Por qué el fix es correcto

### 2.1 El `multiplier` no pertenece al modelo SRWV

El modelo matemático documentado en `README.md` y `WP.md` (Square Root Weighted
Voting) define:

$$
W_i = \sqrt{T_i}
$$

$$
D_r = \frac{S_{vw}}{S_{wt}} = \frac{\sum_{i} (V_i \times \sqrt{T_i})}{\sum_{i} \sqrt{T_i}}
$$

El `multiplier` **no aparece en ninguna ecuación del rating**. Su único uso en
todo el contrato es en `buyDRNK()` para escalar la emisión de tokens por ETH
comprado. Es un mecanismo de _game theory_ (recompensar actividad), no parte del
cálculo de votos.

### 2.2 El valor inicial correcto es `1`

El `multiplier` se incrementa en cada voto:

```solidity
fansIndex[msg.sender].multiplier += 1;   // voteDapp()
```

Su semántica es "cuántas veces ha participado este fan" (o un proxy de
lealtad). El valor neutro inicial es `1` (emisión base `msg.value × 1000`),
no `bonus`. Inicializarlo con `bonus` (1000e18) equivale a que cada fan nuevo
"ya hubiera votado 1e18 veces" — un estado imposible e inflacionario.

### 2.3 El "welcome bonus" nunca se minteaba

El comentario original `// welcome bonus` era engañoso: el código **no minteaba**
ningún bonus al fan nuevo — solo asignaba `multiplier = bonus`. El bonus real
que recibe un fan nuevo es el `amount` que `_mint()` recibe como parámetro
(lo que compró). El fix corrige el comentario y el valor, sin cambiar la
semántica de emisión del primer depósito.

### 2.4 Test de regresión

Se añadió `testBuyTwiceNoInflation()` en `test/DappsManager.t.sol`:

```solidity
// Primera compra: fan nuevo -> msg.value * 1000
// Segunda compra: fan existente -> multiplier(1) * msg.value * 1000
// Total esperado: 0.02 ETH * 1000 = 20 DRNK (no 1e22)
```

Con el bug, la segunda compra minteaba `bonus × value × 1000` y el test falla;
con el fix, pasa. **14/14 tests pasan.**

## 3. ¿Afecta al modelo matemático del README?

### 3.1 Rating SRWV — NO afectado

La fórmula del rating usa `T_i` = tokens **apostados en el voto**
(`_amount` en `voteDapp`), no el `multiplier`:

```solidity
vote.fan_weight = Math.sqrt(_amount, Math.Rounding.Ceil);
dapp.weight_votes_sum += (vote.vote_rate * vote.fan_weight);
dapp.weight_total_sum += vote.fan_weight;
dapp.rate = dapp.weight_votes_sum / dapp.weight_total_sum;
```

El fix no toca `voteDapp()` ni ninguna ecuación del rating. Los valores de
validación del README (`weight_votes_sum = 6,380,084,467,978`,
`weight_total_sum = 106,138,700,962`, `rate = 60`) provienen de `sqrt(monto)`
y **siguen siendo válidos** — el test `testVote4Dapp` los verifica y pasa.

### 3.2 Modelo "ultrasound money" (deflación) — SÍ afectado indirectamente

El modelo deflacionario del README se apoya en la **escasez** del token: el
burn (10% por voto) debe reducir el suministro sobre el tiempo. Con el bug:

- El suministro se infla a ~1e21 DRNK con compras mínimas
- El burn de 10% por voto se vuelve **despreciable** frente al suministro
- La presión deflacionaria (y su señal económica) desaparece

El fix **restaura la premisa de escasez** sobre la que se construye el modelo
deflacionario. Sin él, el burn es cosmético.

### 3.3 Resistencia a ballenas (whale resistance) — SÍ afectado indirectamente

SRWV amortigua el poder de voto con $\sqrt{T_i}$, pero presupone que acumular
$T_i$ tiene un **costo económico real**. Con el bug, cualquiera puede obtener
cantidades astronómicas de DRNK por centavos, comprando poder de voto absoluto
sin costo proporcional. El fix restaura el costo real de acumular tokens,
preservando la propiedad anti-ballena del modelo.

### 3.4 Game theory (multiplier) — NO afectado

El `multiplier` como mecanismo de recompensa a la actividad (crece +1 por voto)
se **preserva intacto**. El fix solo corrige su valor inicial. El diseño de
incentivos (votar más → más emisión por ETH comprado) sigue funcionando, pero
desde una base sana (`1`) en lugar de una base inflada (`1000e18`).

## 4. Impacto en el despliegue

| Aspecto                    | Impacto                                                                                                                 |
| -------------------------- | ----------------------------------------------------------------------------------------------------------------------- |
| ABI / funciones            | Ninguno (solo cambia lógica interna de `_mint`)                                                                         |
| Eventos de The Graph       | Ninguno (los eventos ya integrados no cambian)                                                                          |
| Frontend                   | Ninguno (no usa el `multiplier`)                                                                                        |
| Contrato desplegado actual | **Requiere redeploy** — el suministro ya inflado (~1e21 DRNK) no se desinfla solo; el fix solo evita que siga creciendo |
| Test suite                 | 14/14 pasan, incluido el nuevo test de regresión                                                                        |

## 5. Recomendación

1. Redeployar el contrato en Sepolia con el fix (junto con los eventos de
   The Graph ya integrados).
2. Considerar si el suministro inflado del despliegue actual es aceptable para
   testnet o si conviene un despliegue limpio.
3. Documentar en el README que el `multiplier` es un mecanismo de game theory
   independiente del rating SRWV (para evitar confusión futura).

---

## Fix 2 — Falta aprobación (allowance) antes de emitir un voto

**Estado: ✅ RESUELTO (2026-09-13) — verificado en `Vote4DappModal.svelte`**

### Síntoma

Al hacer clic en **Submit Vote** la transacción se emitía correctamente (la wallet la
firma y la envía), pero el bloque se minaba con `status: 0` (revertido). El modal
mostraba:

```
Transaction failed: transaction execution reverted (action="sendTransaction",
data=null, reason=null, transaction={ "data": "", "from": "...", ... },
receipt={ ...,"gasUsed":"35392","status":0, ... })
```

Detalles clave del revert:

- `data: ""` → el revert **no venía de un `require` con mensaje**.
- `gasUsed: 35392` → consumo bajo, el fallo ocurría pronto en la ejecución.

### Causa raíz

El flujo de la UI en `src/components/Vote4Dapp.svelte` llamaba directamente a
`voteDapp()` sobre el contrato `DappsManager` **sin haber aprobado primero** que ese
contrato pudiera gastar los tokens DRNK del usuario. En `src-sc/DappsManager.sol`,
`voteDapp()` exige `drnk.allowance(msg.sender, address(this)) >= _amount` — el
`require` de allowance **no lleva mensaje**, por lo que ethers decodifica el revert
como `data: ""` (sin razón).

### Evidencia en los tests de Solidity

`test/DappsManager.t.sol` → `testVote4Dapp()`. Antes de votar, cada usuario debe
aprobar al contrato (líneas 228-233). El test pasaba al 100%; el frontend
simplemente omitía ese paso.

### ✅ Resolución aplicada

El flujo de aprobación se implementó en `src/components/Vote4DappModal.svelte`
(L199-213): antes de llamar a `voteDapp()`, se consulta la `allowance` del usuario
hacia el contrato y, si es insuficiente, se envía `approve()` y se espera la
confirmación. Verificado en testnet con la wallet real.

> **Nota de comportamiento:** cada `voteDapp` gasta `_amount` de la allowance (la
> consume el `transferFrom` interno), por lo que la aprobación debe repetirse cuando
> se quiera volver a votar con el mismo o mayor importe.

---

## Fix 3 — Reverts silenciosos en `voteDapp` (imposible diagnosticar desde la UI)

**Estado: ✅ RESUELTO (2026-09-13) — contrato redeployado con mensajes + UI con pre-flight**

### Síntoma

Al votar, la transacción se revertía con un error críptico sin razón:

```
Transaction failed: transaction execution reverted (action="sendTransaction",
data=null, reason=null, ..., "data": "", ..., "status": 0, ...)
```

`data: ""` indicaba un `require` **sin mensaje** — ethers no podía decodificar la causa.

### Causa raíz

`voteDapp()` en `src-sc/DappsManager.sol` tenía 4 `require` sin mensaje:

```solidity
require(DappNameExists(_name));                                  // 1
require(drnk.balanceOf(msg.sender) > 0);                         // 2
require(drnk.allowance(msg.sender, address(this)) >= _amount);   // 3
require(_rate > 0 && _rate <= 100);                              // 4
```

Cualquiera de ellos revertía en silencio. En la práctica, el caso más común era el
**#2 (saldo de DRNK = 0)**: la UI enviaba la aprobación (`approve`) y después
`voteDapp`, pero nunca comprobaba que el usuario tuviera tokens.

### Solución aplicada

1. **Contrato** (`src-sc/DappsManager.sol`): mensajes en los 4 `require` +
   mensaje en el `require` silencioso de `buyDRNK` (`Top-up window expired`).
2. **Frontend** (`src/components/Vote4DappModal.svelte`): chequeos previos
   (pre-flight) antes de enviar cualquier transacción:
   - `balanceOf > 0` → "No tienes DRNK…"
   - `balance >= amount` → "Saldo insuficiente…"
   - `fanIsAlive` → "Tu cuenta de fan no está activa…"
   - `DappNameIsActive` → "Esta dApp no está activa…"
3. El dropdown de dApps ahora solo lista dApps con estado `Active` (las demás no
   pueden recibir votos).

### ✅ Resolución verificada

- **Contrato redeployado** en Sepolia (`0x6b0EB389DD4B3ad4E9a28f56f971735aD2A85baD`)
  con los mensajes en los `require` de `voteDapp()` ("Dapp does not exist",
  "Insufficient DRNK balance", "Allowance not approved", "Rate must be between
  1 and 100").
- **UI con pre-flight checks** en `Vote4DappModal.svelte` (balance, saldo, fan,
  dapp activa) antes de enviar cualquier transacción.
- Verificado en testnet con la wallet real (votar funciona y los errores ahora
  muestran mensajes claros).
