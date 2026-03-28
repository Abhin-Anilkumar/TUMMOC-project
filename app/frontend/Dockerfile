# ============================================
# Frontend - Node.js (Express) Multi-Stage Build
# ============================================

# Stage 1: Install dependencies
FROM node:21-alpine AS deps
WORKDIR /app
COPY package*.json ./
RUN npm ci --only=production

# Stage 2: Production image
FROM node:21-alpine AS production
WORKDIR /app

# Create non-root user for security
RUN addgroup -g 1001 -S nodejs && \
    adduser -S craftista -u 1001

# Copy dependencies from deps stage
COPY --from=deps /app/node_modules ./node_modules

# Copy application code
COPY . .

# Remove unnecessary files
RUN rm -rf .dockerignore Dockerfile README.md

# Set ownership
RUN chown -R craftista:nodejs /app

USER craftista

# Expose the app port
EXPOSE 3000

# Health check
HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
    CMD wget --no-verbose --tries=1 --spider http://localhost:3000/ || exit 1

# Command to run the application
CMD ["node", "app.js"]
