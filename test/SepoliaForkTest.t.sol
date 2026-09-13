// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.26;

import {Test, console2} from "forge-std/Test.sol";
import {DappsManager} from "../src-sc/DappsManager.sol";
import {DappRank} from "../src-sc/DRNK.sol";

/// @title SepoliaForkTest - Tests against live Sepolia state via fork
/// @notice Run with: forge test --match-contract SepoliaForkTest --fork-url $SEPOLIA_RPC_URL
contract SepoliaForkTest is Test {
    DappsManager public dappsMgr;
    DappRank public drnkToken;

    // Live Sepolia addresses
    address constant DAPPS_MANAGER = 0x6b0EB389DD4B3ad4E9a28f56f971735aD2A85baD;
    address constant DRNK_TOKEN = 0x9549A8CcaB9fF25Cf5061bFBC5188Baed0615B60;
    address constant ACC0 = 0x934a406B7CAB0D8cB3aD201f0cdcA6a7855F43b0;

    function setUp() public {
        dappsMgr = DappsManager(DAPPS_MANAGER);
        drnkToken = DappRank(DRNK_TOKEN);
    }

    function testVerifyLiveState() public {
        assertEq(address(dappsMgr), DAPPS_MANAGER);
        assertEq(address(drnkToken), DRNK_TOKEN);
        assertEq(address(dappsMgr.drnk()), DRNK_TOKEN);
        assertEq(drnkToken.name(), "DappRank");
        assertEq(drnkToken.symbol(), "DRNK");
        assertEq(dappsMgr.burnFee(), 1000);
        assertEq(dappsMgr.DAOFee(), 100);
        assertEq(dappsMgr.topUpMin(), 0.001 ether);
        assertGe(drnkToken.totalSupply(), 44913e18);
        assertGe(drnkToken.balanceOf(ACC0), 39900e18);
    }

    function testTopUpState() public {
        uint256 expires = dappsMgr.topUpExpires();
        uint256 current = block.timestamp;
        console2.log("block.timestamp:", current);
        console2.log("topUpExpires:", expires);
        if (current > expires) {
            console2.log("topUp window has expired");
        } else {
            console2.log("topUp window is still active, remaining:", expires - current, "seconds");
        }
        // Record the state - don't assume expired or not
        assertTrue(expires > 0, "topUpExpires should be non-zero");
    }

    function testBuyDRNKOnFork() public {
        uint256 expires = dappsMgr.topUpExpires();
        if (block.timestamp > expires) {
            console2.log("Window expired - warping before expiry");
            vm.warp(expires - 1);
        }

        uint256 drnkBefore = drnkToken.balanceOf(ACC0);
        uint256 supplyBefore = drnkToken.totalSupply();

        (, uint256 multiplier) = dappsMgr.getFanInfo(ACC0);
        console2.log("ACC0 current multiplier:", multiplier);

        vm.deal(ACC0, 1 ether);
        vm.prank(ACC0);
        dappsMgr.buyDRNK{value: 0.01 ether}();

        uint256 drnkAfter = drnkToken.balanceOf(ACC0);
        uint256 supplyAfter = drnkToken.totalSupply();

        uint256 minted = drnkAfter - drnkBefore;
        uint256 expectedFirst = 10e18; // for a brand new buyer
        uint256 expectedRepeat = multiplier * 0.01 ether * 1000;

        console2.log("DRNK minted:", minted / 1e18, "DRNK");
        console2.log("Expected (multiplier=%d):", multiplier, expectedRepeat / 1e18, "DRNK");
        console2.log("Supply increase:", (supplyAfter - supplyBefore) / 1e18, "DRNK");

        // The actual result depends on whether ACC0 is already a fan
        if (multiplier == 0) {
            // First-time buyer: 10 DRNK
            assertEq(minted, expectedFirst, "First buy should mint 10 DRNK");
        } else {
            // Existing fan: multiplier * msg.value * 1000
            assertEq(minted, expectedRepeat, "Repeat buy should use multiplier");
        }
    }

    function testLPReserveCalculation() public {
        // LP target: 5% discount vs buyDRNK price (0.001 ETH/DRNK)
        // LP target price: 0.00095 ETH/DRNK
        // For 0.3 ETH: required DRNK = 0.3 / 0.00095

        uint256 ethReserve = 0.3 ether;
        uint256 drnkReserve = ethReserve * 1e18 / (0.001 ether * 95 / 100);

        console2.log("LP reserves for 5% discount:");
        console2.log("  ETH:  0.3 ETH");
        console2.log("  DRNK: %d wei units", drnkReserve);

        uint256 acc0Drnk = drnkToken.balanceOf(ACC0);
        assertLe(drnkReserve, acc0Drnk, "ACC0 must have enough DRNK");
    }

    function testVotingBurnMechanics() public {
        uint256 voteAmount = 1000e18;
        uint256 burnAmount = (voteAmount * dappsMgr.burnFee()) / 10_000;
        uint256 daoAmount = (voteAmount * dappsMgr.DAOFee()) / 10_000;

        assertEq(burnAmount, 100e18, "10% burn");
        assertEq(daoAmount, 10e18, "1% DAO");
        assertEq(voteAmount - burnAmount - daoAmount, 890e18, "dapp receives 89%");
    }
}
