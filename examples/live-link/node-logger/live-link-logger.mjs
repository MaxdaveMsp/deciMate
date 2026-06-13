import { appendFile, writeFile } from "node:fs/promises";

const DEFAULT_ENDPOINT = "http://iphone.local:8080/status";
const endpoint = process.argv.find((arg) => arg.startsWith("http")) || DEFAULT_ENDPOINT;
const mock = process.argv.includes("--mock");
const output = "decimate-live-link-log.csv";

let mockPhase = 0;
let wroteHeader = false;

function csv(value) {
  return `"${String(value ?? "").replaceAll('"', '""')}"`;
}

function formatNumber(value) {
  return Number.isFinite(value) ? value.toFixed(1) : "";
}

function mockSnapshot() {
  mockPhase += 0.22;
  const spl = 82 + Math.sin(mockPhase) * 13 + Math.sin(mockPhase * 0.43) * 7;
  const thresholdState = spl > 108 ? "peak" : spl > 100 ? "critical" : spl > 90 ? "warning" : "safe";
  const companionMessages = {
    safe: "All good!",
    warning: "Getting loud...",
    critical: "Too loud!",
    peak: "PEAK! Oww!!"
  };

  return {
    app: "DeciMate SPL",
    timestamp: new Date().toISOString(),
    spl_current: spl,
    spl_average: spl - 2.4,
    spl_peak: Math.max(96, spl + 4.8),
    spl_leq: spl - 1.3,
    leq_1_minute: spl - 0.8,
    leq_10_minutes: spl - 2.1,
    measurement_mode: "SPL A Fast",
    threshold_state: thresholdState,
    companion_state: companionMessages[thresholdState]
  };
}

async function getSnapshot() {
  if (mock) return mockSnapshot();

  const response = await fetch(endpoint, { cache: "no-store" });
  if (!response.ok) throw new Error(`HTTP ${response.status}`);
  return response.json();
}

async function writeSnapshot(snapshot) {
  if (!wroteHeader) {
    await writeFile(output, "timestamp,measurement_mode,spl_current,spl_average,spl_peak,spl_leq,leq_1_minute,leq_10_minutes,threshold_state,companion_state\n");
    wroteHeader = true;
  }

  const row = [
    snapshot.timestamp,
    snapshot.measurement_mode,
    formatNumber(snapshot.spl_current),
    formatNumber(snapshot.spl_average),
    formatNumber(snapshot.spl_peak),
    formatNumber(snapshot.spl_leq),
    formatNumber(snapshot.leq_1_minute),
    formatNumber(snapshot.leq_10_minutes),
    snapshot.threshold_state,
    snapshot.companion_state
  ].map(csv).join(",");

  await appendFile(output, `${row}\n`);
}

async function tick() {
  try {
    const snapshot = await getSnapshot();
    await writeSnapshot(snapshot);
    const state = String(snapshot.threshold_state || "unknown").toUpperCase();
    console.log(
      `${snapshot.timestamp} | ${formatNumber(snapshot.spl_current)} dB SPL | ` +
      `Leq1m ${formatNumber(snapshot.leq_1_minute)} | ` +
      `Leq10m ${formatNumber(snapshot.leq_10_minutes)} | peak ${formatNumber(snapshot.spl_peak)} | ${state}`
    );
  } catch (error) {
    console.error(`${new Date().toISOString()} | Live Link unavailable: ${error.message}`);
  }
}

console.log(mock ? "Using mock Live Link data." : `Polling ${endpoint}`);
console.log(`Writing ${output}`);
await tick();
setInterval(tick, 1000);
