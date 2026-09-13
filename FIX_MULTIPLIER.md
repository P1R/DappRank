# FIX: Inflación de emisión de DRNK por `multiplier` inicializado con `bonus`

**Fecha:** 2026-09-12
**Archivo afectado:** `src-sc/DappsManager.sol` — `_mint()`
**Estado:** Implementado, pendiente de redeploy en Sepolia

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
comprado. Es un mecanismo de *game theory* (recompensar actividad), no parte del
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

| Aspecto | Impacto |
|---|---|
| ABI / funciones | Ninguno (solo cambia lógica interna de `_mint`) |
| Eventos de The Graph | Ninguno (los eventos ya integrados no cambian) |
| Frontend | Ninguno (no usa el `multiplier`) |
| Contrato desplegado actual | **Requiere redeploy** — el suministro ya inflado (~1e21 DRNK) no se desinfla solo; el fix solo evita que siga creciendo |
| Test suite | 14/14 pasan, incluido el nuevo test de regresión |

## 5. Recomendación

1. Redeployar el contrato en Sepolia con el fix (junto con los eventos de
   The Graph ya integrados).
2. Considerar si el suministro inflado del despliegue actual es aceptable para
   testnet o si conviene un despliegue limpio.
3. Documentar en el README que el `multiplier` es un mecanismo de game theory
   independiente del rating SRWV (para evitar confusión futura).
