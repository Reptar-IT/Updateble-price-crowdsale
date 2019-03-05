
pragma solidity ^0.4.25;
//give ownership to creator
contract Ownable {
  address public owner;
  event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
  constructor () public {
    owner = msg.sender;
   }
  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }
  function transferOwnership(address newOwner) public onlyOwner {
    require(newOwner != address(0));
    emit OwnershipTransferred(owner, newOwner);
    owner = newOwner;
  }
}
interface token {
    function transfer(address receiver, uint amount) external;
}
//Crowdsale contract
contract Crowdsale is Ownable {
    token public tokenReward;
    address public beneficiary;
    uint public fundingGoal;
    uint public amountRaised;
    uint public deadline;
    uint public price;
    uint public minimum;
    // mapping
    mapping(address => uint256) public balanceOf;
    //booleans
    bool fundingGoalReached = false;
    bool crowdsaleClosed = false;
    // events that will show on the blockchain
    event GoalReached(address recipient, uint totalAmountRaised);
    event FundTransfer(address backer, uint amount, bool isContribution);
    // Constructor function
    // Setup the owner
    constructor(
        address ifSuccessfulSendTo, //address of wallet to recieve invested ether 
        uint fundingGoalInEthers, //funding goal in ether
        uint durationInMinutes, //duration of sale
        uint etherCostOfEachToken, //price in wei example 1000000000000000.
        uint minimumEtherAccepted, //input the minimum acepted wei amount example 10000000000000000.
        address addressOfTokenUsedAsReward //address of token being sold
    ) public {
        beneficiary = ifSuccessfulSendTo; //address of wallet to recieve invested ether
        fundingGoal = fundingGoalInEthers * 1 ether; //funding goal in ether
        deadline = now + durationInMinutes * 1 minutes; //time crowdsale will end
        price = etherCostOfEachToken / 1 wei; //price in wei example 1000000000000000.
        minimum = minimumEtherAccepted / 1 wei; //minimum wei accepted example 10000000000000000.
        tokenReward = token(addressOfTokenUsedAsReward);
    }
    // beneficiary 0x1eCD8a6Bf1fdB629b3e47957178760962C91b7ca
    // fundingGoalInEthers 1
    // durationInMinutes 120
    // price 1000000000000000
    // minim 10000000000000000
    // tokenReward18 0x5899d197A4a647C7AfF2824B47Fc26ECcc28641c
    // tokenReward0 0xBdD6ba5eEAe13A458a0607a6Dcbcffb763348C63

    //gives owner the ability to change the price of token incasr of horrid price swings
    function priceChange(uint etherCostOfEachToken, uint minimumEtherAccepted) public onlyOwner {
        price = etherCostOfEachToken / 1 wei; //price in wei example 1000000000000000.
        minimum = minimumEtherAccepted / 1 wei; //minimum wei accepted example 10000000000000000.
    }
    // The function without name is the default function that is called whenever anyone sends funds to a contract
    function () payable public {
        //require(msg.value >= minimum);
        //if(msg.value < minimum) revert();
        if(crowdsaleClosed) revert();
        uint amount = msg.value;
        balanceOf[msg.sender] += amount;
        amountRaised += amount;
        tokenReward.transfer(msg.sender, (amount / price) * 1 ether);
       emit FundTransfer(msg.sender, amount, true);
    }
    modifier afterDeadline() { if (now >= deadline) _; }
    //Checks if the goal or time limit has been reached and ends the campaign
    function checkGoalReached() public afterDeadline {
        if (amountRaised >= fundingGoal){
            fundingGoalReached = true;
            emit GoalReached(beneficiary, amountRaised);
        }
        crowdsaleClosed = true;
    }
    // safe withdrawal
    function safeWithdrawal() public afterDeadline {            // After the deadline.
        checkGoalReached();                                     // Checks is the funding goal was reached.
        if (!fundingGoalReached && beneficiary == msg.sender) { // If funding goal was not reached and Beneficiary is the caller.
            withdraw();                                         // Beneficiary is allowed withdraw funds raised to beneficiary's account.
            emit FundTransfer(beneficiary, amountRaised, false);     // Trigger and publicly log event. 
            } else {
                fundingGoalReached = true;                      // Funding goal was reached.
            }

        if (fundingGoalReached && beneficiary == msg.sender) {  // If funding goal was reached and Beneficiary is the caller.
            withdraw();                                         // Beneficiary is allowed withdraw funds raised to beneficiary's account.
            emit FundTransfer(beneficiary, amountRaised, false);     // Trigger and publicly log event.
            } else {
                fundingGoalReached = false;                     // Fund goal was not reached.
            }
    }
    // withdraw can only be called other functions within by this contract.
    function withdraw() internal {
        uint cash = amountRaised;
        amountRaised = 0;
        beneficiary.transfer(cash); // transfer all ether to beneficiary address.
    }
}
