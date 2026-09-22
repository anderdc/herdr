# herdr config

My [herdr](https://herdr.dev) setup — keybindings mirrored from my tmux/nvim muscle
memory, plus the Claude Code detection fix. Lives at `~/.config/herdr`.

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
| [herdr-auto-title](https://github.com/kryptamine/herdr-auto-title) | Tab titles follow what each tab is doing | Needs `herdr integration install claude` current (see below). Optional `~/.config/herdr-auto-title/config.env` |
| [herdr-mirror](https://github.com/nikok6/herdr-mirror) | Mirrors remote herdr servers into the local sidebar over ssh | `~/.config/herdr-mirror/hosts.toml`, **kept out of this repo** (public). One `[hosts.<name>]` block per remote with `target = "<ssh alias>"`. Needs passwordless ssh: `ssh -o BatchMode=yes <host> true` |
| [herdr-lazygit](https://github.com/Crokily/herdr-lazygit) | lazygit in a 42-col sidebar pane; `C` writes an AI commit message, `U` expands to the full layout | Binds in `config.toml`: `prefix+g` sidebar, `prefix+alt+g` own tab (the documented `prefix+shift+g` stays herdr's `new_worktree`). Needs `lazygit`. Remote note: `[[keys.command]]` binds don't apply with `herdr --remote` unless you attach with `--remote-keybindings server` |

**Gotcha:** a plugin with a background process (auto-title) does not start from
`herdr server reload-config` — its `startup` command runs when the herdr *server* starts. After
installing mid-session, run its restart action once:
`herdr plugin action invoke herdr.auto-title.restart`.

Updating: `herdr plugin update <id>`, check it works, then bump the commit in
`plugins.txt` (`herdr plugin list` prints the new one).

## Claude Code detection fix (required, lives outside this repo)

Claude Code's native installer runs a versioned binary
(`~/.local/share/claude/versions/N`), so herdr's process-name detection never
sees "claude" and panes stay `unknown` / missing from Agents. Add to
`~/.bashrc` **and** `~/.zshrc`:

```bash
# herdr: Claude Code's native installer runs a versioned binary (~/.local/share/claude/versions/N),
# so herdr's process-name detection can't identify it. HERDR_AGENT hints the manifest to apply.
claude() { HERDR_AGENT=claude command claude "$@"; }
```

Then install the session-identity hook (registers in `~/.claude/settings.json`):

```bash
herdr integration install claude   # verify: herdr integration status → "claude: current"
```

## Keybinding cheat sheet (prefix = ctrl+a)

| Keys | Action |
|---|---|
| `c` | new space (workspace) |
| `t` / `x` / `shift+x` | new tab / close tab / close pane |
| `n` / `p` / `1..9` | next / prev / jump tab |
| `w` then `j`/`k` | flip spaces (vim style) |
| `\|` / `-` | split side-by-side / stacked |
| `h j k l` | resize pane |
| `ctrl+h/j/k/l` (no prefix) | move across nvim splits and herdr panes (vim-herdr-navigation plugin) |
| `m` | zoom pane |
| `b` | toggle sidebar |
| `d` | detach |
| `r` | reload this config |
| `g` / `alt+g` | lazygit sidebar / lazygit in its own tab (plugin) |
