// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.9;

import "./uniswap-updated/IBasePositionManager.sol";

/**
 * @dev Interface of the MigrateV3NFT contract
 */
interface IMigrateV3NFT {
  function migrate (uint256 lockId, IBasePositionManager nftPositionManager, uint256 tokenId) external returns (bool);
}