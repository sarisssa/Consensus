//SPDX-License-Identifier: MIT

pragma solidity ^0.8.13;

contract MultiSig {
    address[] public owners;
    
    mapping(address => bool) public isOwner;
    
    uint public votesRequired;

     //Transaction Index => Owner => Bool denoting transaction approved by I'th Owner or not
    mapping(uint => mapping(address => bool)) public ownerApproved;

    struct Transaction {
        address to;
        uint value;
        bytes data;
        bool executed;
    }

    Transaction[] public transactionHistory;

    modifier onlyOwner() {
        require(isOwner[msg.sender], "Caller is not an owner!");
        _;
    }

    constructor(address[] memory _owners, uint _votesRequired) {
        require(_owners.length > 0, "Multisig must have at least one owner!");

        for (uint i = 0; i < _owners.length; i++) { //Insert owners into state variables
            address curOwner = _owners[i];
            require(!isOwner[curOwner], "Owner already exists!");
            
            isOwner[curOwner] = true;
            owners.push(curOwner);
        }
        votesRequired = _votesRequired;
    }

    receive() external payable {
        
    }

    function submitTransaction(address _to, uint _valueSent, bytes calldata _data) external onlyOwner {
        transactionHistory.push(Transaction({
            to: _to,
            value: _valueSent,
            data: _data,
            executed: false
        }));
    }

    function approveTransaction(uint _txID) external onlyOwner {
        ownerApproved[_txID][msg.sender] = true;
    }

    function txApprovalCount(uint _txID) private view returns (uint count) {
        for (uint i = 0; i < owners.length; i++) {
            if (ownerApproved[_txID][owners[i]]) {
                count += 1;
            }
        }
    }

   
}