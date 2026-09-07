#!/usr/bin/env bash
# Gracefully stops the local Minecraft server (SIGTERM, never -9).
# The server's own shutdown hook saves the world and closes it cleanly on SIGTERM;
# kill -9 skips that hook and risks corrupting in-progress chunk writes.
set -uo pipefail
SERVER_DIR="/home/gaurav"
PID=$(pgrep -f "^java -Xmx4G -Xms4G -jar server.jar nogui$" || true)

if [ -z "$PID" ]; then
  echo "Server is not running."
  exit 0
fi

echo "Sending SIGTERM to PID $PID (graceful shutdown, saves the world)..."
kill -TERM "$PID"

for _ in $(seq 1 60); do
  sleep 1
  if ! kill -0 "$PID" 2>/dev/null; then
    echo "Server stopped."
    exit 0
  fi
done

echo "Server did not stop within 60s." >&2
echo "It may still be saving a large world -- check again before considering anything stronger than SIGTERM." >&2
exit 1
