const { expect } = require("chai");
const { ethers } = require("hardhat");

describe("MultiSig", function () {
  let accounts;

  beforeEach(async function () {
    //Before each test and each instance of ('it')

    accounts = await ethers.getSigners();

    const OWNERS = [
      accounts[0].address,
      accounts[1].address,
      accounts[2].address,
    ];

    const NUM_CONFIRMATIONS = 2;

    const MultiSig = await ethers.getContractFactory("MultiSig"); //Creation of MultiSig class

    multiSig = await MultiSig.deploy(OWNERS, NUM_CONFIRMATIONS);
  });

  it("Owners should approve the setMessage function", async function () {
    const TestContract = await ethers.getContractFactory("TestContract");
    testContract = await TestContract.deploy("Hello World!");

    //transfer ownership to multiSig
    await testContract.connect(accounts[0]).transferOwnership(multiSig.address);

    //submit transaction to change message in testContract

    //The Interface Class abstracts the encoding and decoding required to interact with contracts on the Ethereum network.
    // encoding SetMessage function, this encode data can be used as the data for a transaction
    //https://docs.ethers.io/v5/api/utils/abi/interface/

    //Call the setMessage function and input parameter ["New Message"]. Note params must be enclosed in block [  ]
    const calldata = testContract.interface.encodeFunctionData("setMessage", [
      "New Message",
    ]);

    await multiSig
      .connect(accounts[0])
      .submitTransaction(testContract.address, 0, calldata);

    const tx0 = await multiSig.getTransaction(0);
    console.log(tx0);

    //confirm transaction >= 2
    await multiSig.connect(accounts[0]).confirmTransaction(0); //0 is the index of the transaction
    await multiSig.connect(accounts[1]).confirmTransaction(0);
    await multiSig.connect(accounts[2]).confirmTransaction(0);

    await multiSig.connect(accounts[2]).revokeConfirmation(0);

    //execute transaction
    await multiSig.connect(accounts[0]).executeTransaction(0);

    //check testContract value
    const message = await testContract.message();
    expect(message).to.equal("New Message");
  });
});
