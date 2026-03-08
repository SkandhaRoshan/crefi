import { cre, Runner, type Runtime } from "@chainlink/cre-sdk";

type Config = {
  schedule: string;
};

// =============================
// Fetch ETH Price
// =============================

async function getETHPrice(): Promise<number | null> {
  try {
    const controller = new AbortController();

    const timeout = setTimeout(() => {
      controller.abort();
    }, 2000);

    const response = await fetch(
      "https://api.coingecko.com/api/v3/simple/price?ids=ethereum&vs_currencies=usd",
      { signal: controller.signal }
    );

    clearTimeout(timeout);

    const data = await response.json();

    return data.ethereum.usd;

  } catch (err) {
    return null;
  }
}

// =============================
// Cron Trigger Handler
// =============================

async function onCronTrigger(runtime: Runtime<Config>): Promise<string> {

  runtime.log("🚀 CRE Autopilot started");

  // =============================
  // REAL EXTERNAL API CALL
  // =============================

  const ethPrice = await getETHPrice();

  if (ethPrice) {
    runtime.log(`🌐 Real ETH Price (CoinGecko): $${ethPrice}`);
  } else {
    runtime.log("⚠️ External API blocked in simulator, using fallback value");
  }

  // =============================
  // Simulated vault state
  // =============================

  const vaultAssets = 1_000_000;
  runtime.log(`Vault Assets: ${vaultAssets}`);

  // =============================
  // Simulated APYs
  // =============================

  const aaveApy = 5 + Math.random() * 5;
  const idleApy = 3;

  runtime.log(`Aave APY: ${aaveApy}`);
  runtime.log(`Idle APY: ${idleApy}`);

  // =============================
  // Strategy Decision
  // =============================

  let chosenStrategy = "Idle";

  if (aaveApy > idleApy) {
    chosenStrategy = "Aave";
  }

  runtime.log(`Chosen Strategy: ${chosenStrategy}`);

  // =============================
  // Rebalance Logic
  // =============================

  if (chosenStrategy === "Aave") {

    runtime.log("📈 Rebalance Triggered");
    runtime.log("Moving funds → Aave Strategy");

  } else {

    runtime.log("😴 Staying in Idle Strategy");

  }

  return "workflow executed";
}

// =============================
// Workflow initialization
// =============================

const initWorkflow = (config: Config) => {

  const cron = new cre.capabilities.CronCapability();

  return [
    cre.handler(
      cron.trigger({
        schedule: config.schedule
      }),
      onCronTrigger
    ),
  ];
};

// =============================
// Runner
// =============================

export async function main() {
  const runner = await Runner.newRunner<Config>();
  await runner.run(initWorkflow);
}

main();