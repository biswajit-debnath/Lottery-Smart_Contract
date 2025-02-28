// SPDX-License-Identifier: MIT

pragma solidity ^0.8.28;

// Helper contract for testing transfer failure
contract MaliciousContract {
    // Fallback function that reverts to simulate transfer failure
    fallback() external payable {
        revert("I reject payments");
    }

    receive() external payable {
        revert("I reject payments");
    }
}
