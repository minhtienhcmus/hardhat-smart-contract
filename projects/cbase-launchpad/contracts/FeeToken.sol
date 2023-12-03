//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.19;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";

contract FeeToken is ERC20, ERC20Burnable {
    uint constant _initial_supply = 1000000000 * (10**18);
    constructor() ERC20("CBaseToken", "CBASE") {
        _mint(_msgSender(), _initial_supply);
    }
}