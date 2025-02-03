// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.10;

/// @title IZuvuToken Interface
/// @notice Interface for the ZuvuToken contract handling minting, burning, and rewards.
interface IZuvuToken {

    /// @notice Sets the governance contract address
    /// @param governance The address of the governance contract
    function setGovernanceContract(address governance) external;

    /// @notice Mints rewards and distributes them to stakers
    function mintRewards() external;

    /// @notice Returns the name of the token
    /// @return The name of the token
    function name() external view returns (string memory);

    /// @notice Returns the symbol of the token
    /// @return The symbol of the token
    function symbol() external view returns (string memory);

    /// @notice Returns the number of decimals used
    /// @return The number of decimals
    function decimals() external view returns (uint8);

    /// @notice Returns the total supply of the token
    /// @return The total supply of the token
    function totalSupply() external view returns (uint256);

    /// @notice Transfers tokens from the caller to a recipient
    /// @param to The recipient address
    /// @param amount The amount of tokens to transfer
    /// @return A boolean indicating success
    function transfer(address to, uint256 amount) external returns (bool);

    /// @notice Approves another address to spend tokens on behalf of the caller
    /// @param spender The address authorized to spend
    /// @param amount The amount of tokens to approve
    /// @return A boolean indicating success
    function approve(address spender, uint256 amount) external returns (bool);

    /// @notice Transfers tokens from one address to another
    /// @param from The address to transfer from
    /// @param to The address to transfer to
    /// @param amount The amount of tokens to transfer
    /// @return A boolean indicating success
    function transferFrom(address from, address to, uint256 amount) external returns (bool);

    /// @notice Returns the balance of a given address
    /// @param account The address to query
    /// @return The token balance of the address
    function balanceOf(address account) external view returns (uint256);
}

