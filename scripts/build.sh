#!/usr/bin/env sh

# SPDX-FileCopyrightText: © 2024 Sebastian Davids <sdavids@gmx.de>
# SPDX-License-Identifier: Apache-2.0

set -eu

readonly base_dir="${1:-$PWD}"

readonly node_target="${2:-node24.12.0}"
readonly esbuild_target="${1:-es2024}"

readonly dir="${base_dir}/dist"

rm -rf "${dir}"

if [ ! -d 'node_modules' ]; then
  npm ci --ignore-scripts=false --fund=false
fi

# needs to be bundled as CJS due to
# https://github.com/evanw/esbuild/issues/1921
npx --yes --quiet \
  esbuild "${base_dir}/src/js/server.mjs" \
  --bundle \
  --platform=node \
  --target="${node_target}" \
  --packages=external \
  --minify \
  --legal-comments=none \
  --outdir="${dir}" \
  --out-extension:.js=.cjs

npx --yes --quiet \
  esbuild "${base_dir}/src/js/healthcheck.mjs" \
  --bundle \
  --platform=node \
  --target="${esbuild_target}" \
  --packages=external \
  --format=esm \
  --minify \
  --legal-comments=none \
  --outdir="${dir}" \
  --out-extension:.js=.mjs
