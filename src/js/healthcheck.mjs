/*
 * SPDX-FileCopyrightText: © 2020 Sebastian Davids <sdavids@gmx.de>
 * SPDX-License-Identifier: Apache-2.0
 */

import process from 'node:process';

['uncaughtException', 'unhandledRejection'].forEach((s) =>
  process.once(s, (err) => {
    console.error(err);
    process.exit(70); // EX_SOFTWARE
  }),
);
['SIGINT', 'SIGTERM'].forEach((s) => process.once(s, () => process.exit(0)));

const port = parseInt(process.env.PORT || '3000');
if (isNaN(port) || port < 1 || port > 65535) {
  throw new RangeError('PORT needs to be a number in the range 1-65535');
}

let protocol = process.env.PROTOCOL || 'http';
if (!(protocol === 'http' || protocol === 'https')) {
  throw new Error("PROTOCOL needs to be either 'http' or 'https'");
}
protocol += ':';

const path = process.env.HEALTHCHECK_PATH || '/-/health/liveness';

const timeout = parseInt(process.env.HEALTHCHECK_TIMEOUT_MS || '2000');
if (isNaN(timeout) || timeout < 0) {
  throw new RangeError(
    'HEALTHCHECK_TIMEOUT_MS needs to be a number greater or equal to 0 (timeout disabled)',
  );
}

// eslint-disable-next-line init-declarations
let client;
if (protocol === 'https:') {
  try {
    client = await import('node:https');
  } catch {
    throw new Error('https support is disabled');
  }
} else {
  client = await import('node:http');
}

// https://nodejs.org/api/http.html#http_http_request_options_callback
const options = {
  path,
  port,
  protocol,
  timeout,
};

const request = client.request(options, (res) => {
  process.exit(res.statusCode === 200 ? 0 : 100);
});

request
  .on('error', (e) => {
    console.error(e);
    process.exit(70); // EX_SOFTWARE
  })
  .end();
