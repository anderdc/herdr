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
```

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
| `ctrl+h/j/k/l` (no prefix) | focus pane (vim-tmux-navigator style) |
| `m` | zoom pane |
| `b` | toggle sidebar |
| `d` | detach |
| `r` | reload this config |
