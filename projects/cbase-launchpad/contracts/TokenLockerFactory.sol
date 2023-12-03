pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "./TokenLocker.sol";
import "./IBasePositionManager.sol";

contract TokenLockerFactory is Ownable {
    using SafeMath for uint256;
    using SafeERC20 for ERC20;

    uint256 public lockerCount = 0;
    uint256 public fee = 0;

    struct lockerInfo {
        uint256 lockerId;
        address tokenAddress;
        address creator;
        uint256 ramaining;
        address withdrawer;
        uint256 withdrawTime;
    }
    IBasePositionManager public basePositionManager;
    event LockerCreated(uint256 lockerId, address indexed lockerAddress, address tokenAddress);

    constructor(address _basePositionManager) {
        basePositionManager = IBasePositionManager(_basePositionManager);
    }

    // function isContract(address _addr) private returns (bool isContract) {
    //     uint32 size;
    //     assembly {
    //         size := extcodesize(_addr)
    //     }
    //     return (size > 0);
    // }

    function createLocker(
        ERC20 _tokenAddress,
        string memory _name,
        uint256 _lockAmount,
        address _withdrawer,
        uint256 _withdrawTime,
        bool mode
    ) public payable returns (address) {
        require(msg.value == fee, "Fee amount is required");

        // bool iscontract = isContract(msg.sender);

        TokenLocker tokenLocker = new TokenLocker(
            _tokenAddress,
            _name,
            _withdrawer,
            _withdrawTime,
            mode,
            address(basePositionManager),
            _lockAmount
        );

        tokenLocker.transferOwnership(msg.sender);
        if (mode == true) {
            _tokenAddress.safeTransferFrom(msg.sender, address(tokenLocker), _lockAmount);
        } else {
            basePositionManager.approve(address(tokenLocker), _lockAmount);
            basePositionManager.transferFrom(address(this), address(tokenLocker), _lockAmount);
        }

        emit LockerCreated(lockerCount, address(tokenLocker), address(_tokenAddress));
        lockerCount++;
        return address(tokenLocker);
    }

    function withdrawFee() public onlyOwner {
        (bool success, ) = msg.sender.call{value: address(this).balance}("");
        require(success, "Transfer failed.");
    }

    function setFee(uint256 amount) public onlyOwner {
        fee = amount;
    }
}
