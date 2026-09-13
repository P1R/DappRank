// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.36;

import {Script, console} from "forge-std/Script.sol";
import {DappsManager} from "../src-sc/DappsManager.sol";
import {DappRank} from "../src-sc/DRNK.sol";
import {Conversor} from "../src-sc/Conversor.sol";

contract DemoTestScript is Script {
    DappsManager public dappsMgr;
    DappRank public drnkToken;

    uint256 listingFee = 1e13;
    uint256 burningFee = 1000; // 10%
    uint256 daoFee = 100; // 1 %
    uint256 bonus = 1000e18;
    address public owner;
    address public dappsMgrAddress;
    string[] public dappURIs;
    string[] public dappNames;
    address[] public actors;
    string public dappToApprove;

    function setUp() public {
        owner = vm.envAddress("ACC0");
        dappsMgrAddress = vm.envAddress("VITE_SMARTCONTRACTADDRS");
        dappToApprove = "uniswap.org";
    }

    function run() public {
        //uint256 deployerPrivateKey = vm.envUint("PK0");

        // startBroadcast and stopBraodcast will let us execute transactions anything between them
        //vm.startBroadcast(deployerPrivateKey);
        vm.startBroadcast();
        //dappsMgr = new DappsManager(listingFee, daoFee, burningFee, bonus);
        console.log(dappsMgrAddress);
        dappsMgr = DappsManager(dappsMgrAddress);
        // Attach deployed token
        drnkToken = DappRank(address(dappsMgr.drnk()));
        console.log("-----------------------------------------------------");
        console.log("Dapps contract address is: ", address(dappsMgr));
        console.log("DRNK Token contract address is: ", address(address(dappsMgr.drnk())));

        bytes32[] memory dappsRegistry = dappsMgr.getAllDappNames();

        for (uint256 i; i < dappsRegistry.length; i++) {
            console.log("dapp", i + 1, ": ");
            console.log(Conversor.bytes32ToString(dappsRegistry[i]));
        }
        // Retrive Dapp
        string memory retCID;
        bytes32 status;

        // show submitted dapps status
        for (uint256 i; i < dappNames.length; i++) {
            (retCID,,,,,,, status) = dappsMgr.getDappInfo(Conversor.stringToBytes32(dappNames[i]));
            console.log(dappNames[i], "with CID", retCID);
            console.log("has Status:", Conversor.bytes32ToString(status));
        }

        console.log("-----------------------------------------------------------");

        // execute approval
        dappsMgr.approveDapp(Conversor.stringToBytes32(dappToApprove));
        //for (uint256 i; i < dappNames.length; i++) {
        //    dappsMgr.approveDapp(Conversor.stringToBytes32(dappNames[i]));
        //}

        // show Active dapps status
        for (uint256 i; i < dappNames.length; i++) {
            (retCID,,,,,,, status) = dappsMgr.getDappInfo(Conversor.stringToBytes32(dappNames[i]));
            console.log(dappNames[i], "with CID", retCID);
            console.log("has Status:", Conversor.bytes32ToString(status));
        }

        console.log("-----------------------------------------------------------");

        vm.stopBroadcast();
    }
}
