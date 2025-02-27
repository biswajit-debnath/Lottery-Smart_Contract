// SPDX-License-Identifier: MIT
import {VRFConsumerBaseV2Plus} from "@chainlink/contracts/src/v0.8/vrf/dev/VRFConsumerBaseV2Plus.sol";
import {VRFV2PlusClient} from "@chainlink/contracts/src/v0.8/vrf/dev/libraries/VRFV2PlusClient.sol";

pragma solidity ^0.8.28;

/**
 * @title Raffle Contract
 * @author Biswajit Debnath
 * @notice This contract is a simple raffle system where users can enter the raffle by paying a certain amount of Ether. The contract owner will call the       `pickWinner` function which will randomly select a winner using chainlink's VRF (Verifiable Random Function) service. The winner will receive the total amount of Ether collected from all the participants
 */
contract Raffle is VRFConsumerBaseV2Plus {

    /* Type declarations */
    enum RaffleState {
        OPEN,
        CALCULATING
    }


    /* Errors */
    error Raffle__NotEnoughEtherToEnterRaffle();
    error Raffle__Not_Ready_To_Start();
    error Raffle__Winner_MoneyTransfer_Failed();
    error Raffle_RaffleNotOpen();

    /* State variables */
    uint32 constant NUM_WORDS = 2;
    uint16 constant REQUEST_CONFIRMATIONS = 3;
    uint256 private immutable i_entranceFee;
    uint256 private immutable i_subscriptionId;
    bytes32 private immutable i_keyHash;
    uint32 private immutable i_callbackGasLimit;
    address[] private s_raffleParticipants; 
    mapping(address => uint256) private s_participantToAmount;
    address private lastWinnerAddress;
    uint256 private lastWinnerPrizeAmount;
    RaffleState private s_raffleState;

    
    /* Events */
    event RandomNumberRequested(uint256 indexed reqId);
    event WinnerPicked(address indexed winnderAddress);

    constructor(uint256 _entranceFee, address vrfCoordinatorAddress, uint256 _subscriptionId, bytes32 _keyHash, uint32 _callbackGasLimit) VRFConsumerBaseV2Plus(vrfCoordinatorAddress) {
        i_entranceFee = _entranceFee; 
        i_subscriptionId = _subscriptionId; 
        i_keyHash = _keyHash;
        i_callbackGasLimit = _callbackGasLimit;
        s_raffleState = RaffleState.OPEN;
    }


    /* External Functions */

    /**
     * @notice This function allows users to enter the raffle by paying a certain amount of Ether.
     * @dev Follows CEI pattern (Checks-Effects-Interactions) to prevent reentrancy attacks.
     */
    function enterRaffle() public payable {
        // Check if the user has sent enough Ether to enter the raffle
        if(msg.value < i_entranceFee) {
            revert Raffle__NotEnoughEtherToEnterRaffle();
        }

        if(s_raffleState != RaffleState.OPEN) {
            revert Raffle_RaffleNotOpen();
        }

        // Effect: Add the user to the list of participants
        // If user has already entered earlier don't add the user to the participants list
        if(s_participantToAmount[msg.sender] == 0) {
            s_raffleParticipants.push(msg.sender);
        }
        s_participantToAmount[msg.sender] += msg.value;
    }

    /**
     * @notice Function to start the lottery
     * @dev This function checks if there are at least two players in the raffle and if the contract has a balance before starting the lottery.
     * It requests a random number from Chainlink VRF and emits an event with the request ID.
     * @custom:require At least two players must be in the raffle.
     * @custom:require The contract must have a positive balance.
     * @custom:revert Raffle__Not_Ready_To_Start if the conditions are not met.
     */
    function runLottery() external returns(uint256){
        bool hasAtleastTwoPlayersInRaffle = s_raffleParticipants.length > 1;
        bool contractHasSomeBalance = address(this).balance > 0;
        bool raffleIsOpen = s_raffleState == RaffleState.OPEN;

        if(!hasAtleastTwoPlayersInRaffle || !contractHasSomeBalance || !raffleIsOpen) {
            revert Raffle__Not_Ready_To_Start();
        }

        s_raffleState = RaffleState.CALCULATING;

        // Request chainlink vrf for random number
        uint256 reqId = _requestRandomNumber();

        // Push an event with reqId
        emit RandomNumberRequested(reqId);

        return reqId;

    }

    


    
    /* Internal Functions */

    /**
     * @notice Internal function to request a random number from the VRF Coordinator.
     * @dev This function uses the VRFV2PlusClient to request random words.
     * @return requestId The ID of the request for random words.
     */
    function _requestRandomNumber() internal returns(uint256 requestId) {
        requestId = s_vrfCoordinator.requestRandomWords(VRFV2PlusClient.RandomWordsRequest({
            keyHash: i_keyHash,
            subId: i_subscriptionId,
            requestConfirmations: REQUEST_CONFIRMATIONS,
            callbackGasLimit: i_callbackGasLimit, 
            numWords: NUM_WORDS,
            extraArgs: VRFV2PlusClient._argsToBytes(
                    // Set nativePayment to true to pay for VRF requests with Sepolia ETH instead of LINK
                    VRFV2PlusClient.ExtraArgsV1({nativePayment: false})
                )
        })); 
    }

    /**
     * @notice This function is called by the Chainlink VRF Coordinator with the random words generated.
     * @dev This function overrides the `fulfillRandomWords` function from the VRFConsumerBaseV2 contract.
     * It uses the first random word to pick a winner and send the prize.
     * @param requestId The ID of the request for randomness.
     * @param randomWords An array containing the random words generated by the Chainlink VRF.
     */
    function fulfillRandomWords(uint256 requestId, uint256[] calldata randomWords) internal override {
        _pickWinnerAndSendPrize(randomWords[0]);
    }

    /**
     * @notice Internal function to pick a winner and send the prize amount.
     * @dev This function uses a random number to select a winner from the raffle participants.
     * It transfers the entire contract balance to the winner and updates the internal state.
     * @param randomNumber The random number used to select the winner.
     */
    function _pickWinnerAndSendPrize(uint256 randomNumber) internal {
        uint256 winnerIndex = randomNumber % s_raffleParticipants.length;
        address winnerAddress = s_raffleParticipants[winnerIndex];
        uint256 prizeAmount = address(this).balance;

        // Update internal states
        lastWinnerAddress = winnerAddress;
        lastWinnerPrizeAmount = prizeAmount;
        s_raffleState = RaffleState.OPEN;
        // clear the mapping s_participantToAmount;
        for (uint256 i = 0; i < s_raffleParticipants.length; i++) {
            delete s_participantToAmount[s_raffleParticipants[i]];
        }
        s_raffleParticipants = new address[](0);

        (bool success,) = payable(winnerAddress).call{value: prizeAmount}("");
        if(!success) {
            revert Raffle__Winner_MoneyTransfer_Failed();
        }

        emit WinnerPicked(winnerAddress);

    }

    

    /* Getter Functions */

    function getEntranceFeeAmountInEth() external view returns(uint256) {
        return i_entranceFee;
    }

    function getAllCurrentPerticipantsOfLottery() external view returns(address[] memory) {
        return s_raffleParticipants;
    }

    function getAmountInvestedByUser(address userAddress) external view returns(uint256) {
        return s_participantToAmount[userAddress];
    } 

    function getCurrentStateOfRaffle() external view returns(uint256) {
        return uint256(s_raffleState);
    }

    function getSubscriptionId() external view returns(uint256) {
        return i_subscriptionId;
    }

    
}