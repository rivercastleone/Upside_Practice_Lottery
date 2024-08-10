// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

contract Lottery {
    uint private closetime;
    uint16 private winner;
    uint private prize;
    bool private isDraw;
    uint16 private p_count;
    uint16 private winnerCount;
    bytes32 private seed;
    uint private nonce;

    mapping(address => uint16) public num;
    mapping(uint16 => address) public player;

    constructor() {
        closetime = block.timestamp + 24 hours;
        seed = keccak256(abi.encodePacked(block.timestamp, block.prevrandao, msg.sender));
    }

    function buy(uint16 number) public payable {
        if(isDraw){
            _reset();
        }
        require(msg.value == 0.1 ether);
        require(block.timestamp < closetime);
        require(player[number] != msg.sender);

        player[number] = msg.sender;
        num[msg.sender] = number;
        p_count++;
        prize += msg.value;
        seed = keccak256(abi.encodePacked(seed, msg.sender, block.timestamp, number));
    }

    function draw() public {
        require(block.timestamp >= closetime);
        require(!isDraw);
        winner = uint16(GenRandom() % p_count);
        isDraw = true;

        for (uint16 i = 0; i < p_count; i++) {
            if (num[player[i]] == winner) {
                winnerCount++;
            }
        }
    }

    function claim() public {
        require(isDraw);
        require(p_count > 0);
        require(winnerCount > 0);
        if(num[msg.sender] == winner){
            uint256 share = prize / winnerCount;
            prize -= share;
            winnerCount--;
            msg.sender.call{value: share}("");
        }
        if(winnerCount == 0){
            _reset();
        }
    }

    function winningNumber() public view returns (uint16) {
        require(isDraw);
        return winner;
    }

    function GenRandom() internal returns (uint256) {
        nonce++;
        return uint256(keccak256(abi.encodePacked(seed, block.timestamp, block.prevrandao, nonce)));
    }

    function _reset() internal {
        closetime = block.timestamp + 24 hours;
        p_count = 0;
        winnerCount = 0;
        isDraw = false;
        seed = keccak256(abi.encodePacked(block.timestamp, block.prevrandao, msg.sender));
        for(uint16 i=0; i<p_count; i++){
            delete player[i];
            delete num[player[i]];
        }
    }
}