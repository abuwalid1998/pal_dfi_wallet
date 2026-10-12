# ==============================================================================
# State of Palestine - Ministry of Interior (MoI)
# Digital National ID Issuance & Civil Registry Platform
# Container Image: Production Pilot Ready (Air-Gapped & Self-Contained)
# ==============================================================================

FROM node:20-alpine AS runtime

# Metadata labels adhering to OCI Image Format Specification
LABEL maintainer="Pal-DI Consortium <support@moi.pna.ps>" \
      org.opencontainers.image.title="MoI Palestinian National ID Pilot Container" \
      org.opencontainers.image.description="Ministry of Interior First-Time Digital National ID Issuance Service" \
      org.opencontainers.image.version="1.0.0-pilot" \
      org.opencontainers.image.vendor="State of Palestine - Ministry of Interior" \
      org.opencontainers.image.licenses="Proprietary"

# Install security updates & curl/wget for healthchecks
RUN apk update && apk upgrade && \
    apk add --no-cache wget ca-certificates && \
    rm -rf /var/cache/apk/*

# Working directory inside container
WORKDIR /app

# Configure environment defaults
ENV NODE_ENV=production \
    PORT=9000 \
    HOST=0.0.0.0 \
    DATA_DIR=/app/data \
    APP_VERSION=1.0.0-pilot

# Copy package definition
COPY package.json ./

# Copy server application
COPY server.js ./

# Copy static frontend and biometrics assets
COPY moi_id.html ./
COPY moi_id.html ./index.html
COPY moi_id.js ./
COPY style.css ./
COPY face-api.min.js ./

# Copy pre-downloaded neural network models (ensures air-gapped intranet operation)
COPY models/ ./models/

# Copy official emblems, badges, and image assets
COPY assets/ ./assets/

# Copy initial civil registry data seed
COPY data/ ./data/

# Adjust file ownership to non-root user (node)
RUN chown -R node:node /app

# Switch to standard non-root user for enterprise container security
USER node

# Persistent volume mount point for civil records and database files
VOLUME ["/app/data"]

# Expose service port
EXPOSE 9000

# Container Healthcheck probe for Docker / Kubernetes / Swarm
HEALTHCHECK --interval=30s --timeout=5s --start-period=5s --retries=3 \
  CMD wget --no-verbose --tries=1 --spider http://localhost:9000/health || exit 1

# Default execution command
CMD ["node", "server.js"]
