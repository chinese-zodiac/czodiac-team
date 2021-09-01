//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "hardhat/console.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

interface ICZFToken {
    function mint(address to, uint256 amount) external;
}

contract CZFTeamStream is Ownable {
    struct Member {
        address account;
        uint256 lastUpdatedBlock;
        uint256 allocPoint;
        uint256 debt;
    }

    Member[] public members;
    uint256 public totalAllocPoints;
    uint256 public czfPerBlock;

    address public token = 0x7c1608C004F20c3520f70b924E2BfeF092dA0043;

    modifier updateMemberDebts() {
        Member storage member;

        for (uint256 i = 0; i < members.length; i++) {
            member = members[i];
            if (member.allocPoint == 0) continue;

            member.debt +=
                (czfPerBlock *
                    (block.number - member.lastUpdatedBlock) *
                    member.allocPoint) /
                totalAllocPoints;
            member.lastUpdatedBlock = block.number;
        }

        _;
    }

    function add(address account, uint256 allocPoint)
        external
        onlyOwner
        updateMemberDebts
    {
        Member memory member;

        member.account = account;
        member.allocPoint = allocPoint;
        member.lastUpdatedBlock = block.number;

        totalAllocPoints += allocPoint;

        members.push(member);
    }

    function update(uint256 memberId, uint256 allocPoint)
        public
        onlyOwner
        updateMemberDebts
    {
        totalAllocPoints =
            totalAllocPoints -
            members[memberId].allocPoint +
            allocPoint;
        members[memberId].allocPoint = allocPoint;
    }

    function remove(uint256 memberId) external onlyOwner {
        update(memberId, 0);
    }

    function setCZFPerBlock(uint256 amount) external {
        czfPerBlock = amount;
    }

    function claim(uint256 memberId) external {
        Member storage member = members[memberId];
        uint256 amount;

        amount =
            (czfPerBlock *
                (block.number - member.lastUpdatedBlock) *
                member.allocPoint) /
            totalAllocPoints;

        amount += member.debt;
        member.debt = 0;
        member.lastUpdatedBlock = block.number;

        ICZFToken(token).mint(member.account, amount);
    }
}
