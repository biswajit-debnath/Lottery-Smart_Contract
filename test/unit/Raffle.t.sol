// SPDX-License-Identifier: MIT

pragma solidity 0.8.28;

import {Test, console, console2} from "forge-std/Test.sol";
import {Vm} from "forge-std/Vm.sol";
import {Raffle} from "../../src/Raffle.sol";
import {HelperConfig} from "../../script/HelperConfig.s.sol";
import {DeployRaffle} from "../../script/DeployRaffle.s.sol";
import {VRFCoordinatorV2_5Mock} from "@chainlink/contracts/src/v0.8/vrf/mocks/VRFCoordinatorV2_5Mock.sol";
import {MaliciousContract} from "../mock/MaliciousContract.sol";

/**
 * @title RaffleTest
 * @dev This contract contains unit tests for the Raffle smart contract(Main Contract).
 * It uses the Foundry framework for testing.
 *
 * The tests cover the following functionalities:
 * - Entering the raffle with insufficient funds
 * - Internal state updates after a user enters the raffle
 * - Contract balance updates after a user enters the raffle
 * - Single user entering the raffle multiple times
 * - Reverting when entering the raffle if it is not open
 * - Running the lottery with no participants
 * - Running the lottery with only one participant
 * - Updating the raffle state to CALCULATING after running the lottery
 * - Reverting when running the lottery if it is not open
 * - Emitting events after running the lottery
 * - Winner selection logic and state updates
 * - Correct winner address emitted in the event
 * - Handling winner transfer failure
 *
 * The contract uses helper contracts and mocks such as:
 * - DeployRaffle: For deploying the Raffle contract
 * - HelperConfig: For getting network configuration
 * - VRFCoordinatorV2_5Mock: For mocking VRF Coordinator responses
 * - MaliciousContract: For testing failure scenarios
 *
 * Events:
 * - Raffle.RandomNumberRequested: Emitted when a random number is requested
 * - Raffle.WinnerPicked: Emitted when a winner is picked
 */
