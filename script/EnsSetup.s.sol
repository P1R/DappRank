// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.36;

import {Script, console2} from "forge-std/Script.sol";

// ============================================================================
// ENSv2 (Sepolia) — Setup del namespace DappRank
// ============================================================================
// Crea la infraestructura on-chain del premio ENS:
//   1. Despliega un UserRegistry (subregistry) para `dapprank.eth`
//   2. Lo conecta al nombre (ETHRegistry.setSubregistry + setParent)
//   3. Despliega un PermissionedResolver por dApp con sus records precargados
//      (dapprank.cid = CID IPFS, addr = owner) durante initialize()
//   4. Registra los subnames: <dappname>.dapprank.eth
//
// PREREQUISITO: `dapprank.eth` debe estar registrado en ENSv2 (Sepolia) y
// pertenecer a la cuenta que firma este script. Registrarlo desde el ENS
// Explorer (https://explorer.ens.domains, red Sepolia) — el pago es en USDC.
//
// Uso:
//   source .env
//   forge script script/EnsSetup.s.sol:EnsSetupScript \
//     --rpc-url $SEPOLIA_RPC_URL --private-key $PK0 --broadcast
//
// Direcciones canónicas ENSv2 Sepolia (2026-06-29):
//   https://github.com/ensdomains/contracts-v2/blob/main/contracts/docs/addresses/sepolia.md
// ============================================================================

// --- Interfaces mínimas (solo lo que usa el script) -------------------------

interface IVerifiableFactory {
    function deployProxy(
        address implementation,
        uint256 salt,
        bytes memory data
    ) external returns (address);
}

interface IETHRegistry {
    // Status: 0 AVAILABLE, 1 RESERVED, 2 REGISTERED
    function getStatus(uint256 anyId) external view returns (uint8);

    function getTokenId(uint256 anyId) external view returns (uint256);

    function setSubregistry(uint256 anyId, address registry) external;

    function getSubregistry(
        string calldata label
    ) external view returns (address);
}

interface IUserRegistry {
    function initialize(address rootAccount, uint256 roleBitmap) external;

    function setParent(address parent, string calldata label) external;

    function register(
        string calldata label,
        address owner,
        address registry,
        address resolver,
        uint256 roleBitmap,
        uint64 expiry
    ) external returns (uint256 tokenId);

    function getSubregistry(
        string calldata label
    ) external view returns (address);
}

interface IPermissionedResolver {
    function initialize(
        address admin,
        uint256 roleBitmap,
        bytes[] calldata setters
    ) external;
}

interface ITextResolver {
    function setText(
        bytes32 node,
        string calldata key,
        string calldata value
    ) external;
}

interface IAddrResolver {
    function setAddr(bytes32 node, address addr) external;
}

// --- Roles (RegistryRolesLib / PermissionedResolverLib) ---------------------

library RegistryRoles {
    uint256 internal constant REGISTRAR = 1 << 0;
    uint256 internal constant REGISTER_RESERVED = 1 << 4;
    uint256 internal constant SET_PARENT = 1 << 8;
    uint256 internal constant UNREGISTER = 1 << 12;
    uint256 internal constant RENEW = 1 << 16;
    uint256 internal constant SET_SUBREGISTRY = 1 << 20;
    uint256 internal constant SET_RESOLVER = 1 << 24;
    uint256 internal constant SET_URI = 1 << 36;
    uint256 internal constant CAN_NAME = 1 << 120;
    uint256 internal constant UPGRADE = 1 << 124;

    /// Todos los roles de root para la cuenta administradora del subregistry.
    /// Incluye los roles admin (<< 128) para poder delegar roles después
    /// (ej. ROLE_REGISTRAR al helper de registro automático).
    uint256 internal constant ALL =
        REGISTRAR |
            REGISTER_RESERVED |
            SET_PARENT |
            UNREGISTER |
            RENEW |
            SET_SUBREGISTRY |
            SET_RESOLVER |
            SET_URI |
            CAN_NAME |
            UPGRADE |
            ((REGISTRAR |
                REGISTER_RESERVED |
                SET_PARENT |
                UNREGISTER |
                RENEW |
                SET_SUBREGISTRY |
                SET_RESOLVER |
                SET_URI |
                CAN_NAME |
                UPGRADE) << 128);
}

