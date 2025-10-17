// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.30;

import {Test, console2} from "forge-std/Test.sol";
import {DappsManager} from "../src-sc/DappsManager.sol";
import {DappRank} from "../src-sc/DRNK.sol";

contract DappsManagerTest is Test {
    DappsManager public dappsMgr;
    DappRank public drnkToken;

    address nonAdmin = address(0x20);
    address[] testUsers = [ address(0x1),
        address(0x2),
        address(0x3),
        address(0x4),
        address(0x5)];

    uint256 listingFee = 100e16;
    uint256 burningFee = 10; // 10%
    uint256 daoFee = 1; // 1 %
    uint256 bonus = 1000e18;

    function setUp() public {
        dappsMgr = new DappsManager(
            listingFee,
            daoFee,
            burningFee,
            bonus
        );
        // Attach deployed token
        drnkToken = DappRank(address(dappsMgr.drnk()));
    }

    function testGetAllFansIsEmpty() public view {
        address[] memory fans = dappsMgr.getAllFans();
        assertEq(fans.length, 0, "Expected no fans initially");
    }

    function testRegisterDappRevertsDueToFees() public {
        bytes32 dappName = "TestDapp";
        string memory cid = "QmTestCID";

        // ToDo, add custom Error
        vm.expectRevert( "Error: listing fee uncovered");
        dappsMgr.registerDapp{value: 0}(dappName, cid);
    }

    function testDemoAirdropRevertsForNonAdmin() public {
        vm.prank(nonAdmin);
        vm.expectRevert(abi.encodeWithSelector(DappsManager.CallerNotAdmin.selector, nonAdmin));
        dappsMgr.demoAirdrop(testUsers);
    }

    function testApproveDappRevertsWhenDappNotExists() public {
        bytes32 dappName = "NonExistDapp";
        // Call from the admin (address(this) is admin) but since the dapp does not exist (status is not Active)
        vm.expectRevert();
        dappsMgr.approveDapp(dappName);
    }

    function testUpdateDappCIDRevertsForNonExistentDapp() public {
        bytes32 dappName = "NonExistDapp";
        string memory newCid = "QmNewCID";
        vm.expectRevert();
        dappsMgr.updateDappCID(dappName, newCid);
    }

    function testRemoveDappRevertsWhenIndexOutOfBounds() public {
        bytes32 dappName = "NonExistDapp";
        vm.expectRevert("index is out of dapps bounds");
        dappsMgr.removeDapp(0, dappName);
    }

    // Split into unit tests in the futue, this is dirty for the hackathon.
    function testAddDappLifeTime() public {
        bytes32 dappName = "dapp1";
        string memory cid = "QmNewCID";

        //Dapp memory dappSt;
        // First Dapp gets added
        dappsMgr.registerDapp{value: listingFee}(dappName, cid);
        assertEq(dappsMgr.getAllDappNames()[0], dappName);
        // Retrive Dapp
        string memory retCID;
        bytes32 status;
        (retCID, , , , , , status) = dappsMgr.getDappInfo(dappName);
        //console2.log("retrived status: ");
        //console2.logBytes32(status);
        //console2.log("retrived cid: ", retCID);
        assertEq(status, bytes32("Submitted"));
        assertEq(cid, retCID);
        // Then Dapp gets approved
        dappsMgr.approveDapp(dappName);
        (retCID, , , , , , status) = dappsMgr.getDappInfo(dappName);
        assertEq(status, bytes32("Active"));
        assertEq(cid, retCID);
        // After the Dapp gets banned
        dappsMgr.banDapp(dappName);
        (retCID, , , , , , status) = dappsMgr.getDappInfo(dappName);
        assertEq(status, bytes32("Banned"));
        assertEq(cid, retCID);
        // Then Dapp gets approved Again
        dappsMgr.approveDapp(dappName);
        (retCID, , , , , , status) = dappsMgr.getDappInfo(dappName);
        assertEq(status, bytes32("Active"));
        assertEq(cid, retCID);
        // Remove the Dapp
        //dappsMgr.removeDapp(dappName);
    }

    function testAddandRemoveDapp() external {
        bytes32 dappName = "dapp1";
        string memory cid = "QmNewCID";

        //Dapp memory dappSt;
        // First Dapp gets added
        dappsMgr.registerDapp{value: listingFee}(dappName, cid);
        assertEq(dappsMgr.getAllDappNames()[0], dappName);
        // Retrive Dapp
        string memory retCID;
        bytes32 status;
        (retCID, , , , , , status) = dappsMgr.getDappInfo(dappName);
        assertEq(status, bytes32("Submitted"));
        assertEq(cid, retCID);
        // Remove Dapp knowing the index...
        dappsMgr.removeDapp(0, dappName);
        assertEq(dappsMgr.getAllDappNames().length, 0);
    }

    function testAddandRemoveDappMany() external {
        bytes32[5] memory dappNames = [
            bytes32("dapp1"),
            bytes32("dapp2"),
            bytes32("dapp3"),
            bytes32("dapp4"),
            bytes32("dapp5")
        ];
        string[5] memory cids = [
            "QmNewCID1",
            "QmNewCID2",
            "QmNewCID3",
            "QmNewCID4",
            "QmNewCID5"
        ];
        // Retrive Dapp
        string memory retCID;
        bytes32 status;

        for(uint i; i < dappNames.length; i++) {
            dappsMgr.registerDapp{value: listingFee}(dappNames[i], cids[i]);
        }

        for(uint i; i < dappNames.length; i++) {
            (retCID, , , , , , status) = dappsMgr.getDappInfo(dappNames[i]);
            assertEq(status, bytes32("Submitted"));
            assertEq(retCID, cids[i]);
        }


        // remove all (ToDo, fix math looks dirty)
        bytes32[] memory dappN = dappsMgr.getAllDappNames();
        for(uint i = dappN.length; i > 0; i--) {
            //console2.log(i-1);
            console2.log(dappsMgr.DappNameExists(dappNames[i-1]));
            dappsMgr.removeDapp(i-1, dappNames[i-1]);
            console2.logBytes32(dappNames[i-1]);
            console2.log("removed dappname:",string(abi.encodePacked(dappNames[i-1])));
            console2.log(dappsMgr.DappNameExists(dappNames[i-1]));
            dappN = dappsMgr.getAllDappNames();
        }
        assertEq(dappsMgr.getAllDappNames().length, 0);
    }

    function testBurnTestUsersTokens() public {
        dappsMgr.demoAirdrop(testUsers);
        for(uint i; i < testUsers.length; i++) {
            assertEq(drnkToken.balanceOf(testUsers[i]), bonus);
        }

        // test burning from ERC20
        for(uint i; i < testUsers.length; i++) {
            vm.prank(testUsers[i]);
            drnkToken.burn(bonus);
            assertEq(drnkToken.balanceOf(testUsers[i]), 0);
        }

        // TEST delegated burn
        dappsMgr.demoAirdrop(testUsers);
        for(uint i; i < testUsers.length; i++) {
            assertEq(drnkToken.balanceOf(testUsers[i]), bonus);
        }

        // Delegate daggTokens from testUsers to dappsMgr
        for(uint i; i < testUsers.length; i++) {
            vm.prank(testUsers[i]);
            drnkToken.approve(address(dappsMgr), bonus);
            uint256 allowanceAmount = drnkToken.allowance(testUsers[i], address(dappsMgr));
            assertEq(allowanceAmount, bonus);
        }

        // test burning from ERC20
        for(uint i; i < testUsers.length; i++) {
            vm.prank(testUsers[i]);
            dappsMgr.burn(bonus);
            assertEq(drnkToken.balanceOf(testUsers[i]), 0);
        }

    }

    // ToDo signatures
    //function testAddandRemovefans() external {}
    //function testVote4Dapps() public {}
    //function testDappsExpire() public {}
    //function testFanLifeTime() public {}


}
