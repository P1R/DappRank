// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.36;

import {DappRank} from "./DRNK.sol";
import {AccessControl} from "openzeppelin-contracts/contracts/access/AccessControl.sol";
import {Math} from "openzeppelin-contracts/contracts/utils/math/Math.sol";

// ToDo
// [x] list fans
// [x] list dapps
// [x] airdrop actors demo
// [x] mint DRNK
// [x] registerDapp (payable)
// [x] updateDappCID
// [x] removeDapp
// [x] approveDapp
// [x] burn DRNK
// [x] banDapp
// [x] expiredDapp
// [x] voteDapp
// [x] distribute DRNK
// For sprint 3 increment the deflation of ultrasound.
// [ ] transfer condition and expiration
// [ ] IisAlive
// [ ] sacrifice

// ============================================================================
// PROPUESTA PENDIENTE DE APROBACIÓN — EVENTOS PARA INTEGRACIÓN CON THE GRAPH
// ============================================================================
// Estado: PROPUESTA. Este bloque NO cambia el comportamiento del contrato.
// Si se aprueba: integrar los eventos, añadir tests, redeployar en Sepolia y
// actualizar las direcciones (envexample, src/lib/ethers.svelte.js, README.md).
//
// ----------------------------------------------------------------------------
// 1) CONTEXTO
// ----------------------------------------------------------------------------
// DappsManager NO emite ningún evento hoy. The Graph solo puede indexar datos
// a través de eventos: sin eventos no hay subgraph posible. La estrategia
// ETHOnline 2026 (premio The Graph) requiere:
//   - Un subgraph consumiendo datos LIVE del contrato en Sepolia
//   - Un agente IA (Subgraph MCP) haciendo razonamiento sobre esos datos
//     (preguntas en lenguaje natural: rankings, tendencias, deflación...)
//
// ----------------------------------------------------------------------------
// 2) EVENTOS PROPUESTOS
// ----------------------------------------------------------------------------
//   event DappRegistered(bytes32 indexed name, address indexed owner, string cid);
//   event DappApproved(bytes32 indexed name);
//   event DappBanned(bytes32 indexed name);
//   event VoteCast(bytes32 indexed dapp, address indexed voter, uint256 voteRate, uint256 fanWeight, uint256 timestamp);
//   event TokensBurned(bytes32 indexed dapp, uint256 amount);
//   event DappCashOut(bytes32 indexed dapp, address indexed owner, uint256 amount);
//
// ----------------------------------------------------------------------------
// 3) DÓNDE SE EMITIRÍA CADA UNO Y QUIÉN LO DISPARA
// ----------------------------------------------------------------------------
//   DappRegistered -> registerDapp()   — cualquier usuario pagando el listing fee
//   DappApproved   -> approveDapp()    — solo DEFAULT_ADMIN_ROLE / DAO_ROLE
//   DappBanned     -> banDapp()        — solo DEFAULT_ADMIN_ROLE / DAO_ROLE
//   VoteCast       -> voteDapp()       — cualquier fan con DRNK y allowance
//   TokensBurned   -> voteDapp()       — quema automática (burnFee) al votar
//   DappCashOut    -> dappCashOut()    — solo el owner del dapp
//
// ----------------------------------------------------------------------------
// 4) PARA QUÉ SIRVE CADA EVENTO EN THE GRAPH / MCP
// ----------------------------------------------------------------------------
// DappRegistered / DappApproved / DappBanned
//   -> Alimentan la entidad Dapp del subgraph (estado: Submitted/Active/Banned).
//   -> El agente puede responder: "¿qué dapps están activas?", "¿cuántas están
//      pendientes de aprobación?", "¿qué dapps han sido baneadas?".
//
// VoteCast
//   -> Alimenta la entidad Vote (historial por votante) y actualiza el rating
//      ponderado del dapp en el subgraph.
//   -> El agente puede responder: "¿cómo evolucionó el rating de dapp X?",
//      "¿quién votó y con qué peso?", "¿qué dapp tiene más consenso?".
//
// TokensBurned  <-- el que más dudas genera, explicado en detalle:
//   -> El burn ocurre automáticamente dentro de voteDapp() (L298-300): al votar
//      se quema burnFee (10%) del monto. Hoy es invisible: el contrato solo
//      guarda el acumulado dapp.burned, sin historia.
//   -> El evento convierte ese efecto secundario en un log consultable
//      (dapp, amount, bloque, timestamp). El subgraph lo indexa en:
//        - Dapp.burned            (acumulado por dapp)
//        - GlobalStat.totalBurned (métrica central del modelo "ultrasound money")
//        - (opcional) entidad Burn por evento para series temporales
//   -> Con historia indexada, el agente puede responder:
//        - "¿Qué dapp ha quemado más DRNK esta semana?"
//        - "¿Cómo ha evolucionado la quema de dapp X?"
//        - "¿Cuál es la presión deflacionaria total de DRNK?"
//        - "¿Qué dapps están creciendo en actividad?" (join VoteCast + Burn)
//   -> ¿Por qué un evento explícito si el monto es derivable de VoteCast
//      (amount * burnFee / 10_000)?
//        - El mapping del subgraph no replica la matemática de fees (menos bugs)
//        - Si burnFee cambia en el futuro, el histórico sigue siendo exacto
//        - Autodocumentado: el log dice explícitamente qué y para quién se quemó
//
// DappCashOut
//   -> Registra retiros del owner. El agente puede responder: "¿qué dapps han
//      retirado fondos?", "¿cuánto ha retirado cada una?".
//
// ----------------------------------------------------------------------------
// 5) DECISIONES / DESVIACIONES RESPECTO A LA ESTRATEGIA (requieren tu OK)
// ----------------------------------------------------------------------------
// a) TokensBurned se emite en voteDapp(), NO en burn():
//    burn(uint256) (L139) es un burn genérico del usuario sin contexto de dapp.
//    El burn con contexto ocurre dentro de voteDapp(). Emitir ahí.
//
// b) dappCashOut() NO descuenta dapp.balance (inconsistencia pre-existente):
//    transfiere tokens pero el balance on-chain queda intacto; el subgraph
//    heredaría un balance inflado. Recomendado corregir en la misma pasada
//    (dapp.balance -= _amount). Requiere aprobación porque cambia estado.
//
// c) Eventos adicionales recomendados (NO están en la estrategia):
//    - DappRemoved(bytes32 indexed name)              -> removeDapp()     (L203)
//    - DappCIDUpdated(bytes32 indexed name, string cid) -> updateDappCID() (L194)
//    Sin ellos el subgraph mostraría dapps eliminadas y CIDs obsoletos.
//
// ----------------------------------------------------------------------------
// 6) TRABAJO POSTERIOR A LA APROBACIÓN
// ----------------------------------------------------------------------------
//   1. Integrar eventos + emit en las funciones indicadas
//   2. Añadir tests con vm.expectEmit en test/DappsManager.t.sol
//   3. forge build && forge test
//   4. Redeploy en Sepolia -> NUEVA dirección de contrato
//   5. Actualizar direcciones: envexample, src/lib/ethers.svelte.js, README.md
//   6. Crear subgraph (subgraph.yaml, schema.graphql, src/mapping.ts, abis/)
//   7. Deploy a Subgraph Studio + configurar Subgraph MCP para el agente IA
// ============================================================================

