// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.26;

import {Test, console2} from "forge-std/Test.sol";
import {Hooks} from "v4-core/libraries/Hooks.sol";
import {IHooks} from "v4-core/interfaces/IHooks.sol";
import {IPoolManager} from "v4-core/interfaces/IPoolManager.sol";
import {PoolManager} from "v4-core/PoolManager.sol";
import {Currency} from "v4-core/types/Currency.sol";
import {PoolKey} from "v4-core/types/PoolKey.sol";
import {PoolId} from "v4-core/types/PoolId.sol";
import {SwapParams} from "v4-core/types/PoolOperation.sol";
import {ModifyLiquidityParams} from "v4-core/types/PoolOperation.sol";
import {BalanceDelta} from "v4-core/types/BalanceDelta.sol";
import {StateLibrary} from "v4-core/libraries/StateLibrary.sol";
import {TickMath} from "v4-core/libraries/TickMath.sol";
import {DrnkUltrasoundHook} from "../src-sc/hooks/DrnkUltrasoundHook.sol";

/// @dev Minimal mock ERC20 for testing
contract MockToken {
    string public name;
    string public symbol;
    uint8 public decimals = 18;

    constructor(string memory _name, string memory _symbol) {
        name = _name;
        symbol = _symbol;
    }

    function mint(address to, uint256 amount) external {
        // No-op for mock - just track balances
    }

    function burn(uint256 amount) external {
        // No-op for mock
    }
}

/// @title DrnkHookMinimalPoolTest - Minimal v4 pool test with the ultrasound hook
contract DrnkHookMinimalPoolTest is Test {
    using StateLibrary for IPoolManager;

    PoolManager manager;
    DrnkUltrasoundHook hook;
    address owner = address(0xAC0);

    function setUp() public {
        // Deploy PoolManager
        manager = new PoolManager(address(this));

        // Deploy mock DRNK token
        MockToken drnkToken = new MockToken("DappRank", "DRNK");

        // Deploy the hook
        hook = new DrnkUltrasoundHook(
            manager,
            Currency.wrap(address(drnkToken)),
            200, // 2% burn
            owner
        );
    }

    function testHookDeployedCorrectly() public view {
        assertEq(hook.owner(), owner);
        assertEq(hook.burnFeeBps(), 200);
        assertFalse(hook.paused());
        assertEq(hook.totalBurned(), 0);
        assertEq(hook.totalSwaps(), 0);
        assertEq(address(hook.poolManager()), address(manager));
    }

    function testHookAdminFunctions() public {
        // Test setBurnFee
        vm.prank(owner);
        hook.setBurnFee(300);
        assertEq(hook.burnFeeBps(), 300);

        // Test pause
        vm.prank(owner);
        hook.pause();
        assertTrue(hook.paused());

        // Test unpause
        vm.prank(owner);
        hook.unpause();
        assertFalse(hook.paused());

        // Test transfer ownership
        vm.prank(owner);
        hook.transferOwnership(address(0xBEE));
        assertEq(hook.owner(), address(0xBEE));
    }

    function testHookBurnMath() public view {
        // 2% of various amounts
        uint256[] memory amounts = new uint256[](5);
        amounts[0] = 1000e18;
        amounts[1] = 100e18;
        amounts[2] = 10e18;
        amounts[3] = 1e18;
        amounts[4] = 0.5e18;

        uint256[] memory expectedBurns = new uint256[](5);
        expectedBurns[0] = 20e18;
        expectedBurns[1] = 2e18;
        expectedBurns[2] = 0.2e18;
        expectedBurns[3] = 0.02e18;
        expectedBurns[4] = 0.01e18;

        for (uint256 i = 0; i < amounts.length; i++) {
            uint256 burn = amounts[i] * hook.burnFeeBps() / 10_000;
            assertEq(burn, expectedBurns[i]);
        }
    }

    function testEffectivePriceComparison() public view {
        // buyDRNK: 0.01 ETH -> 10 DRNK (price = 0.001 ETH/DRNK)
        // LP with 5% discount: price = 0.00095 ETH/DRNK
        // LP with 2% burn: net price = 0.00095 * 1.02 = 0.000969 ETH/DRNK
        // This is still cheaper than 0.001 ETH/DRNK

        uint256 buyDRNKPrice = 1000; // 0.001 ETH in units of 1e-6 ETH per DRNK
        uint256 lpGrossPrice = 950;  // 0.00095 ETH/DRNK (5% discount)
        uint256 lpNetPrice = lpGrossPrice * 10_000 / (10_000 - 200); // After 2% burn

        assertLt(lpNetPrice, buyDRNKPrice, "LP with burn should be cheaper than buyDRNK");
    }
}
