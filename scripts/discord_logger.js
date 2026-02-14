#!/usr/bin/env node

const WEBHOOK_URL = process.env.DISCORD_WEBHOOK_URL;
if (!WEBHOOK_URL) {
  console.error("Set DISCORD_WEBHOOK_URL env var");
  process.exit(1);
}

const threadName = process.argv[2];
if (!threadName) {
  console.error('Usage: some_command | node discord-forum-stream.js "Thread Name"');
  process.exit(1);
}

const BATCH_SIZE = 10;
const SAFETY_DELAY_MS = 300; // light throttle (~3 req/sec max)
const MAX_MESSAGE_LENGTH = 2000;

function sleep(ms) {
  return new Promise(r => setTimeout(r, ms));
}

async function discordPost(url, body) {
  while (true) {
    const res = await fetch(url, {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify(body)
    });

    if (res.status === 429) {
      const retryAfter =
        Number(res.headers.get("retry-after")) * 1000 ||
        (await res.json()).retry_after * 1000 ||
        2000;

      console.error(`Rate limited. Sleeping ${retryAfter}ms`);
      await sleep(retryAfter);
      continue;
    }

    if (!res.ok) {
      const text = await res.text();
      throw new Error(`Discord error ${res.status}: ${text}`);
    }

    return res.json().catch(() => null);
  }
}

async function createThread() {
  const json = await discordPost(`${WEBHOOK_URL}?wait=true`, {
    content: "```Starting stream...```",
    thread_name: threadName
  });

  return json.channel_id;
}

async function sendMessage(threadId, content) {
  await discordPost(`${WEBHOOK_URL}?thread_id=${threadId}`, {
    content
  });
  await sleep(SAFETY_DELAY_MS);
}

function chunkString(str, maxLen) {
  const chunks = [];
  let i = 0;
  while (i < str.length) {
    chunks.push(str.slice(i, i + maxLen));
    i += maxLen;
  }
  return chunks;
}

(async () => {
  const threadId = await createThread();
  console.error("Thread created:", threadId);

  let buffer = [];
  let queue = Promise.resolve();

  process.stdin.setEncoding("utf8");

  function enqueueSend(lines) {
    queue = queue.then(async () => {
      const raw = lines.join("\n");
      const wrapped = "```\n" + raw + "\n```";

      if (wrapped.length <= MAX_MESSAGE_LENGTH) {
        await sendMessage(threadId, wrapped);
      } else {
        const inner = raw;
        const chunks = chunkString(inner, MAX_MESSAGE_LENGTH - 10);
        for (const chunk of chunks) {
          await sendMessage(threadId, "```\n" + chunk + "\n```");
        }
      }
    }).catch(err => {
      console.error("Send failed:", err.message);
    });
  }

  process.stdin.on("data", (chunk) => {
    const lines = chunk.split(/\r?\n/);

    for (const line of lines) {
      if (!line) continue;

      buffer.push(line);

      if (buffer.length >= BATCH_SIZE) {
        const batch = buffer;
        buffer = [];
        enqueueSend(batch);
      }
    }
  });

  process.stdin.on("end", () => {
    if (buffer.length > 0) {
      enqueueSend(buffer);
    }
    queue.then(() => {
      console.error("Done.");
    });
  });
})();

