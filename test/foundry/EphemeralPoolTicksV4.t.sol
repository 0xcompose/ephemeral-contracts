// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "contracts/EphemeralPoolTicksV4.sol";
import "./BaseV4.t.sol";
import {PoolId, PoolIdLibrary} from "@uniswap/v4-core/src/types/PoolId.sol";
import {IPoolManager} from "@uniswap/v4-core/src/interfaces/IPoolManager.sol";
import {StateLibrary} from "@uniswap/v4-core/src/libraries/StateLibrary.sol";

contract EphemeralPoolTicksV4Test is BaseV4Test {
    using PoolIdLibrary for PoolKey;
    using StateLibrary for IPoolManager;

    address internal constant STATE_VIEW = 0x7fFE42C4a5DEeA5b0feC41C94C136Cf115597227;

    function test_GetAllTicks() public {
        bytes32 poolId = PoolId.unwrap(poolKey.toId());
        try new EphemeralPoolTicksV4(posManagerAddr, STATE_VIEW, poolId) {}
        catch (bytes memory returnData) {
            Tick[] memory ticks = abi.decode(returnData, (Tick[]));
            assertGt(ticks.length, 0, "should have populated ticks");

            // Verify tick data matches PoolManager
            for (uint256 i; i < ticks.length; ++i) {
                (uint128 liquidityGross, int128 liquidityNet,,) =
                    IPoolManager(poolManagerAddr).getTickInfo(poolKey.toId(), ticks[i].index);
                assertEq(ticks[i].liquidityGross, liquidityGross, "liquidityGross");
                assertEq(ticks[i].liquidityNet, liquidityNet, "liquidityNet");
            }
        }
    }
}
