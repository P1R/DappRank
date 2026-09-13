// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.26;

import {Hooks} from "v4-core/libraries/Hooks.sol";
import {SafeCast} from "v4-core/libraries/SafeCast.sol";
import {IHooks} from "v4-core/interfaces/IHooks.sol";
import {IPoolManager} from "v4-core/interfaces/IPoolManager.sol";
import {PoolKey} from "v4-core/types/PoolKey.sol";
import {BalanceDelta} from "v4-core/types/BalanceDelta.sol";
import {Currency} from "v4-core/types/Currency.sol";
import {ModifyLiquidityParams, SwapParams} from "v4-core/types/PoolOperation.sol";
import {BeforeSwapDelta} from "v4-core/types/BeforeSwapDelta.sol";

/// @dev Minimal ERC20 burn interface for the DRNK token
interface IERC20Burn {
    function burn(uint256 amount) external;
}

/// @title DrnkUltrasoundHook
/// @notice Uniswap v4 hook that burns a configurable percentage of DRNK on each swap.
///         This creates deflationary pressure on the LP route, complementing the
///         DappsManager voting burns. Deployed as an additive-only contract; no
///         existing src-sc contracts are modified.
///
/// @dev    Hook permissions encoded in the deployed address:
///         - afterSwap (bit 7): extracts a burn fee from swap output
///
///         This hook does NOT hold user funds or issue shares.
///         It takes a fee from the PoolManager settlement and burns it immediately.
contract DrnkUltrasoundHook is IHooks {
    using Hooks for IHooks;
    using SafeCast for uint256;
    using SafeCast for int128;

    // === State ===
    IPoolManager public immutable poolManager;
    Currency public immutable drnkCurrency;
    address public owner;
    bool public paused;

    /// @notice Burn fee in basis points (e.g., 200 = 2%)
    uint128 public burnFeeBps;
    uint128 public constant MAX_BPS = 10_000;
    uint128 public constant MIN_BPS = 50; // 0.5%

    /// @notice Total DRNK burned by this hook
    uint256 public totalBurned;

    /// @notice Total swaps processed
    uint256 public totalSwaps;

    // === Events ===
    event BurnFeeUpdated(uint256 oldFee, uint256 newFee);
    event HookPaused(address indexed caller);
    event HookUnpaused(address indexed caller);
    event DrnkBurned(Currency currency, uint256 amount, uint256 totalBurned);
    event OwnershipTransferred(address indexed oldOwner, address indexed newOwner);

    // === Errors ===
    error OnlyOwner();
    error OnlyPoolManager();
    error DrnkHookPaused();
    error InvalidFee();
    error ZeroAddress();
    error HookNotImplemented();

    modifier onlyOwner() {
        if (msg.sender != owner) revert OnlyOwner();
        _;
    }

    modifier onlyPoolManager() {
        if (msg.sender != address(poolManager)) revert OnlyPoolManager();
        _;
    }

    /// @param _poolManager The Uniswap v4 PoolManager address
    /// @param _drnkCurrency The DRNK token currency
    /// @param _burnFeeBps Initial burn fee in basis points
    /// @param _owner The initial owner (account0 for PoC)
    constructor(
        IPoolManager _poolManager,
        Currency _drnkCurrency,
        uint128 _burnFeeBps,
        address _owner
    ) {
        if (address(_poolManager) == address(0)) revert ZeroAddress();
        if (_burnFeeBps < MIN_BPS || _burnFeeBps > MAX_BPS) revert InvalidFee();

        poolManager = _poolManager;
        drnkCurrency = _drnkCurrency;
        burnFeeBps = _burnFeeBps;
        owner = _owner;
    }

    // === Admin Functions ===

    function setBurnFee(uint128 _newFeeBps) external onlyOwner {
        if (_newFeeBps < MIN_BPS || _newFeeBps > MAX_BPS) revert InvalidFee();
        uint256 oldFee = burnFeeBps;
        burnFeeBps = _newFeeBps;
        emit BurnFeeUpdated(oldFee, _newFeeBps);
    }

    function pause() external onlyOwner {
        paused = true;
        emit HookPaused(msg.sender);
    }

    function unpause() external onlyOwner {
        paused = false;
        emit HookUnpaused(msg.sender);
    }

    function transferOwnership(address _newOwner) external onlyOwner {
        if (_newOwner == address(0)) revert ZeroAddress();
        address oldOwner = owner;
        owner = _newOwner;
        emit OwnershipTransferred(oldOwner, _newOwner);
    }

    // === IHooks Implementation ===

    function beforeInitialize(address, PoolKey calldata, uint160) external pure returns (bytes4) {
        return IHooks.beforeInitialize.selector;
    }

    function afterInitialize(address, PoolKey calldata, uint160, int24) external pure returns (bytes4) {
        return IHooks.afterInitialize.selector;
    }

    function beforeAddLiquidity(
        address, PoolKey calldata, ModifyLiquidityParams calldata, bytes calldata
    ) external pure returns (bytes4) {
        revert HookNotImplemented();
    }

    function afterAddLiquidity(
        address, PoolKey calldata, ModifyLiquidityParams calldata,
        BalanceDelta, BalanceDelta, bytes calldata
    ) external pure returns (bytes4, BalanceDelta) {
        revert HookNotImplemented();
    }

    function beforeRemoveLiquidity(
        address, PoolKey calldata, ModifyLiquidityParams calldata, bytes calldata
    ) external pure returns (bytes4) {
        revert HookNotImplemented();
    }

    function afterRemoveLiquidity(
        address, PoolKey calldata, ModifyLiquidityParams calldata,
        BalanceDelta, BalanceDelta, bytes calldata
    ) external pure returns (bytes4, BalanceDelta) {
        revert HookNotImplemented();
    }

    function beforeSwap(
        address, PoolKey calldata, SwapParams calldata, bytes calldata
    ) external pure returns (bytes4, BeforeSwapDelta, uint24) {
        revert HookNotImplemented();
    }

    /// @notice After a swap, extract a burn fee from the DRNK output and burn it.
    ///         Only fires when DRNK is the output token (unspecified currency).
    function afterSwap(
        address,
        PoolKey calldata key,
        SwapParams calldata params,
        BalanceDelta delta,
        bytes calldata
    ) external override onlyPoolManager returns (bytes4, int128) {
        if (paused) revert DrnkHookPaused();

        // Determine which currency is the output (unspecified)
        bool specifiedTokenIs0 = (params.amountSpecified < 0 == params.zeroForOne);
        (Currency outputCurrency, int128 outputAmount) =
            specifiedTokenIs0
                ? (key.currency1, delta.amount1())
                : (key.currency0, delta.amount0());

        // If output is negative, negate to get absolute value
        if (outputAmount < 0) outputAmount = -outputAmount;

        // Only burn if the output is DRNK
        if (!(outputCurrency == drnkCurrency)) return (IHooks.afterSwap.selector, 0);

        uint256 outputAbs = uint128(outputAmount);
        uint256 burnAmount = outputAbs * burnFeeBps / MAX_BPS;

        if (burnAmount > 0) {
            // Take the burn amount from the PoolManager settlement
            poolManager.take(drnkCurrency, address(this), burnAmount);
            // Burn immediately via the DRNK token's burn function
            IERC20Burn(Currency.unwrap(drnkCurrency)).burn(burnAmount);
            totalBurned += burnAmount;
            emit DrnkBurned(drnkCurrency, burnAmount, totalBurned);
        }

        totalSwaps++;
        return (IHooks.afterSwap.selector, 0);
    }

    function beforeDonate(
        address, PoolKey calldata, uint256, uint256, bytes calldata
    ) external pure returns (bytes4) {
        revert HookNotImplemented();
    }

    function afterDonate(
        address, PoolKey calldata, uint256, uint256, bytes calldata
    ) external pure returns (bytes4) {
        revert HookNotImplemented();
    }

    // === View Functions ===

    function getConfig() external view returns (
        address _owner,
        bool _paused,
        uint128 _burnFeeBps,
        uint256 _totalBurned,
        uint256 _totalSwaps
    ) {
        return (owner, paused, burnFeeBps, totalBurned, totalSwaps);
    }
}
