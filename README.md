# minecraft-server

A [Claude Code](https://claude.com/claude-code) skill for operating a specific local
vanilla Minecraft server: checking status, starting/stopping it safely, diagnosing
connection problems from logs, and editing `server.properties`.

It's written for one particular server layout (files directly under a home directory,
launched with `java -Xmx4G -Xms4G -jar server.jar nogui`), but the structure and the
bundled scripts (`scripts/start.sh`, `scripts/stop.sh`, `scripts/status.sh`) should
adapt easily to a similar setup — adjust the paths and launch command in `SKILL.md`
and the scripts to match your own server.

## Install

Copy this directory into `~/.claude/skills/`:

```bash
git clone https://github.com/rangan39/minecraft-server-skill.git ~/.claude/skills/minecraft-server
chmod +x ~/.claude/skills/minecraft-server/scripts/*.sh
```

Then adjust the paths in `SKILL.md` and `scripts/*.sh` to point at your own server's
directory and launch command.

## What it covers

- Checking whether the server is running and listening on its port
- Starting it in the background, refusing to double-start or to bypass the Mojang
  EULA gate without the user's explicit go-ahead
- Stopping it gracefully (`SIGTERM`, never `kill -9`)
- Diagnosing common "it's down" / "my friend can't connect" failure patterns from logs
- Editing `server.properties` (MOTD, difficulty, whitelist, max players, etc.)
