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

RUN apk --no-cache add \
      upx \
    && upx /usr/local/bin/node

WORKDIR /opt/app/

COPY scripts/node_modules-clean.sh scripts/
COPY package.json package-lock.json ./

RUN npm ci --production --no-optional --audit-level=high --silent \
    && scripts/node_modules-clean.sh \
    && find node_modules/ -type d -depth -exec rmdir -p --ignore-fail-on-non-empty {} \; \
    && find node_modules/ -type d -exec chmod 500 {} + \
    && find node_modules/ -type f -exec chmod 400 {} +


### Bundler ###

FROM node:13.12.0-alpine3.11 AS bundler

WORKDIR /opt/app/

COPY webpack.config.cjs ./
COPY package.json package-lock.json ./

RUN npm ci --no-optional --audit-level=high --silent

COPY src/js src/js

RUN npm run build -s \
    && chmod 400 /opt/app/dist/bundle.cjs


### Harden ###

FROM alpine:3.11.5 as hardened

ARG uid=1001
ARG user=node
ARG home="${user}"

ENV APP_USER="${user}"
ENV APP_DIR="${home}"

SHELL ["/bin/sh", "-o", "pipefail", "-c"]

RUN echo "https://alpine.global.ssl.fastly.net/alpine/v$(cut -d . -f 1,2 < /etc/alpine-release)/main" > /etc/apk/repositories \
    && echo "https://alpine.global.ssl.fastly.net/alpine/v$(cut -d . -f 1,2 < /etc/alpine-release)/community" >> /etc/apk/repositories \
    && apk add --no-cache \
       tini \
    && addgroup -g "${uid}" "${user}" \
    && adduser -g "${user}" -u "${uid}" -G "${user}" -s /sbin/false -S -D -H "${user}" \
    && mkdir "${home}" \
    && chown "${user}:${user}" -R "${home}" \
    && chmod 500 "${home}" \
    && find /sbin /usr/sbin \
       ! -type d -a ! -name apk -a ! -name ln ! -name tini \
       -delete \
    && find / -xdev -type d -perm +0002 -exec chmod o-w {} + \
	  && find / -xdev -type f -perm +0002 -exec chmod o-w {} + \
	  && chmod 777 /tmp/ \
    && chown "${user}:root" /tmp/ \
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
    && mkdir -p "/${home}/node_modules" \
    && chown "${user}:${user}" "/${home}/node_modules" \
    && chmod 500 "/${home}/node_modules" \
    && rm -rf /bin/chown /bin/chmod


### Final ###

FROM hardened

ARG git_commit
ARG port=3000

ARG cert_path=/run/secrets/cert.pem
ARG key_path=/run/secrets/key.pem

COPY --from=installer /usr/lib/libgcc_s.so.1 /usr/lib/libstdc++.so.6 /usr/lib/
COPY --from=installer /usr/local/bin/node /usr/bin/

COPY --chown="${APP_USER}" --from=installer /opt/app/node_modules "/${APP_DIR}/node_modules"
COPY --chown="${APP_USER}" --from=bundler /opt/app/dist/bundle.cjs "/${APP_DIR}/"

ENV NODE_ENV=production
ENV PORT="${port}"

ENV CERT_PATH=${cert_path}
ENV KEY_PATH=${key_path}

WORKDIR ${APP_DIR}

USER "${APP_USER}"

EXPOSE "${port}"

ENTRYPOINT ["/sbin/tini", "--"]

CMD ["node", "bundle.cjs"]

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
