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

import http from 'http';

['uncaughtException', 'unhandledRejection'].forEach((signal) =>
  process.on(signal, (err) => {
    console.error(err);
    process.exit(70); // EX_SOFTWARE
  }),
);
['SIGINT', 'SIGTERM'].forEach((signal) =>
  process.on(signal, () => process.exit(0)),
);

const port = parseInt(process.env.PORT || '3000');
if (isNaN(port) || port < 1 || port > 65535) {
  const message = 'PORT needs to be a number in the range 1-65535';
  console.error(message);
  throw new RangeError(message);
}

let protocol = process.env.PROTOCOL || 'http';
if (!(protocol === 'http' || protocol === 'https')) {
  const message = "PROTOCOL needs to be either 'http' or 'https'";
  console.error(message);
  throw new Error(message);
}
protocol += ':';

const timeout = parseInt(process.env.TIMEOUT_MS || '2000');
if (isNaN(timeout) || timeout < 0) {
  const message =
    'TIMEOUT_MS needs to be a number greater or equal to 0 (timeout disabled)';
  console.error(message);
  throw new RangeError(message);
}

// https://nodejs.org/api/http.html#http_http_request_options_callback
const options = {
  path: '/-/health/liveness',
  port,
  protocol,
  timeout,
};

const request = http.request(options, (res) => {
  process.exit(res.statusCode === 200 ? 0 : 100);
});

request
  .on('error', (e) => {
    console.error(e);
    process.exit(70); // EX_SOFTWARE
  })
  .end();
