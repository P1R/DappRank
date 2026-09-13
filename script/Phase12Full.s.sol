// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.26;

import {Script} from "forge-std/Script.sol";
import {console2} from "forge-std/console2.sol";
import {DrnkUltrasoundHook} from "../src-sc/hooks/DrnkUltrasoundHook.sol";
import {IDappsManagerView} from "../src-sc/interfaces/IDappsManagerView.sol";
import {IPoolManager} from "v4-core/interfaces/IPoolManager.sol";
import {Currency} from "v4-core/types/Currency.sol";
import {DappsManager} from "../src-sc/DappsManager.sol";
import {DappRank} from "../src-sc/DRNK.sol";

/// @title Phase12Full - Deploy hook, buy DRNK, verify
contract Phase12Full is Script {
    IPoolManager constant POOL_MANAGER = IPoolManager(0xE03A1074c86CFeDd5C142C4F04F1a1536e203543);
    address constant DAPPS_MANAGER = 0x6b0EB389DD4B3ad4E9a28f56f971735aD2A85baD;

    function run() public {
        vm.startBroadcast();

        // Step 1: Read live state
        IDappsManagerView dappsMgr = IDappsManagerView(DAPPS_MANAGER);
        address drnkAddr = dappsMgr.drnk();
        uint256 topUpExpires = dappsMgr.topUpExpires();

        console2.logString("=== Step 1: Live State ===");
        console2.logAddress(DAPPS_MANAGER);
        console2.logAddress(drnkAddr);

        require(block.timestamp <= topUpExpires, "Top-up window expired");
        console2.logUint(topUpExpires);

        // Step 2: Deploy hook
        console2.logString("=== Step 2: Deploy Hook ===");
        DrnkUltrasoundHook hook = new DrnkUltrasoundHook(
            POOL_MANAGER,
            Currency.wrap(drnkAddr),
            200,
            msg.sender
        );
        console2.logAddress(address(hook));

        // Step 3: Buy 0.01 ETH of DRNK
        console2.logString("=== Step 3: Buy 0.01 ETH DRNK ===");
        DappsManager dappsManager = DappsManager(DAPPS_MANAGER);
        uint256 drnkBefore = DappRank(drnkAddr).balanceOf(msg.sender);
        dappsManager.buyDRNK{value: 0.01 ether}();
        uint256 drnkAfter = DappRank(drnkAddr).balanceOf(msg.sender);
        uint256 drnkMinted = drnkAfter - drnkBefore;
        console2.logUint(drnkMinted);

        console2.logString("=== Phase 12 Complete ===");
        console2.logAddress(address(hook));

        vm.stopBroadcast();
    }
}
