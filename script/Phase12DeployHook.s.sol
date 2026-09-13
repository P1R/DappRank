// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.26;

import {Script} from "forge-std/Script.sol";
import {console2} from "forge-std/console2.sol";
import {DrnkUltrasoundHook} from "../src-sc/hooks/DrnkUltrasoundHook.sol";
import {IDappsManagerView} from "../src-sc/interfaces/IDappsManagerView.sol";
import {IPoolManager} from "v4-core/interfaces/IPoolManager.sol";
import {Currency} from "v4-core/types/Currency.sol";

/// @title Phase12DeployHook - Mines CREATE2 salt, deploys hook with correct permission bits
contract Phase12DeployHook is Script {
    IPoolManager constant POOL_MANAGER = IPoolManager(0xE03A1074c86CFeDd5C142C4F04F1a1536e203543);
    address constant DAPPS_MANAGER = 0x6b0EB389DD4B3ad4E9a28f56f971735aD2A85baD;

    // AFTER_SWAP_FLAG = 1 << 6 = 0x40
    // The hook must have bit 6 set for PoolManager to call afterSwap
    uint160 constant REQUIRED_BIT = 1 << 6;

    function run() public {
        vm.startBroadcast();

        // 1. Read DRNK token from live DappsManager
        IDappsManagerView dappsMgr = IDappsManagerView(DAPPS_MANAGER);
        address drnkToken = dappsMgr.drnk();
        console2.logString("DRNK token:");
        console2.logAddress(drnkToken);

        // 2. Build constructor args
        bytes memory constructorArgs = abi.encode(
            POOL_MANAGER,
            Currency.wrap(drnkToken),
            uint128(200),  // 2% burn
            msg.sender     // owner = account0
        );

        // 3. Compute init code hash
        bytes memory initCode = abi.encodePacked(
            type(DrnkUltrasoundHook).creationCode,
            constructorArgs
        );
        bytes32 initCodeHash = keccak256(initCode);
        console2.logString("Init code hash:");
        console2.logBytes32(initCodeHash);

        // 4. Mine salt
        uint256 salt = _findValidSalt(msg.sender, initCodeHash, REQUIRED_BIT);
        address computed = _computeCreate2(msg.sender, salt, initCodeHash);

        console2.logString("Found valid salt:");
        console2.logUint(salt);
        console2.logString("Computed address:");
        console2.logAddress(computed);

        // 5. Verify permission bits
        uint160 bits = uint160(uint256(uint160(computed)));
        console2.logString("Permission bits:");
        console2.logUint(bits);
        require(bits & REQUIRED_BIT != 0, "AFTER_SWAP bit not set");

        // 6. Deploy via CREATE2
        address deployed;
        assembly {
            deployed := create2(0, add(initCode, 0x20), mload(initCode), salt)
        }
        require(deployed == computed, "CREATE2 mismatch");
        require(deployed != address(0), "Deployment failed");

        console2.logString("Hook deployed at:");
        console2.logAddress(deployed);

        // 7. Verify config
        DrnkUltrasoundHook hook = DrnkUltrasoundHook(deployed);
        console2.logString("Owner:");
        console2.logAddress(hook.owner());
        console2.logUint(hook.burnFeeBps());

        vm.stopBroadcast();
    }

    /// @dev Find a CREATE2 salt that produces an address with the required bit set
    function _findValidSalt(
        address deployer,
        bytes32 initCodeHash,
        uint160 requiredBit
    ) internal pure returns (uint256) {
        for (uint256 salt = 0; salt < 1_000_000; salt++) {
            address computed = _computeCreate2(deployer, salt, initCodeHash);
            if (uint160(uint256(uint160(computed))) & requiredBit != 0) {
                return salt;
            }
        }
        revert("No valid salt found within 1M iterations");
    }

    /// @dev Compute CREATE2 address
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
