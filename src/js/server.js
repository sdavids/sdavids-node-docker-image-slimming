/*
 * Copyright (c) 2020, Sebastian Davids
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *      http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

'use strict';

import express from 'express';
import http from 'http';
import https from 'https';
import fs from 'fs';

['uncaughtException', 'unhandledRejection'].forEach((signal) =>
    process.on(
        signal, (err) => {
          console.error(err);
          process.exit(1);
        }));
['SIGINT', 'SIGTERM'].forEach((signal) =>
    process.on(signal, (_) =>
        process.exit(0)));

const port = process.env.PORT || 3000;
const keyPath = process.env.KEY_PATH;
const certPath = process.env.CERT_PATH;

let secure = keyPath && certPath;
if (secure) {
  secure = fs.existsSync(certPath) && fs.existsSync(keyPath);
}

const app = express();
app.set('port', port);

app.get('/', (_, res) => res.set('Content-Type', 'text/plain').send('42'));

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

server.once('listening',
    () => console.log(`listening on http${secure ? 's' : ''}://localhost:${port}`));

server.on('error', (err) => {
  if (err.syscall === 'listen') {
    switch (err.code) {
      case 'EACCES':
        console.error('Port requires elevated privileges');
        process.exit(1);
      case 'EADDRINUSE':
        console.error('Port is already in use');
        process.exit(1);
    }
  }

  console.error(err);
});
