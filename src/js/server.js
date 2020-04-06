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

const exit = (signal, code) => process.on(signal, (_) => process.exit(code));

['uncaughtException', 'unhandledRejection'].forEach((signal) => exit(signal, 1));
['SIGINT', 'SIGTERM'].forEach((signal) => exit(signal, 0));

const app = express();
const port = process.env.PORT || 3000;

app.get('/', (_, res) => res.set('Content-Type', 'text/plain').send('42'));

app.listen(port, () => console.log(`listening on http://localhost:${port}`));
