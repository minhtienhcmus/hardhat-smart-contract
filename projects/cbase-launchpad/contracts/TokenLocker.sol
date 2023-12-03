pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "./IBasePositionManager.sol";

contract TokenLocker is Ownable {
    using SafeMath for uint256;
    using SafeERC20 for ERC20;

    ERC20 public token;
    address public withdrawer;
    uint256 public withdrawTime;
    string public name;
    bool public mode;
    uint256 public tokenId;
    IBasePositionManager public basePositionManager;
    event withdrawTokenEvent(uint256 timestamp, uint256 amount,bool mode,uint256 tokenId);
    // event unlockOwner(uint256 timestamp, uint256 tokenId, address withdrawer);
    modifier verifyOwner(address owner) {
        require(owner == withdrawer, "You are not withdrawer");
        require(mode == false, "Only use for V3");
        _;
    }

    constructor(
        ERC20 _token,
        string memory _name,
        address _withdrawer,
        uint256 _withdrawTime,
        bool _mode,
        address _basePositionManager,
        uint256 _tokenId
    ) {
        require(_withdrawTime > block.timestamp, "withdraw time should be more than now");

        token = _token;
        name = _name;
        withdrawer = _withdrawer;
        withdrawTime = _withdrawTime;
        mode = _mode;
        basePositionManager = IBasePositionManager(_basePositionManager);
        tokenId = _tokenId;
    }

    function withdrawToken(uint256 amount) public {
        require(mode == true, "Only use for V2");
        require(amount >= token.balanceOf(address(this)), "Withdraw amount is exceed balance");
        require(msg.sender == withdrawer, "You are not withdrawer");
        require(block.timestamp > withdrawTime, "Not time yet");
        token.transfer(msg.sender, amount);
        emit withdrawTokenEvent(block.timestamp, amount,mode,tokenId);
    }

    // function setTokenId(address user, uint256 _tokenId) verifyOwner(user) public {
    //     tokenId = _tokenId;
    // }

    // function tranferToOwner() public {
    //     require(mode == false, "Only use for V3");
    //     require(msg.sender == withdrawer, "You are not withdrawer");
    //     require(block.timestamp > withdrawTime, "Not time yet");
    //     require(tokenId >= 0, "tokenId error");
    //     basePositionManager.safeTransferFrom(address(this), msg.sender, tokenId);
    //     emit unlockOwner(block.timestamp, tokenId, withdrawer);
    // }

    function withdrawTokenAll() public {
        require(msg.sender == withdrawer, "You are not withdrawer");
        require(block.timestamp > withdrawTime, "Not time yet");
        uint256 amount = token.balanceOf(address(this));
        if(mode == false){
            basePositionManager.safeTransferFrom(address(this), msg.sender, tokenId);
        } else {
            token.transfer(msg.sender, amount);
        }
        emit withdrawTokenEvent(block.timestamp, amount,mode,tokenId);
    }

    function tokenRemaining() public view returns (uint256) {
        return token.balanceOf(address(this));
    }
}
