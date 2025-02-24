// SPDX-License-Identifier: MIT

pragma solidity ^0.8.28; 

import {Test} from "forge-std/Test.sol";
import {Raffle} from "../../src/Raffle.sol";
import {HelperConfig} from "../../script/HelperConfig.s.sol";
import {DeployRaffle} from "../../script/DeployRaffle.s.sol";

contract RaffleTest is Test {
    Raffle raffle;
    HelperConfig helperConfig;
    DeployRaffle deployer;
    uint256 constant ENTRANCE_FEE = 5e15;
    address constant VRF_COORDINATOR_ADDRESS = 0x9DdfaCa8183c41ad55329BdeeD9F6A8d53168B1B; // Sepolia testnet
    address testUser = makeAddr("User");


    function setUp() external {
        deployer = new DeployRaffle();
        (raffle, helperConfig) = deployer.run();
    }


    function testRevertOnSendingNotEnoughEth() external {
        vm.prank(testUser);
        vm.expectRevert(Raffle.Raffle__NotEnoughEtherToEnterRaffle.selector);
        raffle.enterRaffle();
    }

    function testInternalStateAfterUserEntered() external {
        uint256 amountToInvest = raffle.getEntranceFeeAmountInEth();
        vm.deal(testUser, 1 ether);
        vm.prank(testUser);

        raffle.enterRaffle{value: amountToInvest}();

        
        assert(raffle.getAllCurrentPerticipantsOfLottery().length == 1);
        
        assert(raffle.getAllCurrentPerticipantsOfLottery()[0] == testUser);

        // Check if money is updated in the userToMoney mapping
        assert(raffle.getAmountInvestedByUser(testUser) == amountToInvest);

    }

    function testContractGotTheMoneyAfterUserEntered() external {
        uint256 amountToInvest = raffle.getEntranceFeeAmountInEth();
        uint256 initialContractBalance = address(raffle).balance;
        vm.deal(testUser, 1 ether);
        vm.prank(testUser);

        raffle.enterRaffle{value: amountToInvest}();
        uint256 contractBalanceAfterUserEntered = address(raffle).balance;

        assert(contractBalanceAfterUserEntered == initialContractBalance+amountToInvest);
    }

    function testSingleUserEntersMultipleTime() external {
        // User entered twice
        uint256 amountToInvest = raffle.getEntranceFeeAmountInEth();
        vm.deal(testUser, 2 ether);
        vm.startPrank(testUser);
        
        raffle.enterRaffle{value: amountToInvest}();
        raffle.enterRaffle{value: amountToInvest}();
        
        vm.stopPrank();

        // Check the s_raffleParticipants array only has single user
        address[] memory participants = raffle.getAllCurrentPerticipantsOfLottery();
        assertEq(participants.length, 1);
        assertEq(participants[0], testUser);

        // Check s_participantToAmount has correct amount for the entered user
        assertEq(raffle.getAmountInvestedByUser(testUser), amountToInvest * 2);
    }

    function testRevertEnterIfRaffleIsNotOpen() external {
        uint256 amountToInvest = raffle.getEntranceFeeAmountInEth();

        vm.deal(testUser, 1 ether);
        vm.prank(testUser);
        raffle.enterRaffle{value: amountToInvest}();

        address testUser2 = makeAddr("TestUser2");
        vm.deal(testUser2, 1 ether);
        vm.prank(testUser2);
        raffle.enterRaffle{value: amountToInvest}();

        raffle.runLottery();

    }

}

