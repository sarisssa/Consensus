//SPDX-License-Identifier: MIT

pragma solidity ^0.8.13;

contract MultiSig {
    address[] public owners;
    
    mapping(address => bool) public isOwner;
    
    uint public votesRequired;

    struct Transaction {
        address to;
        uint value;
        bytes data;
        bool executed;
    }

    Transaction[] public transactionHistory;

    //Transaction Index => Owner => Bool denoting transaction approved by I'th Owner or not
    mapping(uint => mapping(address => bool)) public ownerApproved;

}