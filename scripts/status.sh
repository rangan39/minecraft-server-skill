#!/usr/bin/env bash
# Reports whether the local vanilla Minecraft server is running and listening.
SERVER_DIR="/home/gaurav"
PID=$(pgrep -f "^java -Xmx4G -Xms4G -jar server.jar nogui$" || true)

if [ -z "$PID" ]; then
  echo "Server: NOT RUNNING"
  exit 0
fi

echo "Server: RUNNING (PID $PID)"

if command -v ss >/dev/null 2>&1; then
  if ss -tlnp 2>/dev/null | grep -q ":25565 "; then
    echo "Port 25565: LISTENING"
  else
    echo "Port 25565: NOT LISTENING YET (still booting, or crashed after fork)"
  fi
fi

LATEST_LOG=$(ls -t "${SERVER_DIR}"/logs/run_*.log 2>/dev/null | head -1)
if [ -n "$LATEST_LOG" ]; then
  echo "--- last 10 lines of $LATEST_LOG ---"
  tail -10 "$LATEST_LOG"
fi
