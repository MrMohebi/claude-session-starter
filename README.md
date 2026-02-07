# Claude Session Starter

**Automatically trigger Claude sessions at your chosen hours throughout the day.**

**For Claude Pro & Max subscribers** - uses Claude CLI with OAuth authentication.

## Why Use This?

Claude sessions reset at fixed times. This tool lets you control *when* sessions start by triggering interactions at hours you choose - during your productive hours, not while you sleep.

**Example:** Instead of sessions resetting at 3 AM (wasted), trigger at 9 AM, 1 PM, and 5 PM (aligned with your work schedule).

## Requirements

- **Claude Pro or Max subscription**
- Claude CLI installed and authenticated
- Bash shell (Linux, macOS, WSL) OR Docker

## Quick Start

### Option 1: Local Installation

**1. Install & authenticate Claude CLI:**
```bash
# Install Claude CLI (if not already installed)
curl -fsSL https://claude.ai/install.sh | sh

# Authenticate with your Claude Pro/Max account
claude
# Follow the login prompts
```

**2. Clone and setup:**
```bash
git clone https://github.com/MrMohebi/claude-session-starter.git
cd claude-session-starter
chmod +x claude-session-starter.sh

# Run setup wizard
./claude-session-starter.sh --setup
```

**3. Start the daemon:**
```bash
# Run in background
nohup ./claude-session-starter.sh --daemon > /dev/null 2>&1 &
```

### Option 2: Docker (For users who don't want to install CLI locally)

**Method A: Use your existing Claude CLI credentials**
```bash
# Build image
docker build -t claude-session-starter .

# Run with your local Claude credentials
docker run -d \
  --name claude-session-starter \
  --restart unless-stopped \
  -e TRIGGER_HOURS='9,13,17' \
  -e TZ='America/New_York' \
  -v ~/.claude:/root/.claude:ro \
  -v session-config:/root/.config/claude-session-starter \
  claude-session-starter
```

**Method B: Authenticate inside Docker container**
```bash
# Build image
docker build -t claude-session-starter .

# Run container interactively to authenticate
docker run -it \
  -v claude-data:/root/.claude \
  -v session-config:/root/.config/claude-session-starter \
  claude-session-starter bash

# Inside container, authenticate:
claude
# Follow the login prompts

# Exit container (Ctrl+D)
exit

# Now run normally
docker run -d \
  --name claude-session-starter \
  --restart unless-stopped \
  -e TRIGGER_HOURS='9,13,17' \
  -e TZ='America/New_York' \
  -v claude-data:/root/.claude \
  -v session-config:/root/.config/claude-session-starter \
  claude-session-starter
```

**Method C: Using docker-compose**
```bash
# If using local credentials, edit docker-compose.yml and uncomment the local mount

# Start with docker-compose
docker-compose up -d

# View logs
docker-compose logs -f
```

## Usage

### Command Line Options

```bash
./claude-session-starter.sh [OPTIONS]

OPTIONS:
  -h, --hours HOURS    Comma-separated hours (0-23) to trigger
                       Example: 9,12,15,18
  -d, --daemon         Run in daemon mode (continuous monitoring)
  -c, --cron           Run once (for cron jobs)
  -s, --setup          Interactive setup wizard
  -l, --log            View recent logs
  --help               Show help message
```

### Examples

**9-to-5 schedule:**
```bash
./claude-session-starter.sh --hours 9,13,17 --daemon
```

**Night owl schedule:**
```bash
./claude-session-starter.sh --hours 14,18,22 --daemon
```

**View logs:**
```bash
./claude-session-starter.sh --log
```

## Running as Systemd Service (Linux)

1. Edit the service file:
```bash
nano claude-session-starter.service
# Update User= and paths
```

2. Install and start:
```bash
sudo cp claude-session-starter.service /etc/systemd/system/
sudo systemctl daemon-reload
sudo systemctl enable claude-session-starter
sudo systemctl start claude-session-starter
```

3. Check status:
```bash
sudo systemctl status claude-session-starter
```

## Cron Job Setup

```bash
crontab -e

# Add this line (runs every hour):
0 * * * * /path/to/claude-session-starter.sh --cron
```

## Configuration

Configuration is stored in `~/.config/claude-session-starter/config`:
```bash
HOURS="9,12,15,18"
```

Logs: `~/.config/claude-session-starter/session.log`

## Docker Environment Variables

| Variable | Description | Example |
|----------|-------------|---------|
| `TRIGGER_HOURS` | Hours to trigger (comma-separated) | `9,13,17` |
| `TZ` | Timezone | `America/New_York` |

## How It Works

1. **Monitoring:** Checks current hour every minute (daemon) or once (cron)
2. **Trigger Detection:** If current hour matches configured hours, triggers
3. **Session Start:** Runs `claude --print "ping"` to trigger a Claude Pro session
4. **State Update:** Records trigger to prevent duplicates
5. **Reset:** State resets daily for next day's triggers

**Cost:** FREE! Uses your existing Claude Pro/Max subscription - no additional API costs.

## Troubleshooting

### Claude CLI Issues
```bash
# Test Claude CLI
claude "test"

# Re-authenticate
claude
```

### Script Not Triggering
```bash
# Check if running
ps aux | grep claude-session-starter

# View logs
./claude-session-starter.sh --log

# Test at current hour
./claude-session-starter.sh --hours $(date +%H | sed 's/^0//)')
```

### Docker Issues
```bash
# Check logs
docker logs claude-session-starter

# Check if authenticated
docker exec -it claude-session-starter cat /root/.claude/.credentials.json

# Access container
docker exec -it claude-session-starter bash
```

## Security

- Claude CLI credentials stored in `~/.claude/.credentials.json` with 600 permissions
- OAuth tokens managed by Claude CLI
- Never commit credentials to version control

## License

MIT License - See LICENSE file

## Disclaimer

This tool uses Claude CLI and works within Claude's terms of service. It simply helps schedule when you interact with Claude during your productive hours.

**For Claude Pro & Max users only** - requires an active subscription.

---

**Simplicity is key.** Trigger Claude sessions when YOU need them, not at random times.
