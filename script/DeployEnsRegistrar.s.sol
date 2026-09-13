// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.36;

import {Script, console2} from "forge-std/Script.sol";
import {DappRankEnsRegistrar} from "../src-sc/DappRankEnsRegistrar.sol";

// ============================================================================
// Despliega DappRankEnsRegistrar y le otorga ROLE_REGISTRAR en el subregistry
// de dapprank.eth. Se ejecuta UNA sola vez (acción del equipo).
//
// Uso:
//   source .env
//   forge script script/DeployEnsRegistrar.s.sol:DeployEnsRegistrarScript \
//     --rpc-url https://ethereum-sepolia-rpc.publicnode.com \
//     --private-key $PRIVATE_KEY --broadcast
// ============================================================================

interface IUserRegistry {
    function grantRootRoles(
        uint256 roleBitmap,
        address account
    ) external returns (bool);
}

contract DeployEnsRegistrarScript is Script {
    // Subregistry de dapprank.eth (v1 — desplegado por EnsSetup.s.sol con
    // roles admin incluidos, 2026-09-13)
    address internal constant SUBREGISTRY =
        0x1677CAc3620C9E55D60228b4000D2820CC246179;
    // ENSv2 Sepolia (deployment 2026-07-30)
    address internal constant RESOLVER_IMPL =
        0x9EAe5C2730a7dD16BDD1DeE6421a1B91e3B0365e;
    address internal constant FACTORY =
        0x10dC6333CDFe1FCEf624c6e0a8221b91804Cd7ef;

    uint256 internal constant ROLE_REGISTRAR = 1 << 0;

    function run() external {
        uint256 pk = vm.envUint("PRIVATE_KEY");
        vm.startBroadcast(pk);

        DappRankEnsRegistrar registrar = new DappRankEnsRegistrar(
            SUBREGISTRY,
            RESOLVER_IMPL,
            FACTORY,
            "dapprank"
        );
        console2.log("DappRankEnsRegistrar:", address(registrar));

        // Otorgar ROLE_REGISTRAR (root) al helper en el subregistry.
        // grantRootRoles (grantRoles rechaza ROOT_RESOURCE).
        // El firmante (wallet admin) tiene ROLE_REGISTRAR_ADMIN.
        IUserRegistry(SUBREGISTRY).grantRootRoles(
            ROLE_REGISTRAR,
            address(registrar)
        );
        console2.log("ROLE_REGISTRAR otorgado al helper");

        vm.stopBroadcast();
    }
}
