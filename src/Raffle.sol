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

    // Errors
    error Raffle__NotEnoughEtherToEnterRaffle();
    error Raffle__Not_Ready_To_Start();

    // State variables
    uint256 constant NUM_WORDS = 2;
    uint256 constant REQUEST_CONFIRMATIONS = 3;
    uint256 private immutable i_entranceFee;
    uint256 private immutable i_subscriptionId;
    bytes32 private immutable i_keyHash;
    uint256 private immutable i_callbackGasLimit;
    address[] private s_raffleParticipants; 
    mapping(address => uint256) private s_participantToAmount;

    // Events

    constructor(uint256 _entranceFee, address vrfCoordinatorAddress, uint256 _subscriptionId, bytes32 _keyHash, uint256 _callbackGasLimit) VRFConsumerBaseV2Plus(vrfCoordinatorAddress) {
        i_entranceFee = _entranceFee; 
        i_subscriptionId = _subscriptionId; 
        i_keyHash = _keyHash;
        i_callbackGasLimit = _callbackGasLimit;
    }

    /**
     * @notice This function allows users to enter the raffle by paying a certain amount of Ether.
     * @dev Follows CEI pattern (Checks-Effects-Interactions) to prevent reentrancy attacks.
     */
    function enterRaffle() public payable {
        // Check if the user has sent enough Ether to enter the raffle
        if(msg.value < i_entranceFee) {
            revert Raffle__NotEnoughEtherToEnterRaffle();
        }

        // Effect: Add the user to the list of participants
        s_raffleParticipants.push(msg.sender);
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
    function runLottery() external {
        uint256 hasAtleastTwoPlayersInRaffle = s_raffleParticipants.length > 1;
        uint256 contractHasSomeBalance = address(this).balance > 0;

        if(!hasAtleastTwoPlayersInRaffle || !contractHasSomeBalance) {
            revert Raffle__Not_Ready_To_Start();
        }

        // Request chainlink vrf for random number
        uint256 reqId = _requestRandomNumber();

        // Push an event with reqId

    }



    /**
     * @notice Internal function to request a random number from the VRF Coordinator.
     * @dev This function uses the VRFV2PlusClient to request random words.
     * @return requestId The ID of the request for random words.
     */
    function _requestRandomNumber() internal returns(uint256 requestId) {
        requestId = s_vrfCoordinator.requestRandomWords(VRFV2PlusClient.RandomWordsRequest({
            keyHash: i_keyHash, //0x787d74caea10b2b357790d5b5247c2f63d1d91572a9846f780606e4d953677ae
            subId: i_subscriptionId,
            requestConfirmations: REQUEST_CONFIRMATIONS,
            callbackGasLimit: i_callbackGasLimit, // 100000
            numWords: NUM_WORDS,
            extraArgs: ""
        })); 
    }

    function fulfillRandomWords(uint256 requestId, uint256[] calldata randomWords) internal override {}

    
}