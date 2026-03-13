// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {IERC20Metadata} from "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";

struct TokenData {
    string name;
    string symbol;
    uint8 decimals;
    uint256 totalSupply;
    bool isERC20;
}

contract ERC20InfoFetcher {
    function fetch(address token) public view returns (TokenData memory) {
        if (token.code.length == 0) {
            return TokenData({name: "", symbol: "", decimals: 0, totalSupply: 0, isERC20: false});
        }

        string memory name = IERC20Metadata(token).name();
        string memory symbol = IERC20Metadata(token).symbol();
        uint8 decimals = IERC20Metadata(token).decimals();
        uint256 totalSupply = IERC20Metadata(token).totalSupply();
        return TokenData({name: name, symbol: symbol, decimals: decimals, totalSupply: totalSupply, isERC20: true});
    }
}

contract EphemeralERC20InfoBatch is ERC20InfoFetcher {
    constructor(address[] memory tokens) {
        TokenData[] memory data = new TokenData[](tokens.length);

        for (uint256 i = 0; i < tokens.length; i++) {
            TokenData memory result = fetch(tokens[i]);
            data[i] = result;
        }

        bytes memory returnData = abi.encode(data);

        assembly ("memory-safe") {
            revert(add(returnData, 0x20), mload(returnData))
        }
    }
}

contract EphemeralERC20Info is ERC20InfoFetcher {
    constructor(address token) {
        TokenData memory result = fetch(token);
        bytes memory returnData = abi.encode(result);
        assembly ("memory-safe") {
            revert(add(returnData, 0x20), mload(returnData))
        }
    }
}
