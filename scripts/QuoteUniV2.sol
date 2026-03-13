// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {Script} from "forge-std/Script.sol";
import {UniswapV2Quoter} from "../contracts/UniswapV2Quoter.sol";
import {console} from "forge-std/console.sol";

contract QuoteUniV2 is Script {
    function run() public returns (bytes memory) {
        vm.createSelectFork("https://rpc.fuse.io", 40905469);

        console.logBytes(type(UniswapV2Quoter).creationCode);

        uint256 amountIn = 0.1 ether;

        address _factory = 0x1998E4b0F1F922367d8Ec20600ea2b86df55f34E;

        address[] memory path = new address[](2);

        path[0] = 0xa722c13135930332Eb3d749B2F0906559D2C5b99;
        path[1] = 0x33284f95ccb7B948d9D352e1439561CF83d8d00d;

        // 0 = raw pair quote; set to e.g. 300 (3%) if frontend shows amount after protocol/router fee
        uint256 protocolFeeBps = 0;
        new UniswapV2Quoter(_factory, amountIn, path, protocolFeeBps);

        // return abi.encodeWithSelector(UniswapV2Quoter.Amounts.selector, abi.encode(amounts));
    }
}
