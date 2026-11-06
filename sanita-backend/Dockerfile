# ============================================================
# SANITA Backend — Multi-Stage Hardened Dockerfile
# Maximum Anti-Breach & Zero-Trust Production Image
# Author: Ribka Lusiana Harahap (NIM: 243301631022)
# ============================================================

# ── Stage 1: Build ──────────────────────────────────────────
FROM golang:alpine AS builder

# Install build essentials and security updates
RUN apk update && apk add --no-cache git ca-certificates tzdata

WORKDIR /app

# Cache dependencies
COPY go.mod go.sum* ./
RUN go mod download || true

# Copy source
COPY . .

# Build statically linked binary without debug symbols (-s -w)
RUN CGO_ENABLED=0 GOOS=linux go build -ldflags="-s -w -extldflags '-static'" -o sanita-service ./cmd/sanita-service/main.go

# ── Stage 2: Hardened Runtime ────────────────────────────────
FROM alpine:3.20

# Create unprivileged non-root user
RUN addgroup -S sanita && adduser -S sanita -G sanita

# Security updates & CA certs
RUN apk --no-cache add ca-certificates tzdata \
    && rm -rf /var/cache/apk/*

WORKDIR /app

# Copy binary from builder
COPY --from=builder /app/sanita-service .
COPY --from=builder /app/database ./database

# Create uploads directory and set permissions
RUN mkdir -p uploads && chown -R sanita:sanita /app

# Switch to non-root user (Principle of Least Privilege)
USER sanita:sanita

# Environment configurations
ENV GIN_MODE=release \
    PORT=8080 \
    TZ=Asia/Jakarta

EXPOSE 8080

HEALTHCHECK --interval=30s --timeout=5s --start-period=5s --retries=3 \
  CMD wget --no-verbose --tries=1 --spider http://localhost:${PORT}/health || exit 1

ENTRYPOINT ["./sanita-service"]