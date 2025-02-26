// SPDX-License-Identifier: MIT

pragma solidity ^0.8.28; 

import {Test, console, console2} from "forge-std/Test.sol";
import {Vm} from "forge-std/Vm.sol";
import {Raffle} from "../../src/Raffle.sol";
import {HelperConfig} from "../../script/HelperConfig.s.sol";
import {DeployRaffle} from "../../script/DeployRaffle.s.sol";
import {VRFCoordinatorV2_5Mock} from "@chainlink/contracts/src/v0.8/vrf/mocks/VRFCoordinatorV2_5Mock.sol"; 


contract RaffleTest is Test {
    Raffle raffle;
    HelperConfig helperConfig;
    DeployRaffle deployer;
    HelperConfig.NetworkConfig networkConfig;
    uint256 constant ENTRANCE_FEE = 5e15;
    // address constant VRF_COORDINATOR_ADDRESS = 0x9DdfaCa8183c41ad55329BdeeD9F6A8d53168B1B; // Sepolia testnet
    address testUser = makeAddr("User");

     event RandomNumberRequested(uint256 indexed reqId);


    function setUp() external {
        deployer = new DeployRaffle();
        (raffle, helperConfig) = deployer.run();
        networkConfig = helperConfig.getConfig();
    }


    /* Enter Raffle Function testing */
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

        address testUser3 = makeAddr("TestUser3");
        vm.deal(testUser3, 1 ether);
        vm.prank(testUser3);
        vm.expectRevert(Raffle.Raffle_RaffleNotOpen.selector);
        raffle.enterRaffle{value: amountToInvest}();
    }



    /* Run Lottery Function testing */
    function testRevertRunLotteryIfNoParticipants() external {
        vm.expectRevert(Raffle.Raffle__Not_Ready_To_Start.selector);
        raffle.runLottery();
    }
    
    function testRevertRunLotteryIfOnlyOneParticipant() external {
        uint256 amountToInvest = raffle.getEntranceFeeAmountInEth();
        vm.deal(testUser, 1 ether);
        vm.prank(testUser);
        raffle.enterRaffle{value: amountToInvest}();

        vm.expectRevert(Raffle.Raffle__Not_Ready_To_Start.selector);
        raffle.runLottery();
    }

    function testRaffleStateUpdatedToCalculatingAfterRunLottery() external {
        uint256 amountToInvest = raffle.getEntranceFeeAmountInEth();
        vm.deal(testUser, 1 ether);
        vm.prank(testUser);
        raffle.enterRaffle{value: amountToInvest}();

        address testUser2 = makeAddr("TestUser2");
        vm.deal(testUser2, 1 ether);
        vm.prank(testUser2);
        raffle.enterRaffle{value: amountToInvest}();

        raffle.runLottery();

        assertEq(raffle.getCurrentStateOfRaffle(), uint256(Raffle.RaffleState.CALCULATING)); // 1 represents Calculating state
    }

    function testRevertRunLotteryIfRaffleNotOpen() external {
        uint256 amountToInvest = raffle.getEntranceFeeAmountInEth();
        vm.deal(testUser, 1 ether);
        vm.prank(testUser);
        raffle.enterRaffle{value: amountToInvest}();

        address testUser2 = makeAddr("TestUser2");
        vm.deal(testUser2, 1 ether);
        vm.prank(testUser2);
        raffle.enterRaffle{value: amountToInvest}();

        raffle.runLottery();

        vm.expectRevert(Raffle.Raffle__Not_Ready_To_Start.selector);
        raffle.runLottery();
    }

    function testIfEventEmittedAfterRunLotteryCalled() external {
        uint256 amountToInvest = raffle.getEntranceFeeAmountInEth();
        vm.deal(testUser, 1 ether);
        vm.prank(testUser);
        raffle.enterRaffle{value: amountToInvest}();

        address testUser2 = makeAddr("TestUser2");
        vm.deal(testUser2, 1 ether);
        vm.prank(testUser2);
        raffle.enterRaffle{value: amountToInvest}();

       
        vm.expectEmit(true, false, false, false, 1);
        emit RandomNumberRequested(1);
        raffle.runLottery();
    }


    function testReqIdEventEmittedAfterRunLotteryCalled() external {
        uint256 amountToInvest = raffle.getEntranceFeeAmountInEth();
        vm.deal(testUser, 1 ether);
        vm.prank(testUser);
        raffle.enterRaffle{value: amountToInvest}();

        address testUser2 = makeAddr("TestUser2");
        vm.deal(testUser2, 1 ether);
        vm.prank(testUser2);
        raffle.enterRaffle{value: amountToInvest}();

        // call runLottery
        vm.recordLogs();
        uint256 reqId = raffle.runLottery();
        // check if the event is emitted
        Vm.Log[] memory entries = vm.getRecordedLogs();
        bytes32 requestedIdFromLog = entries[1].topics[1];

        assert(uint256(requestedIdFromLog) == reqId );
    }



    /* _pickWinnerAndSendPrize Function testing */

    function testWinnerSelectionLogicBasedOnRandomNumber() external {
        uint256 amountToInvest = raffle.getEntranceFeeAmountInEth();
        vm.deal(testUser, 1 ether);
        vm.prank(testUser);
        raffle.enterRaffle{value: amountToInvest}();

        address testUser2 = makeAddr("TestUser2");
        vm.deal(testUser2, 1 ether);
        vm.prank(testUser2);
        raffle.enterRaffle{value: amountToInvest}();

        uint256 reqId = raffle.runLottery();
        uint256 subIdFromRaffle = raffle.getSubscriptionId();

        // console.log("Subsciption id::", networkConfig.subId);
        // console.log("Subscription Id from rafle: ", subIdFromRaffle);
        // Act as VRFCoordinator and call fulfillRandomWords
        VRFCoordinatorV2_5Mock(networkConfig.vrfCoordinatorAddress).fulfillRandomWords(reqId, address(raffle));

    }


    

}

