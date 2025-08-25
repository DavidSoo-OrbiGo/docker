# syntax=docker/dockerfile:1.7

# ---- Build JNI bits (Java 21 + Maven) ----
FROM maven:3.9-eclipse-temurin-21 AS jni
WORKDIR /upstream
COPY upstream/ ./
# If the project has a JNI module, this matches typical structure:
# Adjust if the upstream folder names differ.
RUN if [ -d calcite-rs-jni ]; then \
      cd calcite-rs-jni && chmod +x build.sh && ./build.sh; \
    else \
      echo "No calcite-rs-jni module; skipping JNI build"; \
    fi

# ---- Build Rust binary ----
FROM rust:1.78-bullseye AS builder
WORKDIR /upstream
COPY upstream/ ./
# Bring over any JNI outputs (no-op if not present)
COPY --from=jni /upstream/calcite-rs-jni /upstream/calcite-rs-jni
# Adjust the binary name if upstream uses a different one
RUN cargo build --release --bin ndc-calcite

# ---- Runtime image ----
FROM debian:bookworm-slim
RUN apt-get update && apt-get install -y --no-install-recommends \
      ca-certificates openjdk-21-jre && \
    rm -rf /var/lib/apt/lists/*
WORKDIR /app
COPY --from=builder /upstream/target/release/ndc-calcite /app/ndc-calcite
# Copy JNI artifacts if they exist; ignore errors if missing
COPY --from=builder /upstream/calcite-rs-jni/target /app/calcite-rs-jni/target
ENV RUST_LOG=info
EXPOSE 8080
CMD ["/app/ndc-calcite"]
