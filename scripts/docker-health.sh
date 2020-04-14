#!/usr/bin/env sh

set -eu

readonly name="sdavids-node-docker-image-slimming"

docker inspect \
  --format="{{.State.Health.Status}} {{.State.Health.FailingStreak}}" \
  "${name}"
