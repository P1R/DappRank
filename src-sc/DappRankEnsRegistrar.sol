// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.36;

// ============================================================================
// DappRankEnsRegistrar — registro automático de subnames ENSv2
// ============================================================================
// Cuando una dApp se registra en DappsManager, la app llama a este contrato
// para crear su identidad ENSv2: <label>.dapprank.eth. Todo en una sola
// transacción (despliega el PermissionedResolver + registra el subname).
//
// El contrato necesita ROLE_REGISTRAR en el subregistry de dapprank.eth
// (otorgado una sola vez por la wallet administradora). Cualquier usuario
// puede llamar a registerSubname() — no requiere permisos especiales.
//
// El contrato estable (DappsManager.sol) NO se modifica: esta es una capa
// adicional que la app invoca después de registerDapp().
// ============================================================================

interface IVerifiableFactory {
    function deployProxy(
        address implementation,
        uint256 salt,
        bytes memory data
    ) external returns (address);
}

interface IUserRegistry {
    function register(
        string calldata label,
        address owner,
        address registry,
        address resolver,
        uint256 roleBitmap,
        uint64 expiry
    ) external returns (uint256 tokenId);
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

contract DappRankEnsRegistrar {
    address public immutable subregistry;
    address public immutable resolverImpl;
    address public immutable factory;
    string public domain;
    bytes32 public immutable domainNode;
    string public constant TLD = "eth";
    string public constant CID_KEY = "dapprank.cid";
    uint64 public constant SUBNAME_DURATION = 365 days;

    // Roles del resolver (PermissionedResolverLib) — se otorgan al owner del
    // subname para que pueda gestionar sus records después.
    uint256 internal constant RESOLVER_ROLES =
        (1 << 0) |
            (1 << 4) |
            (1 << 8) |
            (1 << 12) |
            (1 << 16) |
            (1 << 20) |
            (1 << 24) |
            (1 << 28) |
            (1 << 32) |
            (1 << 36) |
            (1 << 120) |
            (1 << 124);

    constructor(
        address subregistry_,
        address resolverImpl_,
        address factory_,
        string memory domain_
    ) {
        subregistry = subregistry_;
        resolverImpl = resolverImpl_;
        factory = factory_;
        domain = domain_;
        domainNode = _namehash(domain_, TLD);
    }

    /// Crea el subname <label>.<domain>.eth con su resolver y records.
    /// @return resolver Dirección del PermissionedResolver desplegado.
    function registerSubname(
        string calldata label,
        address owner,
        string calldata cid
    ) external returns (address resolver) {
        require(bytes(label).length > 0, "label vacio");
        require(!_containsDot(label), "label no puede contener '.'");
        require(owner != address(0), "owner invalido");

        bytes32 node = _subnameHash(label);

        // Resolver por subname con records precargados en initialize()
        // (durante la inicialización los setters saltan los chequeos de rol).
        bytes[] memory setters = new bytes[](2);
        setters[0] = abi.encodeCall(IAddrResolver.setAddr, (node, owner));
        setters[1] = abi.encodeCall(
            ITextResolver.setText,
            (node, CID_KEY, cid)
        );
        uint256 salt = uint256(
            keccak256(
                abi.encode(keccak256("PermissionedResolver"), node, uint256(0))
            )
        );
        bytes memory init = abi.encodeCall(
            IPermissionedResolver.initialize,
            (owner, RESOLVER_ROLES, setters)
        );
        resolver = IVerifiableFactory(factory).deployProxy(
            resolverImpl,
            salt,
            init
        );

        IUserRegistry(subregistry).register(
            label,
            owner,
            address(0),
            resolver,
            0,
            uint64(block.timestamp + SUBNAME_DURATION)
        );
    }

    function _subnameHash(string memory label) internal view returns (bytes32) {
        return keccak256(abi.encodePacked(domainNode, keccak256(bytes(label))));
    }

    function _namehash(
        string memory label,
        string memory tld
    ) internal pure returns (bytes32) {
        bytes32 node = bytes32(0);
        node = keccak256(abi.encodePacked(node, keccak256(bytes(tld))));
        node = keccak256(abi.encodePacked(node, keccak256(bytes(label))));
        return node;
    }

    function _containsDot(string memory s) internal pure returns (bool) {
        bytes memory b = bytes(s);
        for (uint256 i = 0; i < b.length; i++) {
            if (b[i] == 0x2e) return true;
        }
        return false;
    }
}
