#!/usr/bin/env bash
# Starts the local vanilla Minecraft server in the background, if it isn't already running.
# Refuses to start if eula.txt hasn't been accepted -- Claude must get the user's
# explicit go-ahead in chat before ever flipping that file to eula=true.
set -uo pipefail
SERVER_DIR="/home/gaurav"
cd "$SERVER_DIR" || exit 1

EXISTING_PID=$(pgrep -f "^java -Xmx4G -Xms4G -jar server.jar nogui$" || true)
if [ -n "$EXISTING_PID" ]; then
  echo "Server already running (PID $EXISTING_PID). Not starting a second instance."
  exit 0
fi

if ! grep -q "^eula=true" eula.txt 2>/dev/null; then
  echo "ERROR: eula.txt does not have eula=true." >&2
  echo "Do not edit this yourself -- ask the user in chat whether they accept Mojang's EULA" >&2
  echo "(https://aka.ms/MinecraftEULA) before setting eula=true and retrying." >&2
  exit 1
fi

mkdir -p logs
LOGFILE="logs/run_$(date +%s).log"
nohup java -Xmx4G -Xms4G -jar server.jar nogui > "$LOGFILE" 2>&1 &
PID=$!
echo "Started server, PID $PID, logging to $LOGFILE"

for _ in $(seq 1 60); do
  sleep 1
  if grep -q "Done (" "$LOGFILE" 2>/dev/null; then
    echo "Server is up and listening on port 25565."
    exit 0
  fi
  if ! kill -0 "$PID" 2>/dev/null; then
    echo "Server process exited unexpectedly. Log:" >&2
    tail -40 "$LOGFILE" >&2
    exit 1
  fi
  if grep -qiE "exception|failed to load|error" "$LOGFILE" 2>/dev/null; then
    echo "Server logged an error while starting. Log:" >&2
    tail -40 "$LOGFILE" >&2
    exit 1
  fi
done

echo "Server did not report ready within 60s. Check $LOGFILE for details." >&2
exit 1
