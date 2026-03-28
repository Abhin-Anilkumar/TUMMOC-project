# ============================================
# Recommendation - Go (Gin) Multi-Stage Build
# ============================================

# Stage 1: Build the Go binary
FROM golang:1.20.10-alpine3.18 AS builder
WORKDIR /app

# Install git for Go modules (some may need it)
RUN apk add --no-cache git

# Copy go mod files first for dependency caching
COPY go.mod go.sum ./
RUN go mod download

# Copy source code
COPY . .

# Build static binary
RUN CGO_ENABLED=0 GOOS=linux go build -a -installsuffix cgo -o app .

# Stage 2: Minimal runtime image
FROM alpine:3.18 AS production
WORKDIR /app

# Install ca-certificates for HTTPS calls
RUN apk --no-cache add ca-certificates

# Create non-root user
RUN addgroup -g 1001 -S appgroup && \
    adduser -S appuser -u 1001

# Copy binary from builder
COPY --from=builder /app/app .

# Copy runtime assets
COPY --from=builder /app/config.json .
COPY --from=builder /app/templates/ ./templates/
COPY --from=builder /app/static/ ./static/
COPY --from=builder /app/data/ ./data/

# Set ownership
RUN chown -R appuser:appgroup /app

USER appuser

# Expose port
EXPOSE 8080

# Health check
HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
    CMD wget --no-verbose --tries=1 --spider http://localhost:8080/ || exit 1

# Run the binary
CMD ["./app"]
