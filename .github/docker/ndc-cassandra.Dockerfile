# syntax=docker/dockerfile:1.7

# ---- Build (Rust) ----
FROM rust:1.78-bullseye AS builder
RUN apt-get update && apt-get install -y --no-install-recommends \
    ca-certificates pkg-config libssl-dev clang llvm make protobuf-compiler findutils tree \
 && rm -rf /var/lib/apt/lists/*
WORKDIR /upstream

# Your workflow checks out the upstream repo into ./upstream in your repo.
COPY upstream/ ./

# Show what actually exists (helps debug wrong repo/branch)
RUN echo "== /upstream tree (depth 2) ==" && tree -L 2 -a

# Find a Cargo.toml (root or a subdir) and build it
RUN set -eux; \
    if [ -f /upstream/Cargo.toml ]; then \
      CARGO_DIR="/upstream"; \
    else \
      CARGO_DIR="$(find /upstream -maxdepth 3 -type f -name Cargo.toml -exec dirname {} \; | head -n1)"; \
    fi; \
    if [ -z "${CARGO_DIR}" ]; then \
      echo "FATAL: No Cargo.toml found in /upstream (is this the correct source repo/branch?)" >&2; \
      exit 66; \
    fi; \
    echo "Building cargo project in: ${CARGO_DIR}"; \
    cd "${CARGO_DIR}"; \
    cargo build --release; \
    mkdir -p /out/bin; \
    # copy all executable files from target/release
    find target/release -maxdepth 1 -type f -perm -111 -exec cp {} /out/bin/ \; ; \
    ls -l /out/bin

# ---- Runtime ----
FROM debian:bookworm-slim
RUN apt-get update && apt-get install -y --no-install-recommends \
    ca-certificates openssl \
 && rm -rf /var/lib/apt/lists/*
WORKDIR /app
COPY --from=builder /out/bin/ /app/

# Pick the first binary by default (override CMD if needed)
RUN set -eu; BIN="$(ls -1 /app | head -n1)"; \
    printf '#!/bin/sh\nexec "/app/%s" "$@"\n' "$BIN" > /app/entrypoint.sh; \
    chmod +x /app/entrypoint.sh; \
    echo "Default runtime binary: $BIN"

ENV RUST_LOG=info
EXPOSE 8080
ENTRYPOINT ["/app/entrypoint.sh"]
