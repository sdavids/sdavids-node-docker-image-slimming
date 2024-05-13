# syntax=docker/dockerfile:1

# SPDX-FileCopyrightText: © 2020 Sebastian Davids <sdavids@gmx.de>
# SPDX-License-Identifier: Apache-2.0

# https://docs.docker.com/engine/reference/builder/

### Installer ###

# https://hub.docker.com/_/node
FROM node:20.13.1-alpine3.19 AS installer

RUN apk --no-cache add upx=4.2.1-r0 && \
    upx /usr/local/bin/node

WORKDIR /opt/app/

LABEL de.sdavids.docker.group="sdavids-node-docker-image-slimming" \
      de.sdavids.docker.type="builder"

### Bundler ###

# https://hub.docker.com/_/node
FROM node:20.13.1-alpine3.19 AS bundler

WORKDIR /opt/app/

COPY scripts/preinstall.sh scripts/prepare.sh scripts/build.sh scripts/
COPY package.json package-lock.json ./

RUN npm ci --omit optional --omit peer --audit-level=high --silent && \
    npm cache clean --force

COPY src/js src/js

RUN npm run build --silent && \
    chmod 400 /opt/app/dist/server.cjs /opt/app/dist/healthcheck.mjs

LABEL de.sdavids.docker.group="sdavids-node-docker-image-slimming" \
      de.sdavids.docker.type="builder"

### Harden ###

# https://hub.docker.com/_/alpine
FROM alpine:3.19.1 as hardened

ARG uid=1001
ARG user=node
ARG app_dir=/${user}

# https://github.com/hadolint/hadolint/wiki/DL4006
SHELL ["/bin/ash", "-eo", "pipefail", "-c"]

# use apk repositories over HTTPS only
# hadolint ignore=DL3018
RUN echo "https://dl-cdn.alpinelinux.org/alpine/v$(cut -d . -f 1,2 < /etc/alpine-release)/main" > /etc/apk/repositories && \
    echo "https://dl-cdn.alpinelinux.org/alpine/v$(cut -d . -f 1,2 < /etc/alpine-release)/community" >> /etc/apk/repositories && \
# add root certificates
    apk add --no-cache ca-certificates && \
# add the app user and the working directory
    addgroup -g ${uid} ${user} && \
    adduser -g ${user} -u ${uid} -G ${user} -s /sbin/nologin -S -D -h ${app_dir} ${user} && \
    mkdir ${app_dir}/tmp && \
    chmod -R 700 "${app_dir}" && \
    chown -R ${user}:${user} ${app_dir} && \
# remove unnecessary accounts
    sed -i -r "/^(${user}|root|nobody)/!d" /etc/group && \
    sed -i -r "/^(${user}|root|nobody)/!d" /etc/passwd && \
# remove interactive login shell for everybody
    sed -i -r 's#^(.*):[^:]*$#\1:/sbin/nologin#' /etc/passwd && \
# disable password login for everybody
   while IFS=: read -r username _; do passwd -l "${username}"; done < /etc/passwd || true && \
# remove account-related temp files
   find /bin /etc /lib /sbin /usr -xdev -type f -regex '.*-$' -exec rm -f {} + && \
# remove admin commands
    find /sbin /usr/sbin ! -type d -a ! -name apk -a -delete && \
# remove crontabs
    rm -rf /var/spool/cron /etc/crontabs /etc/periodic && \
# remove SUID & SGID files
    find /bin /etc /lib /sbin /usr -xdev -type f -a \( -perm +4000 -o -perm +2000 \) -delete && \
# remove world-writeable permissions
    find / -xdev -type d -perm +0002 -exec chmod o-w {} + && \
    find / -xdev -type f -perm +0002 -exec chmod o-w {} + && \
# remove init scripts
    rm -rf /etc/init.d /lib/rc /etc/conf.d /etc/inittab /etc/runlevels /etc/rc.conf /etc/logrotate.d && \
# remove kernel tunables
    rm -rf /etc/sysctl* /etc/modprobe.d /etc/modules /etc/mdev.conf /etc/acpi && \
# remove root home dir
    rm -rf /root && \
# remove fstab
    rm -f /etc/fstab && \
# remove symlinks without targets
    find /bin /etc /lib /sbin /usr -xdev -type l -exec test ! -e {} \; -delete && \
# ensure system directories are owned and writable only by root
    find /bin /etc /lib /sbin /usr -xdev -type d \
      -exec chown root:root {} \; \
      -exec chmod 0755 {} \; && \
# remove dangerous commands
    find /bin /etc /lib /sbin /usr -xdev \( \
      -iname chgrp -o \
      -iname chmod -o \
      -iname chown -o \
      -iname hexdump -o \
      -iname ln -o \
      -iname od -o \
      -iname strings -o \
      -iname su -o \
      -iname sudo \
      -iname wget \
    \) -delete && \
# remove apk-related files
    find /bin /etc /lib /sbin /usr -xdev -type f -regex '.*apk.*' -exec rm -rf {} + && \
    rm -rf /etc/apk /lib/apk /usr/share/apk

# use temp dir inside of app user's home
# https://nodejs.org/api/os.html#ostmpdir
ENV TMPDIR=${app_dir}/tmp

### Final ###

FROM hardened

ARG user=node
ARG app_dir=/${user}

ARG git_commit
ARG created_at
ARG port=3000

ARG cert_path=/run/secrets/cert.pem
ARG key_path=/run/secrets/key.pem

WORKDIR ${app_dir}

COPY --from=installer --chown=${user}:${user} /usr/lib/libgcc_s.so.1 /usr/lib/libstdc++.so.6 /usr/lib/
COPY --from=installer --chown=${user}:${user} /usr/local/bin/node /usr/bin/
COPY --from=bundler --chown=${user}:${user} /opt/app/dist/server.cjs /opt/app/dist/healthcheck.mjs ./

ENV NODE_ENV=production
ENV PORT=${port}

ENV CERT_PATH=${cert_path}
ENV KEY_PATH=${key_path}

ENV APP_DIR=${app_dir}

USER ${user}

EXPOSE ${port}

CMD ["node", "server.cjs"]

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
