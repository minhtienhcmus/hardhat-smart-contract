// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

import "./IBasePositionManager.sol";
import "./IFactory.sol";
import "./TokenLockerFactory.sol";
import "./TokenLocker.sol";
import "./IWETH.sol";
import "./IUniswapV2Router02.sol";
import "./IUniswapV2Factory.sol";
import "./TokenLockerFactory.sol";
import {QtyDeltaMath} from "./QtyDeltaMath.sol";

contract IDOPool is Ownable, ReentrancyGuard {
    using SafeMath for uint256;
    using SafeERC20 for ERC20;

    struct FinInfo {
        uint256 tokenPrice; // one token in WEI
        uint256 softCap;
        uint256 hardCap;
        uint256 minEthPayment;
        uint256 maxEthPayment;
        uint256 listingPrice; // one token in WEI
        uint256 lpInterestRate;
        uint256 claimCycle; // days
        uint256 percentClaimfromSecondTime;
        uint256 percentClaimFisrtTime; // 5 -> 5%, 100 -> 100%
    }

    struct Timestamps {
        uint256 startTimestamp;
        uint256 endTimestamp;
        uint256 unlockTimestamp;
    }

    // struct DEXInfo {
    //     address nonfungiblePositionManager;
    //     address factory;
    //     address weth;
    //     int24 tickLower;
    //     int24 tickUpper;
    //     int24[2] ticksPrevious;
    // }
    struct DEXInfo {
        address nonfungiblePositionManager;
        address router;
        address factory;
        address weth;
        int24 tickLower;
        int24 tickUpper;
        uint160 currentSqrtP;
        int24[2] ticksPrevious;
        // address admin;
        bool fee;
    }

    struct UserInfo {
        uint debt;
        uint total;
        uint totalInvestedETH;
    }

    ERC20 public rewardToken;
    uint256 public decimals;
    string public metadataURL;

    FinInfo public finInfo;
    Timestamps public timestamps;
    DEXInfo public dexInfo;
    TokenLockerFactory public lockerFactory;

    uint256 public totalInvestedETH;
    uint256 public tokensForDistribution;
    uint256 public feeETH1 = 500;
    uint256 public feeETH2 = 200;
    uint256 public feeToken = 200;
    uint24 public feeLq = 300;
    // uint256 public distributedTokens;
    IBasePositionManager public basePositionManager;
    bool public distributed = false;
    bool public iswithdrawnotsold = false;
    bool public isVerify = false;
    mapping(address => UserInfo) public userInfo;
    mapping(address => uint256) public claimed; // if claimed=1, first period is claimed, claimed=2, second period is claimed, claimed=0, nothing claimed.
    mapping(address => uint256) public investmentsCanClaims; // investmentsCanClaims

    event TokensDebt(address indexed holder, uint256 ethAmount, uint256 tokenAmount);

    event TokensWithdrawn(address indexed holder, uint256 amount);
    bool public mode;
    uint256 public claimCycle = 90 days;
    uint256 public claimPeriod;
    address public admin;
    bool public feeOpt;
    modifier isValidClaimPeriod() {
        uint256 currentPeriod = getCurrentPeriod();

        require(currentPeriod > 0, "Listing not started");

        require(claimed[msg.sender] < currentPeriod, "Already claimed or refunded");
        _;
    }
    modifier isAdmin() {
        require(msg.sender == admin, "Only admin");
        _;
    }

    constructor(
        ERC20 _rewardToken,
        FinInfo memory _finInfo,
        Timestamps memory _timestamps,
        DEXInfo memory _dexInfo,
        address _lockerFactoryAddress,
        string memory _metadataURL,
        bool _mode,
        address _admin
    ) {
        rewardToken = _rewardToken;
        decimals = rewardToken.decimals();
        lockerFactory = TokenLockerFactory(_lockerFactoryAddress);
        finInfo = _finInfo;
        admin = _admin;
        feeOpt = _dexInfo.fee;
        setTimestamps(_timestamps);
        claimCycle = _finInfo.claimCycle * 1 days; //  minutes
        dexInfo = _dexInfo;
        basePositionManager = IBasePositionManager(dexInfo.nonfungiblePositionManager);
        setMetadataURL(_metadataURL);
        mode = _mode;

        uint temp = 10000 - finInfo.percentClaimFisrtTime;
        uint counter = 1;
        if (temp > 0) {
            uint temp2 = temp % finInfo.percentClaimfromSecondTime;
            if (temp2 == 0) {
                counter += temp / finInfo.percentClaimfromSecondTime;
            } else {
                counter += uint(temp / finInfo.percentClaimfromSecondTime) + 1;
            }
        }
        claimPeriod = counter;
    }

    function setTimestamps(Timestamps memory _timestamps) internal {
        require(
            _timestamps.startTimestamp < _timestamps.endTimestamp,
            "Start timestamp must be less than finish timestamp"
        );
        require(_timestamps.endTimestamp > block.timestamp, "Finish timestamp must be more than current block");

        timestamps = _timestamps;
    }

    function setMetadataURL(string memory _metadataURL) public {
        metadataURL = _metadataURL;
    }

    function pay() external payable {
        require(block.timestamp >= timestamps.startTimestamp, "Not started");
        require(block.timestamp < timestamps.endTimestamp, "Ended");

        require(msg.value >= finInfo.minEthPayment, "Less then min amount");
        require(msg.value <= finInfo.maxEthPayment, "More then max amount");
        require(totalInvestedETH.add(msg.value) <= finInfo.hardCap, "Overfilled");

        UserInfo storage user = userInfo[msg.sender];
        require(user.totalInvestedETH.add(msg.value) <= finInfo.maxEthPayment, "More then max amount");

        uint256 tokenAmount = getTokenAmount(msg.value, finInfo.tokenPrice);

        totalInvestedETH = totalInvestedETH.add(msg.value);
        tokensForDistribution = tokensForDistribution.add(tokenAmount);
        user.totalInvestedETH = user.totalInvestedETH.add(msg.value);
        user.total = user.total.add(tokenAmount);
        user.debt = user.debt.add(tokenAmount);

        emit TokensDebt(msg.sender, msg.value, tokenAmount);
    }

    function refund() external {
        require(block.timestamp > timestamps.endTimestamp, "The IDO pool has not ended.");
        require(totalInvestedETH < finInfo.softCap, "The IDO pool has reach soft cap.");
        require(claimed[msg.sender] == 0, "Already claimed");
        UserInfo storage user = userInfo[msg.sender];
        uint256 _amount = user.totalInvestedETH;
        require(_amount > 0, "You have no investment.");
        claimed[msg.sender] = claimPeriod;
        user.debt = 0;
        user.totalInvestedETH = 0;
        user.total = 0;

        (bool success, ) = msg.sender.call{value: _amount}("");
        require(success, "Transfer failed.");
    }

    // /// @dev Allows to claim tokens for the specific user.
    // /// @param _user Token receiver.
    // function claimFor(address _user) external isValidClaimPeriod {
    //     proccessClaim(_user);
    // }

    /// @dev Allows to claim tokens for themselves.
    function claim() external isValidClaimPeriod {
        proccessClaim(msg.sender);
    }

    /// @dev Proccess the claim.
    /// @param _receiver Token receiver.
    function proccessClaim(address _receiver) internal nonReentrant {
        require(block.timestamp > timestamps.endTimestamp, "The IDO pool has not ended.");
        require(totalInvestedETH >= finInfo.softCap, "The IDO pool did not reach soft cap.");

        UserInfo storage user = userInfo[_receiver];
        uint currentClaim = getCurrentPeriod();
        // uint256 _amount = user.debt;
        require(user.debt > 0, "You do not have debt tokens.");

        // user.debt = 0;

        // rewardToken.safeTransfer(_receiver, _amount);
        if (currentClaim == claimPeriod) {
            uint256 _claimAmount;
            if (claimed[msg.sender] == 0) {
                require(user.debt > 0, "User not invest");
                _claimAmount = user.debt;
            } else {
                require(investmentsCanClaims[msg.sender] > 0, " User has claimed All");
                _claimAmount = investmentsCanClaims[msg.sender];
            }
            rewardToken.safeTransfer(msg.sender, _claimAmount);
            investmentsCanClaims[msg.sender] = 0;
            claimed[msg.sender] = claimPeriod;
            // distributedTokens = distributedTokens.add(_claimAmount);
            emit TokensWithdrawn(_receiver, _claimAmount);
        } else {
            uint _amount = 0;
            require(claimed[msg.sender] < currentClaim, "Claimed too many times compared to the standard");
            for (uint i = claimed[msg.sender]; i < currentClaim; i++) {
                if (i == 0) {
                    uint _amountFirst = user.debt.mul(finInfo.percentClaimFisrtTime).div(10000);
                    _amount += _amountFirst;
                    investmentsCanClaims[msg.sender] = user.debt.sub(_amountFirst);
                } else {
                    uint _amountClaim = user.total.mul(finInfo.percentClaimfromSecondTime).div(10000);
                    _amount += _amountClaim;
                    investmentsCanClaims[msg.sender] = investmentsCanClaims[msg.sender] - _amountClaim;
                }

                claimed[msg.sender] += 1;
            }
            rewardToken.safeTransfer(msg.sender, _amount);
            // distributedTokens = distributedTokens.add(_amount);
            emit TokensWithdrawn(_receiver, _amount);
        }
        user.debt = investmentsCanClaims[msg.sender];
    }

    function getCurrentPeriod() public view returns (uint256) {
        uint256 currentPeriod = 0;

        for (uint256 i = 0; i < claimPeriod; i++) {
            if (
                block.timestamp >= timestamps.endTimestamp + (claimCycle * i) &&
                block.timestamp < timestamps.endTimestamp + (claimCycle * (i + 1))
            ) {
                currentPeriod = i + 1;
                break;
            }
        }
        if (block.timestamp >= timestamps.endTimestamp + (claimCycle * claimPeriod)) {
            currentPeriod = claimPeriod;
        }
        return currentPeriod;
    }

    function mintNFT(
        uint amount0ToAdd,
        uint amount1ToAdd,
        address lockerAdd
    ) internal returns (uint tokenId, uint128 liquidity, uint amount0, uint amount1, uint amountRefund) {
        require(IWETH(dexInfo.weth).approve(dexInfo.nonfungiblePositionManager, type(uint256).max), "approve failed");
        require(
            rewardToken.approve(dexInfo.nonfungiblePositionManager, type(uint256).max),
            "Approve rewardToken to nonfungiblePositionManager failed"
        );
        require(IWETH(dexInfo.weth).approve(address(this), type(uint256).max), "approve failed");
        require(rewardToken.approve(address(this), type(uint256).max), "Approve rewardToken to this contract failed");
        (address token0, address token1) = (address(rewardToken), (dexInfo.weth));

        (uint256 qty0, uint256 qty1) = QtyDeltaMath.calcUnlockQtys(dexInfo.currentSqrtP);

        if (address(rewardToken) < (dexInfo.weth)) {
            uint256 amount = amount1ToAdd + qty1;
            IWETH(dexInfo.weth).deposit{value: (amount)}();
            amountRefund = qty1;
        } else {
            (token0, token1) = ((dexInfo.weth), address(rewardToken));
            uint256 amount = amount0ToAdd + qty0;
            amountRefund = qty0;
            IWETH(dexInfo.weth).deposit{value: amount}();
        }

        basePositionManager.createAndUnlockPoolIfNecessary(token0, token1, feeLq, dexInfo.currentSqrtP);

        IBasePositionManager.MintParams memory params = IBasePositionManager.MintParams({
            token0: token0,
            token1: token1,
            fee: feeLq,
            tickLower: dexInfo.tickLower,
            tickUpper: dexInfo.tickUpper,
            ticksPrevious: dexInfo.ticksPrevious,
            amount0Desired: amount0ToAdd,
            amount1Desired: amount1ToAdd,
            amount0Min: 0,
            amount1Min: 0,
            recipient: lockerAdd,
            deadline: block.timestamp
        });
        (tokenId, liquidity, amount0, amount1) = basePositionManager.mint(params);

        if (amount0 < amount0ToAdd) {
            ERC20(token0).approve(address(dexInfo.nonfungiblePositionManager), 0);
            uint256 refund0 = amount0ToAdd - amount0;
            ERC20(token0).transfer(msg.sender, refund0);
        }
        if (amount1 < amount1ToAdd) {
            ERC20(token1).approve(address(dexInfo.nonfungiblePositionManager), 0);
            uint256 refund1 = amount1ToAdd - amount1;
            ERC20(token1).transfer(msg.sender, refund1);
        }
    }

    function withdrawETH() external payable onlyOwner {
        require(block.timestamp > timestamps.endTimestamp, "The IDO pool has not ended.");
        require(totalInvestedETH >= finInfo.softCap, "The IDO pool did not reach soft cap.");
        require(!distributed, "Already distributed.");

        // This forwards all available gas. Be sure to check the return value!
        uint256 balance = address(this).balance;
        uint256 feeOP;
        uint amountTokenFee;
        if (feeOpt == false) {
            feeOP = (balance.mul(feeETH1).div(10000));
            amountTokenFee = 0;
        } else {
            feeOP = (balance.mul(feeETH2).div(10000));
            amountTokenFee = getTokenAmount(balance, finInfo.tokenPrice).mul(feeToken).div(10000);
        }
        // if (finInfo.lpInterestRate > 0 && finInfo.listingPrice > 0) {
        // if TokenLockerFactory has fee we should provide there fee by msg.value and sub it from balance for correct execution
        // balance -= msg.value;
        uint256 ethlq = (balance - feeOP);
        uint256 ethForPool = (ethlq * finInfo.lpInterestRate) / 10000;
        uint256 ethWithdraw = ethlq - ethForPool;

        uint256 tokenAmount = getTokenAmount(ethForPool, finInfo.listingPrice);
        // Add Liquidity ETH
        if (mode == false) {
            rewardToken.approve(address(dexInfo.nonfungiblePositionManager), tokenAmount);
            uint256 amount0ToAdd;
            uint256 amount1ToAdd;
            if (address(rewardToken) < (dexInfo.weth)) {
                amount0ToAdd = tokenAmount;
                amount1ToAdd = ethForPool;
            } else {
                amount0ToAdd = ethForPool;
                amount1ToAdd = tokenAmount;
            }
            // Lock LP Tokens

            if (timestamps.unlockTimestamp > block.timestamp) {
                // lpToken.approve(address(lockerFactory), liquidity);
                //Add liquidity
                (uint tokenId, , , , uint amountRefund) = mintNFT(amount0ToAdd, amount1ToAdd, address(lockerFactory));
                // address pool = IFactory(dexInfo.factory).getPool(address(rewardToken), dexInfo.weth, feeLq);

                ERC20 lpToken = ERC20(address(rewardToken));
                lockerFactory.createLocker(
                    lpToken,
                    string.concat(basePositionManager.symbol(), " nft locker"),
                    tokenId,
                    msg.sender,
                    timestamps.unlockTimestamp,
                    false
                );
                ethWithdraw -= amountRefund;
            } else {
                (, , , , uint amountRefund) = mintNFT(amount0ToAdd, amount1ToAdd, msg.sender);
                ethWithdraw -= amountRefund;
            }
        } else {
            // Add Liquidity ETH
            IUniswapV2Router02 uniswapRouter = IUniswapV2Router02(dexInfo.router);
            rewardToken.approve(address(uniswapRouter), tokenAmount);
            (, , uint liquidity) = uniswapRouter.addLiquidityETH{value: ethForPool}(
                address(rewardToken),
                tokenAmount,
                0, // slippage is unavoidable
                0, // slippage is unavoidable
                address(this),
                block.timestamp + 360
            );
            // Lock LP Tokens
            address lpTokenAddress = IUniswapV2Factory(dexInfo.factory).getPair(address(rewardToken), dexInfo.weth);

            ERC20 lpToken = ERC20(lpTokenAddress);

            if (timestamps.unlockTimestamp > block.timestamp) {
                lpToken.approve(address(lockerFactory), liquidity);
                lockerFactory.createLocker{value: msg.value}(
                    lpToken,
                    string.concat(lpToken.symbol(), " tokens locker"),
                    liquidity,
                    msg.sender,
                    timestamps.unlockTimestamp,
                    true
                );
            } else {
                lpToken.transfer(msg.sender, liquidity);
                // return msg.value along with eth to output if someone sent it wrong
                ethWithdraw += msg.value;
            }
        }
        // Withdraw rest ETH
        (bool success, ) = msg.sender.call{value: ethWithdraw}("");
        require(success, "Transfer ethWithdraw failed.");
        // } else {
        //     (bool success, ) = msg.sender.call{value: (balance - feeOP)}("");
        //     require(success, "Transfer balance failed.");
        // }

        (bool admsuccess, ) = admin.call{value: feeOP}("");
        require(admsuccess, "Transfer feeOP failed.");
        if (amountTokenFee != 0) {
            rewardToken.safeTransfer(admin, amountTokenFee);
        }
        distributed = true;
    }

    function setPoolVerify() public isAdmin returns (bool) {
        isVerify = true;
        return isVerify;
    }

    function getBalance() public view returns (uint) {
        return address(this).balance;
    }

    function withdrawBalance() public onlyOwner {
        (bool success, ) = msg.sender.call{value: address(this).balance}("");
        require(success, "Transfer failed!");
    }

    function withdrawNotSoldTokens() external onlyOwner {
        require(distributed, "Withdraw allowed after distributed.");

        uint256 balance = getNotSoldToken();
        require(balance > 0, "The IDO pool has not unsold tokens.");
        rewardToken.safeTransfer(msg.sender, balance);
        iswithdrawnotsold = true;
    }

    function getNotSoldToken() public view returns (uint256) {
        // uint256 balance = rewardToken.balanceOf(address(this));
        // return balance.add(distributedTokens).sub(tokensForDistribution);
        if (iswithdrawnotsold) {
            return 0;
        }
        uint256 bl = getTokenAmount(finInfo.hardCap, finInfo.tokenPrice);
        uint256 tokenlst;
    
        if (feeOpt == true) {
            uint256 hardcapETH = finInfo.hardCap - (finInfo.hardCap * feeETH2).div(100000);
            bl += getTokenAmount(((hardcapETH * finInfo.lpInterestRate) / 10000), finInfo.listingPrice);
            bl += getTokenAmount(finInfo.hardCap, finInfo.tokenPrice).mul(feeToken).div(10000);
            uint256 totalETH = totalInvestedETH - (totalInvestedETH * feeETH2).div(100000);
            bl -= getTokenAmount(totalInvestedETH, finInfo.tokenPrice).mul(feeToken).div(10000);
            tokenlst = getTokenAmount(((totalETH * finInfo.lpInterestRate) / 10000), finInfo.listingPrice);
        } else {
            uint256 hardcapETH = finInfo.hardCap - (finInfo.hardCap * feeETH1).div(100000);
            bl += getTokenAmount(((hardcapETH * finInfo.lpInterestRate) / 10000), finInfo.listingPrice);
            uint256 totalETH = totalInvestedETH - (totalInvestedETH * feeETH1).div(100000);
            tokenlst = getTokenAmount(((totalETH * finInfo.lpInterestRate) / 10000), finInfo.listingPrice);
        }
        return bl.sub(tokensForDistribution).sub(tokenlst);
    }

    function refundTokens() external onlyOwner {
        require(block.timestamp > timestamps.endTimestamp, "The IDO pool has not ended.");
        require(totalInvestedETH < finInfo.softCap, "The IDO pool has reach soft cap.");

        uint256 balance = rewardToken.balanceOf(address(this));
        require(balance > 0, "The IDO pool has not refund tokens.");
        rewardToken.safeTransfer(msg.sender, balance);
    }

    function setFeeETH1(uint256 _amount) external onlyOwner {
        feeETH1 = _amount;
    }

    function setFeeETH2(uint256 _amount) external onlyOwner {
        feeETH2 = _amount;
    }

    function setFeeToken(uint256 _amount) external onlyOwner {
        feeToken = _amount;
    }

    function setFeeLq(uint24 _amount) external onlyOwner {
        feeLq = _amount;
    }

    function getTokenAmount(uint256 ethAmount, uint256 oneTokenInWei) internal view returns (uint256) {
        return (ethAmount * (10 ** decimals)) / oneTokenInWei;
    }

    /**
     * @notice It allows the owner to recover wrong tokens sent to the contract
     * @param _tokenAddress: the address of the token to withdraw with the exception of rewardToken
     * @param _tokenAmount: the number of token amount to withdraw
     * @dev Only callable by owner.
     */
    function recoverWrongTokens(address _tokenAddress, uint256 _tokenAmount) external onlyOwner {
        require(_tokenAddress != address(rewardToken));
        ERC20(_tokenAddress).safeTransfer(address(msg.sender), _tokenAmount);
    }
}
