// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.30;

import {Script, console} from "forge-std/Script.sol";
import {DappsManager} from "../src-sc/DappsManager.sol";
import {DappRank} from "../src-sc/DRNK.sol";
import {Conversor} from "../src-sc/Conversor.sol";

contract DemoTestScript is Script {
    DappsManager public dappsMgr;
    DappRank public drnkToken;

    uint256 listingFee = 100e16;
    uint256 burningFee = 1000; // 10%
    uint256 daoFee = 100; // 1 %
    uint256 bonus = 1000e18;
    address public owner;
    address public actor1;
    address public actor2;
    address public actor3;
    address public actor4;
    address public actor5;
    address public dappsMgrAddress;
    string[] public dappURIs;
    string[] public dappNames;
    address[] public actors;

    function setUp() public {
        dappURIs = vm.envString("DAPPS", '\n');
        dappNames = vm.envString("DAPPNAMES", '\n');
        owner = vm.envAddress("ACC0");
        actor1 = vm.envAddress("ACC1");
        actor2 = vm.envAddress("ACC2");
        actor3 = vm.envAddress("ACC3");
        actor4 = vm.envAddress("ACC4");
        actor5 = vm.envAddress("ACC5");
        actors = [actor1, actor2, actor3, actor4, actor5];
        dappsMgrAddress = vm.envAddress("VITE_SMARTCONTRACTADDRS");
    }

    function run() public {
        uint256 deployerPrivateKey = vm.envUint("PK0");

        // startBroadcast and stopBraodcast will let us execute transactions anything between them
        vm.startBroadcast(deployerPrivateKey);

        //dappsMgr = new DappsManager(listingFee, daoFee, burningFee, bonus);
        console.log(dappsMgrAddress);
        dappsMgr =  DappsManager(dappsMgrAddress);
        // Attach deployed token
        drnkToken = DappRank(address(dappsMgr.drnk()));
        console.log("-----------------------------------------------------");
        console.log("Dapps contract address is: ", address(dappsMgr));
        console.log("DRNK Token contract address is: ", address(address(dappsMgr.drnk())));

        // Do airdrops
        dappsMgr.demoAirdrop(actors);
        for(uint i; i < actors.length; i++) {
            console.log("actor",i+1," balance is ", drnkToken.balanceOf(actors[i]));
        }

        //Register Dapps
        for (uint256 i; i < dappNames.length; i++) {
            dappsMgr.registerDapp{value: listingFee}(Conversor.stringToBytes32(dappNames[i]), dappURIs[i]);
        }

        bytes32[] memory dappsRegistry = dappsMgr.getAllDappNames();

        for (uint256 i; i < dappsRegistry.length; i++) {
            console.log("dapp",i+1,": ");
            console.log(Conversor.bytes32ToString(dappsRegistry[i]));
        }
        // Retrive Dapp
        string memory retCID;
        bytes32 status;

        // show submitted dapps status
        for (uint256 i; i < dappNames.length; i++) {
            (retCID,,,,,,, status) = dappsMgr.getDappInfo(Conversor.stringToBytes32(dappNames[i]));
            console.log(dappNames[i],"with CID", retCID);
            console.log("has Status:", Conversor.bytes32ToString(status));
        }

        console.log("-----------------------------------------------------------");

        // execute approval
        for (uint256 i; i < dappNames.length; i++) {
            dappsMgr.approveDapp(Conversor.stringToBytes32(dappNames[i]));
        }

        // show Active dapps status
        for (uint256 i; i < dappNames.length; i++) {
            (retCID,,,,,,, status) = dappsMgr.getDappInfo(Conversor.stringToBytes32(dappNames[i]));
            console.log(dappNames[i],"with CID", retCID);
            console.log("has Status:", Conversor.bytes32ToString(status));
        }

        console.log("-----------------------------------------------------------");

        // Voting Process
        uint256 vote_amount = 100e18;

        // allow daggTokens from broadcaster to dappsMgr
        drnkToken.approve(address(dappsMgr), vote_amount);
        uint256 allowanceAmount = drnkToken.allowance(owner, address(dappsMgr));
        console.log("Allowed for voting:", allowanceAmount);

        // test Voting for 80
        dappsMgr.voteDapp(Conversor.stringToBytes32(dappNames[0]), vote_amount, 80);
        console.log("Voted first dapp with a rate of 80 and wight of 100");

        //dappsMgr.dappCashOut(dappNames[0], 100e18);

        vm.stopBroadcast();
    }

}
