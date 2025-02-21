// SPDX-License-Indentifier: MIT

pragma solidity ^0.8.28; 

import {Test} from "forge-std/Test.sol";
import {Raffle} from "../../src/Raffle.sol";
import {HelperConfig} from "../../script/HelperConfig.s.sol";
import {DeployRaffle} from "../../script/DeployRaffle.s.sol";

contract RaffleTest is Test {
    Raffle raffle;
    HelperConfig helperConfig;
    uint256 constant ENTRANCE_FEE = 5e15;
    address constant VRF_COORDINATOR_ADDRESS = 0x9DdfaCa8183c41ad55329BdeeD9F6A8d53168B1B; // Sepolia testnet
    address testUser = makeAddr("User");

    function setUp() external {
        (raffle, helperConfig) = new DeployRaffle();
    }

    function testRevertOnSendingNotEnoughEth() external {
        vm.prank(testUser);
        vm.expectRevert(Raffle.Raffle__NotEnoughEtherToEnterRaffle.selector);
        raffle.enterRaffle();
    }

}

