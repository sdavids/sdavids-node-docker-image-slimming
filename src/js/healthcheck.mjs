/*
 * Copyright (c) 2020-2024, Sebastian Davids
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

import http from 'node:http';
import https from 'node:https';
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

// https://nodejs.org/api/http.html#http_http_request_options_callback
const options = {
  path,
  port,
  protocol,
  timeout,
};

const client = protocol === 'https:' ? https : http;

const request = client.request(options, (res) => {
  process.exit(res.statusCode === 200 ? 0 : 100);
});

request
  .on('error', (e) => {
    console.error(e);
    process.exit(70); // EX_SOFTWARE
  })
  .end();
