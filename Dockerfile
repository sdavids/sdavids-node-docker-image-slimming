#
# Copyright (c) 2020, Sebastian Davids
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#      http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#

# https://docs.docker.com/engine/reference/builder/

### Installer ###

FROM node:13.12.0-alpine3.11 AS installer

WORKDIR /opt/app/

COPY scripts/node_modules-clean.sh scripts/
COPY package.json package-lock.json ./

RUN npm ci --production --no-optional --audit-level=high --silent \
    && scripts/node_modules-clean.sh \
    && find node_modules/ -type d -depth -exec rmdir -p --ignore-fail-on-non-empty {} \; \
    && find node_modules/ -type d -exec chmod 500 {} + \
    && find node_modules/ -type f -exec chmod 400 {} +


### Final ###

FROM alpine:3.11.5

ARG git_commit
ARG port=3000
ARG uid=1001
ARG user=node

RUN apk --no-cache add \
      tini \
      nodejs \
    && addgroup -g "${uid}" "${user}" \
    && adduser -g "${user}" -u "${uid}" -G "${user}" -s /sbin/false -S -D -H "${user}" \
    && mkdir -p /opt/app/node_modules \
    && chown "${user}:${user}" /opt/app/node_modules \
    && chmod 500 /opt/app/node_modules

COPY --chown="${user}" --from=installer /opt/app/node_modules /opt/app/node_modules
COPY --chown="${user}" --from=installer /opt/app/package.json /opt/app/package-lock.json /opt/app/
COPY --chown="${user}" src/js /opt/app/src/js

WORKDIR /opt/app/

USER "${user}"

ENV NODE_ENV=production
ENV PORT="${port}"

EXPOSE "${port}"

ENTRYPOINT ["/sbin/tini", "--"]

CMD ["node", "--experimental-modules", "/opt/app/src/js/server.js"]

# https://github.com/opencontainers/image-spec/blob/master/annotations.md
LABEL org.opencontainers.image.revision="${git_commit}" \
      org.opencontainers.image.licenses="Apache-2.0" \
      org.opencontainers.image.vendor="Sebastian Davids" \
      org.opencontainers.image.authors="Sebastian Davids <sdavids@gmx.de>" \
      org.opencontainers.image.title="sdavids-node-docker-image-slimming" \
      org.opencontainers.image.description="node docker image slimming" \
      org.opencontainers.image.source="https://github.com/sdavids/sdavids-node-docker-image-slimming.git" \
      org.opencontainers.image.url="https://github.com/sdavids/sdavids-node-docker-image-slimming" \
      org.opencontainers.image.documentation="https://github.com/sdavids/sdavids-node-docker-image-slimming"
