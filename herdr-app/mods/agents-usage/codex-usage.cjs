// Read-only account requests; Codex owns authentication and token refresh.
// https://learn.chatgpt.com/docs/app-server#6-rate-limits-chatgpt
const { spawn } = require("node:child_process");
const { createInterface } = require("node:readline");

const server = spawn("codex", ["app-server", "--listen", "stdio://"], {
  stdio: ["pipe", "pipe", "ignore"],
});
let finished = false;
let plan = null;
const timer = setTimeout(() => finish({ error: "Codex usage request timed out. Try refreshing." }), 30000);

function finish(result) {
  if (finished) return;
  finished = true;
  clearTimeout(timer);
  process.stdout.write(JSON.stringify(result) + "\n");
  server.stdin.destroy();
  server.kill();
  // Bound cleanup even if the server is busy shutting down.
  const killTimer = setTimeout(() => server.kill("SIGKILL"), 1000);
  killTimer.unref();
}

function send(message) {
  if (!finished) server.stdin.write(JSON.stringify(message) + "\n");
}

server.on("error", (error) => finish({ error: error.code === "ENOENT"
  ? "Codex CLI not found. Install Codex and sign in with ChatGPT."
  : "Could not start Codex to read subscription usage." }));
server.stdin.on("error", () => finish({ error: "Could not connect to the Codex app server." }));
server.on("exit", () => finish({ error: "Codex could not read usage. Run `codex` and check your login." }));

createInterface({ input: server.stdout }).on("line", (line) => {
  if (finished) return;
  let message;
  try { message = JSON.parse(line); } catch { return; }
  if (![1, 2, 3].includes(message.id)) return;
  if (message.error) {
    finish({ error: "Codex could not read subscription usage. Run `codex` to check your login, then refresh." });
    return;
  }
  if (message.id === 1) {
    send({ method: "initialized" });
    send({ id: 2, method: "account/read", params: { refreshToken: false } });
  } else if (message.id === 2) {
    const account = message.result?.account;
    if (!account || !["chatgpt", "chatgptAuthTokens"].includes(account.type)) {
      finish({ error: "Sign in to Codex with ChatGPT to see subscription usage. Run `codex login`." });
      return;
    }
    plan = account.planType;
    send({ id: 3, method: "account/rateLimits/read" });
  } else {
    const result = message.result;
    const limits = result?.rateLimitsByLimitId?.codex ?? result?.rateLimits;
    if (!limits) {
      finish({ error: "Codex did not return subscription limits. Try refreshing." });
      return;
    }
    // Only return usage and plan details; never return credentials or account identity.
    finish({ plan: limits.planType ?? plan, limits: {
      primary: limits.primary, secondary: limits.secondary, credits: limits.credits,
    } });
  }
});

send({ id: 1, method: "initialize", params: {
  clientInfo: { name: "herdr_usage", title: "Herdr Usage", version: "1.0.0" },
} });