contract DappsManager is AccessControl {
    bytes32 public constant DAO_ROLE = keccak256("DAO_ROLE");

    DappRank public drnk;

    error CallerNotAdmin(address caller);
    error CallerNotDAO(address caller);
    error UnknownStatus(Status unknown);

    // --- Events (The Graph integration) — PROPUESTA PENDIENTE DE APROBACIÓN ---
    // Descomentar al aprobar la integración. Nota: VoteCast incluye `amount`
    // (desviación de la estrategia) para que el subgraph calcule el delta de
    // balance; DappRemoved y DappCIDUpdated evitan datos obsoletos en el índice.
    // event DappRegistered(bytes32 indexed name, address indexed owner, string cid);
    // event DappApproved(bytes32 indexed name);
    // event DappBanned(bytes32 indexed name);
    // event VoteCast(bytes32 indexed dapp, address indexed voter, uint256 voteRate, uint256 fanWeight, uint256 timestamp, uint256 amount);
    // event TokensBurned(bytes32 indexed dapp, uint256 amount);
    // event DappCashOut(bytes32 indexed dapp, address indexed owner, uint256 amount);
    // event DappRemoved(bytes32 indexed name);
    // event DappCIDUpdated(bytes32 indexed name, string cid);

    // airdrops
    uint256 public bonus;
    // listingFee
    uint256 public listingFee;
    // DAOFee fixed to 1% on vote in bp
    uint256 public DAOFee;
    address public DAOAddrss;
    // burn fee % to make it ultrasound will be fixable in the future
    uint256 public burnFee; // bp

    // temporal for getting tokens to test Demo
    uint256 public topUpExpires;
    uint256 public topUpMin = 0.001 ether;

    enum Status {
        Submitted,
        Active,
        Expired,
        Banned
    }

    struct Dapp {
        string cid;
        uint256 rate; // Dr = Dapp rate
        uint256 weight_votes_sum; // sum(Vi x sqrt(Ti)) see WP.md
        uint256 weight_total_sum; // sum(sqrt(Ti)) see WP.md
        uint256 balance;
        uint256 burned;
        address owner;
        Status status;
        mapping(address => Vote) votes;
    }

    struct Fan {
        uint256 multiplier;
        uint256 expires;
    }

    struct Vote {
        uint256 vote_rate; // Vi must be between 0 and 100
        uint256 fan_weight; // Wi = sqrt(Ti)
        uint256 timestamp;
    }

    bytes32[] public dapps;
    address[] public fans;

    mapping(bytes32 => Dapp) public dappsIndex;
    mapping(address => Fan) public fansIndex;

    constructor(
        uint256 _listingFee,
        uint256 _daoFee,
        uint256 _burnFee,
        uint256 _bonus
    ) {
        drnk = new DappRank(address(this), address(this));
        listingFee = _listingFee; // fixed price updateable
        DAOFee = _daoFee; // ToDo: based on ultrasound model
        burnFee = _burnFee; // ToDo: based on ultrasound model
        bonus = _bonus;
        DAOAddrss = msg.sender; // temporal patch should be parameter...
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        // to be updated with an address as the admin role
        _grantRole(DAO_ROLE, msg.sender);
        topUpExpires = block.timestamp + 12 weeks;
    }

    function demoAirdrop(address[] calldata actors) public {
        if (!hasRole(DEFAULT_ADMIN_ROLE, msg.sender)) {
            revert CallerNotAdmin(msg.sender);
        }

        for (uint256 i; i < actors.length; i++) {
            _mint(actors[i], bonus);
        }
    }

    function buyDRNK() public payable {
        require(msg.value >= topUpMin, "Error: minmum price uncovered");
        require(block.timestamp <= topUpExpires, "Top-up window expired");
        if (fanExists(msg.sender)) {
            _mint(
                msg.sender,
                fansIndex[msg.sender].multiplier * msg.value * 1000
            );
        } else {
            _mint(msg.sender, msg.value * 1000);
        }
    }

    function _mint(address to, uint256 amount) internal {
        if (fanExists(to)) {
            drnk.mint(to, amount);
            fansIndex[to].expires = block.timestamp + 4 weeks;
        } else {
            fans.push(to);
            drnk.mint(to, amount);
            // welcome bonus
            fansIndex[to] = Fan(bonus, block.timestamp + 4 weeks);
        }
    }

    function burn(uint256 _amount) public {
        require(drnk.balanceOf(msg.sender) > 0);
        require(drnk.allowance(msg.sender, address(this)) >= _amount);

        drnk.burnFrom(msg.sender, _amount);

        //if(drnk.balanceOf(msg.sender) == 0) {
        //    ToDo Remove Fan, might get index on iters out of solidity ?
        //     because gas expensive and as parameter.
        //}
    }

    function registerDapp(bytes32 name, string memory cid) public payable {
        require(msg.value >= listingFee, "Error: listing fee uncovered");
        require(!DappNameExists(name));
        // solidity gimnastics...
        Dapp storage dp = dappsIndex[name];
        dp.cid = cid;
        dp.rate = 0;
        dp.weight_votes_sum = 0;
        dp.weight_total_sum = 0;
        dp.balance = 0;
        dp.burned = 0;
        dp.owner = msg.sender;
        dp.status = Status.Submitted;

        dapps.push(name);
        _mint(msg.sender, 10 * bonus);

        // emit DappRegistered(name, msg.sender, cid); // PROPUESTA The Graph
    }

    function approveDapp(bytes32 _name) external {
        require(DappNameExists(_name));
        require(
            hasRole(DEFAULT_ADMIN_ROLE, msg.sender) ||
                hasRole(DAO_ROLE, msg.sender)
        );
        dappsIndex[_name].status = Status.Active;

        // emit DappApproved(_name); // PROPUESTA The Graph
    }

    function banDapp(bytes32 _name) external {
        require(DappNameExists(_name));
        require(
            hasRole(DEFAULT_ADMIN_ROLE, msg.sender) ||
                hasRole(DAO_ROLE, msg.sender)
        );
        dappsIndex[_name].status = Status.Banned;

        // emit DappBanned(_name); // PROPUESTA The Graph
    }

    //function expiredDapp(bytes32 name) external {
    //    require(DappNameExists(name));
    //    require(hasRole(DEFAULT_ADMIN_ROLE, msg.sender) || hasRole(DAO_ROLE, msg.sender));
    //    // ToDo: require(many epoach of none votes))
    //    dappsIndex[name].status = Status.Expired;
    //}

    function updateDappCID(bytes32 name, string memory cid) external {
        require(DappNameExists(name));
        require(msg.sender == dappsIndex[name].owner);
        dappsIndex[name].cid = cid;

        // emit DappCIDUpdated(name, cid); // PROPUESTA The Graph
    }

    function rateDapp(bytes32 name, uint256 amount) external {}

    // @notice: index should be compute externally using getAllDapps
    function removeDapp(uint256 index, bytes32 name) public {
        require(
            index >= 0 && index < dapps.length,
            "index is out of dapps bounds"
        );
        require(dapps[index] == name, "index do not match with dapp name");
        require(DappNameExists(name));
        require(
            msg.sender == dappsIndex[name].owner ||
                hasRole(DEFAULT_ADMIN_ROLE, msg.sender) ||
                hasRole(DAO_ROLE, msg.sender)
        );
        dapps[index] = dapps[dapps.length - 1];
        dapps.pop();
        delete dappsIndex[name];

        // emit DappRemoved(name); // PROPUESTA The Graph
    }

    function removeFan(uint256 index, address fan) public {
        require(
            index >= 0 && index < dapps.length,
            "index is out of fans bounds"
        );
        require(fans[index] == fan, "index do not match with fan");
        require(fanExists(fan));
        require(!fanIsAlive(fan)); //fan is not alive
        require(
            msg.sender == fan ||
                hasRole(DEFAULT_ADMIN_ROLE, msg.sender) ||
                hasRole(DAO_ROLE, msg.sender)
        );
        fans[index] = fans[fans.length - 1];
        fans.pop();
        delete fansIndex[fan];
    }

    function fanIsAlive(address _fan) public view returns (bool) {
        return fansIndex[_fan].expires > block.timestamp;
    }

    function fanExists(address _fan) public view returns (bool) {
        Fan storage fn = fansIndex[_fan];
        return (!(fn.expires == 0 && fn.multiplier == 0));
    }

    function DappNameIsActive(bytes32 _dapp) public view returns (bool) {
        return dappsIndex[_dapp].status == Status.Active;
    }

    function DappNameExists(bytes32 _dapp) public view returns (bool) {
        Dapp storage dp = dappsIndex[_dapp];
        return (
            !(bytes(dp.cid).length == 0 &&
                dp.rate == 0 &&
                dp.weight_votes_sum == 0 &&
                dp.weight_total_sum == 0 &&
                dp.balance == 0 &&
                dp.burned == 0 &&
                dp.owner == address(0x0))
        );
    }

    function voteDapp(bytes32 _name, uint256 _amount, uint256 _rate) external {
        require(DappNameExists(_name), "Dapp does not exist");
        require(drnk.balanceOf(msg.sender) > 0, "Insufficient DRNK balance");
        require(
            drnk.allowance(msg.sender, address(this)) >= _amount,
            "Allowance not approved"
        );
        require(_rate > 0 && _rate <= 100, "Rate must be between 1 and 100");
        Fan memory voter = fansIndex[msg.sender];
        require(voter.expires > block.timestamp, "Voter is not a valid Fan");

        Dapp storage dapp = dappsIndex[_name];
        require(dapp.status == Status.Active, "Dapp is not active");

        // READY TO VOTE! ;)

        // increase lifetime and multiplier of Voter(fan) for the future game theory
        fansIndex[msg.sender].expires = block.timestamp + 4 weeks;
        fansIndex[msg.sender].multiplier += 1;

        //Add Vote struct to Dapp for the voter
        Vote storage vote = dapp.votes[msg.sender];
        vote.vote_rate = _rate;
        vote.fan_weight = Math.sqrt(_amount, Math.Rounding.Ceil);
        vote.timestamp = block.timestamp;

        // Square Root Weighted Voting (SRWV)
        dapp.weight_votes_sum += (vote.vote_rate * vote.fan_weight);
        dapp.weight_total_sum += vote.fan_weight;
        dapp.rate = dapp.weight_votes_sum / dapp.weight_total_sum;

        // emit VoteCast(_name, msg.sender, _rate, vote.fan_weight, block.timestamp, _amount); // PROPUESTA The Graph

        // Distribution
        //drnk.transferFrom(msg.sender, address(this), (_amount * DAOFee)); //charged on cashout
        drnk.transferFrom(msg.sender, address(this), _amount);
        drnk.approve(address(this), ((_amount * burnFee) / 10_000));
        drnk.burn((_amount * burnFee) / 10_000);
        dapp.burned += ((_amount * burnFee) / 10_000);
        dapp.balance +=
            _amount -
            ((_amount * burnFee) / 10_000) -
            ((_amount * DAOFee) / 10_000);

        // emit TokensBurned(_name, (_amount * burnFee) / 10_000); // PROPUESTA The Graph
    }

    function dappCashOut(bytes32 _name, uint256 _amount) external {
        require(DappNameExists(_name));
        Dapp storage dapp = dappsIndex[_name];
        require(dapp.status == Status.Active, "Dapp is not active");
        require(dapp.owner == msg.sender, "Ups... You are not the dapp owner");

        // dapp.balance -= _amount; // PROPUESTA The Graph: mantener contabilidad en sync
        drnk.approve(msg.sender, _amount - ((_amount * DAOFee) / 10_000));
        drnk.transfer(msg.sender, _amount - ((_amount * DAOFee) / 10_000)); //charged on cashout
        drnk.transfer(DAOAddrss, (_amount * DAOFee) / 10_000); //charged on cashout

        // emit DappCashOut(_name, msg.sender, _amount); // PROPUESTA The Graph
    }

    function getAllFans() external view returns (address[] memory) {
        return fans;
    }

    function getAllDappNames() external view returns (bytes32[] memory) {
        return dapps;
    }

    // ToDo check with the Solidity Gimnastics storage how to handle
    //function getDappInfoStruct(bytes32 _dapp) public view returns(Dapp calldata) {
    //    require(DappNameExists(_dapp));
    //    return dappsIndex[_dapp];
    //}

    function getDappInfo(
        bytes32 _dapp
    )
        public
        view
        returns (
            string memory cid,
            uint256 rate,
            uint256 weight_votes_sum,
            uint256 weight_total_sum,
            uint256 balance,
            uint256 burned,
            address owner,
            bytes32 status
        )
    {
        require(DappNameExists(_dapp));
        Dapp storage dp = dappsIndex[_dapp];
        return (
            dp.cid,
            dp.rate,
            dp.weight_votes_sum,
            dp.weight_total_sum,
            dp.balance,
            dp.burned,
            dp.owner,
            _mapDappStatusToBytes32(dp.status)
        );
    }

    function _mapDappStatusToBytes32(
        Status status
    ) internal pure returns (bytes32) {
        if (status == Status.Submitted) {
            return bytes32("Submitted");
        } else if (status == Status.Active) {
            return bytes32("Active");
        } else if (status == Status.Expired) {
            return bytes32("Expired");
        } else if (status == Status.Banned) {
            return bytes32("Banned");
        } else {
            revert UnknownStatus(status);
        }
    }

    function getFanInfo(address _fan) external view returns (uint256, uint256) {
        Fan storage fanData = fansIndex[_fan];
        return (fanData.expires, fanData.multiplier);
    }

    function getFanInfoStruct(address _fan) external view returns (Fan memory) {
        require(fanExists(_fan));
        return fansIndex[_fan];
    }
}
