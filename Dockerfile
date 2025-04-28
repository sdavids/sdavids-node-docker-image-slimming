# syntax=docker/dockerfile:1
# check=error=true

# SPDX-FileCopyrightText: © 2020 Sebastian Davids <sdavids@gmx.de>
# SPDX-License-Identifier: Apache-2.0

# https://docs.docker.com/engine/reference/builder/

### node_modules ###

# https://hub.docker.com/_/node
FROM node:24.12.0-alpine3.23 AS node

WORKDIR /node

COPY --chown=node:node package.json package-lock.json ./

RUN npm ci --omit=dev --omit=optional --omit=peer && \
    npm i --global --omit=optional --omit=peer clean-modules@3.1.1 && \
    clean-modules --yes '**/*.d.ts' '**/@types/**' 'tsconfig.json' && \
    npm cache clean --force

# https://github.com/opencontainers/image-spec/blob/master/annotations.md
LABEL de.sdavids.docker.group="sdavids-node-docker-image-slimming" \
      de.sdavids.docker.type="builder"

### Final ###

# https://hub.docker.com/_/node
FROM node:24.12.0-alpine3.23

WORKDIR /node

COPY --from=node --chown=node:node /node/node_modules node_modules

COPY --chown=node:node src/js ./

ENV NODE_ENV=production
ENV PORT=3000

USER node:node

EXPOSE 3000

CMD ["node", "server.mjs"]

HEALTHCHECK --interval=5s --timeout=5s --start-period=5s \
    CMD node /node/healthcheck.mjs

# https://github.com/opencontainers/image-spec/blob/master/annotations.md
LABEL org.opencontainers.image.licenses="Apache-2.0" \
      org.opencontainers.image.vendor="Sebastian Davids" \
      org.opencontainers.image.authors="Sebastian Davids <sdavids@gmx.de>" \
      org.opencontainers.image.title="sdavids-node-docker-image-slimming" \
      org.opencontainers.image.description="node docker image slimming" \
      org.opencontainers.image.source="https://github.com/sdavids/sdavids-node-docker-image-slimming.git" \
      org.opencontainers.image.url="https://github.com/sdavids/sdavids-node-docker-image-slimming" \
      org.opencontainers.image.documentation="https://github.com/sdavids/sdavids-node-docker-image-slimming" \
      de.sdavids.docker.group="sdavids-node-docker-image-slimming" \
      de.sdavids.docker.type="production"
