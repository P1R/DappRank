// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.30;

import {Script, console} from "forge-std/Script.sol";
import {DappsManager} from "../src-sc/DappsManager.sol";
import {DappRank} from "../src-sc/DRNK.sol";

contract DappsManagerScript is Script {
    DappsManager public dappsMgr;
    DappRank public drnkToken;

    uint256 listingFee = 100e16;
    uint256 burningFee = 1000; // 10%
    uint256 daoFee = 100; // 1 %
    uint256 bonus = 1000e18;
    address public owner;
    string[] public dappsURI;

    function setUp() public {
        //dappsURI = vm.envString("dapps", '\n');
        //owner = vm.envAddress("ACC0");
    }

    function run() public {
        //uint256 deployerPrivateKey = vm.envUint("PK0");

        // startBroadcast and stopBraodcast will let us execute transactions anything between them
        //vm.startBroadcast(deployerPrivateKey);
        vm.startBroadcast();

        dappsMgr = new DappsManager(
            listingFee,
            daoFee,
            burningFee,
            bonus
        );
        // Attach deployed token
        drnkToken = DappRank(address(dappsMgr.drnk()));
        console.log("-----------------------------------------------------");
        console.log("Dapps Indexer contract address is: ", address(dappsMgr));
        console.log("DRNK Token contract address is: ", address(address(dappsMgr.drnk())));

        vm.stopBroadcast();
    }
}
