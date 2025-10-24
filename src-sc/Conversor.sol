// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.30;
library Conversor {
    function stringToBytes32(string memory source) public pure returns (bytes32 out) {
        bytes memory sourceBytes = bytes(source);
        require(sourceBytes.length <= 32, "string at most 32 bytes");

        assembly {
            // Load the 32 bytes of the string data
            out := mload(add(sourceBytes, 32))
        }
    }
    function bytes32ToString(bytes32 source) public pure returns (string memory) {
        // Concatenate the two bytes32 variables
        bytes memory concatenatedBytes = abi.encodePacked(source);
        // bytes memory concatenatedBytes = new bytes(source);

        // Truncate the concatenated bytes to 32 bytes
        bytes memory truncatedBytes = new bytes(32);
        for (uint i = 0; i < 32; i++) {
            truncatedBytes[i] = concatenatedBytes[i];
        }

        // Convert the truncated bytes to a string
        string memory str = string(truncatedBytes);

        return str;
    }
}
