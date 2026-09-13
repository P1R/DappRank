// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.26;

import {Script} from "forge-std/Script.sol";
import {console2} from "forge-std/console2.sol";
import {DrnkUltrasoundHook} from "../src-sc/hooks/DrnkUltrasoundHook.sol";
import {IDappsManagerView} from "../src-sc/interfaces/IDappsManagerView.sol";
import {IPoolManager} from "v4-core/interfaces/IPoolManager.sol";
import {Currency} from "v4-core/types/Currency.sol";

/// @title DeployDrnkHookCREATE2 - Deploys hook at a permission-compatible address
/// @notice Mines a salt so the deployed address has AFTER_SWAP bit (bit 6) set.
///         After deployment, verify the address bits match the hook's callback overrides.
///         Run with: forge script script/DeployDrnkHookCREATE2.s.sol --rpc-url $SEPOLIA_RPC_URL --private-key $PK0 --broadcast
contract DeployDrnkHookCREATE2 is Script {
    IPoolManager constant POOL_MANAGER = IPoolManager(0xE03A1074c86CFeDd5C142C4F04F1a1536e203543);
    address constant DAPPS_MANAGER = 0x6b0EB389DD4B3ad4E9a28f56f971735aD2A85baD;

    function run() public {
        vm.startBroadcast();

        IDappsManagerView dappsMgr = IDappsManagerView(DAPPS_MANAGER);
        address drnkToken = dappsMgr.drnk();
        console2.logString("DRNK token:");
        console2.logAddress(drnkToken);

        // Deploy bytecode for the hook constructor
        bytes memory initCode = abi.encodePacked(
            type(DrnkUltrasoundHook).creationCode,
            abi.encode(
                POOL_MANAGER,
                Currency.wrap(drnkToken),
                uint128(200),  // 2% burn
                msg.sender
            )
        );

        // AFTER_SWAP_FLAG = 1 << 6 = 0x40
        // We need the hook address to have bit 6 set.
        // Mine a salt using brute force.
        uint160 requiredBit = 1 << 6; // bit 6 = AFTER_SWAP

        console2.logString("Mining salt for address with AFTER_SWAP bit set...");

        for (uint256 salt = 0; salt < type(uint256).max; salt++) {
            address computed = computeCreate2Address(initCode, salt);
            if (uint160(computed) & requiredBit != 0) {
                console2.logString("Found valid salt:");
                console2.logUint(salt);
                console2.logString("Deploying hook at address:");
                console2.logAddress(computed);

                // Deploy using CREATE2
                address deployed;
                assembly {
                    deployed := create2(0, add(initCode, 0x20), mload(initCode), salt)
                }
                require(deployed == computed, "CREATE2 address mismatch");
                console2.logString("Hook deployed successfully!");
                console2.logAddress(deployed);

                // Verify
                DrnkUltrasoundHook hook = DrnkUltrasoundHook(deployed);
                console2.logString("Verifying config...");
                console2.logAddress(hook.owner());
                console2.logUint(hook.burnFeeBps());

                break;
            }
        }

        vm.stopBroadcast();
    }

    function computeCreate2Address(
        bytes memory bytecode,
        uint256 salt
    ) internal view returns (address) {
        return address(
            uint160(
                uint256(
                    keccak256(
                        abi.encodePacked(
                            bytes1(0xff),
                            address(this),
                            salt,
                            keccak256(bytecode)
                        )
                    )
                )
            )
        );
    }
}
