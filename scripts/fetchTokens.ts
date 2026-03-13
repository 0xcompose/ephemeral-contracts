import { createPublicClient, http, type Address } from "viem";
import { mainnet } from "viem/chains";
import { readFileSync, writeFileSync } from "fs";
import { join } from "path";
import { fetchTokenInfosBatch, type TokenData } from "../src/viem/erc20Info";
import * as dotenv from "dotenv";

dotenv.config();

const TOKENS_PATH = join(process.cwd(), "data/tokens-ethereum-array.json");
const START_INDEX = 50;
const BATCH_SIZE = 50;
const AMOUNT_OF_TOKENS_TO_FETCH = 50;
const OUT_PATH = join(process.cwd(), "data/token-infos-ethereum.json");

async function main() {
  const rpcUrl = process.env.ETHEREUM_RPC_URL;
  if (!rpcUrl) throw new Error("ETHEREUM_RPC_URL required");

  const tokens: string[] = JSON.parse(readFileSync(TOKENS_PATH, "utf-8"));
  const addresses = tokens.map((t) => t as Address);

  const client = createPublicClient({
    chain: mainnet,
    transport: http(rpcUrl),
  });

  const results: { address: string; data: TokenData }[] = [];

  for (let i = START_INDEX; i < START_INDEX + AMOUNT_OF_TOKENS_TO_FETCH; i += BATCH_SIZE) {
    const batch = addresses.slice(i, i + BATCH_SIZE);
    const infos = await fetchTokenInfosBatch(batch, client);
    for (let j = 0; j < batch.length; j++) {
      results.push({ address: batch[j], data: infos[j] });
    }
    console.error(`Fetched ${Math.min(i + BATCH_SIZE, addresses.length)} / ${addresses.length}`);
  }

  writeFileSync(
    OUT_PATH,
    JSON.stringify(results, (_, v) => (typeof v === "bigint" ? v.toString() : v), 2),
  );
  console.error(`Wrote ${results.length} token infos to ${OUT_PATH}`);
}

main().catch((e) => {
  console.error(e);
  process.exit(1);
});
