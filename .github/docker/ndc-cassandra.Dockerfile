# Placeholder image to prove CI works. Replace with the real connector build.
FROM busybox:uclibc
WORKDIR /app
# Copy something small from upstream so the image isn't empty (optional)
# This path will exist once the workflow checks out 'hasura/ndc-cassandra' into ./upstream.
# The build context is ./upstream, so paths here are relative to that.
# COPY connector-definition /app/connector-definition
EXPOSE 8080
CMD ["sh","-lc","echo 'Built OK (placeholder). Replace .github/docker/ndc-cassandra.Dockerfile with real steps.'; sleep 3600"]
