// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/math/SafeMath.sol";

contract EduInsurance {
    using SafeMath for uint256;

    address public owner;
    uint256 public policyCount = 0;

    uint256 public constant MIN_PREMIUM = 100000000000; // 0.0000001 ETH in Wei

    // Define a structure for insurance policies
    struct Policy {
        uint256 policyId;
        address policyholder;
        uint256 premiumAmount;
        uint256 investedAmount;
        uint256 yieldGenerated;
        uint256 payoutAmount;
        uint256 milestone; // Milestone representing educational achievements
        bool isActive; // Flag to check if the policy is still active
    }

    mapping(uint256 => Policy) public policies;

    event PolicyCreated(uint256 policyId, address indexed policyholder, uint256 premiumAmount);
    event YieldGenerated(uint256 policyId, uint256 yieldAmount);
    event PayoutIssued(uint256 policyId, uint256 payoutAmount);
    event MilestoneUpdated(uint256 policyId, uint256 milestone);

    constructor() {
        owner = msg.sender;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "You are not authorized");
        _;
    }

    modifier isPolicyActive(uint256 policyId) {
        require(policies[policyId].isActive, "Policy is not active");
        _;
    }

    // Function to create a new policy
    function createPolicy() external payable {
        require(msg.value >= MIN_PREMIUM, "Premium must be at least 0.0000001 ETH");

        policyCount++;
        policies[policyCount] = Policy({
            policyId: policyCount,
            policyholder: msg.sender,
            premiumAmount: msg.value,
            investedAmount: msg.value, // Initial investment is the premium
            yieldGenerated: 0,
            payoutAmount: 0,
            milestone: 0, // Milestone starts at 0, can be updated later
            isActive: true
        });

        emit PolicyCreated(policyCount, msg.sender, msg.value);
    }

    // Simulate the yield generation
    function generateYield(uint256 policyId, uint256 yieldAmount) external onlyOwner isPolicyActive(policyId) {
        require(yieldAmount > 0, "Yield amount must be greater than zero");

        Policy storage policy = policies[policyId];
        policy.yieldGenerated = policy.yieldGenerated.add(yieldAmount);
        policy.investedAmount = policy.investedAmount.add(yieldAmount);

        emit YieldGenerated(policyId, yieldAmount);
    }

    // Function to trigger payout when a milestone is reached
    function issuePayout(uint256 policyId) external onlyOwner isPolicyActive(policyId) {
        Policy storage policy = policies[policyId];

        uint256 payout = policy.investedAmount.add(policy.yieldGenerated);
        policy.payoutAmount = payout;

        // Transfer payout to the policyholder
        require(address(this).balance >= payout, "Insufficient contract balance for payout");
        payable(policy.policyholder).transfer(payout);

        // Deactivate the policy after payout
        policy.isActive = false;

        emit PayoutIssued(policyId, payout);
    }

    // Function to update the milestone (e.g., when the child reaches a certain educational level)
    function updateMilestone(uint256 policyId, uint256 milestone) external onlyOwner isPolicyActive(policyId) {
        Policy storage policy = policies[policyId];
        policy.milestone = milestone;

        emit MilestoneUpdated(policyId, milestone);
    }

    // Function to view policy details
    function getPolicyDetails(uint256 policyId) external view returns (
        address policyholder,
        uint256 premiumAmount,
        uint256 investedAmount,
        uint256 yieldGenerated,
        uint256 payoutAmount,
        uint256 milestone,
        bool isActive
    ) {
        Policy storage policy = policies[policyId];
        return (
            policy.policyholder,
            policy.premiumAmount,
            policy.investedAmount,
            policy.yieldGenerated,
            policy.payoutAmount,
            policy.milestone,
            policy.isActive
        );
    }

    // Function to withdraw contract balance (only for the owner)
    function withdrawFunds(uint256 amount) external onlyOwner {
        require(amount <= address(this).balance, "Insufficient balance");
        payable(owner).transfer(amount);
    }

    // Fallback function to accept ETH
    receive() external payable {}
}
