# Use carlosedp/golang for riscv64 support
FROM carlosedp/golang:1.18 AS build

# Install dependencies
RUN apt-get update && apt-get install -y git build-essential libsecret-1-dev

# Build
WORKDIR /build/
COPY build.sh VERSION /build/
RUN bash build.sh

FROM ubuntu:jammy
LABEL maintainer="Xiaonan Shen <s@sxn.dev>"

EXPOSE 25/tcp
EXPOSE 143/tcp

# Install dependencies and protonmail bridge
RUN apt-get update \
    && apt-get install -y --no-install-recommends socat pass libsecret-1-0 ca-certificates \
    && rm -rf /var/lib/apt/lists/*

# Copy bash scripts
COPY gpgparams entrypoint.sh /protonmail/

# Copy protonmail
COPY --from=build /build/proton-bridge/bridge /protonmail/
COPY --from=build /build/proton-bridge/proton-bridge /protonmail/

RUN addgroup --gid 1000 service
RUN adduser --disabled-password --uid 1000 --gid 1000 service
RUN chgrp -R service /protonmail && chown -R service /protonmail
USER service:service

WORKDIR /protonmail

ENTRYPOINT ["bash", "./entrypoint.sh"]
