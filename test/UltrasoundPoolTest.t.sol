// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.26;

import {Test, console2} from "forge-std/Test.sol";
import {Hooks} from "v4-core/libraries/Hooks.sol";
import {IHooks} from "v4-core/interfaces/IHooks.sol";
import {IPoolManager} from "v4-core/interfaces/IPoolManager.sol";
import {PoolManager} from "v4-core/PoolManager.sol";
import {Currency, CurrencyLibrary} from "v4-core/types/Currency.sol";
import {PoolKey} from "v4-core/types/PoolKey.sol";
import {PoolId} from "v4-core/types/PoolId.sol";
import {ModifyLiquidityParams} from "v4-core/types/PoolOperation.sol";
import {BalanceDelta} from "v4-core/types/BalanceDelta.sol";
import {StateLibrary} from "v4-core/libraries/StateLibrary.sol";
import {HookMiner} from "lib/v4-periphery/test/shared/HookMiner.sol";
import {CurrencySettler} from "lib/v4-core/test/utils/CurrencySettler.sol";
import {PoolModifyLiquidityTest} from "v4-core/test/PoolModifyLiquidityTest.sol";

import {DrnkUltrasoundHook} from "../src-sc/hooks/DrnkUltrasoundHook.sol";

/// @dev Minimal mock ERC20 for testing
contract MockERC20 {
    string public name;
    string public symbol;
    uint8 public decimals = 18;
    mapping(address => uint256) public balanceOf;
    mapping(address => mapping(address => uint256)) public allowance;

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);

    constructor(string memory _name, string memory _symbol) {
        name = _name;
        symbol = _symbol;
    }

    function mint(address to, uint256 amount) external {
        balanceOf[to] += amount;
        emit Transfer(address(0), to, amount);
    }

    function approve(address spender, uint256 amount) external returns (bool) {
        allowance[msg.sender][spender] = amount;
        emit Approval(msg.sender, spender, amount);
        return true;
    }

    function transfer(address to, uint256 amount) external returns (bool) {
        balanceOf[msg.sender] -= amount;
        balanceOf[to] += amount;
        emit Transfer(msg.sender, to, amount);
        return true;
    }

    function transferFrom(address from, address to, uint256 amount) external returns (bool) {
        allowance[from][msg.sender] -= amount;
        balanceOf[from] -= amount;
        balanceOf[to] += amount;
        emit Transfer(from, to, amount);
        return true;
    }

    function burn(uint256 amount) external {
        balanceOf[msg.sender] -= amount;
        emit Transfer(msg.sender, address(0), amount);
    }
}

/// @title UltrasoundPoolTest - Pool creation and liquidity seeding test
contract UltrasoundPoolTest is Test {
    using StateLibrary for IPoolManager;
    using CurrencyLibrary for Currency;
    using CurrencySettler for Currency;

    receive() external payable {}

    IPoolManager manager;
    PoolModifyLiquidityTest liquidityRouter;
    DrnkUltrasoundHook hook;

    MockERC20 drnkToken;
    address owner = address(this);

    uint160 constant AFTER_SWAP_FLAG = Hooks.AFTER_SWAP_FLAG;
    uint160 constant BEFORE_INITIALIZE_FLAG = Hooks.BEFORE_INITIALIZE_FLAG;
    uint160 constant AFTER_INITIALIZE_FLAG = Hooks.AFTER_INITIALIZE_FLAG;

    function setUp() public {
        // Deploy PoolManager
        manager = new PoolManager(owner);

        // Deploy pool liquidity test router
        liquidityRouter = new PoolModifyLiquidityTest(manager);

        // Deploy mock DRNK token
        drnkToken = new MockERC20("DappRank", "DRNK");

        // Mine salt for hook with correct permission bits
        uint160 desiredFlags = AFTER_SWAP_FLAG | BEFORE_INITIALIZE_FLAG | AFTER_INITIALIZE_FLAG;
        bytes memory constructorArgs = abi.encode(
            IPoolManager(address(manager)),
            Currency.wrap(address(drnkToken)),
            uint128(200), // 2% burn
            owner
        );

        (address hookAddress, bytes32 salt) = HookMiner.find(
            address(this),
            desiredFlags,
            type(DrnkUltrasoundHook).creationCode,
            constructorArgs
        );

        console2.log("Hook address:");
        console2.logAddress(hookAddress);

        // Deploy hook at mined address
        hook = new DrnkUltrasoundHook{salt: salt}(
            IPoolManager(address(manager)),
            Currency.wrap(address(drnkToken)),
            uint128(200),
            owner
        );

        // Verify address
        require(address(hook) == hookAddress, "Hook address mismatch");

        // Initialize pool: currency0 must be < currency1 numerically
        // So ETH (address 0) is currency0, DRNK is currency1
        uint160 sqrtPriceX96 = 79228162514264337593543950336; // sqrt(1) in Q64.96
        PoolKey memory key = PoolKey({
            currency0: Currency.wrap(address(0)),
            currency1: Currency.wrap(address(drnkToken)),
            fee: 3000,
            tickSpacing: 60,
            hooks: IHooks(hookAddress)
        });

        manager.initialize(key, sqrtPriceX96);
        console2.log("Pool initialized");

        // Mint DRNK to this contract for LP seeding
        drnkToken.mint(address(this), 1000e18);
        drnkToken.approve(address(liquidityRouter), type(uint256).max);

        // Add full-range liquidity
        // liquidityDelta is a pool-specific unit, not token amount
        // Use a small value that fits within our 0.3 ETH
        ModifyLiquidityParams memory params = ModifyLiquidityParams({
            tickLower: -887220,
            tickUpper: 887220,
            liquidityDelta: 1e10,
            salt: 0
        });

        liquidityRouter.modifyLiquidity{value: 0.3 ether}(key, params, "");

        console2.log("Liquidity seeded");
        console2.log("Set up complete");
    }

    function testHookPermissions() public view {
        require(
            uint160(address(hook)) & Hooks.AFTER_SWAP_FLAG != 0,
            "AFTER_SWAP flag not set"
        );
        require(
            uint160(address(hook)) & Hooks.BEFORE_INITIALIZE_FLAG != 0,
            "BEFORE_INITIALIZE flag not set"
        );
        require(
            uint160(address(hook)) & Hooks.AFTER_INITIALIZE_FLAG != 0,
            "AFTER_INITIALIZE flag not set"
        );
    }

    function testHookConfig() public view {
        (address _owner, bool _paused, uint128 _burnFeeBps, uint256 _totalBurned, uint256 _totalSwaps) =
            hook.getConfig();
        assertEq(_owner, owner);
        assertFalse(_paused);
        assertEq(_burnFeeBps, 200);
        assertEq(_totalBurned, 0);
        assertEq(_totalSwaps, 0);
    }

    function testPoolInitialized() public view {
        PoolKey memory key = PoolKey({
            currency0: Currency.wrap(address(0)),
            currency1: Currency.wrap(address(drnkToken)),
            fee: 3000,
            tickSpacing: 60,
            hooks: IHooks(address(hook))
        });

        (uint160 sqrtPriceX96,,,) = manager.getSlot0(key.toId());
        assertGt(sqrtPriceX96, 0, "Pool should be initialized");
        console2.log("Pool sqrtPriceX96:");
        console2.logUint(sqrtPriceX96);
    }
}
