# syntax=docker/dockerfile:1.7

# ---- Build (Rust) ----
FROM rust:1.78-bullseye AS builder
# Native libs commonly needed by Rust crates (openssl/protobuf/bindgen, etc.)
RUN apt-get update && apt-get install -y --no-install-recommends \
    pkg-config libssl-dev ca-certificates clang llvm make protobuf-compiler \
  && rm -rf /var/lib/apt/lists/*
WORKDIR /upstream

# The workflow checks out upstream into ./upstream in your repo.
# Copy that directory into the image.
COPY upstream/ ./

# Build & "install" compiled binaries into /out/bin (handles unknown bin names)
# --locked uses Cargo.lock if present; drop it if it causes issues.
RUN cargo install --path . --locked --root /out

# Create a tiny entrypoint that executes the single produced binary
# (Assumes the package exposes exactly one binary; if multiple, pick one.)
RUN set -eu; \
    BIN="$(ls -1 /out/bin | head -n1)"; \
    echo "Built binary: ${BIN}"; \
    printf '#!/bin/sh\nexec "/app/%s" "$@"\n' "$BIN" > /out/entrypoint.sh; \
    chmod +x /out/entrypoint.sh

# ---- Runtime (slim) ----
FROM debian:bookworm-slim
RUN apt-get update && apt-get install -y --no-install-recommends \
    ca-certificates openssl \
  && rm -rf /var/lib/apt/lists/*
WORKDIR /app

# Bring the compiled binary and launcher
COPY --from=builder /out/bin/*         /app/
COPY --from=builder /out/entrypoint.sh /app/entrypoint.sh

ENV RUST_LOG=info
EXPOSE 8080
ENTRYPOINT ["/app/entrypoint.sh"]
