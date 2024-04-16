/*
 * SPDX-FileCopyrightText: © 2020 Sebastian Davids <sdavids@gmx.de>
 * SPDX-License-Identifier: Apache-2.0
 */

import express from 'express';
import { faker } from '@faker-js/faker';
import fs from 'node:fs';
import http from 'node:http';
import https from 'node:https';

['uncaughtException', 'unhandledRejection'].forEach((signal) =>
  process.on(signal, (err) => {
    console.error(err);
    process.exit(70); // EX_SOFTWARE
  }),
);
['SIGINT', 'SIGTERM'].forEach((signal) =>
  process.on(signal, () => process.exit(0)),
);

const port = process.env.PORT || 3000;
const keyPath = process.env.KEY_PATH;
const certPath = process.env.CERT_PATH;

let secure = keyPath && certPath;
if (secure) {
  secure = fs.existsSync(certPath) && fs.existsSync(keyPath);
}

const app = express();
app.set('port', port);

// https://expressjs.com/en/advanced/best-practice-security.html#at-a-minimum-disable-x-powered-by-header
app.disable('x-powered-by');

app.get('/', (_, res) =>
  res.set('Content-Type', 'application/json').send({
    userId: faker.string.uuid(),
    username: faker.internet.userName(),
    email: faker.internet.email(),
  }),
);

app.get('/-/health/liveness', (_, res) => res.json({ status: 'ok' }));

// eslint-disable-next-line init-declarations
let server;
if (secure) {
  const serverOpts = {
    cert: fs.readFileSync(certPath),
    key: fs.readFileSync(keyPath),
  };
  server = https.createServer(serverOpts, app);
} else {
  server = http.createServer(app);
}

server.listen(port);

server.once('listening', () =>
  // https://googlechrome.github.io/lighthouse-ci/docs/configuration.html#startserverreadypattern
  console.log(`Listen local: http${secure ? 's' : ''}://localhost:${port}`),
);

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
