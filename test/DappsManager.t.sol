// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.30;

import {Test, console2} from "forge-std/Test.sol";
import {DappsManager} from "../src-sc/DappsManager.sol";

contract DappsManagerTest is Test {
    DappsManager public dappsMgr;

    address nonAdmin = address(0x20);
    address[] testUsers = [ address(0x1),
        address(0x2),
        address(0x3),
        address(0x4),
        address(0x5)];

    uint256 fee = 100e16;
    uint256 bonus = 1000e18;

    function setUp() public {
        dappsMgr = new DappsManager(fee, bonus);
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
        dappsMgr.registerDapp{value: fee}(dappName, cid);
        assertEq(dappsMgr.getAllDappNames()[0], dappName);
        // Retrive Dapp
        string memory retCID;
        bytes32 status;
        (retCID, , , , ,status) = dappsMgr.getDappInfo(dappName);
        //console2.log("retrived status: ");
        //console2.logBytes32(status);
        //console2.log("retrived cid: ", retCID);
        assertEq(status, bytes32("Submitted"));
        assertEq(cid, retCID);
        // Then Dapp gets approved
        dappsMgr.approveDapp(dappName);
        (retCID, , , , ,status) = dappsMgr.getDappInfo(dappName);
        assertEq(status, bytes32("Active"));
        assertEq(cid, retCID);
        // After the Dapp gets banned
        dappsMgr.banDapp(dappName);
        (retCID, , , , ,status) = dappsMgr.getDappInfo(dappName);
        assertEq(status, bytes32("Banned"));
        assertEq(cid, retCID);
        // Then Dapp gets approved Again
        dappsMgr.approveDapp(dappName);
        (retCID, , , , ,status) = dappsMgr.getDappInfo(dappName);
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
        dappsMgr.registerDapp{value: fee}(dappName, cid);
        assertEq(dappsMgr.getAllDappNames()[0], dappName);
        // Retrive Dapp
        string memory retCID;
        bytes32 status;
        (retCID, , , , ,status) = dappsMgr.getDappInfo(dappName);
        assertEq(status, bytes32("Submitted"));
        assertEq(cid, retCID);
        // Remove Dapp knowing the index...
        dappsMgr.removeDapp(0, dappName);
        assertEq(dappsMgr.getAllDappNames().length, 0);
    }

    //function testAddandRemoveDappMany() external {
    //}

    //function testFanLifeTime() public {
    //}

    //function testVote4Dapps() public {}
    //function testDappsExpire() public {}

}
