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

    // State variables
    uint256 private immutable i_entranceFee;
    address[] private s_raffleParticipants; 
    mapping(address => uint256) private s_participantToAmount;

    // Events

    constructor(uint256 entranceFee, address vrfCoordinatorAddress) VRFConsumerBaseV2Plus(vrfCoordinatorAddress) {
        i_entranceFee = entranceFee; 
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

    function requestRandomNumber() public {
        uint256 requestId = s_vrfCoordinator.requestRandomWords(VRFV2PlusClient.RandomWordsRequest({
            keyHash: 0x787d74caea10b2b357790d5b5247c2f63d1d91572a9846f780606e4d953677ae,
            subId: 18541826859728935111278688522415752663091092770622187897088624603391258799582,
            requestConfirmations: 3,
            callbackGasLimit: 100000,
            numWords: 2,
            extraArgs: ""
        })); 
    }

    function fulfillRandomWords(uint256 requestId, uint256[] calldata randomWords) internal override {}

    
}