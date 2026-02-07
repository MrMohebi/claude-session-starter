FROM node:20-alpine

# Install dependencies
RUN apk add --no-cache \
    bash \
    curl \
    tzdata \
    ca-certificates \
    && rm -rf /var/cache/apk/*

# Install Claude CLI
RUN npm install -g @anthropic-ai/claude-cli

# Set working directory
WORKDIR /app

# Copy script and related files
COPY claude-session-starter.sh /app/
COPY docker-entrypoint.sh /app/

# Make scripts executable
RUN chmod +x /app/claude-session-starter.sh /app/docker-entrypoint.sh

# Create Claude config directory
RUN mkdir -p /root/.claude

# Create configuration directory for session starter
RUN mkdir -p /root/.config/claude-session-starter

# Create volumes for persistent data
VOLUME ["/root/.claude", "/root/.config/claude-session-starter"]

# Set environment variables
ENV TZ=UTC

# Healthcheck to verify Claude CLI and auth
HEALTHCHECK --interval=5m --timeout=10s --start-period=30s --retries=3 \
    CMD test -f /root/.claude/.credentials.json || exit 1

# Use custom entrypoint for initialization
ENTRYPOINT ["/app/docker-entrypoint.sh"]

# Default command - run in daemon mode
CMD ["--daemon"]
