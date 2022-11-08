// SPDX-License-Identifier: MIT
pragma solidity 0.8.4; //Do not change the solidity version as it negativly impacts submission grading

import "hardhat/console.sol";
import "./ExampleExternalContract.sol";

contract Staker {
    ExampleExternalContract public exampleExternalContract;

    constructor(address exampleExternalContractAddress) {
        exampleExternalContract = ExampleExternalContract(
            exampleExternalContractAddress
        );
    }

    // Collect funds in a payable `stake()` function and track individual `balances` with a mapping:
    // ( Make sure to add a `Stake(address,uint256)` event and emit it for the frontend <List/> display )

    mapping(address => uint256) public balances;

    uint256 public constant threshold = 1 wei;
    uint256 public deadline = block.timestamp + 30 seconds;

    event Stake(address indexed sender, uint256 amount);

    function stake(address, uint256) public payable {
        balances[msg.sender] += msg.value;
        console.log(msg.value);
        emit Stake(msg.sender, msg.value);
    }

    // After some `deadline` allow anyone to call an `execute()` function
    // If the deadline has passed and the threshold is met, it should call `exampleExternalContract.complete{value: address(this).balance}()`

    function execute() public {
        require(timeLeft() == 0, "Deadline not yet expired");

        uint256 contractBalance = address(this).balance;

        // check the contract has enough ETH to reach the threshold
        require(contractBalance >= threshold, "Threshold is not reached");

        // Execute the external contract, transfer all the balance to the contract
        // (bool sent, bytes memory data) = exampleExternalContract.complete{value: contractBalance}();
        (bool sent, ) = address(exampleExternalContract).call{
            value: contractBalance
        }(abi.encodeWithSignature("complete()"));
        require(sent, "exampleExternalContract.complete failed :(");
    }

    // If the `threshold` was not met, allow everyone to call a `withdraw()` function to withdraw their balance
    function withdraw(address payable depositor) public {
        require(timeLeft() == 0, "Deadline not expired yet");
        uint256 userBalance = balances[depositor];
        require(userBalance > 0, "No funds to withdraw");
        (bool sent, ) = depositor.call{value: userBalance}("");
        require(sent, "Failed to withdraw funds");

        balances[depositor] = 0;
    }

    // Add a `timeLeft()` view function that returns the time left before the deadline for the frontend
    function timeLeft() public view returns (uint256) {
        return deadline >= block.timestamp ? (deadline - block.timestamp) : 0;
    }

    // Add the `receive()` special function that receives eth and calls stake()
    receive() external payable {
        stake(msg.sender, msg.value);
    }
}
