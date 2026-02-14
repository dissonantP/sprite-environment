#!/usr/bin/env node

const WEBHOOK_URL = process.env.DISCORD_WEBHOOK_URL;

if (!WEBHOOK_URL) {
  console.error("Set DISCORD_WEBHOOK_URL env var");
  process.exit(1);
}

const threadName = process.argv[2];
if (!threadName) {
  console.error("Usage: some_command | node discord-forum-stream.js \"Thread Name\"");
  process.exit(1);
}

const BATCH_SIZE = 10;

async function createThread() {
  const res = await fetch(`${WEBHOOK_URL}?wait=true`, {
    method: "POST",
    headers: { "Content-Type": "application/json" },
    body: JSON.stringify({
      content: "```Starting stream...```",
      thread_name: threadName
    })
  });

  if (!res.ok) {
    const text = await res.text();
    throw new Error(`Thread creation failed: ${text}`);
  }

  const json = await res.json();
  return json.channel_id; // thread id
}

async function sendBatch(threadId, lines) {
  const content = "```\n" + lines.join("\n") + "\n```";

  await fetch(`${WEBHOOK_URL}?thread_id=${threadId}`, {
    method: "POST",
    headers: { "Content-Type": "application/json" },
    body: JSON.stringify({ content })
  });
}

(async () => {
  const threadId = await createThread();
  console.error("Thread created:", threadId);

  let buffer = [];

  process.stdin.setEncoding("utf8");

  process.stdin.on("data", async (chunk) => {
    const lines = chunk.split(/\r?\n/);

    for (const line of lines) {
      if (line.length === 0) continue;

      buffer.push(line);

      if (buffer.length >= BATCH_SIZE) {
        const batch = buffer;
        buffer = [];
        await sendBatch(threadId, batch);
      }
    }
  });

  process.stdin.on("end", async () => {
    if (buffer.length > 0) {
      await sendBatch(threadId, buffer);
    }
    console.error("Done.");
  });
})();
