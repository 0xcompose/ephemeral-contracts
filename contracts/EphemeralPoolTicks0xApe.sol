// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IPool {
    function tickSpacing() external view returns (int24);

    function tickBitmap(int16 wordPos) external view returns (uint256);

    function ticks(int24 tick) external view returns (uint128 liquidityGross, int128 liquidityNet);
}

struct Tick {
    int24 index;
    uint128 liquidityGross;
    int128 liquidityNet;
}

/// @notice A lens that fetches the `tickBitmap` for a Uniswap v3 pool without deployment
/// @author Aperture Finance
/// @dev The return data can be accessed externally by `eth_call` without a `to` address or internally by catching the
/// revert data, and decoded by `abi.decode(data, (Slot[]))`
contract EphemeralPoolTicks0xApe {
    int24 internal constant MIN_TICK = -887272;
    int24 internal constant MAX_TICK = -MIN_TICK;

    error Ticks(Tick[] ticks);

    constructor(address pool) payable {
        Tick[] memory ticks = getAllTicks(IPool(pool));
        // bytes memory returnData = abi.encode(ticks);
        revert Ticks(ticks);
        // assembly ("memory-safe") {
        //     revert(add(returnData, 0x20), mload(returnData))
        // }
    }

    function getAllTicks(IPool pool) public view returns (Tick[] memory ticks) {
        int24 tickSpacing = pool.tickSpacing();
        int256 minWord = int16((MIN_TICK / tickSpacing) >> 8);
        int256 maxWord = int16((MAX_TICK / tickSpacing) >> 8);

        uint256 numTicks = 0;
        for (int256 word = minWord; word <= maxWord; word++) {
            uint256 bitmap = pool.tickBitmap(int16(word));
            if (bitmap == 0) continue;
            for (uint256 bit; bit < 256; bit++) {
                if (bitmap & (1 << bit) > 0) numTicks++;
            }
        }

        ticks = new Tick[](numTicks);
        uint256 idx = 0;
        for (int256 word = minWord; word <= maxWord; word++) {
            uint256 bitmap = pool.tickBitmap(int16(word));
            if (bitmap == 0) continue;
            for (uint256 bit; bit < 256; bit++) {
                if (bitmap & (1 << bit) == 0) continue;
                ticks[idx].index = int24((word << 8) + int256(bit)) * tickSpacing;
                (ticks[idx].liquidityGross, ticks[idx].liquidityNet) = pool.ticks(ticks[idx].index);
                idx++;
            }
        }
    }
}
