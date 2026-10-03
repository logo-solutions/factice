const { test, before, after } = require('node:test');
const assert = require('node:assert');
const { spawn } = require('node:child_process');

const PORT = 39001;
const base = `http://127.0.0.1:${PORT}`;
let server;

before(async () => {
  server = spawn(process.execPath, ['src/index.js'], {
    env: { ...process.env, PORT: String(PORT), DB_HOST: '127.0.0.1', DB_PORT: '1' },
    stdio: 'ignore',
  });
  for (let i = 0; i < 50; i++) {
    try {
      await fetch(`${base}/items`);
      return;
    } catch {
      await new Promise((r) => setTimeout(r, 100));
    }
  }
  throw new Error('application non démarrée');
});

after(() => server.kill('SIGTERM'));

test('POST /items sans nom est refusé', async () => {
  const res = await fetch(`${base}/items`, {
    method: 'POST',
    headers: { 'content-type': 'application/json' },
    body: '{}',
  });
  assert.strictEqual(res.status, 400);
});

test('GET /health signale la base indisponible', async () => {
  const res = await fetch(`${base}/health`);
  assert.strictEqual(res.status, 503);
  assert.strictEqual((await res.json()).status, 'error');
});
