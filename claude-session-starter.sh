#!/bin/bash

# Claude Session Starter
# Triggers Claude CLI sessions at specific hours for Pro/Max users

set -e

# Configuration
CONFIG_FILE="${HOME}/.config/claude-session-starter/config"
LOG_FILE="${HOME}/.config/claude-session-starter/session.log"
STATE_FILE="${HOME}/.config/claude-session-starter/state"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to print usage
usage() {
    cat << EOF
Usage: $(basename "$0") [OPTIONS]

Triggers Claude CLI sessions at specific hours for Claude Pro/Max users.

OPTIONS:
    -h, --hours HOURS       Comma-separated list of hours (0-23) to trigger sessions
                           Example: 9,12,15,18
    -d, --daemon           Run in daemon mode (continuous monitoring)
    -c, --cron             Run once (suitable for cron jobs)
    -s, --setup            Interactive setup wizard
    -l, --log              View recent logs
    --help                 Display this help message

EXAMPLES:
    # Interactive setup
    $(basename "$0") --setup

    # Run in daemon mode with specific hours
    $(basename "$0") --hours 9,14,18 --daemon

    # Run once (for cron)
    $(basename "$0") --cron

REQUIREMENTS:
    - Claude CLI installed and authenticated
    - Claude Pro or Max subscription

EOF
    exit 0
}

# Function to log messages
log() {
    local level="$1"
    shift
    local message="$*"
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')

    mkdir -p "$(dirname "$LOG_FILE")"
    echo "[${timestamp}] [${level}] ${message}" >> "$LOG_FILE"

    case "$level" in
        INFO)
            echo -e "${BLUE}[INFO]${NC} ${message}"
            ;;
        SUCCESS)
            echo -e "${GREEN}[SUCCESS]${NC} ${message}"
            ;;
        WARNING)
            echo -e "${YELLOW}[WARNING]${NC} ${message}"
            ;;
        ERROR)
            echo -e "${RED}[ERROR]${NC} ${message}"
            ;;
    esac
}

# Function to send request via Claude CLI
send_claude_request() {
    log "INFO" "Triggering Claude CLI session..."

    # Check if claude command is available
    if ! command -v claude &> /dev/null; then
        log "ERROR" "Claude CLI not found. Please install from https://claude.ai/download"
        return 1
    fi

    # Check if authenticated
    if [ ! -f "$HOME/.claude/.credentials.json" ]; then
        log "ERROR" "Claude CLI not authenticated. Run 'claude' to login."
        return 1
    fi

    # Send a simple prompt to trigger session activity
    local response=$(claude --print "ping" 2>&1)
    local exit_code=$?

    if [ $exit_code -eq 0 ]; then
        log "SUCCESS" "Claude CLI session triggered successfully"
        log "INFO" "Response: ${response:0:100}..."
        return 0
    else
        log "ERROR" "Claude CLI request failed (exit code: $exit_code)"
        log "ERROR" "Response: $response"
        return 1
    fi
}

# Function to check if it's time to trigger
should_trigger() {
    local current_hour=$(date +%H | sed 's/^0//')
    local target_hours="$1"
    local last_triggered="$2"
    local today=$(date +%Y-%m-%d)

    # Check if we already triggered this hour today
    if [ -f "$STATE_FILE" ]; then
        local last_trigger_time=$(cat "$STATE_FILE")
        local last_trigger_date=$(echo "$last_trigger_time" | cut -d' ' -f1)
        local last_trigger_hour=$(echo "$last_trigger_time" | cut -d' ' -f2)

        if [ "$last_trigger_date" = "$today" ] && [ "$last_trigger_hour" = "$current_hour" ]; then
            return 1
        fi
    fi

    # Check if current hour is in target hours
    IFS=',' read -ra HOURS <<< "$target_hours"
    for hour in "${HOURS[@]}"; do
        hour=$(echo "$hour" | xargs) # trim whitespace
        if [ "$current_hour" = "$hour" ]; then
            return 0
        fi
    done

    return 1
}

# Function to update state
update_state() {
    local current_hour=$(date +%H | sed 's/^0//')
    local today=$(date +%Y-%m-%d)

    mkdir -p "$(dirname "$STATE_FILE")"
    echo "$today $current_hour" > "$STATE_FILE"
}

# Function to load configuration
load_config() {
    if [ -f "$CONFIG_FILE" ]; then
        source "$CONFIG_FILE"
        echo "${HOURS}"
    else
        echo ""
    fi
}

# Function to save configuration
save_config() {
    local hours="$1"

    mkdir -p "$(dirname "$CONFIG_FILE")"
    cat > "$CONFIG_FILE" << EOF
# Claude Session Starter Configuration
# For Claude Pro/Max users with Claude CLI
HOURS="${hours}"
EOF
    chmod 600 "$CONFIG_FILE"
    log "SUCCESS" "Configuration saved to $CONFIG_FILE"
}

