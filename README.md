## Foundry

Foundry consists of:

-   **Forge**: Ethereum testing framework (like Truffle, Hardhat and DappTools).
-   **Cast**: Swiss army knife for interacting with EVM smart contracts, sending transactions and getting chain data.
-   **Anvil**: Local Ethereum node, akin to Ganache, Hardhat Network.
-   **Chisel**: Fast, utilitarian, and verbose solidity REPL.

https://book.getfoundry.sh/

## Usage

### Build

```shell
$ forge build
```

### Test

```shell
$ forge test
```

### Format

```shell
$ forge fmt
```

### Gas Snapshots

```shell
$ forge snapshot
```

### Anvil

```shell
$ anvil
```

### Deploy

```shell
$ forge script script/Counter.s.sol:CounterScript --rpc-url <your_rpc_url> --private-key <your_private_key>
```

### Cast

```shell
$ cast <subcommand>
```

### Help

```shell
$ forge --help
$ anvil --help
$ cast --help
```

# Zuvu Smart Contracts Documentation

The Zuvu ecosystem is governed by three main smart contracts:

1. **ZuvuToken.sol** – An ERC20 token with custom minting, burning, and reward distribution logic.
2. **Governance.sol** – The governance hub where governors register, stake tokens, cast votes, and manage reward distribution.
3. **Submission.sol** – *Work in Progress.* This contract will allow users to submit their AI agents and handle submission voting.

In addition, there are two interfaces:
- **IZuvuToken.sol** – Interface for the ZuvuToken contract.
- **IGovernance.sol** – Interface for the Governance contract.

---

## 1. ZuvuToken.sol

### Overview

The **ZuvuToken** contract implements an ERC20 token with additional functionality:

- **Minting Schedule:** Tokens are minted at fixed intervals (every day) using a pre-defined mint amount.
- **Reward Distribution:** A percentage of the minted tokens is allocated as rewards and distributed to stakers via the Governance contract.
- **Burn Mechanism:** The remainder of the minted tokens (after rewards) is burned to reduce the overall token supply.
- **Governance Integration:** The token contract must be connected to the Governance contract via the `setGovernanceContract` function. Reward minting is then performed through `mintRewards`.

### Key Constants and Variables

- `MINT_INTERVAL`: Time interval between mints (set to 1 day).
- `MINT_AMOUNT`: Number of tokens minted per interval (1,000,000 tokens, adjusted by decimals).
- `lastMintTimestamp`: Records the timestamp of the last mint.
- `governance`: The address of the connected Governance contract.
- `isGovernanceSet`: Ensures the governance address is set only once.

### Key Functions

- **setGovernanceContract(address a)**
  - _Purpose:_ Links the Governance contract to the token.
  - _Access:_ Owner-only; callable only once.
  
- **mintRewards()**
  - _Purpose:_ Mints new tokens after the mint interval has passed, calculates reward and burn amounts, and triggers reward distribution.
  - _Process:_
    1. Verifies the minting interval has passed.
    2. Computes the total mint amount.
    3. Retrieves the reward percentage by calling `governance.getStakeVote()`.
    4. Mints tokens for rewards and mints then burns the remainder.
    5. Calls `governance.distributeRewards(rewardAmount)` to distribute rewards to stakers.
    6. Updates `lastMintTimestamp` and emits a `RewardsMinted` event.

---

## 2. Governance.sol

### Overview

The **Governance** contract serves as the core hub for governance activities. It manages:

- **Governor Registration:** Users register as governors to participate in the ecosystem.
- **Staking:** Users can stake tokens toward a governor, and their stakes count toward the governor’s total.
- **Voting:** Governors can vote on the reward percentage (stake vote) and, in the future, on submissions.
- **Reward Distribution:** Rewards from the token minting process are distributed to stakers based on their stake.

### Roles

- **Governors:**  
  - Register using `registerGovernor()`.
  - Set their metadata using `setGovernorMetadata(string name, string url)`.
  - Cast their vote on reward percentages using `voteStake(uint8 stakeVote)`.
  - (Future functionality) Vote on submissions using `voteForSubmission(...)`.

- **Stakers:**  
  - Stake tokens for a governor using `setStake(address governor, uint256 amount)`.
  - Accumulate rewards based on their stake, which they can claim later using `claimReward()`.

### Key Structures

- **Stake:**  
  Tracks individual staker addresses and their staked amounts for a given governor.

- **Vote:**  
  Records the stake vote (a percentage) along with an array of submission votes.

- **GovernorVoteStake:**  
  Internal structure to aid in calculating the weighted median of stake votes, including the governor’s address, vote percentage, and total stake.

- **GovernorMetadata:**  
  Contains metadata (name and URL) for each governor.

- **GovernorStake (defined in IGovernance):**  
  Used to return a governor's address and total stake when querying the top N governors.

### Key Mappings and Variables

- **Governor Tracking:**  
  - `governorsIds` and `governors` map governor addresses to their IDs and vice versa.
  - `governorLength` tracks the total number of registered governors.

- **Stakes and Votes:**  
  - `stakes`: Maps each governor to an array of stake entries.
  - `votes`: Maps each governor to their vote (for stake reward and submissions).

- **Rewards:**  
  - `stakerRewards`: Maps staker addresses to their accumulated rewards.

- **Token Integration and Kill Switch:**  
  - `tokenAddress`: Points to the connected ZuvuToken contract.
  - `killSwitch`: Can disable operations across the contract during maintenance.

