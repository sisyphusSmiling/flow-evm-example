// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "@openzeppelin/contracts/access/Ownable.sol";

// This is a simple lottery contract running a single round. The winner is selected at random, and
// the winner must claim their winnings
//
// NOTE: This is for demonstration purposes only and should not be used in production
//
contract SimpleLottery is Ownable {
    // Price of a one lottery ticket
    uint256 public ticketPrice;
    // Blocks between rounds during which value can accumulate
    uint256 public endBlock;
    // Address array of purchasers
    address[] public purchasers;
    address public winner;
    // Mapping of purchasers to the number of tickets they have purchased
    mapping(address => uint64) public ticketsPurchased;

    // Event to be emitted when a round is completed and a winner is selected
    event RoundComplete(address indexed winner, uint256 amount);

    constructor() Ownable(msg.sender) {
        ticketPrice = 1 ether;
        // Delay the end of this lottery by 100 blocks
        endBlock = block.number + 100;
    }

    // Function to purchase tickets
    function purchaseTickets(uint64 numTickets) public payable {
        require(isRoundOver() == false, "This lottery is over.");
        require(numTickets > 0, "You must purchase at least one ticket.");
        require(msg.value >= numTickets * ticketPrice, "Insufficient funds sent.");

        // Increment the number of tickets purchased by the caller
        ticketsPurchased[msg.sender] += numTickets;
        // Push the caller's address for each ticket purchased, increasing their odds of winning
        for (uint64 i = 0; i < numTickets; i++) {
            purchasers.push(msg.sender);
        }
    }

    // Function to end the round, pick a winner - callable only by the contract owner
    function endRoundAndPickWinner(uint64 randomSeed) public onlyOwner returns (address, uint256) {
        require(isRoundOver(), "Current round is not yet over.");
        require(winner != address(0), "Winner has already been picked.");
        if (purchasers.length == 0) {
            emit RoundComplete(address(0), 0);
            return (address(0), 0);
        }

        uint256 winnerIndex = randomFromRange(0, purchasers.length, randomSeed);
        winner = purchasers[winnerIndex];
        uint256 winningAmount = address(this).balance;

        emit RoundComplete(winner, winningAmount);

        return (winner, winningAmount);
    }

    // Function for winners to claim their winnings
    function claimWinnings() public {
        require(msg.sender == winner, "Caller is not the lottery winner");

        (bool sent,) = msg.sender.call{value: address(this).balance}("");
        require(sent, "Failed to send FLOW.");
    }

    // Returns whether the lottery has passed its end block
    function isRoundOver() public view returns (bool) {
        return block.number >= endBlock;
    }

    // Retrieves the number of tickets purchased
    function getNumberOfTicketsPurchased() public view returns (uint256) {
        return purchasers.length;
    }

    // Utility function to generate a pseudo-random number within a range
    function randomFromRange(uint256 min, uint256 max, uint64 randomSeed) private pure returns (uint256) {
        return ((randomSeed % (max - min)) + min);
    }
}
