#!/bin/bash

# Docker entrypoint script for Claude Session Starter
# Handles Claude CLI authentication and configuration

set -e

CONFIG_FILE="/root/.config/claude-session-starter/config"
CLAUDE_CREDS="/root/.claude/.credentials.json"

echo "=========================================="
echo "  Claude Session Starter (Docker)"
echo "  For Claude Pro/Max users"
echo "=========================================="
echo ""

# Function to check if Claude CLI is authenticated
check_auth() {
    if [ -f "$CLAUDE_CREDS" ]; then
        echo "✓ Claude CLI authenticated"
        return 0
    fi
    return 1
}

# Function to check if session starter is configured
check_config() {
    if [ -f "$CONFIG_FILE" ]; then
        echo "✓ Session starter configured"
        return 0
    fi
    return 1
}

# Check if authenticated
if ! check_auth; then
    echo ""
    echo "⚠ Claude CLI is not authenticated"
    echo ""
    echo "To authenticate, you need to:"
    echo "  1. Run the container interactively:"
    echo "     docker run -it -v claude-data:/root/.claude <image> bash"
    echo "  2. Inside container, run: claude"
    echo "  3. Follow the authentication prompts"
    echo "  4. Exit and restart container normally"
    echo ""
    echo "Or mount an existing .claude directory:"
    echo "  docker run -v ~/.claude:/root/.claude <image>"
    echo ""

    # If running interactively and user wants to setup
    if [ "$1" = "--setup" ] || [ "$1" = "bash" ] || [ "$1" = "sh" ]; then
        echo "Starting interactive mode..."
        exec "$@"
    else
        exit 1
    fi
fi

# Check if configured
if ! check_config; then
    echo ""
    echo "⚠ Session starter not configured"
    echo ""

    if [ -n "$TRIGGER_HOURS" ]; then
        echo "Creating configuration from TRIGGER_HOURS environment variable..."
        mkdir -p "$(dirname "$CONFIG_FILE")"
        cat > "$CONFIG_FILE" << EOF
# Claude Session Starter Configuration
HOURS="${TRIGGER_HOURS}"
EOF
        chmod 600 "$CONFIG_FILE"
        echo "✓ Configuration created: HOURS=$TRIGGER_HOURS"
    else
        echo "Please configure by either:"
        echo "  1. Set TRIGGER_HOURS environment variable (e.g., '9,13,17')"
        echo "  2. Run: docker run -it <image> --setup"
        echo "  3. Mount existing config volume"
        echo ""

        if [ "$1" = "--setup" ]; then
            exec /app/claude-session-starter.sh --setup
        else
            exit 1
        fi
    fi
fi

echo ""
echo "Starting Claude Session Starter..."
echo "Timezone: $(date +%Z)"
echo "Current time: $(date)"
echo ""

# Execute the main script with provided arguments
exec /app/claude-session-starter.sh "$@"