contract RaffleTest is Test {
    Raffle raffle;
    HelperConfig helperConfig;
    DeployRaffle deployer;
    HelperConfig.NetworkConfig networkConfig;
    uint256 constant ENTRANCE_FEE = 5e15;
    address testUser = makeAddr("User");

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

        assert(contractBalanceAfterUserEntered == initialContractBalance + amountToInvest);
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
        vm.expectRevert(Raffle.Raffle__RaffleNotOpen.selector);
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
        emit Raffle.RandomNumberRequested(1);
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

        assert(uint256(requestedIdFromLog) == reqId);
    }

    /* _pickWinnerAndSendPrize Function testing */

    function testWinnerSelectionLogicAndStateUpdates() external {
        uint256 amountToInvest = raffle.getEntranceFeeAmountInEth();

        // Users enter raffle
        vm.deal(testUser, 1 ether);
        vm.prank(testUser);
        raffle.enterRaffle{value: amountToInvest}();

        address testUser2 = makeAddr("TestUser2");
        vm.deal(testUser2, 1 ether);
        vm.prank(testUser2);
        raffle.enterRaffle{value: amountToInvest}();

        // Setup initial balances
        uint256 initialBalanceUser1 = testUser.balance;
        uint256 initialBalanceUser2 = testUser2.balance;

        // Total prize amount
        uint256 totalPrize = amountToInvest * 2;

        uint256 reqId = raffle.runLottery();

        // Before fulfillment checks
        assertEq(address(raffle).balance, totalPrize);
        assertEq(raffle.getCurrentStateOfRaffle(), uint256(Raffle.RaffleState.CALCULATING));

        // Fulfill random words
        VRFCoordinatorV2_5Mock(networkConfig.vrfCoordinatorAddress).fulfillRandomWords(reqId, address(raffle));

        // Check raffle state is open
        assertEq(raffle.getCurrentStateOfRaffle(), uint256(Raffle.RaffleState.OPEN));

        // Check if contract balance is 0 after winner selection
        assertEq(address(raffle).balance, 0);

        // Check if s_raffleParticipants is cleared
        assertEq(raffle.getAllCurrentPerticipantsOfLottery().length, 0);

        // Check if s_participantToAmount is cleared for both users
        assertEq(raffle.getAmountInvestedByUser(testUser), 0);
        assertEq(raffle.getAmountInvestedByUser(testUser2), 0);

        // Check if one of the users got the prize (their balance increased by total prize amount)
        uint256 finalBalanceUser1 = testUser.balance;
        uint256 finalBalanceUser2 = testUser2.balance;

        bool user1Won = finalBalanceUser1 > initialBalanceUser1;
        bool user2Won = finalBalanceUser2 > initialBalanceUser2;

        assertTrue(user1Won || user2Won); // One user must have won
        assertTrue(!(user1Won && user2Won)); // Both users cannot win

        // If user1 won, check they received the total prize
        if (user1Won) {
            assertEq(finalBalanceUser1, initialBalanceUser1 + totalPrize);
            assertEq(finalBalanceUser2, initialBalanceUser2);
        } else {
            // If user2 won, check they received the total prize
            assertEq(finalBalanceUser2, initialBalanceUser2 + totalPrize);
            assertEq(finalBalanceUser1, initialBalanceUser1);
        }
    }

    function testCorrectWinnerAddressEmittedInEvent() external {
        uint256 amountToInvest = raffle.getEntranceFeeAmountInEth();

        // Setup users
        vm.deal(testUser, 1 ether);
        vm.prank(testUser);
        raffle.enterRaffle{value: amountToInvest}();

        address testUser2 = makeAddr("TestUser2");
        vm.deal(testUser2, 1 ether);
        vm.prank(testUser2);
        raffle.enterRaffle{value: amountToInvest}();

        uint256 reqId = raffle.runLottery();

        // Create predetermined random number to select testUser2 as winner
        uint256[] memory randomWords = new uint256[](2);
        randomWords[0] = 1;
        randomWords[1] = 1; // This will select testUser2

        // Expect winnerPicked event with specific winner address
        vm.expectEmit(true, false, false, false);
        emit Raffle.WinnerPicked(testUser2);

        VRFCoordinatorV2_5Mock(networkConfig.vrfCoordinatorAddress).fulfillRandomWordsWithOverride(
            reqId, address(raffle), randomWords
        );
    }

    function testWinnerSelectionLogic() external {
        uint256 amountToInvest = raffle.getEntranceFeeAmountInEth();

        // Setup participants
        vm.deal(testUser, 1 ether);
        vm.prank(testUser);
        raffle.enterRaffle{value: amountToInvest}();

        address testUser2 = makeAddr("TestUser2");
        vm.deal(testUser2, 1 ether);
        vm.prank(testUser2);
        raffle.enterRaffle{value: amountToInvest}();

        uint256 reqId = raffle.runLottery();

        // Create predetermined random number to test winner selection
        uint256[] memory randomWords = new uint256[](2);
        randomWords[0] = 1; // This should select the second participant
        randomWords[1] = 1;

        vm.recordLogs();
        VRFCoordinatorV2_5Mock(networkConfig.vrfCoordinatorAddress).fulfillRandomWordsWithOverride(
            reqId, address(raffle), randomWords
        );

        // Get the winner from the emitted event
        Vm.Log[] memory entries = vm.getRecordedLogs();
        bytes32 expectedEventSignature = keccak256("WinnerPicked(address)");

        address actualWinner;
        for (uint256 i = 0; i < entries.length; i++) {
            if (entries[i].topics[0] == expectedEventSignature) {
                actualWinner = address(uint160(uint256(entries[i].topics[1])));
                break;
            }
        }

        // Since randomWords[0] = 1, the second participant (testUser2) should be the winner
        assertEq(actualWinner, testUser2, "Winner selection logic failed");
    }

    function testWinnerTransferFailureReverts() external {
        uint256 amountToInvest = raffle.getEntranceFeeAmountInEth();

        // Create a malicious contract that rejects payments
        MaliciousContract maliciousContract = new MaliciousContract();

        // Setup participants
        vm.deal(address(maliciousContract), 1 ether);
        vm.prank(address(maliciousContract));
        raffle.enterRaffle{value: amountToInvest}();

        vm.deal(testUser, 1 ether);
        vm.prank(testUser);
        raffle.enterRaffle{value: amountToInvest}();

        uint256 reqId = raffle.runLottery();

        // Mock the random number to select the malicious contract as winner
        uint256[] memory randomWords = new uint256[](2);
        randomWords[0] = 0; // This will select the first participant (malicious contract)
        randomWords[1] = 0;
        VRFCoordinatorV2_5Mock(networkConfig.vrfCoordinatorAddress).fulfillRandomWordsWithOverride(
            reqId, address(raffle), randomWords
        );

        // Check current state should be open
        /**
         * Major security issue if payment sending the winner fails the contract will be stuct in calculating state
         */
        assertEq(raffle.getCurrentStateOfRaffle(), uint256(Raffle.RaffleState.CALCULATING));

        // Check contract balance should not be zero
        assertGt(address(raffle).balance, 0);
    }
}
