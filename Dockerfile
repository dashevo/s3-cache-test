# syntax = docker/dockerfile:1.5

FROM rust:alpine3.16 as builder

# Install tools and deps
RUN apk update && \
apk --no-cache upgrade && \
apk add --no-cache \
    alpine-sdk \
    bash \
    binutils \
    ca-certificates \
    clang \
    clang-dev \
    clang-static \
    cmake \
    gcc \
    git \
    libc-dev \
    linux-headers \
    llvm-dev \
    llvm-static \
    make \
    nodejs \
    npm \
    openssh-client \
    openssl \
    openssl-dev \
    perl \
    pkg-config \
    python3 \
    unzip \
    wget \
    xz \
    zeromq-dev

# Configure Node.js
RUN npm install -g npm@latest && \
    npm install -g corepack@latest && \
    corepack prepare yarn@stable --activate && \
    corepack enable

SHELL ["/bin/bash", "-c"]

# # Install sccache for caching
# ENV SCCACHE_VERSION=0.4.2
# RUN if [[ "$TARGETARCH" == "arm64" ]] ; then export SCC_ARCH=aarch64; else export SCC_ARCH=x86_64; fi; \
#     curl -Ls \
#         https://github.com/mozilla/sccache/releases/download/v${SCCACHE_VERSION}/sccache-v${SCCACHE_VERSION}-${SCC_ARCH}-unknown-linux-musl.tar.gz | \
#         tar -C /tmp -xz && \
#         mv /tmp/sccache-*/sccache /usr/local/bin/

# # Activate sccache for Rust code
# ENV RUSTC_WRAPPER=/usr/local/bin/sccache

# # Disable incremental buildings, not supported by sccache
# ENV CARGO_INCREMENTAL=false

# Configure Rust
RUN rustup toolchain install stable && \
    rustup target add wasm32-unknown-unknown --toolchain stable && \
    cargo install -f wasm-bindgen-cli

COPY . .

RUN --mount=type=cache,sharing=shared,target=${CARGO_HOME}/registry/index \
    --mount=type=cache,sharing=shared,target=${CARGO_HOME}/registry/cache \
    --mount=type=cache,sharing=shared,target=${CARGO_HOME}/git/db \
    cargo build \
        --package dashcore-rpc \
        --config net.git-fetch-with-cli=true && \
    cargo build \
        --package drive-abci \
        --config net.git-fetch-with-cli=true && \
    cp /usr/src/dash-platform/target/*/drive-abci /usr/src/dash-platform/drive-abci && \
    cargo clean
