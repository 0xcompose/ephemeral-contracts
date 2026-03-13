// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {Script} from "forge-std/Script.sol";
import {EphemeralPoolTicks0xApe, Tick} from "../contracts/EphemeralPoolTicks0xApe.sol";
import {console} from "forge-std/console.sol";
import {DEX} from "../contracts/Dex.sol";

contract GetBytecode is Script {
    function run() public returns (bytes memory) {
        vm.createSelectFork("https://rpc.fuse.io", 40902451);

        address pool = 0xD32e2544d1BE13a61A8Ce650A10818df207492E0;

        Tick memory tick = Tick(1, 1, 1);

        console.logBytes(abi.encodeWithSelector(EphemeralPoolTicks0xApe.Ticks.selector, abi.encode(tick)));

        bytes memory creationCode = type(EphemeralPoolTicks0xApe).creationCode;

        bytes memory completeBytecode = abi.encodePacked(creationCode, abi.encode(pool));

        console.logBytes(creationCode);
        // console.logBytes(completeBytecode);

        // new EphemeralPoolTicks0xApe(pool);

        return completeBytecode;
    }
}

