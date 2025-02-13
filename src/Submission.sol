// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import "@openzeppelin/contracts/access/Ownable.sol";
import { IZuvuToken } from './IZuvuToken.sol';
import { IGovernance } from './IGovernance.sol';

contract Submission is Ownable {

    struct SubmissionMetadata {
        string name;
        string url;
    }
   
    mapping(address => uint160) submissionIds;
    mapping(uint160 => address) submissions;
    uint160 public submissionLength = 0;

    mapping(address => uint256) submissionRewards;
    mapping(address => SubmissionMetadata) public submissionMetadata;

    IZuvuToken public zuvuToken;
    uint256 public submissionFee;
    
    bool tokenAddressSet = false;
    bool killSwitch = false;

    modifier onlyTokenContract() {
        require(msg.sender == address(zuvuToken), "Caller is not the token contract");
        _;
    }

    modifier isSubmissionRegistered(address submisison) {
        require(submissionIds[submisison] != 0, "Submission not registered");
        _;
    }

    // Kill switch 
    modifier ks() {
        require(killSwitch == false, "The contract is in maintenance mode");
        _;
    }

    constructor(uint256 fee) Ownable(msg.sender) {
        submissionFee = fee;
    }

    /// @notice Sets the token contract address
    /// @dev Can only be called by the owner and only once
    /// @param token The address of the ZuvuToken contract
    function setTokenAddress(address token) public onlyOwner {
        require(tokenAddressSet == false, "Token address already set");
        zuvuToken = IZuvuToken(token);
        tokenAddressSet = true;
    }

    /// @notice sets the killSwitch value for ks modifier
    function setKillSwitch(bool val) public onlyOwner {
        killSwitch = val;
    }    

    /// @notice Registers the caller as a submission
    function registerSubmission() public ks {
        require(submissionIds[msg.sender] == 0, "Submission already registered");
        require(zuvuToken.balanceOf(msg.sender) >= submissionFee, "Insufficient Zuvu balance");
        require(zuvuToken.transferFrom(msg.sender,address(this),submissionFee), "Transfer failed");

        submissionLength++;
        submissionIds[msg.sender] = submissionLength;
        submissions[submissionLength] = msg.sender;
    }

    /// @notice Set's metadata for the submission
    function setSubmissionMetadata(string calldata name, string calldata url) public isSubmissionRegistered(msg.sender) ks {
        SubmissionMetadata memory metadata = SubmissionMetadata({
           name: name,
           url: url
        });

        submissionMetadata[msg.sender] = metadata;
    }

    /// @notice Unregisters the caller as a submission
    /// @dev Removes the caller from the list of submissions
    function unregisterSubmission() public isSubmissionRegistered(msg.sender) ks {
        uint160 submissionId = submissionIds[msg.sender];

        // Swap the last submission with the one being removed
        if (submissionId != submissionLength) {
            address lastSubmission = submissions[submissionLength];
            submissions[submissionId] = lastSubmission;
            submissionIds[lastSubmission] = submissionId;
        }

        // Delete the submission from the mappings
        delete submissionIds[msg.sender];
        delete submissions[submissionLength];
        delete submissionMetadata[msg.sender];

        submissionLength--;
    }

    /// @notice distributes the submission rewards 
    /// @dev Can only be called by the owner and only once
    /// @param rewards struct with the submission address and weighted median vote
    /// @param totalVote all the median votes added, so we can calculate each submission's reward
    /// @param amount total tokens awarded 
    function distributeRewards(IGovernance.SubmissionReward[] memory rewards, uint256 totalVote, uint256 amount) external onlyTokenContract {
        for(uint i = 0; i < rewards.length; i++) {
            IGovernance.SubmissionReward memory rew = rewards[i];
            uint256 reward = (rew.reward * amount) / totalVote;
            submissionRewards[rew.submission] += reward;
        }
    }

    /// @notice permits the submission author to claim the reward
    function claimReward() public isSubmissionRegistered(msg.sender) {
        require(submissionRewards[msg.sender] > 0, "No rewards");
        uint256 reward = submissionRewards[msg.sender];
        submissionRewards[msg.sender] = 0;
        zuvuToken.transfer(msg.sender, reward);
    }
}
