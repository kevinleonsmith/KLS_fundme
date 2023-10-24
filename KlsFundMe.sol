// SPDX-License-Identifier: MIT
// Another Kevin Leon Smith smart contract! 2023

pragma solidity ^0.6.6 <0.9.0;

import "@chainlink/contracts/src/v0.6/interfaces/AggregatorV3Interface.sol";
import "@chainlink/contracts/src/v0.6/vendor/SafeMathChainlink.sol";

contract FundMe {
    using SafeMathChainlink for uint256;

    mapping(address => uint256) public addressToAmountFunded;
    address[] public funders;
    address public owner;

    // the owner
    constructor() public {
        owner = msg.sender;
    }

    function fund() public payable {
        // 18 digit number to be compared with donated amount
        uint256 minimumUSD = 50 * 10 ** 18;
        //is the donated amount less than 50USD?
        require(
            getConversionRate(msg.value) >= minimumUSD,
            "You need to spend more ETH!"
        );
        //if not, add to mapping and funders array
        addressToAmountFunded[msg.sender] += msg.value;
        funders.push(msg.sender);
    }

    //Chainlink pricefeed
    function getVersion() public view returns (uint256) {
        AggregatorV3Interface priceFeed = AggregatorV3Interface(
            0xD4a33860578De61DBAbDc8BFdb98FD742fA7028e
        );
        return priceFeed.version();
    }

    function getPrice() public view returns (uint256) {
        AggregatorV3Interface priceFeed = AggregatorV3Interface(
            0xD4a33860578De61DBAbDc8BFdb98FD742fA7028e
        );
        (, int256 answer, , , ) = priceFeed.latestRoundData();
        // ETH/USD rate in 18 digit
        return uint256(answer * 10000000000);
    }

    function getConversionRate(
        uint256 ethAmount
    ) public view returns (uint256) {
        uint256 ethPrice = getPrice();
        uint256 ethAmountInUsd = (ethPrice * ethAmount) / 1000000000000000000;
        // Actual ETH/USD conversation rate, after adjusting the extra 0s.
        return ethAmountInUsd;
    }

    modifier onlyOwner() {
        //is the message sender owner of the contract?
        require(msg.sender == owner);

        _;
    }

    /* onlyOwner modifer will first check the condition inside it and
     if true, the withdraw function will be executed */
    function withdraw() public payable onlyOwner {
        msg.sender.transfer(address(this).balance);

        /* iterate through all the mappings and make them 0
        since all the deposited amount has been withdrawn */
        for (
            uint256 funderIndex = 0;
            funderIndex < funders.length;
            funderIndex++
        ) {
            address funder = funders[funderIndex];
            addressToAmountFunded[funder] = 0;
        }

        funders = new address[](0);
    }
}
