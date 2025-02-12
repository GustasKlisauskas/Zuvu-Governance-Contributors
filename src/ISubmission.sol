// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.10;

import { IGovernance } from "./IGovernance.sol";

/// @title ISubmission Interface
/// @notice Interface for the submission registering and rewards distribution.
interface ISubmission {

    // @notice Used to organize the returned information 
    struct GovernorStake {
        address governor;
        uint256 totalStake;
    }

    struct SubmissionReward {
        address submission;
        uint256 rew;
    }

    /// @notice Sets the token contract address
    /// @param token The address of the ZuvuToken contract
    function setTokenAddress(address token) external;

    /// @notice Registers the caller as a governor
    function registerGovernor() external;

    /// @notice Unregisters the caller as a governor
    function unregisterGovernor() external;

    /// @notice Sets the stake for a governor
    /// @param governor The address of the governor
    /// @param amount The amount of tokens to stake
    function setStake(address governor, uint256 amount) external;

    /// @notice Gets the total stake for a governor
    /// @param governor The address of the governor
    /// @return The total stake for the governor
    function getGovernorTotalStake(address governor) external view returns (uint256);

    /// @notice Casts a vote for a governor's stake
    /// @param stakeVote The percentage vote for the governor's stake
    function voteStake(uint8 stakeVote) external;

    /// @notice Casts a vote for a submission
    /// @param submission The address of the submission
    /// @param submissionVote The percentage vote for the submission
    function voteForSubmission(address submission, uint8 submissionVote) external;

    /// @notice Gets the total stake across all governors
    /// @return The total stake across all governors
    function getTotalStake() external view returns (uint256);

    /// @notice Distributes rewards to stakers based on their stake votes
    /// @param amount The total amount of rewards to distribute
    function distributeRewards(IGovernance.SubmissionReward[] calldata rewards, uint256 totalVote, uint256 amount) external;

    /// @notice Allows a staker to claim their rewards
    function claimReward() external;

    /// @notice Returns the weighted median stake vote
    /// @return The weighted median stake vote
    function getStakeVote() external view returns (uint256);

    /// @notice Returns the top N governors by total stake
    /// @param N The number of top governors to return
    /// @return governors An array of governor addresses and their total stakes
    function getTopGovernorsByStake(uint256 N) external view returns (GovernorStake[] memory governors);
}

