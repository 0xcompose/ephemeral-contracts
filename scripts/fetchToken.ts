import { createPublicClient, http, isAddress } from "viem";
import { mainnet } from "viem/chains";
import { readFileSync, writeFileSync } from "fs";
import { join } from "path";
import { fetchEphemeralERC20Info, fetchTokenInfosBatch, type TokenData } from "../src/viem/erc20Info";
import * as dotenv from "dotenv";

dotenv.config();

const helpMessage = `Usage: yarn ts-node scripts/fetchToken.ts <token address> <RPC URL>`;

async function main() {
  // Parse args
  // [0] - token address
  // [1] - RPC URL
  const tokenAddress = process.argv[2];
  const rpcUrl = process.argv[3];

  if (!tokenAddress || !rpcUrl) {
    console.error(helpMessage);
    process.exit(1);
  }

  if (!isAddress(tokenAddress)) {
    console.error("Invalid token address");
    process.exit(1);
  }

  const client = createPublicClient({
    chain: mainnet,
    transport: http(rpcUrl),
  });

  const info = await fetchEphemeralERC20Info(tokenAddress, client);

  console.log(info);
}

main().catch((e) => {
  console.error(e);
  process.exit(1);
});
