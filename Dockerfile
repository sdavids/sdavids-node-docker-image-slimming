# syntax=docker/dockerfile:1

#
# Copyright (c) 2020-2024, Sebastian Davids
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

# https://hub.docker.com/_/node
FROM node:20.11.1-alpine3.19 AS installer

RUN apk --no-cache add upx=4.2.1-r0

RUN upx /usr/local/bin/node

WORKDIR /opt/app/

COPY scripts/node_modules-clean.sh scripts/preinstall.sh scripts/prepare.sh scripts/
COPY package.json package-lock.json ./

RUN npm ci --production --no-optional --audit-level=high --silent \
    && scripts/node_modules-clean.sh \
    && find node_modules/ -type d -depth -exec rmdir -p --ignore-fail-on-non-empty {} \; \
    && find node_modules/ -type d -exec chmod 500 {} + \
    && find node_modules/ -type f -exec chmod 400 {} +

LABEL io.sdavids.image.group="sdavids-node-docker-image-slimming" \
      io.sdavids.image.type="builder"

### Bundler ###

# https://hub.docker.com/_/node
FROM node:20.11.1-alpine3.19 AS bundler

WORKDIR /opt/app/

COPY scripts/preinstall.sh scripts/prepare.sh scripts/
COPY webpack.config.cjs ./
COPY package.json package-lock.json ./

RUN npm ci --no-optional --audit-level=high --silent

COPY src/js src/js

RUN npm run build --silent \
    && cp src/js/healthcheck.mjs /opt/app/dist/ \
    && chmod 400 /opt/app/dist/bundle.cjs /opt/app/dist/healthcheck.mjs

LABEL io.sdavids.image.group="sdavids-node-docker-image-slimming" \
      io.sdavids.image.type="builder"

### Harden ###

# https://hub.docker.com/_/alpine
FROM alpine:3.19.1 as hardened

ARG uid=1001
ARG user=node
ARG app_dir=/${user}

ENV APP_USER=${user}
ENV APP_DIR=${app_dir}

# https://github.com/hadolint/hadolint/wiki/DL4006
SHELL ["/bin/ash", "-eo", "pipefail", "-c"]

RUN addgroup -g ${uid} ${user} \
    && adduser -g ${user} -u ${uid} -G ${user} -s /sbin/false -S -D -H ${user} \
    && mkdir -p ${app_dir} \
    && chown ${user}:${user} -R ${app_dir} \
    && chmod 500 ${app_dir} \
    && find /sbin /usr/sbin \
       ! -type d -a ! -name apk -a ! -name ln \
       -delete \
    && find / -xdev -type d -perm +0002 -exec chmod o-w {} + \
	  && find / -xdev -type f -perm +0002 -exec chmod o-w {} + \
	  && chmod 777 /tmp/ \
    && chown ${user}:root /tmp/ \
    && sed -i -r "/^(${user}|root|nobody)/!d" /etc/group \
    && sed -i -r "/^(${user}|root|nobody)/!d" /etc/passwd \
    && sed -i -r 's#^(.*):[^:]*$#\1:/sbin/nologin#' /etc/passwd \
    && find /bin /etc /lib /sbin /usr -xdev -type f -regex '.*-$' -exec rm -f {} + \
    && find /bin /etc /lib /sbin /usr -xdev -type d \
       -exec chown root:root {} \; \
       -exec chmod 0755 {} \; \
    && find /bin /etc /lib /sbin /usr -xdev -type f -a \( -perm +4000 -o -perm +2000 \) -delete \
    && find /bin /etc /lib /sbin /usr -xdev \( \
         -name hexdump -o \
         -name chgrp -o \
         -name ln -o \
         -name od -o \
         -name strings -o \
         -name su \
         -name sudo \
       \) -delete \
    && rm -fr /var/spool/cron \
              /etc/crontabs \
              /etc/periodic \
              /etc/init.d \
              /lib/rc \
              /etc/conf.d \
              /etc/inittab \
              /etc/runlevels \
              /etc/rc.conf \
              /etc/logrotate.d \
              /etc/sysctl* \
              /etc/modprobe.d \
              /etc/modules \
              /etc/mdev.conf \
              /etc/acpi \
              /root \
              /etc/fstab \
              /usr/bin/wget \
    && find / -type f -iname '*apk*' -xdev -delete \
    && find / -type d -iname '*apk*' -print0 -xdev | xargs -0 rm -r -- \
    && find /bin /etc /lib /sbin /usr -xdev -type l -exec test ! -e {} \; -delete \
    && mkdir -p ${app_dir}/node_modules \
    && chown ${user}:${user} ${app_dir}/node_modules \
    && chmod 500 ${app_dir}/node_modules \
    && rm -rf /bin/chown /bin/chmod

LABEL io.sdavids.image.group="sdavids-node-docker-image-slimming" \
      io.sdavids.image.type="builder"


### Final ###

FROM hardened

ARG user=node
ARG app_dir=/${user}

ARG git_commit
ARG port=3000

ARG cert_path=/run/secrets/cert.pem
ARG key_path=/run/secrets/key.pem

COPY --from=installer /usr/lib/libgcc_s.so.1 /usr/lib/libstdc++.so.6 /usr/lib/
COPY --from=installer /usr/local/bin/node /usr/bin/

COPY --chown=${user} --from=installer /opt/app/node_modules ${app_dir}/node_modules
COPY --chown=${user} --from=bundler /opt/app/dist/bundle.cjs /opt/app/dist/healthcheck.mjs ${app_dir}/

ENV NODE_ENV=production
ENV PORT=${port}

ENV CERT_PATH=${cert_path}
ENV KEY_PATH=${key_path}

WORKDIR ${app_dir}

USER ${user}

EXPOSE ${port}

CMD ["node", "bundle.cjs"]

HEALTHCHECK --interval=5s --timeout=5s --start-period=5s \
    CMD node --no-warnings ${APP_DIR}/healthcheck.mjs

# https://github.com/opencontainers/image-spec/blob/master/annotations.md
LABEL org.opencontainers.image.revision=${git_commit} \
      org.opencontainers.image.licenses="Apache-2.0" \
      org.opencontainers.image.vendor="Sebastian Davids" \
      org.opencontainers.image.authors="Sebastian Davids <sdavids@gmx.de>" \
      org.opencontainers.image.title="sdavids-node-docker-image-slimming" \
      org.opencontainers.image.description="node docker image slimming" \
      org.opencontainers.image.source="https://github.com/sdavids/sdavids-node-docker-image-slimming.git" \
      org.opencontainers.image.url="https://github.com/sdavids/sdavids-node-docker-image-slimming" \
      org.opencontainers.image.documentation="https://github.com/sdavids/sdavids-node-docker-image-slimming" \
      io.sdavids.image.group="sdavids-node-docker-image-slimming" \
      io.sdavids.image.type="production"
