// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/access/Ownable.sol";
import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/token/ERC1155/presets/ERC1155PresetMinterPauser.sol";


contract Marvel1155 is ERC1155PresetMinterPauser {
    
    uint256 public constant Sy = 0;
    uint256 public constant Touf = 1;
    uint256 public constant Xiez = 2;
    uint256 public constant Ku = 4;
   
    
    constructor() ERC1155PresetMinterPauser( "https://gateway.pinata.cloud/ipfs/Qma8mtNcvAeAkKSrYkEEHNaAgW3jZsUbgwzavX2MJasCLF/{id}.json") {
        _mint(msg.sender, Sy, 10000, "");
        _mint(msg.sender, Touf, 10000, "");
        _mint(msg.sender, Xiez, 10000, "");
        _mint(msg.sender, Ku, 10000, "");
    }
    
}