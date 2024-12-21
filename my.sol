// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract EducationInsurancePolicy {
    address public owner;
    uint256 public premiumAmount;
    uint256 public yieldRate; // Annual yield rate in percentage (e.g., 5 for 5%)
    uint256 public policyDuration; // Duration in years
    uint256 public startTimestamp;
    uint256 public minimumPremium; // Minimum premium amount (0.01 ETH)
    
    struct Policy {
        uint256 premiumPaid;
        uint256 startTimestamp;
        uint256 yieldEarned;
        address beneficiary;
    }
    
    mapping(address => Policy) public policies;
    
    modifier onlyOwner() {
        require(msg.sender == owner, "You are not authorized");
        _;
    }
    
    event PolicyCreated(address indexed policyHolder, uint256 premiumPaid, uint256 startTimestamp);
    event YieldClaimed(address indexed policyHolder, uint256 yieldAmount);
    event PremiumPaid(address indexed policyHolder, uint256 amount);
    
    constructor(uint256 _yieldRate, uint256 _policyDuration) {
        owner = msg.sender;
        yieldRate = _yieldRate;
        policyDuration = _policyDuration;
        minimumPremium = 0.01 ether; // Set the minimum premium to 0.01 ETH
    }

    // Ensure the premium is at least 0.01 ETH
    modifier validPremium(uint256 _premium) {
        require(_premium >= minimumPremium, "Premium must be at least 0.01 ETH");
        _;
    }

    function createPolicy(address beneficiary) external payable validPremium(msg.value) {
        require(policies[msg.sender].premiumPaid == 0, "Policy already exists");
        
        policies[msg.sender] = Policy({
            premiumPaid: msg.value,
            startTimestamp: block.timestamp,
            yieldEarned: 0,
            beneficiary: beneficiary
        });

        emit PolicyCreated(msg.sender, msg.value, block.timestamp);
    }

    function calculateYield(address policyHolder) public view returns (uint256) {
        Policy storage policy = policies[policyHolder];
        require(policy.premiumPaid > 0, "Policy does not exist");
        
        uint256 timeElapsed = block.timestamp - policy.startTimestamp;
        uint256 yearsElapsed = timeElapsed / 365 days;
        
        if (yearsElapsed >= policyDuration) {
            uint256 yield = (policy.premiumPaid * yieldRate * yearsElapsed) / 100;
            return yield;
        }
        return 0;
    }

    function claimYield() external {
        Policy storage policy = policies[msg.sender];
        require(policy.premiumPaid > 0, "Policy does not exist");
        
        uint256 yieldAmount = calculateYield(msg.sender);
        require(yieldAmount > 0, "Yield not available yet");
        
        policy.yieldEarned += yieldAmount;
        payable(policy.beneficiary).transfer(yieldAmount);
        
        emit YieldClaimed(msg.sender, yieldAmount);
    }

    function payPremium() external payable validPremium(msg.value) {
        policies[msg.sender].premiumPaid += msg.value;
        
        emit PremiumPaid(msg.sender, msg.value);
    }

    function getPolicyDetails(address policyHolder) external view returns (uint256, uint256, uint256, address) {
        Policy storage policy = policies[policyHolder];
        return (policy.premiumPaid, policy.yieldEarned, policy.startTimestamp, policy.beneficiary);
    }
}



