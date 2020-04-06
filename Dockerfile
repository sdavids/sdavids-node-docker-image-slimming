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

### Final ###

FROM node:13.12.0

ARG git_commit
ARG port=3000
ARG user=node

ADD https://github.com/krallin/tini/releases/download/v0.18.0/tini /sbin/tini

RUN chmod +x /sbin/tini

COPY --chown="${user}" package.json package-lock.json /opt/app/
COPY --chown="${user}" src/js /opt/app/src/js

WORKDIR /opt/app/

USER "${user}"

RUN npm i --audit-level=high --silent

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
