// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.10;

import "@openzeppelin/contracts/access/Ownable.sol";

import { IGovernance } from './IGovernance.sol';
import { IZuvuToken } from "./IZuvuToken.sol";

/// @title ZUV Governance Contract
/// @author BeAWhale
/// @notice This contract handles governance, staking, and reward distribution for the ZUV ecosystem.
contract Governance is IGovernance, Ownable {
    struct Stake {
        address staker;
        uint256 amount;
    }
    
    struct Vote {
        uint8 stake;
        SubmissionVote[] submissions;
    }

    // Used internally to aid with sorting 
    struct GovernorVoteStake {
        address governor;
        uint256 stakeVote;
        uint256 totalStake;
    }
    
    //TODO: needs a submission contract.
    struct SubmissionVote {
        uint256 id;
        uint8 percent;
    }

    struct GovernorMetadata {
        string name;
        string url;
    }

    mapping(address => uint256) governorsIds; // Maps governor address to their ID
    mapping(uint256 => address) governors;    // Maps ID to governor address
    uint256 public governorLength = 0;      // Total number of governors

    mapping(address => Vote) public votes;    // Maps governor address to their vote
    mapping(address => Stake[]) public stakes; // Maps governor address to their stakes
    mapping(address => GovernorMetadata) public governorMetadata; // Maps governor address to their metadata
    mapping(address => uint256) public stakerRewards; // Maps staker rewards which can be claimed later

    IZuvuToken public tokenAddress;
    bool tokenAddressSet = false;
    bool killSwitch = false;

    modifier isPercentage(uint256 p) {
        require(p <= 100, "percentage must be between 0 and 100");
        _;
    }

    modifier onlyTokenContract() {
        require(msg.sender == address(tokenAddress), "Caller is not the token contract");
        _;
    }

    modifier isGovernor(address governor) {
        require(governorsIds[governor] != 0, "Governor not registered");
        _;
    }

    // Kill switch 
    modifier ks() {
        require(killSwitch == false, "The contract is in maintenance mode");
        _;
    }

    constructor() Ownable(msg.sender) {}

    /// @notice Sets the token contract address
    /// @dev Can only be called by the owner and only once
    /// @param token The address of the ZuvuToken contract
    function setTokenAddress(address token) public onlyOwner {
        require(!tokenAddressSet, "Token address already set");
        tokenAddress = IZuvuToken(token);
        tokenAddressSet = true;
    }

    /// @notice sets the killSwitch value for ks modifier
    function setKillSwitch(bool val) public onlyOwner {
        killSwitch = val;
    }

    /// @notice Registers the caller as a governor
    /// @dev Governors can vote and participate in governance
    function registerGovernor() public ks {
        require(governorsIds[msg.sender] == 0, "Governor already registered");
        governorLength++;
        governorsIds[msg.sender] = governorLength;
        governors[governorLength] = msg.sender;
    }

    /// @notice Set's metadata for the governor
    function setGovernorMetadata(string calldata name, string calldata url) public isGovernor(msg.sender) ks {
        GovernorMetadata memory metadata = GovernorMetadata({
           name: name,
           url: url
        });

        governorMetadata[msg.sender] = metadata;
    }

    /// @notice Unregisters the caller as a governor
    /// @dev Removes the caller from the list of governors
    function unregisterGovernor() public isGovernor(msg.sender) ks {
        uint256 governorId = governorsIds[msg.sender];

        // Swap the last governor with the one being removed
        if (governorId != governorLength) {
            address lastGovernor = governors[governorLength];
            governors[governorId] = lastGovernor;
            governorsIds[lastGovernor] = governorId;
        }

        // Delete the governor from the mappings
        delete governorsIds[msg.sender];
        delete governors[governorLength];

        // Decrease the length
        governorLength--;
    }

    /// @notice Sets the stake for a governor
    /// @dev If the staker already exists, updates their stake; otherwise, creates a new stake entry
    /// @param governor The address of the governor
    /// @param amount The amount of tokens to stake
    function setStake(address governor, uint256 amount) public isGovernor(governor) ks {
        uint256 currentStake = 0;
        uint256 stakerIndex = stakes[governor].length;

        // Search for the staker in the stakes array
        for (uint256 i = 0; i < stakes[governor].length; i++) {
            if (stakes[governor][i].staker == msg.sender) {
                currentStake = stakes[governor][i].amount;
                stakerIndex = i;
                break;
            }
        }

        // Calculate the difference between the new stake and the current stake
        int256 difference = int256(amount) - int256(currentStake);

        // Update or create the stake entry
        if (stakerIndex < stakes[governor].length) {
            stakes[governor][stakerIndex].amount = amount;
        } else {
            stakes[governor].push(Stake({staker: msg.sender, amount: amount}));
        }   

        // Do the transfer
        if (difference > 0) {
            // If the new stake is higher, transfer the difference from the staker to this contract
            require(tokenAddress.transferFrom(msg.sender, address(this), uint256(difference)), "Transfer failed");
        } else if (difference < 0) {
            // If the new stake is lower, transfer the difference back to the staker
            require(tokenAddress.transfer(msg.sender, uint256(-difference)), "Transfer failed");
        }
    }

    /// @notice Gets the total stake for a governor
    /// @param governor The address of the governor
    /// @return The total stake for the governor
    function getGovernorTotalStake(address governor) public view isGovernor(governor) returns(uint256) {
        uint256 total = 0;

        for(uint256 i = 0; i < stakes[governor].length; i++) {
            total += stakes[governor][i].amount; 
        }

        return total;
    }

    /// @notice Casts a vote for a governor's stake
    /// @dev The vote must be a percentage (0-100)
    /// @param stakeVote The percentage vote for the governor's stake
    function voteStake(uint8 stakeVote) public isPercentage(stakeVote) isGovernor(msg.sender) ks {
        require(governorsIds[msg.sender] != 0, "Governor not registered");
        votes[msg.sender].stake = stakeVote;
    }

    /// @notice Casts a vote for a submission
    /// @dev Updates the vote if it already exists; otherwise, creates a new vote
    /// @param governor The address of the governor
    /// @param submissionId The ID of the submission
    /// @param submissionVote The percentage vote for the submission
    function voteForSubmission(address governor, uint256 submissionId, uint8 submissionVote) public isPercentage(submissionVote) isGovernor(governor) ks {
        Vote storage governorVote = votes[governor];
        bool found = false;

        // Check if the submission already exists
        for (uint256 i = 0; i < governorVote.submissions.length; i++) {
            if (governorVote.submissions[i].id == submissionId) {
                governorVote.submissions[i].percent = submissionVote;
                found = true;
                break;
            }
        }

        // If the submission doesn't exist, add it
        if (!found) {
            governorVote.submissions.push(SubmissionVote({id: submissionId, percent: submissionVote}));
        }
    }

    /// @notice Gets the total stake across all governors
    /// @return The total stake across all governors
    function getTotalStake() public view returns (uint256) {
        uint256 res = 0;

        // Calculate total stake for each governor
        for (uint256 i = 1; i <= governorLength; i++) {
            address governor = governors[i];
            res += getGovernorTotalStake(governor);
        }

        return res;
    }

    /// @notice Distributes rewards to stakers based on their stake votes
    /// @dev Can only be called by the token contract
    /// @param amount The total amount of rewards to distribute
    function distributeRewards(uint256 amount) public onlyTokenContract ks {
        uint256 totalStake = getTotalStake();
        require(totalStake > 0, "No stakes available");
    
        uint256 distributedAmount = 0;
        address lastStaker = address(0);
    
        for (uint256 i = 1; i <= governorLength; i++) {
            address governor = governors[i];
            for (uint256 j = 0; j < stakes[governor].length; j++) {
                Stake memory s = stakes[governor][j];
                
                // Calculate reward using fixed-point arithmetic
                uint256 reward = (s.amount * amount) / totalStake;
    
                // Add the reward to the staker's rewards
                stakerRewards[s.staker] += reward;
                distributedAmount += reward;
    
                // Track the last staker for remainder distribution
                lastStaker = s.staker;
            }
        }
    
        // Distribute the remainder to the last staker
        if (distributedAmount < amount) {
            uint256 remainder = amount - distributedAmount;
            stakerRewards[lastStaker] += remainder;
        }
    }

    /// @notice Allows a staker to claim their rewards
    function claimReward() public ks {
        require(stakerRewards[msg.sender] > 0, "No rewards");

        uint256 reward = stakerRewards[msg.sender];
        stakerRewards[msg.sender] = 0;
        tokenAddress.transfer(msg.sender, reward); 
    }

    /// @notice Returns the weighted median stake vote using governor total stake as weight
    /// @return The weighted median stake vote
    function getStakeVote() public view returns (uint256) {
        // Create an array to store governor addresses, their stake votes, and total stakes
        GovernorVoteStake[] memory governorVoteStakes = new GovernorVoteStake[](governorLength);
    
        // Calculate total stake for each governor and populate the array
        uint256 totalStake = 0;
        for (uint256 i = 1; i <= governorLength; i++) {
            address governor = governors[i];
            uint256 governorTotalStake = 0;
    
            // Sum up all stakes for the governor
            for (uint256 j = 0; j < stakes[governor].length; j++) {
                governorTotalStake += stakes[governor][j].amount;
            }
    
            governorVoteStakes[i - 1] = GovernorVoteStake({
                governor: governor,
                stakeVote: votes[governor].stake,
                totalStake: governorTotalStake
            });
    
            totalStake += governorTotalStake;
        }

        // Early return if the stake is 0
        if(totalStake == 0) {
            return 0;
        }
    
        // Sort the governors by stake vote (ascending order for median calculation)
        quickSortByVote(governorVoteStakes, 0, int256(governorVoteStakes.length - 1));
    
        // Calculate the weighted median
        uint256 halfTotalStake = totalStake / 2;
        uint256 accumulatedStake = 0;
    
        for (uint256 i = 0; i < governorVoteStakes.length; i++) {
            accumulatedStake += governorVoteStakes[i].totalStake;
            if (accumulatedStake >= halfTotalStake) {
                return governorVoteStakes[i].stakeVote;
            }
        }
    
        revert("Median calculation failed");
    }   

    /// @notice QuickSort implementation to sort GovernorVoteStake array by stakeVote (ascending)
    function quickSortByVote(GovernorVoteStake[] memory arr, int256 left, int256 right) internal pure {
        int256 i = left;
        int256 j = right;
        if (i == j) return;
        uint256 pivot = arr[uint256(left + (right - left) / 2)].stakeVote;
        while (i <= j) {
            while (arr[uint256(i)].stakeVote < pivot) i++;
            while (pivot < arr[uint256(j)].stakeVote) j--;
            if (i <= j) {
                (arr[uint256(i)], arr[uint256(j)]) = (arr[uint256(j)], arr[uint256(i)]);
                i++;
                j--;
            }
        }
        if (left < j) quickSortByVote(arr, left, j);
        if (i < right) quickSortByVote(arr, i, right);
    }

    /// @notice Returns the top N governors by total stake
    /// @param N The number of top governors to return
    /// @return An array of GovernorStake structs representing the top N governors
    function getTopGovernorsByStake(uint256 N) public view returns (GovernorStake[] memory) {
        require(N > 0 && N <= governorLength, "Invalid value for N");

        // Create an array to store governor addresses and their total stakes
        GovernorStake[] memory governorStakes = new GovernorStake[](governorLength);

        // Calculate total stake for each governor
        for (uint256 i = 1; i <= governorLength; i++) {
            address governor = governors[i];
            governorStakes[i - 1] = GovernorStake({governor: governor, totalStake: getGovernorTotalStake(governor)});
        }

        // Sort the governors by total stake (descending order)
        quickSort(governorStakes, 0, int256(governorStakes.length - 1));

        // Prepare the result array with the top N governors
        GovernorStake[] memory topGovernors = new GovernorStake[](N);
        for (uint256 i = 0; i < N; i++) {
            topGovernors[i] = governorStakes[i];
        }

        return topGovernors;
    }

    /// @notice QuickSort implementation to sort GovernorStake array by totalStake (descending)
    function quickSort(GovernorStake[] memory arr, int256 left, int256 right) internal pure {
        int256 i = left;
        int256 j = right;
        if (i == j) return;
        uint256 pivot = arr[uint256(left + (right - left) / 2)].totalStake;
        while (i <= j) {
            while (arr[uint256(i)].totalStake > pivot) i++;
            while (pivot > arr[uint256(j)].totalStake) j--;
            if (i <= j) {
                (arr[uint256(i)], arr[uint256(j)]) = (arr[uint256(j)], arr[uint256(i)]);
                i++;
                j--;
            }
        }
        if (left < j) quickSort(arr, left, j);
        if (i < right) quickSort(arr, i, right);
    }
}
