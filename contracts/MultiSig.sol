//SPDX-License-Identifier: MIT

pragma solidity ^0.8.13;

// ["0x5B38Da6a701c568545dCfcB03FcB875f56beddC4", "0xAb8483F64d9C6d1EcF9b849Ae677dD3315835cb2" ], 2

// "0x617F2E2fD72FD9D5503197092aC168c91465E7f2", 1000000000000000000, 0x00

contract MultiSig {
    event Deposit(address indexed sender, uint256 depositAmount, uint256 contractBalance);
    event SubmitTransaction(
        address indexed owner,
        uint256 indexed txIndex,
        address indexed to,
        uint256 value,
        bytes data
    );
    event ApproveTransaction(address indexed owner, uint256 indexed txID);
    event ExecuteTransaction(address indexed owner, uint256 indexed txID);

    address[] public owners;
    mapping(address => bool) public isOwner; 
    uint256 public votesRequired;

    struct Transaction {
        address to;
        uint256 value;
        bytes data;
        bool executed;
        uint256 numConfirmations;
    }

    //Transaction Index => Owner => Bool denoting whether transaction approved by I'th Owner 
    mapping(uint256 => mapping(address => bool)) public ownerApproved;

    Transaction[] public transactionHistory;

    modifier onlyOwner() {
        require(isOwner[msg.sender], "Caller is not an owner!");
        _;
    }

    modifier transactionExists(uint256 _txID) {
        require(_txID < transactionHistory.length, "Transaction does not exist");
        _;
    }

    modifier notApproved(uint256 _txID) {
        require(!ownerApproved[_txID][msg.sender], "Transaction already approved!");
        _;
    }

    modifier notExecuted(uint256 _txID) {
        require(!transactionHistory[_txID].executed, "Transaction already executed!");
        _;
    }

    constructor(address[] memory _owners, uint256 _votesRequired) {
        require(_owners.length > 0, "Multisig must have at least one owner!");
        require(
            _votesRequired > 0 && 
            _votesRequired <= _owners.length, 
            "Invalid number of required confirmations"
        );

        for (uint256 i = 0; i < _owners.length; i++) { 
            address curOwner = _owners[i];
            require(curOwner != address(0), "Invalid owner");
            require(!isOwner[curOwner], "Owner already exists!");
            
            isOwner[curOwner] = true;
            owners.push(curOwner);
        }
        votesRequired = _votesRequired;
    }

    function deposit() external payable {
        
    }

    receive() external payable {
        emit Deposit(msg.sender, msg.value, address(this).balance);
    }

    function submitTransaction(
        address _to, 
        uint256 _value, 
        bytes calldata _data
    ) external onlyOwner {
        // uint256 txIndex = transactionHistory.length; Should we apply -1 to this?

        transactionHistory.push(Transaction({
            to: _to,
            value: _value,
            data: _data,
            executed: false,
            numConfirmations: 0
        }));
        emit SubmitTransaction(msg.sender, transactionHistory.length - 1, _to, _value, _data);
    }

    function approveTransaction(uint256 _txID) external 
        onlyOwner 
        transactionExists(_txID) 
        notApproved(_txID) 
        notExecuted(_txID)  {
        ownerApproved[_txID][msg.sender] = true;
        emit ApproveTransaction(msg.sender, _txID);
    }

    function executeTransaction(uint256 _txID) 
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
        emit ExecuteTransaction(msg.sender, _txID); 
    }  

    function txApprovalCount(uint256 _txID) private view returns (uint256 count) {
        uint256 length = owners.length;

        for (uint256 i = 0; i < length; i++) { 
            if (ownerApproved[_txID][owners[i]]) {
                count += 1;
            }
        }
    }   
}

