//SPDX-License-Identifier: MIT

pragma solidity ^0.8.13;

// ["0x5B38Da6a701c568545dCfcB03FcB875f56beddC4", "0xAb8483F64d9C6d1EcF9b849Ae677dD3315835cb2" ], 2

// "0x617F2E2fD72FD9D5503197092aC168c91465E7f2", 1000000000000000000, 0x00

contract MultiSig {

     struct Transaction {
        address to;
        uint value;
        bytes data;
        bool executed;
    }

    address[] public owners;
    
    mapping(address => bool) public isOwner;
    
    uint public votesRequired;

    //Transaction Index => Owner => Bool denoting whether transaction approved by I'th Owner 
    mapping(uint => mapping(address => bool)) public ownerApproved;

    Transaction[] public transactionHistory;

    event ExecuteTransaction(uint indexed txID); 

    modifier onlyOwner() {
        require(isOwner[msg.sender], "Caller is not an owner!");
        _;
    }

    modifier transactionExists(uint _txID) {
        require(_txID < transactionHistory.length, "Transaction does not exist");
        _;
    }

    modifier notApproved(uint _txID) {
        require(!ownerApproved[_txID][msg.sender], "Transaction already approved!");
        _;
    }

    modifier notExecuted(uint _txID) {
        require(!transactionHistory[_txID].executed, "Transaction already executed!");
        _;
    }

    function deposit() payable external {
        
    }

    constructor(address[] memory _owners, uint _votesRequired) {
        require(_owners.length > 0, "Multisig must have at least one owner!");

        for (uint i = 0; i < _owners.length; i++) { 
            address curOwner = _owners[i];
            require(!isOwner[curOwner], "Owner already exists!");
            
            isOwner[curOwner] = true;
            owners.push(curOwner);
        }
        votesRequired = _votesRequired;
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

    function executeTransaction(uint _txID) 
        external 
        transactionExists(_txID) 
        notApproved(_txID) 
        notExecuted(_txID) 
    {
        require(txApprovalCount(_txID) >= votesRequired, "Insufficient number of approvals"); 
        
        Transaction storage curTransaction = transactionHistory[_txID];
        curTransaction.executed = true;

        (bool success, ) = curTransaction.to.call{value: curTransaction.value}(
            curTransaction.data
        );
        require(success, "Transaction failed!");
        emit ExecuteTransaction(_txID); 
    }  

    function txApprovalCount(uint _txID) private view returns (uint count) {
        for (uint i = 0; i < owners.length; i++) { 
            if (ownerApproved[_txID][owners[i]]) {
                count += 1;
            }
        }
    }   
}