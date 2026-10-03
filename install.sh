#!/usr/bin/env bash
# Install skills-sync onto this account, merge the sources manifest, run one sync,
# then enable the daily timer only after that sync succeeds.
set -euo pipefail

ROOT=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
PREFIX=${SKILLS_SYNC_PREFIX:-$HOME}
BIN="$PREFIX/.local/bin"
CFG="$PREFIX/.config/skills-sync"
UNIT_DIR="$PREFIX/.config/systemd/user"

log() { printf 'skills-sync-install %s\n' "$*"; }
die() { log "error: $*"; exit 1; }

for bin in bash git curl jq flock python3 tar sha256sum node npm; do
  command -v "$bin" >/dev/null || die "missing: $bin"
done

install -d -m 0755 "$BIN" "$CFG" "$UNIT_DIR" "$PREFIX/.cursor/rules" "$PREFIX/.agents/skills"
install -m 0755 "$ROOT/scripts/skills-sync" "$BIN/skills-sync"
install -m 0644 "$ROOT/scripts/skills-sync-integrations.sh" "$BIN/skills-sync-integrations.sh"
install -m 0644 "$ROOT/config/skills-sync/skills-sync.service" "$UNIT_DIR/skills-sync.service"
install -m 0644 "$ROOT/config/skills-sync/skills-sync.timer" "$UNIT_DIR/skills-sync.timer"
install -m 0644 "$ROOT/config/skills-sync/workflow-routing.mdc" "$CFG/workflow-routing.mdc"

merge_sources() {
  local supplied=$1 dest=$2 tmp line url dir selector extra have
  tmp=$(mktemp)
  if [[ ! -f $dest ]]; then
    install -m 0644 "$supplied" "$dest"
    rm -f "$tmp"
    return 0
  fi
  : > "$tmp"
  while IFS=$'\t' read -r url dir selector extra || [[ -n ${url:-} ]]; do
    [[ -z ${url:-} || $url == \#* ]] && { printf '%s\n' "${url:-}" >> "$tmp"; continue; }
    if [[ -z ${dir:-} ]]; then die "existing sources record missing clone dir"; fi
    if [[ -z ${selector:-} ]]; then selector='*'; fi
    if [[ -n ${extra:-} ]]; then die "existing sources record has extra fields: $url"; fi
    printf '%s\t%s\t%s\n' "$url" "$dir" "$selector" >> "$tmp"
  done < "$dest"
  while IFS=$'\t' read -r url dir selector extra || [[ -n ${url:-} ]]; do
    [[ -z ${url:-} || $url == \#* ]] && continue
    [[ -z ${dir:-} || -z ${selector:-} || -n ${extra:-} ]] && die "supplied sources record is not three fields: $url"
    have=0
    while IFS=$'\t' read -r eurl edir esel; do
      [[ $eurl == "$url" ]] && { have=1; break; }
    done < "$tmp"
    if (( have == 0 )); then
      printf '%s\t%s\t%s\n' "$url" "$dir" "$selector" >> "$tmp"
    fi
  done < "$supplied"
  install -m 0644 "$tmp" "$dest"
  rm -f "$tmp"
}

merge_sources "$ROOT/config/skills-sync/sources" "$CFG/sources"

export HOME="$PREFIX"
"$BIN/skills-sync"

if command -v systemctl >/dev/null && systemctl --user is-system-running >/dev/null 2>&1; then
  systemctl --user daemon-reload
  systemctl --user enable --now skills-sync.timer
  log "timer enabled"
else
  log "skip timer: systemd user manager not available"
fi
log "ok"
