// SPDX-FileCopyrightText: © 2020 Sebastian Davids <sdavids@gmx.de>
// SPDX-License-Identifier: Apache-2.0

import { existsSync, readFileSync } from 'node:fs';
import http from 'node:http';
import https from 'node:https';
import process from 'node:process';
import express from 'express';
import { faker } from '@faker-js/faker';

['uncaughtException', 'unhandledRejection'].forEach((signal) =>
  process.on(signal, (err) => {
    console.error(err);
    process.exit(70); // EX_SOFTWARE
  }),
);
['SIGINT', 'SIGTERM'].forEach((signal) =>
  process.on(signal, () => process.exit(0)),
);

// eslint-disable-next-line dot-notation
const port = Number(process.env['PORT'] ?? 3000);
if (isNaN(port) || port < 1 || port > 65535) {
  console.error(`port must be between 1 and 65535: ${port}`);
  process.exit(64); // EX_USAGE
}
// eslint-disable-next-line dot-notation
const certPath = process.env['CERT_PATH'];
// eslint-disable-next-line dot-notation
const keyPath = process.env['KEY_PATH'];

let secure = keyPath && certPath;
if (secure) {
  secure = existsSync(certPath) && existsSync(keyPath);
}

const app = express();
app.set('port', port);

// https://expressjs.com/en/advanced/best-practice-security.html#at-a-minimum-disable-x-powered-by-header
app.disable('x-powered-by');

app.get('/', (_, res) =>
  res.json({
    userId: faker.string.uuid(),
    username: faker.internet.userName(),
    email: faker.internet.email(),
  }),
);

app.get('/-/health/liveness', (_, res) => res.json({ status: 'ok' }));

const options = {};
// eslint-disable-next-line init-declarations
let engine;
if (secure) {
  try {
    options.cert = readFileSync(certPath);
  } catch {
    console.error(`cert path "${certPath}" invalid`);
    process.exit(64); // EX_USAGE
  }
  try {
    options.key = readFileSync(keyPath);
  } catch {
    console.error(`key path "${keyPath}" invalid`);
    process.exit(64); // EX_USAGE
  }
  engine = https;
} else {
  engine = http;
}

const server = engine.createServer(options, app);

server.keepAliveTimeout = 5000;
server.requestTimeout = 10000;
server.timeout = 15000;

server.listen(port, () =>
  console.log(`Listen local: http${secure ? 's' : ''}://localhost:${port}`),
);

server.on('timeout', (socket) => {
  socket.destroy();
});

server.on('error', (err) => {
  if (err.syscall === 'listen') {
    switch (err.code) {
      case 'EACCES':
        console.error('Port requires elevated privileges');
        process.exit(77); // EX_NOPERM
        break;
      case 'EADDRINUSE':
        console.error('Port is already in use');
        process.exit(75); // EX_TEMPFAIL
        break;
      default:
      // just log
    }
  }

  console.error(err);
});
