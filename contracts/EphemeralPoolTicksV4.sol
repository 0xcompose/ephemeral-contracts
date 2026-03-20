// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {TickBitmap} from "@uniswap/v4-core/src/libraries/TickBitmap.sol";
import {PoolId} from "@uniswap/v4-core/src/types/PoolId.sol";

struct Tick {
    int24 index;
    uint128 liquidityGross;
    int128 liquidityNet;
}

/// @notice Minimal interface for PositionManager.poolKeys
interface IPositionManagerPoolKeys {
    function poolKeys(bytes25 poolId)
        external
        view
        returns (address currency0, address currency1, uint24 fee, int24 tickSpacing, address hooks);
}

/// @notice Minimal interface for StateView tick queries
interface IStateViewTicks {
    function getTickBitmap(PoolId poolId, int16 tick) external view returns (uint256 tickBitmap);
    function getTickLiquidity(PoolId poolId, int24 tick)
        external
        view
        returns (uint128 liquidityGross, int128 liquidityNet);
}

/// @notice A lens that fetches all populated ticks for a Uniswap V4 pool without deployment
/// @author Aperture Finance
/// @dev Uses PositionManager + poolId to resolve poolKey, StateView for tick data. Return data via revert Ticks(ticks).
contract EphemeralPoolTicksV4 {
    int24 internal constant MIN_TICK = -887272;
    int24 internal constant MAX_TICK = -MIN_TICK;

    /// @param positionManager PositionManager address (e.g. 0xbD216513d74C8cf14cf4747E6AaA6420FF64ee9e on Ethereum)
    /// @param stateView StateView helper address (e.g. 0x7fFE42C4a5DEeA5b0feC41C94C136Cf115597227 on Ethereum)
    /// @param poolId Pool ID (bytes32). Use bytes25(poolId) to get poolKey from PositionManager.poolKeys
    constructor(address positionManager, address stateView, bytes32 poolId) payable {
        Tick[] memory ticks = getAllTicks(positionManager, stateView, poolId);
        bytes memory returnData = abi.encode(ticks);
        assembly ("memory-safe") {
            revert(add(returnData, 0x20), mload(returnData))
        }
    }

    /// @notice Get all populated ticks for a V4 pool
    /// @param positionManager PositionManager address
    /// @param stateView StateView helper address
    /// @param poolId The pool ID (bytes32)
    function getAllTicks(address positionManager, address stateView, bytes32 poolId)
        public
        view
        returns (Tick[] memory ticks)
    {
        // bytes25 = poolId with last 7 bytes stripped
        bytes25 poolIdPrefix = bytes25(poolId);
        int24 tickSpacing = _getTickSpacing(positionManager, poolIdPrefix);

        (int16 wordPosLower, int16 wordPosUpper) = _getWordPositions(tickSpacing);

        uint256 numTicks = 0;
        for (int256 word = wordPosLower; word <= wordPosUpper; word++) {
            uint256 bitmap = IStateViewTicks(stateView).getTickBitmap(PoolId.wrap(poolId), int16(word));
            if (bitmap == 0) continue;
            for (uint256 bit; bit < 256; bit++) {
                if (bitmap & (1 << bit) > 0) numTicks++;
            }
        }

        ticks = new Tick[](numTicks);
        uint256 idx = 0;
        for (int256 word = wordPosLower; word <= wordPosUpper; word++) {
            uint256 bitmap = IStateViewTicks(stateView).getTickBitmap(PoolId.wrap(poolId), int16(word));
            if (bitmap == 0) continue;
            for (uint256 bit; bit < 256; bit++) {
                if (bitmap & (1 << bit) == 0) continue;
                int24 tick = int24(int256((word << 8) + int256(bit))) * tickSpacing;
                (ticks[idx].liquidityGross, ticks[idx].liquidityNet) =
                    IStateViewTicks(stateView).getTickLiquidity(PoolId.wrap(poolId), tick);
                ticks[idx].index = tick;
                idx++;
            }
        }
    }

    function _getTickSpacing(address positionManager, bytes25 poolIdPrefix)
        internal
        view
        returns (int24 tickSpacing)
    {
        (, , , tickSpacing,) = IPositionManagerPoolKeys(positionManager).poolKeys(poolIdPrefix);
    }

    function _getWordPositions(int24 tickSpacing) internal pure returns (int16 wordPosLower, int16 wordPosUpper) {
        int24 compressed = TickBitmap.compress(MIN_TICK, tickSpacing);
        wordPosLower = int16(compressed >> 8);
        compressed = TickBitmap.compress(MAX_TICK, tickSpacing);
        wordPosUpper = int16(compressed >> 8);
    }
}
