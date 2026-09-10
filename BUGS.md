# DappRank — Bugs & FIXMEs

Registro de bugs encontrados durante el desarrollo del frontend, con su causa
raíz, evidencia (tests/contrato) y estado.

---

## Bug 1 — Falta aprobación (allowance) antes de emitir un voto

**Estado: detectado — a la espera de unificar con el flujo de votación**

### Síntoma

Al hacer clic en **Submit Vote** la transacción se emite correctamente (la wallet la
firma y la envía), pero el bloque se mina con `status: 0` (revertido). El modal
muestra:

```
Transaction failed: transaction execution reverted (action="sendTransaction",
data=null, reason=null, transaction={ "data": "", "from": "...", ... },
receipt={ ...,"gasUsed":"35392","status":0, ... })
```

Detalles clave del revert:

- `data: ""` → el revert **no viene de un `require` con mensaje**.
- `gasUsed: 35392` → consumo bajo, el fallo ocurre pronto en la ejecución.

### Causa raíz

El flujo de la UI en `src/components/Vote4Dapp.svelte` llama directamente a
`voteDapp()` sobre el contrato `DappsManager` **sin haber aprobado primero** que ese
contrato pueda gastar los tokens DRNK del usuario.

En `src-sc/DappsManager.sol`, `voteDapp()` exige:

```solidity
function voteDapp(bytes32 _name, uint256 _amount, uint256 _rate) external {
    require(DappNameExists(_name));
    require(drnk.balanceOf(msg.sender) > 0);
    require(drnk.allowance(msg.sender, address(this)) >= _amount);   // ← falla aquí
    require(_rate > 0 && _rate <= 100);
    Fan memory voter = fansIndex[msg.sender];
    require(voter.expires > block.timestamp, "Voter is not a valid Fan");
    Dapp storage dapp = dappsIndex[_name];
    require(dapp.status == Status.Active, "Dapp is not active");
    ...
}
```

El `require` de allowance **no lleva mensaje**, por lo que ethers decodifica el revert
como `data: ""` (sin razón), coincidiendo con el error observado. A diferencia de los
`require` con mensaje (`"Voter is not a valid Fan"`, `"Dapp is not active"`), este
falla en silencio.

### Evidencia en los tests de Solidity

`test/DappsManager.t.sol` → `testVote4Dapp()`. Antes de votar, cada usuario debe
aprobar al contrato (líneas 228-233):

```solidity
vm.prank(testUsers[i]);
drnkToken.approve(address(dappsMgr), (vote_amount * 2 * i) + vote_amount);
uint256 allowanceAmount = drnkToken.allowance(testUsers[i], address(dappsMgr));
assertEq(allowanceAmount, (vote_amount * 2 * i) + vote_amount);
```

El test pasa al 100%; el frontend simplemente omite ese paso.

### Solución requerida

Antes de llamar a `voteDapp()`, aprobar al contrato `DappsManager`
(`ethVars.contractAddress`) para gastar los DRNK del usuario, p. ej.:

```js
const amountWei = parseEther(amount.toString());
const allowance = await ethVars.tokenContract.allowance(
  ethVars.signerAddress,
  ethVars.contractAddress,
);
if (allowance < amountWei) {
  const approval = await ethVars.tokenContract.approve(
    ethVars.contractAddress,
    amountWei,
  );
  await approval.wait();
}
```

> **Nota de comportamiento:** cada `voteDapp` gasta `_amount` de la allowance (la
> consume el `transferFrom` interno), por lo que la aprobación debe repetirse cuando
> se quiera volver a votar con el mismo o mayor importe.
