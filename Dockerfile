# syntax=docker/dockerfile:1

# SPDX-FileCopyrightText: © 2020 Sebastian Davids <sdavids@gmx.de>
# SPDX-License-Identifier: Apache-2.0

# https://docs.docker.com/engine/reference/builder/

### Installer ###

# https://hub.docker.com/_/node
FROM node:20.13.1-alpine3.19 AS installer

RUN npm i --global --omit optional --omit peer --silent clean-modules@3.0.5

WORKDIR /opt/app/

COPY scripts/preinstall.sh scripts/prepare.sh scripts/
COPY package.json package-lock.json ./

RUN npm ci --omit dev --omit optional --omit peer --audit-level=high --silent && \
    npm cache clean --force && \
    clean-modules --yes '**/*.d.ts' '**/@types/**' 'tsconfig.json'

LABEL de.sdavids.docker.group="sdavids-node-docker-image-slimming" \
      de.sdavids.docker.type="builder"

### Final ###

# https://hub.docker.com/_/node
FROM node:20.13.1-alpine3.19

ARG user=node
ARG app_dir=/${user}

ARG git_commit
ARG created_at
ARG port=3000

ARG cert_path=/run/secrets/cert.pem
ARG key_path=/run/secrets/key.pem

WORKDIR ${app_dir}

COPY --from=installer --chown=${user}:${user} /opt/app/node_modules node_modules
COPY --chown=${user}:${user} src/js ./

ENV NODE_ENV=production
ENV PORT=${port}

ENV CERT_PATH=${cert_path}
ENV KEY_PATH=${key_path}

ENV APP_DIR=${app_dir}

USER ${user}

EXPOSE ${port}

CMD ["node", "server.mjs"]

HEALTHCHECK --interval=5s --timeout=5s --start-period=5s \
    CMD node --no-warnings ${APP_DIR}/healthcheck.mjs

# https://github.com/opencontainers/image-spec/blob/master/annotations.md
LABEL org.opencontainers.image.revision=${git_commit} \
      org.opencontainers.image.created="${created_at}" \
      org.opencontainers.image.licenses="Apache-2.0" \
      org.opencontainers.image.vendor="Sebastian Davids" \
      org.opencontainers.image.authors="Sebastian Davids <sdavids@gmx.de>" \
      org.opencontainers.image.title="sdavids-node-docker-image-slimming" \
      org.opencontainers.image.description="node docker image slimming" \
      org.opencontainers.image.source="https://github.com/sdavids/sdavids-node-docker-image-slimming.git" \
      org.opencontainers.image.url="https://github.com/sdavids/sdavids-node-docker-image-slimming" \
      org.opencontainers.image.documentation="https://github.com/sdavids/sdavids-node-docker-image-slimming" \
      de.sdavids.docker.group="sdavids-node-docker-image-slimming" \
      de.sdavids.docker.type="production"
