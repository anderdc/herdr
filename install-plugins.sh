#!/usr/bin/env bash
# Install every plugin in plugins.txt at its pinned commit, then reload herdr.
# Needs: go (herdr-auto-title builds from source), curl (herdr-mirror downloads a release),
# jq (vim-herdr-navigation detects vim panes with it).
set -euo pipefail
cd "$(dirname "$0")"

# "owner/repo@commit" for every installed github plugin
installed=$(herdr plugin list --json | jq -r '.result.plugins[].source | select(.kind == "github") | "\(.owner)/\(.repo)@\(.resolved_commit)"')

grep -vE '^\s*(#|$)' plugins.txt | while IFS='@' read -r repo ref; do
  if grep -qxF "${repo}@${ref}" <<<"$installed"; then
    echo "ok       ${repo}@${ref:0:7}"
    continue
  fi
  echo "install  ${repo}@${ref:0:7}"
  herdr plugin install "$repo" --ref "$ref" --yes
done

herdr server reload-config
herdr plugin list
