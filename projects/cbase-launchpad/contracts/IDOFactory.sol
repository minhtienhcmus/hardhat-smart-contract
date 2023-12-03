pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
// import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";

import "./IDOPool.sol";

contract IDOFactory is Ownable {
    using SafeMath for uint256;
    // using SafeERC20 for ERC20Burnable;
    using SafeERC20 for ERC20;

    // ERC20Burnable public feeToken;
    address public feeWallet;
    uint256 public feeAmount;
    uint256 public feeETH1 = 500;
    uint256 public feeETH2 = 200;
    uint256 public feeToken = 200;
    uint24 public feeLq = 300;
    // uint256 public burnPercent; // use this state only if your token is ERC20Burnable and has burnFrom method
    // uint256 public divider;
    address public admin;
    event IDOCreated(
        address indexed owner,
        address idoPool,
        address indexed rewardToken,
        string tokenURI,
        address nonfungiblePositionManager,
        address router,
        address factory,
        bool mode
    );
    event TokenFeeUpdated(address newFeeToken);
    event FeeAmountUpdated(uint256 newFeeAmount);
    event BurnPercentUpdated(uint256 newBurnPercent, uint256 divider);
    event FeeWalletUpdated(address newFeeWallet);

    constructor(
        // ERC20Burnable _feeToken,
        uint256 _feeAmount,
        address _admin
        // uint256 _burnPercent
    ){
        // feeToken = _feeToken;
        feeAmount = _feeAmount;
        admin = _admin;
        feeWallet = _admin;
        // burnPercent = _burnPercent;
        // divider = 100;
    }

    // function setFeeToken(address _newFeeToken) external onlyOwner {
    //     require(isContract(_newFeeToken), "New address is not a token");
    //     feeToken = ERC20Burnable(_newFeeToken);

    //     emit TokenFeeUpdated(_newFeeToken);
    // }

    function setFeeAmount(uint256 _newFeeAmount) external onlyOwner {
        feeAmount = _newFeeAmount;

        emit FeeAmountUpdated(_newFeeAmount);
    }
    function setAddAdmin(address _admin) external onlyOwner {
        admin = _admin;
    }
    function setFeeWallet(address _newFeeWallet) external onlyOwner {
        feeWallet = _newFeeWallet;

        emit FeeWalletUpdated(_newFeeWallet);
    }

    // function setBurnPercent(uint256 _newBurnPercent, uint256 _newDivider)
    //     external
    //     onlyOwner
    // {
    //     require(_newBurnPercent <= _newDivider, "Burn percent must be less than divider");
    //     burnPercent = _newBurnPercent;
    //     divider = _newDivider;

    //     emit BurnPercentUpdated(_newBurnPercent, _newDivider);
    // }

    function createIDO(
        ERC20 _rewardToken,
        IDOPool.FinInfo memory _finInfo,
        IDOPool.Timestamps memory _timestamps,
        IDOPool.DEXInfo memory _dexInfo,
        address _lockerFactoryAddress,
        string memory _metadataURL,
        bool mode
    ) external payable {
        IDOPool idoPool =
            new IDOPool(
                _rewardToken,
                _finInfo,
                _timestamps,
                _dexInfo,
                _lockerFactoryAddress,
                _metadataURL,
                mode,
                admin
            );

        // uint8 tokenDecimals = _rewardToken.decimals();

        uint256 transferAmount = getTokenAmount(_finInfo.hardCap, _finInfo.tokenPrice, _rewardToken.decimals());
        if (_dexInfo.fee == true) {
            uint256 hardcapETH = _finInfo.hardCap - (_finInfo.hardCap * feeETH2).div(100000);
            transferAmount += getTokenAmount(hardcapETH * _finInfo.lpInterestRate / 10000, _finInfo.listingPrice, _rewardToken.decimals());
             transferAmount += getTokenAmount(_finInfo.hardCap * feeToken / 10000, _finInfo.tokenPrice, _rewardToken.decimals());
        } else {
            uint256 hardcapETH = _finInfo.hardCap - (_finInfo.hardCap * feeETH1).div(100000);
            transferAmount += getTokenAmount(hardcapETH * _finInfo.lpInterestRate / 10000, _finInfo.listingPrice, _rewardToken.decimals());
        }
        require(_rewardToken.approve(address(idoPool), type(uint256).max), "approve failed");
        idoPool.transferOwnership(msg.sender);
        _rewardToken.safeTransferFrom(
            msg.sender,
            address(idoPool),
            transferAmount
        );

        emit IDOCreated(
            msg.sender,
            address(idoPool),
            address(_rewardToken),
            _metadataURL,
            _dexInfo.nonfungiblePositionManager,
            _dexInfo.router,
            _dexInfo.factory,
            mode
        );
        if(feeAmount > 0){
            require(feeAmount == msg.value,"The fee amount must be set to the same value as the setting.");
            (bool success, ) = feeWallet.call{value: feeAmount}("");
            require(success, "Transfer ethWithdraw failed.");
        }
    }

    function getTokenAmount(uint256 ethAmount, uint256 oneTokenInWei, uint8 decimals)
        internal
        pure
        returns (uint256)
    {
        return (ethAmount  * 10**decimals)/ oneTokenInWei;
    }

    function isContract(address _addr) private view returns (bool) {
        uint32 size;
        assembly {
            size := extcodesize(_addr)
        }
        return (size > 0);
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
}