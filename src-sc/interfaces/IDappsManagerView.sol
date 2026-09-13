// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.26;

/// @title IDappsManagerView - Read-only interface for the deployed DappsManager
interface IDappsManagerView {
    function drnk() external view returns (address);
    function burnFee() external view returns (uint256);
    function DAOFee() external view returns (uint256);
    function topUpMin() external view returns (uint256);
    function topUpExpires() external view returns (uint256);
    function listingFee() external view returns (uint256);
}
