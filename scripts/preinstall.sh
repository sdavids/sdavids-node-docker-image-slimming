#!/usr/bin/env sh

# SPDX-FileCopyrightText: © 2023 Sebastian Davids <sdavids@gmx.de>
# SPDX-License-Identifier: Apache-2.0

# script needs to be invoked from the project's root directory

set -eu

if [ "$(uname)" = 'Darwin' ]; then
  if [ -d node_modules ]; then
    # https://apple.stackexchange.com/questions/25779/on-os-x-what-files-are-excluded-by-rule-from-a-time-machine-backup
    xattr -w com.apple.metadata:com_apple_backup_excludeItem com.apple.backupd node_modules
    # https://apple.stackexchange.com/a/258791
    touch node_modules/.metadata_never_index
  fi
fi
