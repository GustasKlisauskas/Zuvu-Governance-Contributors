// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.10;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import { IGovernance } from "./IGovernance.sol";
import { ISubmission } from "./ISubmission.sol";

/// @title ZuvuToken
/// @author BeAWhale
/// @notice This contract handles the ZUV token, including minting, burning, and reward distribution.
contract ZuvuToken is ERC20, Ownable {
    // Minting schedule
    uint256 public constant MINT_INTERVAL = 1 days; 
    uint256 public constant MINT_AMOUNT = 1_000_000;

    uint256 public lastMintTimestamp;

    IGovernance public governance;
    bool isGovernanceSet = false;

    ISubmission public submission;
    bool isSubmissionSet = false;

    modifier governanceContractSet() {
        require(isGovernanceSet);
        _;
    }

    modifier submissionContractSet() {
        require(isSubmissionSet);
        _;
    }
    constructor() ERC20("ZuvuToken", "ZUV") Ownable(msg.sender) {
        lastMintTimestamp = block.timestamp;
    }

    /// @notice Sets the governance contract address
    /// @dev Can only be called by the owner and only once
    /// @param a The address of the governance contract
    function setGovernanceContract(address a) public onlyOwner {
        require(isGovernanceSet == false, "Governance contract already set");
        isGovernanceSet = true;
        governance = IGovernance(a); 
    }

    /// @notice Sets the governance contract address
    /// @dev Can only be called by the owner and only once
    /// @param a The address of the governance contract
    function setSubmissionContract(address a) public onlyOwner {
        require(isSubmissionSet == false, "Submission contract already set");
        isSubmissionSet = true;
        submission = ISubmission(a); 
    }

    /// @notice Mints rewards and distributes them to stakers
    /// @dev Can only be called after the minting interval has passed
    function mintRewards() external governanceContractSet submissionContractSet {
        require(isGovernanceSet, "Governance contract not set");
        require(isSubmissionSet, "Submission contract not set");

        require(block.timestamp >= lastMintTimestamp + MINT_INTERVAL, "Minting interval not passed");
        uint256 mints = 1; 
        //uint256 mints = (block.timestamp - lastMintTimestamp) / MINT_INTERVAL; // If more than one mint interval passed, calculate how many mints could've happened

        uint256 mintAmount = MINT_AMOUNT * mints * 10 ** decimals();

        uint256 stakeVote = governance.getStakeVote();
        (IGovernance.SubmissionReward[] memory submisssionRewards, uint256 submissionVote) = governance.getSubmissionRewards();
      
        uint256 rewardStake = (mintAmount * stakeVote) / (stakeVote + submissionVote);
        uint256 rewardSubmission = (mintAmount * submissionVote) / (stakeVote + submissionVote); 

        _mint(address(governance), rewardStake); // Mint to governance contract for distribution
        _mint(address(submission), rewardSubmission);

        // Distribute rewards to stakers via Governance contract
        governance.distributeRewards(rewardStake);
        // Distribute rewards to submissions via Submission contract 
        submission.distributeRewards(submisssionRewards, submissionVote, rewardSubmission);

        lastMintTimestamp = block.timestamp;
    }
}
