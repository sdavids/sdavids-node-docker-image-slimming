# syntax=docker/dockerfile:1
# check=error=true

# SPDX-FileCopyrightText: © 2020 Sebastian Davids <sdavids@gmx.de>
# SPDX-License-Identifier: Apache-2.0

# https://docs.docker.com/engine/reference/builder/

### Node ###

# https://hub.docker.com/_/node
FROM node:22.16.0-alpine3.22 AS node

RUN apk --no-cache add upx=5.0.2-r0 && \
    upx /usr/local/bin/node

LABEL de.sdavids.docker.group="sdavids-node-docker-image-slimming" \
      de.sdavids.docker.type="builder"

### Builder ###

# https://hub.docker.com/_/node
FROM node:22.16.0-alpine3.22 AS builder

WORKDIR /node

COPY scripts/build.sh scripts/
COPY package.json package-lock.json ./

RUN npm ci --ignore-scripts=true --omit=dev --omit=optional --omit=peer

COPY src/js src/js

RUN node --run build && \
# keep only JavaScript/JSON files and harden permissions
    find dist -type f ! \( -name '*.cjs' -o -name '*.js' -o -name '*.json' -o -name '*.mjs' \) -delete && \
    find dist -type d -empty -delete && \
    find dist -type d -exec chmod 500 {} + && \
    find dist -type f -exec chmod 400 {} +

LABEL de.sdavids.docker.group="sdavids-node-docker-image-slimming" \
      de.sdavids.docker.type="builder"

### Harden ###

# https://hub.docker.com/_/alpine
FROM alpine:3.22.1 AS hardened

# https://github.com/hadolint/hadolint/wiki/DL4006
SHELL ["/bin/ash", "-eo", "pipefail", "-c"]

# use apk repositories over HTTPS only
# hadolint ignore=DL3018
RUN echo "https://dl-cdn.alpinelinux.org/alpine/v$(cut -d . -f 1,2 </etc/alpine-release)/main" >/etc/apk/repositories && \
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

COPY --from=builder --chown=node:node /node/dist ./

ENV NODE_ENV=production
ENV PORT=3000

USER node:node

EXPOSE 3000

CMD ["node", "server.cjs"]

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
