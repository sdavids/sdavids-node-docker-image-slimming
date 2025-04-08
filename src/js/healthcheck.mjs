// SPDX-FileCopyrightText: © 2020 Sebastian Davids <sdavids@gmx.de>
// SPDX-License-Identifier: Apache-2.0

import process from 'node:process';

['uncaughtException', 'unhandledRejection'].forEach((s) =>
  process.once(s, (err) => {
    console.error(err);
    process.exit(70); // EX_SOFTWARE
  }),
);
['SIGINT', 'SIGTERM'].forEach((signal) =>
  process.on(signal, () => process.exit(0)),
);

const url =
  process.env['HEALTHCHECK_URL'] ?? 'http://localhost:3000/-/health/liveness';

try {
  new URL(url);
} catch {
  console.error(`'${url}' is not a valid URL`);
  process.exit(64); // EX_USAGE
}

const httpClient = await import('node:http');

let httpsClient;
try {
  httpsClient = await import('node:https');
} catch {
  console.error('https support is disabled');
  process.exit(78); // EX_CONFIG
}

// https://nodejs.org/api/http.html#http_http_request_options_callback
const timeout = 5000;

const maxRedirects = 3;

const call = (location, count) => {
  count ??= 1;
  if (count > maxRedirects) {
    console.error(
      `the maximum number of redirects (${maxRedirects}) has been exceeded`,
    );
    process.exit(69); // EX_UNAVAILABLE
  }
  const client = location.startsWith('https:') ? httpsClient : httpClient;
  client
    .request(
      location,
      {
        timeout,
      },
      (res) => {
        const { statusCode } = res;
        if (statusCode === 301 || statusCode === 307) {
          let redirect = res.headers?.location ?? '';
          if (redirect === '') {
            process.exit(100);
          }
          if (redirect.startsWith('/')) {
            try {
              redirect = new URL(location).origin + redirect;
            } catch {
              process.exit(100);
            }
          }
          call(redirect, count + 1);
        } else {
          process.exit(statusCode === 200 ? 0 : 100);
        }
      },
    )
    .on('error', (e) => {
      if (e.code === 'DEPTH_ZERO_SELF_SIGNED_CERT') {
        console.error(`'${location}' uses a self-signed-certificate`);
        process.exit(76); // EX_PROTOCOL
      } else if (e.code === 'UNABLE_TO_VERIFY_LEAF_SIGNATURE') {
        console.error(
          `'${location}' uses a certificate with an invalid certificate chain`,
        );
        process.exit(76); // EX_PROTOCOL
      }
      console.error(e);
      process.exit(70); // EX_SOFTWARE
    })
    .end();
};

call(url, 0);
