FROM nginx:1.25-alpine

# Remove default nginx config
RUN rm /etc/nginx/conf.d/default.conf

# Copy custom nginx config
COPY nginx.conf /etc/nginx/conf.d/

# Install curl for health checks
RUN apk add --no-cache curl

# Expose port 80
EXPOSE 80

CMD ["nginx", "-g", "daemon off;"]