library ResolverRoles {
    uint256 internal constant SET_ADDR = 1 << 0;
    uint256 internal constant SET_TEXT = 1 << 4;
    uint256 internal constant SET_CONTENTHASH = 1 << 8;
    uint256 internal constant SET_PUBKEY = 1 << 12;
    uint256 internal constant SET_ABI = 1 << 16;
    uint256 internal constant SET_INTERFACE = 1 << 20;
    uint256 internal constant SET_NAME = 1 << 24;
    uint256 internal constant SET_ALIAS = 1 << 28;
    uint256 internal constant CLEAR = 1 << 32;
    uint256 internal constant SET_DATA = 1 << 36;
    uint256 internal constant CAN_NAME = 1 << 120;
    uint256 internal constant UPGRADE = 1 << 124;

    uint256 internal constant ALL =
        SET_ADDR |
            SET_TEXT |
            SET_CONTENTHASH |
            SET_PUBKEY |
            SET_ABI |
            SET_INTERFACE |
            SET_NAME |
            SET_ALIAS |
            CLEAR |
            SET_DATA |
            CAN_NAME |
            UPGRADE;
}

contract EnsSetupScript is Script {
    // Estado compartido entre run() y los helpers (reduce stack pressure).
    address internal s_deployer;
    address internal s_subregistry;
    bytes32 internal s_domainNode;

    // ENSv2 Sepolia (canonical — deployment 2026-07-30, verificado on-chain)
    // Fuente: https://docs.ens.domains/learn/deployments/ (el doc del repo
    // contracts-v2/docs/addresses/sepolia.md quedó desactualizado 2026-06-29).
    address internal constant ETH_REGISTRY =
        0xBDC85dD5b15D7ecb354cd7cb6f2c50b4f2c4F0E2;
    address internal constant USER_REGISTRY_IMPL =
        0x624a25d67B59D587752EbEc8DdeD8827dAe52050;
    address internal constant PERMISSIONED_RESOLVER_IMPL =
        0x9EAe5C2730a7dD16BDD1DeE6421a1B91e3B0365e;
    address internal constant VERIFIABLE_FACTORY =
        0x10dC6333CDFe1FCEf624c6e0a8221b91804Cd7ef;

    // Dominio raíz (configurable por env: ENS_DOMAIN="dapprank" por defecto).
    // Si dapprank.eth ya está registrado en Sepolia por otra cuenta, usa otro
    // nombre libre (ej. ENS_DOMAIN="dapprankapp") y el mismo valor en
    // VITE_DAPPRANK_ENS_DOMAIN del frontend.
    string internal s_domain;
    string internal constant TLD = "eth";
    string internal constant CID_KEY = "dapprank.cid";

    // Duración de los subnames (1 año).
    uint64 internal constant SUBNAME_DURATION = 365 days;

    function run() external {
        uint256 deployerKey = vm.envUint("PRIVATE_KEY");
        address deployer = vm.addr(deployerKey);
        // Acepta "dapprank" o "dapprank.eth" (se normaliza a la etiqueta).
        s_domain = _stripTld(vm.envOr("ENS_DOMAIN", string("dapprank")));
        vm.startBroadcast(deployerKey);

        // --- 0. Verificar que <domain>.eth está registrado ------------------
        bytes32 domainNode = namehash(s_domain, TLD);
        bytes32 domainLabelHash = keccak256(bytes(s_domain));
        IETHRegistry ethRegistry = IETHRegistry(ETH_REGISTRY);
        uint8 status = ethRegistry.getStatus(uint256(domainLabelHash));
        require(
            status == 2,
            "<domain>.eth no esta registrado en ENSv2 (Sepolia)"
        );
        uint256 domainTokenId = ethRegistry.getTokenId(
            uint256(domainLabelHash)
        );
        console2.log(string.concat(s_domain, ".eth tokenId:"), domainTokenId);

        // --- 1. Desplegar el subregistry (UserRegistry) ---------------------
        // Salt determinista (mismo que usa ens-cli): keccak256(abi.encode(
        // keccak256("UserRegistry"), namehash(domain), version)).
        // version=1: el subregistry v0 (2026-09-13) no incluyó los roles admin
        // (<< 128) y no puede delegar ROLE_REGISTRAR al helper automático.
        uint256 registrySalt = uint256(
            keccak256(
                abi.encode(keccak256("UserRegistry"), domainNode, uint256(1))
            )
        );
        bytes memory registryInit = abi.encodeCall(
            IUserRegistry.initialize,
            (deployer, RegistryRoles.ALL)
        );
        address subregistry = IVerifiableFactory(VERIFIABLE_FACTORY)
            .deployProxy(USER_REGISTRY_IMPL, registrySalt, registryInit);
        console2.log("Subregistry (UserRegistry):", subregistry);

        // --- 2. Conectar el subregistry al nombre ---------------------------
        // El owner de <domain>.eth (deployer) tiene ROLE_SET_SUBREGISTRY.
        ethRegistry.setSubregistry(domainTokenId, subregistry);
        IUserRegistry(subregistry).setParent(ETH_REGISTRY, s_domain);
        console2.log(
            "Subregistry conectado a",
            string.concat(s_domain, ".eth")
        );

        // --- 3. Registrar subnames por dApp ---------------------------------
        // Formato env ENS_DAPPS: "label:owner:cid,label:owner:cid,..."
        // owner vacio -> deployer; cid vacio -> sin record.
        s_deployer = deployer;
        s_subregistry = subregistry;
        s_domainNode = domainNode;
        string memory ensDapps = vm.envOr("ENS_DAPPS", defaultDapps());
        string[] memory entries = split(ensDapps, ",");
        for (uint256 i = 0; i < entries.length; i++) {
            string[] memory parts = split(entries[i], ":");
            string memory label = parts[0];
            address owner = bytes(parts[1]).length > 0
                ? toAddress(parts[1])
                : deployer;
            string memory cid = bytes(parts[2]).length > 0 ? parts[2] : "";
            _registerSubname(label, owner, cid);
        }

        vm.stopBroadcast();
    }

    /// Registra un subname <label>.dapprank.eth con su resolver y records.
    function _registerSubname(
        string memory label,
        address owner,
        string memory cid
    ) internal {
        bytes32 subNode = subnameHash(label, s_domainNode);

        // Resolver por subname con records precargados en initialize()
        // (durante la inicializacion los setters saltan los chequeos de rol).
        bytes[] memory setters = new bytes[](bytes(cid).length > 0 ? 2 : 1);
        setters[0] = abi.encodeCall(IAddrResolver.setAddr, (subNode, owner));
        if (bytes(cid).length > 0) {
            setters[1] = abi.encodeCall(
                ITextResolver.setText,
                (subNode, CID_KEY, cid)
            );
        }
        uint256 resolverSalt = uint256(
            keccak256(
                abi.encode(
                    keccak256("PermissionedResolver"),
                    subNode,
                    uint256(1)
                )
            )
        );
        address resolver = IVerifiableFactory(VERIFIABLE_FACTORY).deployProxy(
            PERMISSIONED_RESOLVER_IMPL,
            resolverSalt,
            abi.encodeCall(
                IPermissionedResolver.initialize,
                (s_deployer, ResolverRoles.ALL, setters)
            )
        );

        // Registrar el subname en el subregistry (sin subregistry propio).
        IUserRegistry(s_subregistry).register(
            label,
            owner,
            address(0),
            resolver,
            0,
            uint64(block.timestamp + SUBNAME_DURATION)
        );
        console2.log(
            "Subname registrado:",
            string.concat(label, ".", s_domain, ".", TLD)
        );
        console2.log("  owner:", owner);
        console2.log("  resolver:", resolver);
        if (bytes(cid).length > 0) {
            console2.log("  dapprank.cid:", cid);
        }
    }

    // --- Helpers ------------------------------------------------------------

    /// Quita el sufijo ".eth" si viene incluido en ENS_DOMAIN.
    function _stripTld(
        string memory name
    ) internal pure returns (string memory) {
        bytes memory b = bytes(name);
        uint256 len = b.length;
        if (
            len > 4 &&
            b[len - 4] == 0x2e &&
            b[len - 3] == 0x65 &&
            b[len - 2] == 0x74 &&
            b[len - 1] == 0x68
        ) {
            return substring(name, 0, len - 4);
        }
        return name;
    }

    function labelhash(string memory label) internal pure returns (bytes32) {
        return keccak256(bytes(label));
    }

    function namehash(
        string memory label,
        string memory tld
    ) internal pure returns (bytes32) {
        bytes32 node = bytes32(0);
        node = keccak256(abi.encodePacked(node, labelhash(tld)));
        node = keccak256(abi.encodePacked(node, labelhash(label)));
        return node;
    }

    function subnameHash(
        string memory label,
        bytes32 parentNode
    ) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked(parentNode, labelhash(label)));
    }

    function defaultDapps() internal pure returns (string memory) {
        // Mismas dApps demo que script/DemoTest.s.sol (CIDs de envexample).
        // Nota: "desci.org" no es un label ENS valido (contiene un punto), se
        // usa "desci".
        return
            string.concat(
                "desci::bafybeidt6pwzf2n3q7gab6axfyh2bqhkobawtdbnrpgasfex4geqahcjsa",
                ",search::bafybeigep2fh4zdiat363qutigtlhcggwtojrdo7m24jljnmkb7nke6phq",
                ",nethunters::bafybeichiubhbdx6aafmx7ckdnjnvk6fxhlmdrwxwj2mx4pmfhjg3wdavy",
                ",deca::bafybeievgnjjc7gf7akrxoy4mc7yrs5rrh4chu3r5wvulaqeg5hp2xvhpm"
            );
    }

    function split(
        string memory s,
        string memory delimiter
    ) internal pure returns (string[] memory) {
        bytes memory b = bytes(s);
        bytes memory d = bytes(delimiter);
        uint256 count = 1;
        for (uint256 i = 0; i + d.length <= b.length; i++) {
            if (sliceEq(b, i, d)) count++;
        }
        string[] memory out = new string[](count);
        uint256 start = 0;
        uint256 idx = 0;
        for (uint256 i = 0; i + d.length <= b.length; i++) {
            if (sliceEq(b, i, d)) {
                out[idx++] = substring(s, start, i);
                start = i + d.length;
            }
        }
        out[idx] = substring(s, start, b.length);
        return out;
    }

    function sliceEq(
        bytes memory b,
        uint256 pos,
        bytes memory d
    ) internal pure returns (bool) {
        for (uint256 i = 0; i < d.length; i++) {
            if (b[pos + i] != d[i]) return false;
        }
        return true;
    }

    function substring(
        string memory s,
        uint256 start,
        uint256 end
    ) internal pure returns (string memory) {
        bytes memory b = bytes(s);
        bytes memory out = new bytes(end - start);
        for (uint256 i = start; i < end; i++) {
            out[i - start] = b[i];
        }
        return string(out);
    }

    function toAddress(string memory s) internal pure returns (address) {
        bytes memory b = bytes(s);
        require(
            b.length == 42 && b[0] == 0x30 && (b[1] == 0x78 || b[1] == 0x58),
            "bad addr"
        );
        uint160 result = 0;
        for (uint256 i = 2; i < 42; i++) {
            result = (result << 4) | uint160(hexVal(b[i]));
        }
        return address(result);
    }

    function hexVal(bytes1 c) internal pure returns (uint256) {
        uint8 v = uint8(c);
        if (v >= 48 && v <= 57) return v - 48;
        if (v >= 97 && v <= 102) return v - 87;
        if (v >= 65 && v <= 70) return v - 55;
        revert("bad hex");
    }
}
