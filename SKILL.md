---
name: minecraft-server
description: Operate the user's local vanilla Minecraft server (version 1.26.2, running from /home/gaurav, port 25565). Use this whenever the user asks to start, stop, restart, or check the status of their Minecraft server, wants to know why it crashed or why someone can't connect, wants to read its logs, or wants to change server.properties settings like motd, difficulty, whitelist, or max-players. Trigger on phrases like "is my minecraft server up", "start the minecraft server", "the server crashed", "can't connect to my minecraft server", "add someone to the whitelist", or "change the server MOTD" -- even if the user doesn't name this skill directly or say "Minecraft server" verbatim.
---

# Minecraft server operations

This skill operates one specific, already-configured vanilla Minecraft server on
this machine. It is not a general Minecraft tutorial -- there is nothing to install
or download here, just a server to run and maintain.

## Layout

Everything lives directly in `/home/gaurav`:

| Path | Purpose |
|---|---|
| `server.jar` | The vanilla server, version 1.26.2 |
| `server.properties` | Server config (motd, difficulty, whitelist, etc.) |
| `eula.txt` | Mojang EULA acceptance flag -- see gate below |
| `libraries/`, `versions/26.2/` | Server dependencies, do not touch |
| `logs/` | One `run_<unix-timestamp>.log` per launch, plus `latest.log` |
| `world/` | World save data (created on first successful boot) |

The server is launched with:
```
java -Xmx4G -Xms4G -jar server.jar nogui
```

## Scripts

Use the bundled scripts rather than retyping these commands -- they encode the
checks (already running? EULA accepted? did it actually come up cleanly?) that are
easy to skip when typing commands ad hoc:

- `scripts/status.sh` -- is it running, is it listening on 25565, tail of the latest log
- `scripts/start.sh` -- starts it in the background via `nohup`, refuses to double-start,
  refuses to run if the EULA gate isn't satisfied (see below), waits for "Done" in the
  log before reporting success, and surfaces the log tail if it fails or crashes
- `scripts/stop.sh` -- sends `SIGTERM` to the java process and waits for it to exit

Always run `status.sh` first when asked to do anything with the server -- it tells you
whether you're dealing with "already running", "crashed", or "never started", which
determines what to do next and what to tell the user.

## The EULA gate -- do not bypass this

`start.sh` will refuse to launch the server unless `eula.txt` contains `eula=true`.
This is intentional and mirrors a real legal step: running a Minecraft server requires
accepting Mojang's EULA (https://aka.ms/MinecraftEULA), and that's the user's decision
to make, not something to wave through on their behalf just because it's blocking a task.

If `status.sh` or `start.sh` shows `eula=false`:
1. Tell the user the server needs the EULA accepted before it can run, and link
   https://aka.ms/MinecraftEULA.
2. Ask them to explicitly confirm they accept it.
3. Only after they say yes, edit `eula.txt` to set `eula=true`, then run `start.sh`.

Never flip `eula=true` preemptively "to save a round trip" -- treat it the same as any
other action that requires the user's explicit go-ahead.

## Diagnosing problems

When the user reports the server is down, crashed, or unreachable, read the most
recent `logs/run_*.log` (or ask `status.sh` to show its tail) before guessing. Common
patterns:

- `NoSuchFileException: server.properties` at the very top of a log, immediately
  followed by the process exiting -- usually means it was launched from the wrong
  working directory. It should always be launched from `/home/gaurav`.
- A stack trace mentioning `Exception` partway through startup -- read the exception
  type and message, don't just note that a exception occurred.
- Log ends cleanly with `Done (...)!` but the port isn't listening -- rare; wait a
  couple seconds and recheck with `status.sh`, `ss` output can lag slightly behind the
  log line.
- Nothing wrong in the log at all, but a specific player can't join -- check
  `online-mode`, `white-list`, and `max-players` in `server.properties` rather than
  assuming the server itself is broken.

## Editing server.properties

Common asks and the relevant keys:

- MOTD (the message shown in the server list): `motd`
- Difficulty: `difficulty` (`peaceful` / `easy` / `normal` / `hard`)
- Whitelist: `white-list` (`true`/`false`) -- also need to add names via the running
  server's `whitelist add <name>` console command, or a `whitelist.json` file; editing
  `server.properties` alone only turns enforcement on/off
- Player cap: `max-players`
- Game mode: `gamemode` (`survival` / `creative` / `adventure` / `spectator`)
- PvP: `pvp`

Changes to `server.properties` only take effect on the *next* boot. If the server is
currently running, tell the user the change needs a restart (via `stop.sh` then
`start.sh`) to apply, and confirm they want to restart now versus later -- a restart
kicks any connected players.

## Stopping

Always use `stop.sh` (SIGTERM), never `kill -9` and never `pkill java` (that would
also kill unrelated Java processes on the machine). SIGTERM lets the server's shutdown
hook save all dimensions and close the world file cleanly; `kill -9` skips that and
risks corrupting whatever chunk was mid-write.
