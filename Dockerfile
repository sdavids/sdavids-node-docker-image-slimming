# syntax=docker/dockerfile:1
# check=error=true

# SPDX-FileCopyrightText: © 2020 Sebastian Davids <sdavids@gmx.de>
# SPDX-License-Identifier: Apache-2.0

# https://docs.docker.com/engine/reference/builder/

### Node ###

# https://hub.docker.com/_/node
FROM node:24.12.0-alpine3.23 AS node

RUN apk --no-cache add upx=5.0.2-r0 && \
    upx /usr/local/bin/node

LABEL de.sdavids.docker.group="sdavids-node-docker-image-slimming" \
      de.sdavids.docker.type="builder"

### node_modules ###

# https://hub.docker.com/_/node
FROM node:24.12.0-alpine3.23 AS nodemodules

WORKDIR /node

COPY --chown=node:node package.json package-lock.json ./

RUN npm ci --ignore-scripts=true --omit=dev --omit=optional --omit=peer && \
    npm i --global --ignore-scripts=true --omit=optional --omit=peer clean-modules@3.1.1 && \
    clean-modules --yes '**/*.d.ts' '**/@types/**' 'tsconfig.json' && \
    npm cache clean --force && \
# harden permissions
    chmod 500 node_modules && \
    find node_modules -type d -exec chmod 500 {} + && \
    find node_modules -type f -exec chmod 400 {} +

# https://github.com/opencontainers/image-spec/blob/master/annotations.md
LABEL de.sdavids.docker.group="sdavids-node-docker-image-slimming" \
      de.sdavids.docker.type="builder"

### Builder ###

# https://hub.docker.com/_/alpine
FROM alpine:3.23.2 AS builder

WORKDIR /node

COPY src/js .

# keep only JavaScript/JSON files and harden permissions
RUN find . -type f ! \( -name '*.cjs' -o -name '*.js' -o -name '*.json' -o -name '*.mjs' \) -delete && \
    find . -type d -empty -delete && \
    find . -type d -exec chmod 500 {} + && \
    find . -type f -exec chmod 400 {} +

LABEL de.sdavids.docker.group="sdavids-node-docker-image-slimming" \
      de.sdavids.docker.type="builder"

### Harden ###

# https://hub.docker.com/_/alpine
FROM alpine:3.23.2 AS hardened

# https://github.com/hadolint/hadolint/wiki/DL4006
SHELL ["/bin/ash", "-eo", "pipefail", "-c"]

# use apk repositories over HTTPS only
# hadolint ignore=DL3018
RUN echo "https://dl-cdn.alpinelinux.org/alpine/v$(cut -d . -f 1,2 </etc/alpine-release)/main" > /etc/apk/repositories && \
    echo "https://dl-cdn.alpinelinux.org/alpine/v$(cut -d . -f 1,2 </etc/alpine-release)/community" >>/etc/apk/repositories && \
# add root certificates
    apk add --no-cache ca-certificates && \
# add the app user and the working directory
    addgroup -g 1001 node && \
    adduser -g node -u 1001 -G node -s /sbin/nologin -S -D -h /node node && \
    mkdir /node/tmp && \
    chmod -R 700 /node && \
    chown -R node:node /node && \
# remove unnecessary accounts
    sed -i -r "/^(node|root|nobody)/!d" /etc/group && \
    sed -i -r "/^(node|root|nobody)/!d" /etc/passwd && \
# remove interactive login shell for everybody
    sed -i -r 's#^(.*):[^:]*$#\1:/sbin/nologin#' /etc/passwd && \
# disable password login for everybody
   while IFS=: read -r username _; do passwd -l "${username}"; done </etc/passwd || true && \
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
ENV TMPDIR=/node/tmp

### Final ###

FROM hardened

COPY --from=node --chown=node:node /usr/local/bin/node /usr/bin/
COPY --from=node --chown=node:node /usr/lib/libgcc_s.so.1 /usr/lib/libstdc++.so.6 /usr/lib/

WORKDIR /node

COPY --from=nodemodules --chown=node:node /node/node_modules node_modules
COPY --from=builder --chown=node:node /node ./

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
