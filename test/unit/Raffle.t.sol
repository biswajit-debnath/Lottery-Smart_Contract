// SPDX-License-Indentifier: MIT

pragma solidity ^0.8.28; 

import {Test} from "forge-std/Test.sol";
import {Raffle} from "../../src/Raffle.sol";

contract RaffleTest is Test {
    Raffle raffle;
    uint256 constant ENTRANCE_FEE = 5e15;
    address constant VRF_COORDINATOR_ADDRESS = 0x9DdfaCa8183c41ad55329BdeeD9F6A8d53168B1B; // Sepolia testnet
    address testUser = makeAddr("User");

    function setUp() external {
        raffle = new Raffle(ENTRANCE_FEE, VRF_COORDINATOR_ADDRESS);
    }

    function testRevertOnSendingNotEnoughEth() external {
        vm.prank(testUser);
        vm.expectRevert(Raffle.Raffle__NotEnoughEtherToEnterRaffle.selector);
        raffle.enterRaffle();
    }

}