### Key Functions

- **setTokenAddress(address token)**
  - _Purpose:_ Sets the token contract address (owner-only, one-time call).

- **setKillSwitch(bool val)**
  - _Purpose:_ Enables or disables operations via the `ks` (kill switch) modifier.

- **registerGovernor() & unregisterGovernor()**
  - _Purpose:_ Allow users to register or unregister as governors.
  - _Mechanism:_ Registration assigns an ID and updates internal mappings. Unregistration swaps the governor to be removed with the last entry to maintain continuity.

- **setGovernorMetadata(string calldata name, string calldata url)**
  - _Purpose:_ Allows governors to set or update their metadata.

- **setStake(address governor, uint256 amount)**
  - _Purpose:_ Lets a staker deposit tokens to a governor's stake.
  - _Mechanism:_  
    - If the staker already has a stake, the function computes the difference and either transfers tokens from or back to the staker.
    - Tokens must be approved beforehand via ERC20’s `approve`.

- **getGovernorTotalStake(address governor)**
  - _Purpose:_ Returns the total tokens staked for a governor.

- **voteStake(uint8 stakeVote)**
  - _Purpose:_ Allows a governor to cast a vote for the reward percentage (0-100).

- **voteForSubmission(address governor, uint256 submissionId, uint8 submissionVote)**
  - _Purpose:_ Enables voting on submissions (work in progress).

- **getTotalStake()**
  - _Purpose:_ Calculates the overall staked tokens across all governors.

- **distributeRewards(uint256 amount)**
  - _Purpose:_ Distributes reward tokens among stakers proportional to their stake.
  - _Access:_ Callable only by the ZuvuToken contract.

- **claimReward()**
  - _Purpose:_ Allows stakers to claim their accumulated rewards.

- **getStakeVote()**
  - _Purpose:_ Returns the weighted median of stake votes.
  - _Mechanism:_  
    1. Creates an array of `GovernorVoteStake` objects.
    2. Sorts this array by vote percentages.
    3. Iterates until the accumulated stake exceeds half of the total stake and returns that vote as the median.

- **getTopGovernorsByStake(uint256 N)**
  - _Purpose:_ Returns the top N governors sorted by total stake.
  - _Mechanism:_ Constructs and sorts an array of `GovernorStake` objects in descending order and returns the top N entries.

### Internal Sorting Algorithms

The contract uses two custom quicksort implementations:
- **quickSortByVote:** Sorts an array of `GovernorVoteStake` structures in ascending order based on `stakeVote`.
- **quickSort:** Sorts an array of `GovernorStake` structures in descending order based on `totalStake`.

---

## 3. Submission.sol

**Note:** This contract is currently a work in progress. It is planned to handle the submission of AI agents and facilitate voting on these submissions.

---

## 4. Interfaces

### IZuvuToken.sol

Defines the external interface for the **ZuvuToken** contract. Key functions include:

- `setGovernanceContract(address governance)`
- `mintRewards()`
- Standard ERC20 functions:
  - `name()`
  - `symbol()`
  - `decimals()`
  - `totalSupply()`
  - `transfer(address to, uint256 amount)`
  - `approve(address spender, uint256 amount)`
  - `transferFrom(address from, address to, uint256 amount)`
  - `balanceOf(address account)`

### IGovernance.sol

Defines the external interface for the **Governance** contract. Key functions include:

- `setTokenAddress(address token)`
- `registerGovernor() / unregisterGovernor()`
- `setStake(address governor, uint256 amount)`
- `getGovernorTotalStake(address governor)`
- `voteStake(uint8 stakeVote)`
- `voteForSubmission(address governor, uint256 submissionId, uint8 submissionVote)`
- `getTotalStake()`
- `distributeRewards(uint256 amount)`
- `claimReward()`
- `getStakeVote()`
- `getTopGovernorsByStake(uint256 N)`

---

## Usage Summary

1. **Deployment and Setup:**
   - Deploy the **ZuvuToken** contract.
   - Deploy the **Governance** contract.
   - As the owner, call `setTokenAddress(address token)` on the Governance contract to set the token address.
   - Next, call `setGovernanceContract(address governance)` on the ZuvuToken contract to link the governance module.

2. **Governance and Staking:**
   - Users register as governors using `registerGovernor()`.
   - Governors may set metadata with `setGovernorMetadata(string name, string url)`.
   - Stakers can stake tokens for any governor using `setStake(address governor, uint256 amount)`.
     - **Note:** Ensure tokens are approved for transfer by calling the ERC20 `approve` function first.

3. **Voting:**
   - Governors cast their vote on the reward percentage using `voteStake(uint8 percentage)`.
   - (WIP) Governors may also vote on submissions via `voteForSubmission()`.

4. **Reward Distribution:**
   - After the minting interval, call `mintRewards()` on the ZuvuToken contract.
   - Rewards are distributed to stakers via the Governance contract.
   - Stakers can claim their rewards using `claimReward()`.

5. **Querying Governance Data:**
   - Use `getTotalStake()` to view overall staked tokens.
   - Use `getStakeVote()` to retrieve the current weighted median vote for reward allocation.
   - Use `getTopGovernorsByStake(uint256 N)` to see the top N governors by stake.

---

This documentation provides a concise overview of the Zuvu smart contracts, their interactions, and usage. Save this file in your repository to help developers and users understand the system architecture.
