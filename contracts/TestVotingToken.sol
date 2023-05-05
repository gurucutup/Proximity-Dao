// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (governance/utils/Votes.sol)
pragma solidity ^0.8.0;

import {VotesUpgradeable} from "@openzeppelin/contracts-upgradeable/governance/utils/VotesUpgradeable.sol";
import {ContextUpgradeable} from "@openzeppelin/contracts-upgradeable/utils/ContextUpgradeable.sol";

import {ERC20Upgradeable} from "@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol";
import {Context} from "@openzeppelin/contracts/utils/Context.sol";
import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract TestVotingToken is VotesUpgradeable, ERC20{
    constructor(uint256 initialSupply) ERC20("Vote Token", "VTT") {
        _mint(msg.sender, initialSupply);
    }

    function _getVotingUnits(address account) internal view override returns (uint256) {
        return balanceOf(account);
    }

    function _msgData() internal view override(ContextUpgradeable, Context) returns (bytes calldata) {
        return super._msgData();
    }

    function _msgSender() internal view override(ContextUpgradeable,  Context) returns (address) {
        return super._msgSender();
    }
}