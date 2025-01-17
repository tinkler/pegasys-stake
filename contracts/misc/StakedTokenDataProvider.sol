// SPDX-License-Identifier: MIT
pragma solidity 0.7.5;
pragma experimental ABIEncoderV2;

import {IERC20} from '../interfaces/IERC20.sol';
import {AggregatedStakedPSYSV3} from '../interfaces/AggregatedStakedPSYSV3.sol';
import {IStakedToken} from '../interfaces/IStakedToken.sol';
import {AggregatorInterface} from '../interfaces/AggregatorInterface.sol';
import {IStakedTokenDataProvider} from '../interfaces/IStakedTokenDataProvider.sol';

/**
 * @title StakedTokenDataProvider
 * @notice Data provider contract for Staked Tokens of the Safety Module (e.g. PSYS:stkPSYS and BPT:StkBPT)
 */
contract StakedTokenDataProvider is IStakedTokenDataProvider {
  /// @inheritdoc IStakedTokenDataProvider
  address public immutable override ETH_USD_PRICE_FEED;

  /// @inheritdoc IStakedTokenDataProvider
  address public immutable override PSYS_PRICE_FEED;

  /// @inheritdoc IStakedTokenDataProvider
  address public immutable override BPT_PRICE_FEED;

  /// @inheritdoc IStakedTokenDataProvider
  address public immutable override PSYS;

  /// @inheritdoc IStakedTokenDataProvider
  address public immutable override STAKED_PSYS;

  /// @inheritdoc IStakedTokenDataProvider
  address public immutable override BPT;

  /// @inheritdoc IStakedTokenDataProvider
  address public immutable override STAKED_BPT;

  uint256 private constant SECONDS_PER_YEAR = 365 days;

  uint256 private constant APY_PRECISION = 10000;

  /**
   * @dev Constructor
   * @param psys The address of the PSYS token
   * @param stkPSYS The address of the StkPSYS token
   * @param bpt The address of the BPT PSYS / ETH token
   * @param stkBpt The address of the StkBptPSYS token
   * @param ethUsdPriceFeed The address of ETH price feed (USD denominated, with 8 decimals)
   * @param psysPriceFeed The address of PSYS price feed (ETH denominated, with 18 decimals)
   * @param bptPriceFeed The address of StakedBpt price feed (ETH denominated, with 18 decimals)
   */
  constructor(
    address psys,
    address stkPSYS,
    address bpt,
    address stkBpt,
    address ethUsdPriceFeed,
    address psysPriceFeed,
    address bptPriceFeed
  ) public {
    PSYS = psys;
    STAKED_PSYS = stkPSYS;
    BPT = bpt;
    STAKED_BPT = stkBpt;
    ETH_USD_PRICE_FEED = ethUsdPriceFeed;
    PSYS_PRICE_FEED = psysPriceFeed;
    BPT_PRICE_FEED = bptPriceFeed;
  }

  /// @inheritdoc IStakedTokenDataProvider
  function getAllStakedTokenData()
    external
    view
    override
    returns (
      StakedTokenData memory stkPSYSData,
      StakedTokenData memory stkBptData,
      uint256 ethPrice
    )
  {
    stkPSYSData = _getStakedTokenData(AggregatedStakedPSYSV3(STAKED_PSYS));
    stkBptData = _getStakedTokenData(AggregatedStakedPSYSV3(STAKED_BPT));
    ethPrice = uint256(AggregatorInterface(ETH_USD_PRICE_FEED).latestAnswer());
  }

  /// @inheritdoc IStakedTokenDataProvider
  function getstkPSYSData() external view override returns (StakedTokenData memory stkPSYSData) {
    stkPSYSData = _getStakedTokenData(AggregatedStakedPSYSV3(STAKED_PSYS));
  }

  /// @inheritdoc IStakedTokenDataProvider
  function getStkBptData() external view override returns (StakedTokenData memory stkBptData) {
    stkBptData = _getStakedTokenData(AggregatedStakedPSYSV3(STAKED_BPT));
  }

  /// @inheritdoc IStakedTokenDataProvider
  function getAllStakedTokenUserData(
    address user
  )
    external
    view
    override
    returns (
      StakedTokenData memory stkPSYSData,
      StakedTokenUserData memory stkPSYSUserData,
      StakedTokenData memory stkBptData,
      StakedTokenUserData memory stkBptUserData,
      uint256 ethPrice
    )
  {
    stkPSYSData = _getStakedTokenData(AggregatedStakedPSYSV3(STAKED_PSYS));
    stkPSYSUserData = _getStakedTokenUserData(AggregatedStakedPSYSV3(STAKED_PSYS), user);
    stkBptData = _getStakedTokenData(AggregatedStakedPSYSV3(STAKED_BPT));
    stkBptUserData = _getStakedTokenUserData(AggregatedStakedPSYSV3(STAKED_BPT), user);
    ethPrice = uint256(AggregatorInterface(ETH_USD_PRICE_FEED).latestAnswer());
  }

  /// @inheritdoc IStakedTokenDataProvider
  function getstkPSYSUserData(
    address user
  )
    external
    view
    override
    returns (StakedTokenData memory stkPSYSData, StakedTokenUserData memory stkPSYSUserData)
  {
    stkPSYSData = _getStakedTokenData(AggregatedStakedPSYSV3(STAKED_PSYS));
    stkPSYSUserData = _getStakedTokenUserData(AggregatedStakedPSYSV3(STAKED_PSYS), user);
  }

  /// @inheritdoc IStakedTokenDataProvider
  function getStkBptPegasysUserData(
    address user
  )
    external
    view
    override
    returns (StakedTokenData memory stkBptData, StakedTokenUserData memory stkBptUserData)
  {
    stkBptData = _getStakedTokenData(AggregatedStakedPSYSV3(STAKED_BPT));
    stkBptUserData = _getStakedTokenUserData(AggregatedStakedPSYSV3(STAKED_BPT), user);
  }

  /**
   * @notice Returns data of the Staked Token passed as parameter
   * @param stakedToken The address of the StakedToken (eg. stkPSYS, stkbptPSYS)
   * @return data An object with general data of the StakedToken
   */
  function _getStakedTokenData(
    AggregatedStakedPSYSV3 stakedToken
  ) internal view returns (StakedTokenData memory data) {
    data.stakedTokenTotalSupply = stakedToken.totalSupply();
    data.stakedTokenTotalRedeemableAmount = stakedToken.previewRedeem(data.stakedTokenTotalSupply);
    data.stakeCooldownSeconds = stakedToken.COOLDOWN_SECONDS();
    data.stakeUnstakeWindow = stakedToken.UNSTAKE_WINDOW();
    data.rewardTokenPriceEth = uint256(AggregatorInterface(PSYS_PRICE_FEED).latestAnswer());
    data.distributionEnd = stakedToken.DISTRIBUTION_END();

    data.distributionPerSecond = block.timestamp < data.distributionEnd
      ? stakedToken.assets(address(stakedToken)).emissionPerSecond
      : 0;

    // stkPSYS
    if (address(stakedToken) == STAKED_PSYS) {
      data.stakedTokenPriceEth = data.rewardTokenPriceEth;
      // assumes PSYS and stkPSYS have the same value
      data.stakeApy = _calculateApy(data.distributionPerSecond, data.stakedTokenTotalSupply);

      // stkbptPSYS
    } else if (address(stakedToken) == STAKED_BPT) {
      data.stakedTokenPriceEth = uint256(AggregatorInterface(BPT_PRICE_FEED).latestAnswer());
      data.stakeApy = _calculateApy(
        data.distributionPerSecond * data.rewardTokenPriceEth,
        data.stakedTokenTotalSupply * data.stakedTokenPriceEth
      );
    }
  }

  /**
   * @notice Calculates the APY of the reward distribution among StakedToken holders
   * @dev It uses the value of the reward and StakedToken asset
   * @param distributionPerSecond The value of the rewards being distributed per second
   * @param stakedTokenTotalSupply The value of the total supply of StakedToken asset
   */
  function _calculateApy(
    uint256 distributionPerSecond,
    uint256 stakedTokenTotalSupply
  ) internal pure returns (uint256) {
    if (stakedTokenTotalSupply == 0) return 0;
    return (distributionPerSecond * SECONDS_PER_YEAR * APY_PRECISION) / stakedTokenTotalSupply;
  }

  /**
   * @notice Returns user data of the Staked Token
   * @param stakedToken The address of the StakedToken asset
   * @param user The address of the user
   */
  function _getStakedTokenUserData(
    AggregatedStakedPSYSV3 stakedToken,
    address user
  ) internal view returns (StakedTokenUserData memory data) {
    data.stakedTokenUserBalance = stakedToken.balanceOf(user);
    data.rewardsToClaim = stakedToken.getTotalRewardsBalance(user);
    data.underlyingTokenUserBalance = IERC20(stakedToken.STAKED_TOKEN()).balanceOf(user);
    data.stakedTokenRedeemableAmount = stakedToken.previewRedeem(data.stakedTokenUserBalance);
    (data.userCooldownTimestamp, data.userCooldownAmount) = stakedToken.stakersCooldowns(user);
  }
}
