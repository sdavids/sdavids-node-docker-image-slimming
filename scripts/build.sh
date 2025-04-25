#!/usr/bin/env sh

# SPDX-FileCopyrightText: © 2024 Sebastian Davids <sdavids@gmx.de>
# SPDX-License-Identifier: Apache-2.0

set -eu

readonly base_dir="${1:-$PWD}"

readonly node_target="${2:-node20.12}"
readonly esbuild_target="${1:-es2022}"

readonly dir="${base_dir}/dist"

rm -rf "${dir}"

if [ ! -d 'node_modules' ]; then
  npm ci --ignore-scripts=false --fund=false
fi

npx --yes --quiet \
  esbuild "${base_dir}/src/js/server.mjs" \
  --bundle \
  --platform=node \
  --target="${node_target}" \
  --minify \
  --legal-comments=none \
  --outdir="${dir}" \
  --out-extension:.js=.cjs

npx --yes --quiet \
  esbuild "${base_dir}/src/js/healthcheck.mjs" \
  --bundle \
  --platform=node \
  --target="${esbuild_target}" \
  --format=esm \
  --minify \
  --legal-comments=none \
  --outdir="${dir}" \
  --out-extension:.js=.mjs
