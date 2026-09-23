# herdr config

My [herdr](https://herdr.dev) setup — keybindings mirrored from my tmux/nvim muscle
memory, pinned plugins, and the Claude Code session hook. Lives at `~/.config/herdr`.

## New machine

```bash
# herdr not yet run (no ~/.config/herdr):
git clone git@github.com:anderdc/herdr.git ~/.config/herdr

# herdr already ran (dir exists with runtime state):
cd ~/.config/herdr && git init -b main \
  && git remote add origin git@github.com:anderdc/herdr.git \
  && git fetch origin && git checkout -f -t origin/main

herdr server reload-config   # or just start herdr
./install-plugins.sh         # see Plugins below
```

## Plugins

`plugins.txt` is the source of truth: one `owner/repo@commit` per line, pinned to the
commit tested here. `./install-plugins.sh` installs anything missing at that commit
(skips what's already there) and reloads herdr. The installed code, build output and
`plugins.json` registry under `plugins/` are machine-local and gitignored.

Prerequisites: `go` (auto-title builds from source; `mise use -g go@latest`), `curl`,
`jq`.

| Plugin | What it does | Extra setup |
|---|---|---|
| [vim-herdr-navigation](https://github.com/paulbkim-dev/vim-herdr-navigation) | `ctrl+h/j/k/l` moves between nvim splits, then crosses into herdr panes at the edge | Binds live in `config.toml` (`[[keys.command]]`). nvim side is in my nvim config (`lua/ander/plugins/init.lua` loads the plugin's `editor/nvim.lua`) |
| [herdr-auto-title](https://github.com/kryptamine/herdr-auto-title) | Tab titles follow what each tab is doing | Needs `herdr integration install claude` current (see below). Settings in `auto-title-config.env` here, symlinked by `install-plugins.sh` to `~/.config/herdr-auto-title/config.env`: 28-column titles, no `claude ›` prefix (the sidebar shows the vendor), no position prefix (it is counted against the 28, and the sidebar already prefixes the workspace name) |
| [herdr-mirror](https://github.com/nikok6/herdr-mirror) | Mirrors remote herdr servers into the local sidebar over ssh | `~/.config/herdr-mirror/hosts.toml`, **kept out of this repo** (public). One `[hosts.<name>]` block per remote with `target = "<ssh alias>"`. Needs passwordless ssh: `ssh -o BatchMode=yes <host> true` |
| [herdr-lazygit](https://github.com/Crokily/herdr-lazygit) | lazygit in a 42-col sidebar pane; `C` writes an AI commit message, `U` expands to the full layout | Binds in `config.toml`: `prefix+g` sidebar, `prefix+alt+g` own tab (the documented `prefix+shift+g` stays herdr's `new_worktree`). Needs `lazygit`. Remote note: `[[keys.command]]` binds don't apply with `herdr --remote` unless you attach with `--remote-keybindings server` |

**Gotcha:** a plugin with a background process (auto-title) does not start from
`herdr server reload-config` — its `startup` command runs when the herdr *server* starts. After
installing mid-session, run its restart action once:
`herdr plugin action invoke herdr.auto-title.restart`.

Updating: `herdr plugin update <id>`, check it works, then bump the commit in
`plugins.txt` (`herdr plugin list` prints the new one).

## Claude Code session hook (required, lives outside this repo)

Install the session-identity hook, which registers in `~/.claude/settings.json`:

```bash
herdr integration install claude   # verify: herdr integration status → "claude: current"
```

It is what gives a pane an `agent_session` (`herdr pane current` →
`"source": "herdr:claude"`). Without it herdr can see a `claude` process but not
which session it is, so auto-title has nothing to name the tab after.

### No longer needed: the `claude()` shell wrapper

Claude Code's **native** installer runs a versioned binary
(`~/.local/share/claude/versions/N`), whose process name is the version number,
so herdr's process-name detection never saw `claude` and panes stayed `unknown`.
The workaround was a `~/.bashrc`/`~/.zshrc` wrapper exporting `HERDR_AGENT=claude`.

This machine installs Claude through mise
(`~/.local/share/mise/installs/claude/<version>/claude`), so the process really
is named `claude` and detection works unaided — `HERDR_AGENT` is unset here and
`herdr pane current` still reports `"agent": "claude"`. The wrapper is gone from
both rc files. Put it back only on a machine using the native installer.

## Remote machines (`herdr --remote`)

Core herdr, not a plugin: `herdr --remote <ssh-target>` attaches to a herdr
server running on another box over SSH. **Nothing in this repo is needed for
it**, and it has nothing to do with herdr-mirror's `hosts.toml` — that file is
only for mirroring remote servers into the local sidebar.

```bash
herdr --remote ventura                   # attach
herdr --remote ventura --session work    # a named persistent session there
```

What it needs:

- herdr installed locally (https://herdr.dev).
- Working SSH to the box: `ssh <target> true`. `ventura` is an alias in my
  `~/.ssh/config`, not something this repo ships — use your own host or alias.
- herdr on the remote, which you do **not** install by hand: herdr prepares the
  remote installation on first connect, and an incompatible or missing one needs
  approval in an interactive terminal.

To keep a box in the sidebar instead of retyping the target:

```bash
herdr machine add <ssh-target> --label ventura
herdr machine list
```

Saved machines hold only a label, SSH target, session name and enabled state —
credentials stay with OpenSSH.

A saved machine shows up in the local sidebar next to Local. A workspace created
while it is selected (or with `herdr --machine ventura workspace create`) lives
on the **remote** server, so it keeps running after the local client closes or
the laptop shuts down, and it is there again on the next `herdr`.

Gotchas:

- You attach to the **remote's** server, so its `config.toml` and its plugins
  are what run there.
- `[[keys.command]]` binds (ctrl+hjkl navigation, `prefix+g` lazygit) are
  local-client binds and do not apply over `--remote` unless you attach with
  `--remote-keybindings server`, which uses the remote's config instead.
- Two people attaching as the same remote user land in the same session. Give
  each person their own `--session <name>` if that is not what you want.

### Keeping the remote server up across reboots

The remote server outlives SSH disconnects on its own, as long as logind's
`KillUserProcesses` is `no`, which is the Debian default. It does **not** come back
after the box reboots unless systemd starts it. One-time setup on the remote:

```bash
sudo loginctl enable-linger $USER          # user manager runs without a login
mkdir -p ~/.config/systemd/user
# write ~/.config/systemd/user/herdr.service (below), then:
systemctl --user daemon-reload
systemctl --user enable herdr.service      # enable, not --now: see gotcha
```

```ini
[Unit]
Description=herdr server (default session)
After=network-online.target

[Service]
Type=simple
ExecStart=%h/.local/bin/herdr server
WorkingDirectory=%h
Environment=PATH=%h/.local/bin:/usr/local/bin:/usr/bin:/bin
Environment=SHELL=/bin/bash
Restart=on-failure
RestartSec=5

[Install]
WantedBy=default.target
```

`herdr server` runs in the foreground, so `Type=simple` is right. The `PATH` line
matters because systemd's environment lacks `~/.local/bin`, and the panes inherit
it.

Gotchas:

- If a herdr server is already running (one started by a client attach),
  starting the unit too would put two servers on the same session socket (not
  tested). Enable the unit and let the next reboot hand the server over to
  systemd. The other way is `herdr server stop` and then `start`, but that kills
  every pane.
- `systemctl --user` over Tailscale SSH fails with `Failed to lookup
  RuntimeDirectory path` because the session has no `XDG_RUNTIME_DIR`. Set it
  first with `export XDG_RUNTIME_DIR=/run/user/$(id -u)`.

## Keybinding cheat sheet (prefix = ctrl+a)

| Keys | Action |
|---|---|
| `c` | new space (workspace) |
| `t` / `x` / `shift+x` | new tab / close tab / close pane |
| `n` / `p` / `1..9` | next / prev / jump tab (the tab bar no longer prints the number — auto-title's position prefix is off) |
| `w` then `j`/`k` | flip spaces (vim style) |
| `\|` / `-` | split side-by-side / stacked |
| `h j k l` | resize pane |
| `ctrl+h/j/k/l` (no prefix) | move across nvim splits and herdr panes (vim-herdr-navigation plugin) |
| `m` | zoom pane |
| `b` | toggle sidebar |
| `d` | detach |
| `r` | reload this config |
| `g` / `alt+g` | lazygit sidebar / lazygit in its own tab (plugin) |
