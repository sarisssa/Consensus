//SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

import "@openzeppelin/contracts/access/Ownable.sol";

contract TestContract is Ownable {
    string public message;

    constructor(string memory _message) {
        message = _message;
    }

    function setMessage(string memory _message) external onlyOwner {
        message = _message;
    }
}