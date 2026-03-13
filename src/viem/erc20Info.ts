import { Address, PublicClient, CallExecutionError, decodeAbiParameters, encodeDeployData, Hex } from "viem";
import { readFileSync } from "fs";
import { join } from "path";

const TOKEN_DATA_ABI = [
  {
    type: "tuple[]",
    components: [
      { name: "name", type: "string" },
      { name: "symbol", type: "string" },
      { name: "decimals", type: "uint8" },
      { name: "totalSupply", type: "uint256" },
      { name: "isERC20", type: "bool" },
    ],
  },
] as const;

const TOKEN_DATA_SINGLE_ABI = [
  {
    type: "tuple",
    components: [
      { name: "name", type: "string" },
      { name: "symbol", type: "string" },
      { name: "decimals", type: "uint8" },
      { name: "totalSupply", type: "uint256" },
      { name: "isERC20", type: "bool" },
    ],
  },
] as const;

export type TokenData = {
  name: string;
  symbol: string;
  decimals: number;
  totalSupply: bigint;
  isERC20: boolean;
};

function loadEphemeralERC20InfoBatchArtifact(): { abi: unknown[]; bytecode: Hex } {
  const artifactPath = join(process.cwd(), "out/EphemeralERC20Info.sol/EphemeralERC20InfoBatch.json");
  const artifact = JSON.parse(readFileSync(artifactPath, "utf-8"));
  return {
    abi: artifact.abi,
    bytecode: artifact.bytecode.object as Hex,
  };
}

function loadEphemeralERC20InfoArtifact(): { abi: unknown[]; bytecode: Hex } {
  const artifactPath = join(process.cwd(), "out/EphemeralERC20Info.sol/EphemeralERC20Info.json");
  const artifact = JSON.parse(readFileSync(artifactPath, "utf-8"));
  return {
    abi: artifact.abi,
    bytecode: artifact.bytecode.object as Hex,
  };
}

/**
 * Fetches ERC20 token info for a batch of token addresses via ephemeral contract (eth_call).
 * Constructor reverts with abi.encode(TokenData[]); we decode that revert payload.
 */
export async function fetchTokenInfosBatch(
  tokens: Address[],
  publicClient: PublicClient,
  blockNumber?: bigint,
): Promise<TokenData[]> {
  console.time("load atrifact");

  if (tokens.length === 0) return [];
  const { abi, bytecode } = loadEphemeralERC20InfoBatchArtifact();
  console.timeEnd("load atrifact");

  console.time("encode deploy data");
  const data = encodeDeployData({
    abi,
    bytecode,
    args: [tokens],
  });
  console.timeEnd("encode deploy data");

  console.time("call");
  try {
    await publicClient.call({ data, blockNumber });
    console.timeEnd("call");
  } catch (error) {
    console.timeEnd("call");

    console.time("decode");
    const baseError = (error as CallExecutionError).walk();
    // console.log("Base error:", baseError);

    if ("data" in baseError && baseError.data) {
      const [decoded] = decodeAbiParameters(TOKEN_DATA_ABI, baseError.data as Hex);
      // console.log("Decoded:", decoded);
      console.timeEnd("decode");
      return decoded as TokenData[];
    }
    console.timeEnd("decode");
    throw error;
  }
  throw new Error("EphemeralERC20Info constructor should revert with data");
}

export async function fetchEphemeralERC20Info(
  tokenAddress: Address,
  publicClient: PublicClient,
  blockNumber?: bigint,
): Promise<TokenData> {
  console.time("load atrifact");

  const { abi, bytecode } = loadEphemeralERC20InfoArtifact();
  console.timeEnd("load atrifact");

  console.time("encode deploy data");
  const data = encodeDeployData({
    abi,
    bytecode,
    args: [tokenAddress],
  });
  console.timeEnd("encode deploy data");

  console.time("call");
  try {
    await publicClient.call({ data, blockNumber });
    console.timeEnd("call");
  } catch (error) {
    console.timeEnd("call");

    console.time("decode");
    const baseError = (error as CallExecutionError).walk();
    // console.log("Base error:", baseError);

    if ("data" in baseError && baseError.data) {
      const [decoded] = decodeAbiParameters(TOKEN_DATA_SINGLE_ABI, baseError.data as Hex);

      console.timeEnd("decode");
      return decoded as TokenData;
    }
    console.timeEnd("decode");
    throw error;
  }
  throw new Error("EphemeralERC20Info constructor should revert with data");
}
