# Claude CLI Session Starter - Quick Reference

**For Claude Pro & Max subscribers using Claude CLI**

## ✅ What You Have Now

- **Pure Claude CLI mode** - No API keys needed!
- **OAuth authentication** - Uses your Claude Pro/Max subscription
- **Docker support** - Run without installing CLI locally
- **Zero API costs** - Completely free with your subscription

## 🚀 Quick Commands

### Local Usage

**Setup (First time)**
```bash
# Make sure Claude CLI is authenticated
claude

# Configure your trigger hours
./claude-session-starter.sh --setup
# Enter hours like: 9,13,17
```

**Start Daemon**
```bash
# Run in foreground (see output)
./claude-session-starter.sh --daemon

# Run in background (recommended)
nohup ./claude-session-starter.sh --daemon > /dev/null 2>&1 &
```

**Check Status**
```bash
# View logs
./claude-session-starter.sh --log

# Check if running
ps aux | grep claude-session-starter

# Stop daemon
pkill -f claude-session-starter.sh
```

### Docker Usage

**Pre-built image:** `ghcr.io/mrmohebi/claude-session-starter:latest`

**Option 1: Use your local Claude credentials**
```bash
# Run with your credentials (uses pre-built image)
docker run -d \
  --name claude-session-starter \
  --restart unless-stopped \
  -e TRIGGER_HOURS='9,13,17' \
  -v ~/.claude:/root/.claude:ro \
  -v session-config:/root/.config/claude-session-starter \
  ghcr.io/mrmohebi/claude-session-starter:latest

# View logs
docker logs -f claude-session-starter
```

**Option 2: Authenticate inside Docker**
```bash
# Run interactively
docker run -it \
  -v claude-data:/root/.claude \
  ghcr.io/mrmohebi/claude-session-starter:latest bash

# Inside container:
claude  # Follow login prompts
exit

# Run normally
docker run -d \
  --name claude-session-starter \
  --restart unless-stopped \
  -e TRIGGER_HOURS='9,13,17' \
  -v claude-data:/root/.claude \
  -v session-config:/root/.config/claude-session-starter \
  ghcr.io/mrmohebi/claude-session-starter:latest
```

**Option 3: docker-compose**
```bash
# Clone repo to get docker-compose.yml
git clone https://github.com/MrMohebi/claude-session-starter.git
cd claude-session-starter

# Start (uses pre-built image from GHCR)
docker-compose up -d

# View logs
docker-compose logs -f

# Stop
docker-compose down
```

## 📅 Example Schedules

### Standard 9-to-5
```bash
./claude-session-starter.sh --hours 9,13,17 --daemon
```
Triggers: 9 AM, 1 PM, 5 PM

### Night Owl (2 PM - Midnight)
```bash
./claude-session-starter.sh --hours 14,18,22 --daemon
```
Triggers: 2 PM, 6 PM, 10 PM

### Maximum Coverage
```bash
./claude-session-starter.sh --hours 8,11,14,17,20 --daemon
```
Triggers: Every 3 hours during active time

### Early Bird
```bash
./claude-session-starter.sh --hours 6,10,14,18 --daemon
```
Triggers: 6 AM, 10 AM, 2 PM, 6 PM

## 🔧 Configuration

**Location:** `~/.config/claude-session-starter/config`

**Example:**
```bash
HOURS="9,13,17"
```

**Edit config:**
```bash
nano ~/.config/claude-session-starter/config
# Change HOURS line
# Restart daemon if running
```

## 🏃 Run as System Service

**Install:**
```bash
# Edit service file first (update User and paths)
nano claude-session-starter.service

# Install
sudo cp claude-session-starter.service /etc/systemd/system/
sudo systemctl daemon-reload
sudo systemctl enable claude-session-starter
sudo systemctl start claude-session-starter
```

**Manage:**
```bash
# Check status
sudo systemctl status claude-session-starter

# View logs
sudo journalctl -u claude-session-starter -f

# Restart
sudo systemctl restart claude-session-starter

# Stop
sudo systemctl stop claude-session-starter
```

## 📊 How It Works

```
Every minute:
├─ Check current hour
├─ If hour matches config (e.g., 9, 13, or 17)
│  ├─ Run: claude --print "ping"
│  ├─ Triggers Claude Pro session
│  └─ Mark hour as triggered (prevents duplicates)
└─ Sleep 60 seconds, repeat
```

## 💡 Tips

1. **Start with 3-4 triggers** during your productive hours
2. **Check logs regularly** to verify triggers are working
3. **Adjust based on your schedule** - change hours anytime
4. **No cost** - uses your Pro/Max subscription
5. **Works anywhere** - respects your timezone

## 🐛 Troubleshooting

### Script not triggering?
```bash
# Check if running
ps aux | grep claude-session-starter

# View logs
./claude-session-starter.sh --log

# Test manually at current hour
./claude-session-starter.sh --hours $(date +%H | sed 's/^0//)')
```

### Claude CLI issues?
```bash
# Test CLI
claude "test"

# Re-authenticate
claude

# Check credentials
ls -la ~/.claude/.credentials.json
```

### Docker not working?
```bash
# Check container logs
docker logs claude-session-starter

# Check if Claude CLI is in container
docker exec -it claude-session-starter which claude

# Check authentication in container
docker exec -it claude-session-starter ls -la /root/.claude/

# Access container shell
docker exec -it claude-session-starter bash
```

### Config issues?
```bash
# View current config
cat ~/.config/claude-session-starter/config

# View logs
cat ~/.config/claude-session-starter/session.log

# Check state
cat ~/.config/claude-session-starter/state
```

## 📁 File Locations

**Local installation:**
- Config: `~/.config/claude-session-starter/config`
- Logs: `~/.config/claude-session-starter/session.log`
- State: `~/.config/claude-session-starter/state`
- Claude credentials: `~/.claude/.credentials.json`

**Docker:**
- Config: `/root/.config/claude-session-starter/` (in container)
- Claude credentials: `/root/.claude/` (in container)
- Volumes: `claude-data` and `session-config`

## ⚙️ Advanced

### Change hours on the fly
```bash
# Edit config
nano ~/.config/claude-session-starter/config

# If daemon is running, restart it
pkill -f claude-session-starter.sh
nohup ./claude-session-starter.sh --daemon > /dev/null 2>&1 &
```

### Run via cron instead of daemon
```bash
crontab -e

# Add this line:
0 * * * * /path/to/claude-session-starter.sh --cron
```

### Multiple schedules (different projects)
```bash
# Use different config directories
export CONFIG_DIR=~/.config/project1
./claude-session-starter.sh --hours 9,13,17 --daemon &

export CONFIG_DIR=~/.config/project2
./claude-session-starter.sh --hours 10,15,20 --daemon &
```

## 🎯 Next Steps

1. ✅ Make sure Claude CLI is authenticated
2. ✅ Run `./claude-session-starter.sh --setup`
3. ✅ Start daemon: `nohup ./claude-session-starter.sh --daemon &`
4. ✅ Check logs after first trigger
5. ✅ Adjust hours if needed

---

**Enjoy fresh Claude sessions when YOU need them!** 🚀
