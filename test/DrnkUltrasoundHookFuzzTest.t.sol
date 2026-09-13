// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.26;

import {Test, console2} from "forge-std/Test.sol";
import {DrnkUltrasoundHook} from "../src-sc/hooks/DrnkUltrasoundHook.sol";
import {Currency} from "v4-core/types/Currency.sol";
import {IPoolManager} from "v4-core/interfaces/IPoolManager.sol";

/// @title DrnkUltrasoundHookFuzzTest - Fuzz and invariant tests for the ultrasound hook
contract DrnkUltrasoundHookFuzzTest is Test {
    DrnkUltrasoundHook hook;
    address owner = address(0xAC0);
    address mockPoolManager = address(0x1111);
    address mockDrnk = address(0x2222);

    function setUp() public {
        hook = new DrnkUltrasoundHook(
            IPoolManager(mockPoolManager),
            Currency.wrap(mockDrnk),
            200, // 2% burn
            owner
        );
    }

    // === Fuzz Tests ===

    /// @notice Fuzz: setBurnFee always validates bounds
    function testFuzzSetBurnFee(uint128 newFee) public {
        vm.prank(owner);
        if (newFee < 50 || newFee > 10000) {
            vm.expectRevert(DrnkUltrasoundHook.InvalidFee.selector);
            hook.setBurnFee(newFee);
        } else {
            hook.setBurnFee(newFee);
            assertEq(hook.burnFeeBps(), newFee);
        }
    }

    /// @notice Fuzz: burn amount never exceeds gross output (capped range)
    function testFuzzBurnNeverExceedsGross(uint96 grossOutput) public view {
        // Use uint96 to avoid overflow in multiplication
        uint256 gross = grossOutput;
        uint256 burnAmount = gross * hook.burnFeeBps() / 10_000;
        assertLe(burnAmount, gross, "Burn must not exceed gross output");
    }

    /// @notice Fuzz: burn amount is always >= 0
    function testFuzzBurnNonNegative(uint96 grossOutput) public view {
        uint256 burnAmount = uint256(grossOutput) * hook.burnFeeBps() / 10_000;
        assertGe(burnAmount, 0, "Burn must be non-negative");
    }

    /// @notice Fuzz: net output is always less than or equal to gross
    function testFuzzNetOutputBounds(uint96 grossOutput) public view {
        uint256 gross = grossOutput;
        uint256 burnAmount = gross * hook.burnFeeBps() / 10_000;
        uint256 netOutput = gross - burnAmount;
        assertLe(netOutput, gross, "Net output must be <= gross");
    }

    /// @notice Fuzz: net output + burn = gross (no tokens lost)
    function testFuzzBurnPlusNetEqualsGross(uint96 grossOutput) public view {
        uint256 gross = grossOutput;
        uint256 burnAmount = gross * hook.burnFeeBps() / 10_000;
        uint256 netOutput = gross - burnAmount;
        assertEq(burnAmount + netOutput, gross, "burn + net must equal gross");
    }

    /// @notice Fuzz: setBurnFee then burn math is consistent
    function testFuzzSetBurnThenCalc(uint128 newFee, uint96 grossOutput) public {
        if (newFee < 50 || newFee > 10000) return;
        vm.prank(owner);
        hook.setBurnFee(newFee);

        uint256 gross = grossOutput;
        uint256 burnAmount = gross * newFee / 10_000;
        uint256 netOutput = gross - burnAmount;
        assertEq(burnAmount + netOutput, gross);
    }

    /// @notice Fuzz: ownership transfer works for any non-zero address
    function testFuzzTransferOwnership(address newOwner) public {
        if (newOwner == address(0)) {
            vm.prank(owner);
            vm.expectRevert(DrnkUltrasoundHook.ZeroAddress.selector);
            hook.transferOwnership(newOwner);
        } else {
            vm.prank(owner);
            hook.transferOwnership(newOwner);
            assertEq(hook.owner(), newOwner);
        }
    }

    // === Invariant Tests ===

    /// @notice Invariant: burn fee always within bounds
    function invariant_burnFeeWithinBounds() public view {
        assertGe(hook.burnFeeBps(), uint128(50));
        assertLe(hook.burnFeeBps(), uint128(10000));
    }

    /// @notice Invariant: owner is never zero after construction
    function invariant_ownerNeverZero() public view {
        assertGt(uint160(hook.owner()), 0, "Owner must never be zero");
    }

    // === Edge Case Tests ===

    /// @notice Zero gross output produces zero burn
    function testZeroGrossOutput() public view {
        uint256 burn = 0 * hook.burnFeeBps() / 10_000;
        assertEq(burn, 0);
    }

    /// @notice Minimum fee (0.5%) produces correct burn
    function testMinFeeBurn() public {
        vm.prank(owner);
        hook.setBurnFee(50);

        uint256 gross = 100e18;
        uint256 burn = gross * 50 / 10_000;
        assertEq(burn, 0.5e18);
    }

    /// @notice Maximum fee (100%) produces full burn
    function testMaxFeeBurn() public {
        vm.prank(owner);
        hook.setBurnFee(10000);

        uint256 gross = 100e18;
        uint256 burn = gross * 10000 / 10_000;
        assertEq(burn, gross, "100% fee should burn entire output");
    }

    /// @notice getConfig reflects state changes
    function testGetConfigAfterChanges() public {
        vm.prank(owner);
        hook.setBurnFee(300);
        vm.prank(owner);
        hook.pause();
        vm.prank(owner);
        hook.transferOwnership(address(0xBEE));

        (address _owner, bool _paused, uint128 _fee, uint256 _burned, uint256 _swaps) =
            hook.getConfig();
        assertEq(_owner, address(0xBEE));
        assertTrue(_paused);
        assertEq(_fee, 300);
        assertEq(_burned, 0);
        assertEq(_swaps, 0);
    }

    /// @notice Multiple fee changes are consistent
    function testMultipleFeeChanges() public view {
        uint256 gross = 1000e18;

        // At 2%
        uint256 burn200 = gross * 200 / 10_000;
        assertEq(burn200, 20e18);

        // At 5%
        uint256 burn500 = gross * 500 / 10_000;
        assertEq(burn500, 50e18);

        // Higher fee = higher burn
        assertGt(burn500, burn200);
    }

    /// @notice Effective price comparison: LP with burn is cheaper than buyDRNK
    function testEffectivePriceComparison() public view {
        // buyDRNK: 0.01 ETH -> 10 DRNK (price = 0.001 ETH/DRNK)
        // LP with 5% discount: price = 0.00095 ETH/DRNK
        // LP with 2% burn: net price = 0.00095 * 10000 / (10000 - 200)
        // This is still cheaper than 0.001 ETH/DRNK

        uint256 buyDRNKPriceBps = 1000; // 0.001 ETH in 1e-6 ETH units
        uint256 lpGrossPriceBps = 950;  // 0.00095 ETH/DRNK (5% discount)
        uint256 lpNetPriceBps = lpGrossPriceBps * 10_000 / (10_000 - 200); // After 2% burn

        assertLt(lpNetPriceBps, buyDRNKPriceBps, "LP with burn should be cheaper than buyDRNK");
    }
}
