# syntax=docker/dockerfile:1.7

# Build args you can override from the workflow
ARG RUST_IMAGE=rust:1.78-bullseye
ARG RUNTIME_IMAGE=eclipse-temurin:21-jre-jammy
ARG CARGO_SUBDIR=.
ARG BINARY_NAME=ndc-calcite

# ---- Build stage ----
FROM ${RUST_IMAGE} AS builder
ARG CARGO_SUBDIR
ARG BINARY_NAME

WORKDIR /upstream
# The workflow checks out the upstream source into ./upstream at build context root
COPY upstream/ ./

# Build the Rust binary in the specified subdir (default ".")
WORKDIR /upstream/${CARGO_SUBDIR}

# Caches for cargo speeds up repeated builds
RUN --mount=type=cache,target=/usr/local/cargo/registry \
    --mount=type=cache,target=/upstream/target \
    cargo build --release --bin ${BINARY_NAME}

# ---- Runtime stage ----
FROM ${RUNTIME_IMAGE}
WORKDIR /app

# These ARGs must be re-declared in the final stage if referenced
ARG CARGO_SUBDIR
ARG BINARY_NAME

# Copy the compiled binary from the builder
COPY --from=builder /upstream/${CARGO_SUBDIR}/target/release/${BINARY_NAME} /app/${BINARY_NAME}

ENV RUST_LOG=info
EXPOSE 8080

# If your binary name is different, pass BINARY_NAME via build-args in the workflow
CMD ["/app/ndc-calcite"]
