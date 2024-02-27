// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import "../src/SimpleLottery.sol";

contract SimpleLotteryTest is Test {
    SimpleLottery lottery;
    address owner;
    address payable[] testAccounts;

    function setUp() public {
        owner = address(this);
        lottery = new SimpleLottery();
        testAccounts = new address payable[](1);
        testAccounts.push(payable(address(0xBEEF)));
        vm.deal(testAccounts[0], 10 ether);
    }

    function testPurchaseTicketsAndPurchasersLength() public {
        uint64 numTickets = 1;
        uint256 ticketPrice = lottery.ticketPrice();
        address purchaser = testAccounts[0]; // Use the funded test account

        uint256 initialPurchasersLength = lottery.getNumberOfTicketsPurchased();
        assertEq(initialPurchasersLength, 0, "Initial purchasers length should be 0.");

        vm.prank(purchaser);
        lottery.purchaseTickets{value: numTickets * ticketPrice}(numTickets);

        assertEq(lottery.ticketsPurchased(purchaser), numTickets, "Incorrect number of tickets recorded for purchaser.");
        assertEq(
            lottery.getNumberOfTicketsPurchased(),
            initialPurchasersLength + numTickets,
            "Purchasers length did not increase correctly."
        );
    }
}
