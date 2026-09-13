// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.26;

import {Script} from "forge-std/Script.sol";
import {console2} from "forge-std/console2.sol";
import {DrnkUltrasoundHook} from "../src-sc/hooks/DrnkUltrasoundHook.sol";
import {IDappsManagerView} from "../src-sc/interfaces/IDappsManagerView.sol";
import {IPoolManager} from "v4-core/interfaces/IPoolManager.sol";
import {Currency} from "v4-core/types/Currency.sol";

/// @title Phase12Final - Deploy hook via CREATE2 with mined salt
contract Phase12Final is Script {
    IPoolManager constant POOL_MANAGER = IPoolManager(0xE03A1074c86CFeDd5C142C4F04F1a1536e203543);
    address constant DAPPS_MANAGER = 0x6b0EB389DD4B3ad4E9a28f56f971735aD2A85baD;
    address constant CREATE2_DEPLOYER = 0x4e59b44847B379578588920cA78FbF26C0b49864;

    uint160 constant FLAG_MASK = uint160(0x3FFF);
    uint160 constant BEFORE_INITIALIZE_FLAG = 1 << 13;
    uint160 constant AFTER_INITIALIZE_FLAG = 1 << 12;
    uint160 constant AFTER_SWAP_FLAG = 1 << 6;

    function run() public {
        vm.startBroadcast();

        IDappsManagerView dappsMgr = IDappsManagerView(DAPPS_MANAGER);
        address drnkAddr = dappsMgr.drnk();
        console2.logString("DRNK token:");
        console2.logAddress(drnkAddr);

        bytes memory constructorArgs = abi.encode(
            POOL_MANAGER,
            Currency.wrap(drnkAddr),
            uint128(200),
            msg.sender
        );
        bytes memory initCode = abi.encodePacked(
            type(DrnkUltrasoundHook).creationCode,
            constructorArgs
        );

        uint160 desiredFlags = BEFORE_INITIALIZE_FLAG | AFTER_INITIALIZE_FLAG | AFTER_SWAP_FLAG;
        (address hookAddr, bytes32 salt) = _findSalt(CREATE2_DEPLOYER, desiredFlags, initCode);

        console2.logString("Found salt:");
        console2.logUint(uint256(salt));
        console2.logString("Hook address:");
        console2.logAddress(hookAddr);

        // Deploy via CREATE2 deployer
        (bool success,) = CREATE2_DEPLOYER.call(
            abi.encodeWithSignature("create2(bytes32,bytes)", salt, initCode)
        );
        require(success, "CREATE2 deployment failed");

        // Verify
        DrnkUltrasoundHook hook = DrnkUltrasoundHook(hookAddr);
        console2.logString("Hook owner:");
        console2.logAddress(hook.owner());
        console2.logString("Burn fee:");
        console2.logUint(hook.burnFeeBps());
        console2.logString("DRNK currency:");
        console2.logAddress(Currency.unwrap(hook.drnkCurrency()));

        // Buy 0.01 ETH DRNK
        (bool buySuccess,) = DAPPS_MANAGER.call{value: 0.01 ether}(
            abi.encodeWithSignature("buyDRNK()")
        );
        require(buySuccess, "buyDRNK failed");

        console2.logString("Phase 12 deployment complete");
        console2.logAddress(hookAddr);

        vm.stopBroadcast();
    }

    function _findSalt(
        address deployer,
        uint160 desiredFlags,
        bytes memory initCode
    ) internal pure returns (address hookAddr, bytes32 salt) {
        bytes32 initCodeHash = keccak256(initCode);
        for (uint256 s; s < 160_444; s++) {
            hookAddr = _computeCreate2(deployer, s, initCodeHash);
            if (uint160(hookAddr) & FLAG_MASK == desiredFlags) {
                return (hookAddr, bytes32(s));
            }
        }
        revert("HookMiner: could not find salt");
    }

    function _computeCreate2(
        address deployer,
        uint256 salt,
        bytes32 initCodeHash
    ) internal pure returns (address) {
        return address(
            uint160(
                uint256(
                    keccak256(
                        abi.encodePacked(
                            bytes1(0xff),
                            deployer,
                            salt,
                            initCodeHash
                        )
                    )
                )
            )
        );
    }
}