# Function for interactive setup
interactive_setup() {
    echo -e "${BLUE}=== Claude Session Starter Setup ===${NC}"
    echo -e "${BLUE}For Claude Pro/Max users with Claude CLI${NC}\n"

    # Check if Claude CLI is available
    if ! command -v claude &> /dev/null; then
        echo -e "${RED}✗${NC} Claude CLI not found\n"
        echo "Please install Claude CLI first:"
        echo "  Visit: https://claude.ai/download"
        echo "  Or run: curl -fsSL https://claude.ai/install.sh | sh"
        exit 1
    fi

    echo -e "${GREEN}✓${NC} Claude CLI found\n"

    # Check if Claude CLI is authenticated
    if [ ! -f "$HOME/.claude/.credentials.json" ]; then
        echo -e "${YELLOW}⚠${NC}  Claude CLI is not authenticated\n"
        echo "Please authenticate first by running:"
        echo -e "  ${BLUE}claude${NC}"
        echo ""
        echo "Follow the prompts to log in to your Claude Pro/Max account."
        exit 1
    fi

    echo -e "${GREEN}✓${NC} Claude CLI authenticated\n"

    # Test Claude CLI
    log "INFO" "Testing Claude CLI connection..."
    if send_claude_request; then
        log "SUCCESS" "Claude CLI is working correctly"
    else
        log "ERROR" "Claude CLI test failed"
        exit 1
    fi

    # Get hours
    echo -e "\n${YELLOW}Enter hours (0-23) to trigger sessions${NC}"
    echo "Comma-separated (e.g., 9,12,15,18 for 9am, 12pm, 3pm, 6pm):"
    read hours

    if [ -z "$hours" ]; then
        log "ERROR" "Hours are required"
        exit 1
    fi

    # Save configuration
    save_config "$hours"

    echo -e "\n${GREEN}✓ Setup complete!${NC}\n"
    echo "Run in daemon mode:"
    echo -e "  ${BLUE}$(basename "$0") --daemon${NC}"
    echo
    echo "Or run in background:"
    echo -e "  ${BLUE}nohup $(basename "$0") --daemon > /dev/null 2>&1 &${NC}"
    echo
    echo "Or add to cron (runs every hour):"
    echo -e "  ${BLUE}0 * * * * $(realpath "$0") --cron${NC}"
}

# Function to view logs
view_logs() {
    if [ -f "$LOG_FILE" ]; then
        echo -e "${BLUE}=== Recent Logs (last 50 lines) ===${NC}\n"
        tail -n 50 "$LOG_FILE"
    else
        log "WARNING" "No logs found at $LOG_FILE"
    fi
}

# Function to run in daemon mode
daemon_mode() {
    local hours="$1"

    log "INFO" "Starting daemon mode..."
    log "INFO" "Monitoring hours: $hours"
    log "INFO" "Press Ctrl+C to stop"

    while true; do
        if should_trigger "$hours" ""; then
            log "INFO" "Trigger time reached!"
            if send_claude_request; then
                update_state
            fi
        fi

        # Sleep for 1 minute before checking again
        sleep 60
    done
}

# Function to run once (cron mode)
cron_mode() {
    local hours="$1"

    if should_trigger "$hours" ""; then
        log "INFO" "Trigger time reached!"
        if send_claude_request; then
            update_state
        fi
    fi
}

# Main script
main() {
    local hours=""
    local mode="once"

    # Parse arguments
    while [[ $# -gt 0 ]]; do
        case $1 in
            -h|--hours)
                hours="$2"
                shift 2
                ;;
            -d|--daemon)
                mode="daemon"
                shift
                ;;
            -c|--cron)
                mode="cron"
                shift
                ;;
            -s|--setup)
                interactive_setup
                exit 0
                ;;
            -l|--log)
                view_logs
                exit 0
                ;;
            --help)
                usage
                ;;
            *)
                echo "Unknown option: $1"
                usage
                ;;
        esac
    done

    # Load configuration if not provided
    if [ -z "$hours" ]; then
        hours=$(load_config)
    fi

    # Validate required parameters
    if [ -z "$hours" ]; then
        log "ERROR" "Hours not specified. Run --setup to configure"
        exit 1
    fi

    # Verify Claude CLI is available
    if ! command -v claude &> /dev/null; then
        log "ERROR" "Claude CLI not found. Please install from https://claude.ai/download"
        exit 1
    fi

    # Check authentication
    if [ ! -f "$HOME/.claude/.credentials.json" ]; then
        log "ERROR" "Claude CLI not authenticated. Run 'claude' to login first"
        exit 1
    fi

    # Run in selected mode
    case "$mode" in
        daemon)
            daemon_mode "$hours"
            ;;
        cron)
            cron_mode "$hours"
            ;;
        once)
            if should_trigger "$hours" ""; then
                send_claude_request
                update_state
            else
                log "INFO" "Not a trigger hour. Current hour: $(date +%H)"
            fi
            ;;
    esac
}

# Run main function
main "$@"
