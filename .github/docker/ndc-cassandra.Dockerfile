# syntax=docker/dockerfile:1.7

# ---- Build Rust binary (no JNI) ----
FROM rust:1.78-bullseye AS builder
WORKDIR /upstream
COPY upstream/ ./
# Adjust the binary name if upstream uses a different one
RUN cargo build --release --bin ndc-calcite

# ---- Runtime image (Java 21 kept only if your app needs it) ----
FROM eclipse-temurin:21-jre-jammy
WORKDIR /app
COPY --from=builder /upstream/target/release/ndc-calcite /app/ndc-calcite
ENV RUST_LOG=info
EXPOSE 8080
CMD ["/app/ndc-calcite"]
