// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.30;

import {Script, console} from "forge-std/Script.sol";
import {DappsManager} from "../src-sc/DappsManager.sol";

contract DappsManagerScript is Script {
    DappsManager public dappsMgr;
    uint256 listingFee = 100e16;
    uint256 burningFee = 10; // 10%
    uint256 daoFee = 1; // 1 %
    uint256 bonus = 1000e18;

    function setUp() public {}

    function run() public {
        vm.startBroadcast();

        dappsMgr = new DappsManager(
            listingFee,
            daoFee,
            burningFee,
            bonus
        );

        vm.stopBroadcast();
    }
}
