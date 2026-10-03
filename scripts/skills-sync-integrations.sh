# Managed optional integrations; sourced by scripts/skills-sync.
SCRIPT_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
DEPLOY_ROOT="$HOME/.local/share/skills-sync/deployments"

publish_deployment() {
  local candidate=$1 active=$2 root=$3 id=$4 gen tmp marker
  gen="$root/$id"
  mkdir -p "$root" "$(dirname "$active")"
  if [[ -e $gen || -L $gen ]]; then
    [[ -f $gen/.skills-sync-owned ]] || { log "error: unmanaged deployment generation: $gen" >&2; return 1; }
  else
    tmp="$root/.stage.$$.$RANDOM"
    mkdir -p "$tmp" || return 1
    cp -a "$candidate"/. "$tmp"/ || { rm -rf "$tmp"; return 1; }
    : > "$tmp/.skills-sync-owned"
    mv "$tmp" "$gen" || { rm -rf "$tmp"; return 1; }
  fi
  if [[ -e $active && ! -L $active ]]; then log "error: unmanaged deployment destination: $active" >&2; return 1; fi
  if [[ -L $active ]]; then
    marker=$(readlink "$active") || return 1
    [[ $marker == "$root"/* && -f $active/.skills-sync-owned ]] || { log "error: unmanaged deployment link: $active" >&2; return 1; }
  fi
  tmp="$(dirname "$active")/.skills-sync-link.$$.$RANDOM"
  ln -s -- "$gen" "$tmp" || return 1
  mv -Tf "$tmp" "$active" || { rm -f "$tmp"; return 1; }
}

configure_omp_shared_skills() {
  have omp || { log "skip omp provider: omp not on PATH"; return 0; }
  local value providers setting
  value=$(omp config get enabledProviders --json) || return 1
  providers=$(jq -ce '.value | select(type == "array")' <<< "$value") || return 1
  if ! jq -e 'index("agents") != null' <<< "$providers" >/dev/null; then
    providers=$(jq -c '. + ["agents"]' <<< "$providers") || return 1
    omp config set enabledProviders "$providers" || return 1
  fi
  for setting in skills.enabled skills.enableSkillCommands; do
    value=$(omp config get "$setting" --json 2>/dev/null) || continue
    if jq -e '.value == false' <<< "$value" >/dev/null; then log "error: OMP setting $setting disables shared skills; preserving user setting" >&2; return 1; fi
  done
}

cleanup_cursor_mirrors() {
  local src dest name failed=0 resolved
  for src in "$HUB"/*; do
    [[ -e $src || -L $src ]] || continue
    name=$(basename "$src"); dest="$HOME/.cursor/skills/$name"
    resolved=$(readlink -f "$src" 2>/dev/null || true)
    if [[ $(readlink "$dest") == "$src" || ( -n $resolved && $(readlink -f "$dest" 2>/dev/null || true) == "$resolved" ) ]]; then rm "$dest" || failed=1; fi
  done
  return "$failed"
}

install_cursor_routing() {
  have cursor-agent || have cursor || { log "skip Cursor routing: Cursor binary not on PATH"; return 0; }
   local dest="$HOME/.cursor/rules/workflow-routing.mdc" src="$HOME/.config/skills-sync/workflow-routing.mdc" model="$HOME/.cursor/rules/pstack-models.mdc"
  mkdir -p "$HOME/.cursor/rules"
  if [[ -e $dest ]] && ! cmp -s "$src" "$dest"; then log "error: unmanaged Cursor routing rule: $dest" >&2; return 1; fi
  install -m 0644 "$src" "$dest" || return 1
  if [[ -f $model ]]; then
    if ! python3 - "$model" <<'PY'
import pathlib, re, sys
p=pathlib.Path(sys.argv[1]); b=p.read_bytes(); m=re.match(rb'\A---\r?\n(.*?)\r?\n---\r?\n', b, re.S)
if not m: raise SystemExit('malformed pstack model-rule frontmatter; leaving file unchanged')
head=m.group(1).decode(); lines=[x for x in head.splitlines() if not re.match(r'^(description|globs|alwaysApply):', x)]
lines.append('alwaysApply: false')
p.write_bytes(b'---\n'+('\n'.join(lines)).encode()+b'\n---\n'+b[m.end():])
PY
    then return 1; fi
  fi
}


skills_sync_script_hash() {
  sha256sum "${BASH_SOURCE[0]%/*}/skills-sync" | awk 'NR==1 {print $1}'
}

ui_ux_pro_max_current() {
  local prefix="$HOME/.local/share/skills-sync/uipro" pkg ver latest script_hash id link
  pkg="$prefix/node_modules/ui-ux-pro-max-cli/package.json"
  [[ -f $pkg ]] || return 1
  ver=$(node -p "require('$pkg').version" 2>/dev/null) || return 1
  latest=$(npm view ui-ux-pro-max-cli version 2>/dev/null) || return 1
  latest=${latest//[[:space:]]/}
  [[ -n $ver && $ver == "$latest" ]] || return 1
  script_hash=$(skills_sync_script_hash) || return 1
  id="$ver-$script_hash"
  link=$(readlink "$HUB/ui-ux-pro-max" 2>/dev/null || true)
  [[ $link == "$DEPLOY_ROOT/ui-ux-pro-max/$id" && -f $DEPLOY_ROOT/ui-ux-pro-max/$id/.skills-sync-owned ]]
}

sync_ui_ux_pro_max() {
  have npm && have node || { log "error: Node.js and npm are required for UI UX Pro Max" >&2; return 1; }
  have python3 || return 1
  if ui_ux_pro_max_current; then log "skip UI UX Pro Max already current"; return 0; fi
  local prefix="$HOME/.local/share/skills-sync/uipro" stage cli pkgver script_hash id candidate
  mkdir -p "$prefix" || return 1
  npm install --prefix "$prefix" --ignore-scripts --no-audit --no-fund ui-ux-pro-max-cli@latest || return 1
  cli="$prefix/node_modules/ui-ux-pro-max-cli/dist/index.js"
  [[ -f $cli ]] || { log "error: UI UX Pro Max CLI entry missing: $cli" >&2; return 1; }
  stage=$(mktemp -d) || return 1
  if ! HOME="$stage" node "$cli" init --ai universal --global --force >/dev/null; then
    if ! (cd "$stage" && HOME="$stage" node "$cli" init --ai universal --force >/dev/null); then rm -rf "$stage"; log "error: installed CLI lacks complete universal generation" >&2; return 1; fi
    candidate="$stage/.agents/skills/ui-ux-pro-max"
    [[ -d $candidate ]] || { rm -rf "$stage"; return 1; }
    python3 -c 'import pathlib,sys; root=pathlib.Path(sys.argv[1]); [p.write_text(p.read_text().replace(".agents/skills/ui-ux-pro-max/scripts/search.py", "~/.agents/skills/ui-ux-pro-max/scripts/search.py")) for p in root.rglob("SKILL.md")]' "$candidate" || { rm -rf "$stage"; return 1; }
  else candidate="$stage/.agents/skills/ui-ux-pro-max"; fi
  [[ -f $candidate/SKILL.md && -f $candidate/scripts/search.py ]] || { rm -rf "$stage"; log "error: complete UI UX Pro Max assets missing" >&2; return 1; }
  if ! python3 - "$candidate/SKILL.md" <<'PY'
import pathlib,re,sys
p=pathlib.Path(sys.argv[1]); s=p.read_text(); m=re.match(r'\A---\n(.*?)\n---\n',s,re.S)
if not m: raise SystemExit('malformed UI UX Pro Max frontmatter')
h=m.group(1); d='Use for UI/UX research and validation: accessibility, layout, typography, colors, interactions, and stack-specific guidance; run local searches on demand.'
h2=re.sub(r'(?m)^description:.*$', 'description: '+d, h)
if h2==h: raise SystemExit('missing UI UX Pro Max description field')
p.write_text('---\n'+h2+'\n---\n'+s[m.end():])
PY
  then rm -rf "$stage"; return 1; fi
  (cd /tmp && python3 "$candidate/scripts/search.py" 'beauty spa wellness' --design-system -p 'Serenity Spa' >/dev/null) || { rm -rf "$stage"; return 1; }
  pkgver=$(node -p "require('$prefix/node_modules/ui-ux-pro-max-cli/package.json').version") || { rm -rf "$stage"; return 1; }
  script_hash=$(sha256sum "${BASH_SOURCE[0]%/*}/skills-sync" | cut -d' ' -f1) || { rm -rf "$stage"; return 1; }
  id="$pkgver-$script_hash"
  publish_deployment "$candidate" "$HUB/ui-ux-pro-max" "$DEPLOY_ROOT/ui-ux-pro-max" "$id" || { rm -rf "$stage"; return 1; }
  rm -rf "$stage"
  log "published UI UX Pro Max $id"
}


pstack_pi_current() {
  local src="$HOME/.local/src/oh-my-pstack" active="$HOME/.local/share/skills-sync/pstack-pi" branch commit script_hash id link
  [[ -d $src/.git && -L $active ]] || return 1
  branch=$(git -C "$src" symbolic-ref --short refs/remotes/origin/HEAD 2>/dev/null) || return 1
  branch=${branch#origin/}
  commit=$(git -C "$src" rev-parse HEAD 2>/dev/null) || return 1
  [[ $commit == "$(git -C "$src" rev-parse "refs/remotes/origin/$branch" 2>/dev/null)" ]] || return 1
  script_hash=$(skills_sync_script_hash) || return 1
  id="$commit-$script_hash"
  link=$(readlink "$active" 2>/dev/null || true)
  [[ $link == "$DEPLOY_ROOT/pstack-pi/$id" && -f $link/.skills-sync-owned ]]
}

sync_omp_pstack() {
  have omp || { log "skip pstack: omp not on PATH"; return 0; }
  have python3 || return 1
  if pstack_pi_current; then log "skip pstack-pi already current"; return 0; fi
  local url=https://github.com/JonathanPitre/oh-my-pstack.git src="$HOME/.local/src/oh-my-pstack" stage candidate commit script_hash id skilldir skillname active previous plugin_json registered registered_resolved active_resolved
  ensure_clone "$url" "$src" || return 1
  commit=$(git -C "$src" rev-parse HEAD) || return 1
  stage=$(mktemp -d) || return 1; candidate="$stage/pstack-pi"
  mkdir -p "$candidate" || { rm -rf "$stage"; return 1; }
  git -C "$src" archive "$commit" | tar -x -C "$candidate" || { rm -rf "$stage"; return 1; }
  if jq -e '((.pi.extensions // []) | length > 0) or ((.extensions // []) | length > 0) or ((.pi.hooks // []) | length > 0) or has("hooks")' "$candidate/package.json" >/dev/null 2>&1 || [[ -d $candidate/extensions || -d $candidate/hooks || -d $candidate/.pi/extensions ]]; then rm -rf "$stage"; log "error: pstack adds startup extensions or hooks" >&2; return 1; fi
  [[ -d $candidate/skills && -d $candidate/agents ]] || { rm -rf "$stage"; log "error: pstack package missing skills or agents" >&2; return 1; }
  local skillmd
  while IFS= read -r -d "" skillmd; do
    skillname=$(basename "$(dirname "$skillmd")")
    if [[ -e $HUB/$skillname || -L $HUB/$skillname ]]; then rm -rf "$stage"; log "error: pstack skill name conflicts with shared skill: $skillname" >&2; return 1; fi
  done < <(find "$candidate/skills" -type f -name SKILL.md -print0)
  plugin_json=$(omp plugin list --json) || { rm -rf "$stage"; return 1; }
  printf '%s\n' "$plugin_json" > "$stage/plugins.json"
  if ! python3 - "$candidate" "$stage/plugins.json" <<'PY'
import json,pathlib,re,sys
root=pathlib.Path(sys.argv[1]); inventory=json.loads(pathlib.Path(sys.argv[2]).read_text()); policy='''## Local invocation policy
This workflow starts only after an explicit user request for pstack, poteto-mode, or a bundled pstack skill. For that task, use the selected pstack playbook rather than starting a competing Superpowers workflow loop; Superpowers' automatic bootstrap remains installed. Bundled helpers are hidden from automatic selection. Read a helper with skill://<helper-name> or its SKILL.md in this package when the active playbook names it. Start a fresh ordinary session to return to the default workflow.
'''
skills=list((root/'skills').rglob('SKILL.md'))
if not skills: raise SystemExit('pstack contains no skills')
def skill_names(paths):
 out=set()
 for path in paths:
  m=re.match(r"\A---\r?\n(.*?)\r?\n---\r?\n",path.read_text(),re.S)
  if not m: raise SystemExit(f"malformed skill frontmatter: {path}")
  out.add(path.parent.name.lower())
  for line in m.group(1).splitlines():
   if line.startswith("name:"):
    value=line.split(":",1)[1].strip().strip("\"\'").lower()
    out.add(value); out.add(value.replace(" ","-")); break
 return out
owned_names=skill_names(skills)
for plugin in inventory.get("npm",[]):
 if plugin.get("name")=="pstack-pi": continue
 base=pathlib.Path(plugin.get("path",""))
 for rel in (plugin.get("manifest") or {}).get("skills",[]):
  skill_root=(base/rel).resolve()
  if not skill_root.exists(): continue
  for path in skill_root.rglob("SKILL.md"):
   overlaps=owned_names & skill_names([path])
   if overlaps: raise SystemExit(f"skill name conflict with OMP plugin {plugin.get('name')}: {path} ({sorted(overlaps)[0]})")
for p in skills:
 s=p.read_text(); m=re.match(r'\A---\r?\n(.*?)\r?\n---\r?\n',s,re.S)
 if not m: raise SystemExit(f'malformed skill frontmatter: {p.relative_to(root)}')
 h=[x for x in m.group(1).splitlines() if not re.match(r'^disable-model-invocation\s*:',x)]; h.append('disable-model-invocation: true')
 body=s[m.end():]
 if p.parent.name=='poteto-mode': body=policy+'\n'+body
 p.write_text('---\n'+'\n'.join(h)+'\n---\n'+body)
agents=list((root/'agents').glob('*.md'))
if not agents: raise SystemExit('pstack contains no agents')
for p in agents:
 s=p.read_text(); m=re.match(r'\A---\r?\n(.*?)\r?\n---\r?\n',s,re.S)
 if not m: raise SystemExit(f'malformed agent frontmatter: {p.relative_to(root)}')
 h=m.group(1).splitlines(); found=False
 for i,line in enumerate(h):
  if line.startswith('description:'):
   val=line[len('description:'):].lstrip()
   if not val or val.startswith('|') or val.startswith('>'): raise SystemExit(f'unsupported agent description: {p.relative_to(root)}')
   h[i]='description: '+json.dumps('Use only for a parent task explicitly using pstack. '+val,ensure_ascii=False); found=True; break
 if not found: raise SystemExit(f'missing agent description: {p.relative_to(root)}')
 p.write_text('---\n'+'\n'.join(h)+'\n---\n'+s[m.end():])
data=json.loads((root/'package.json').read_text())
if not data.get('pi',{}).get('skills'): raise SystemExit('native pi skill manifest missing')
for path in root.rglob("*"):
 if path.is_dir() and path.name.lower() in {"hooks","extensions"}: raise SystemExit(f"unsupported startup capability: {path.relative_to(root)}")
 if path.suffix==".mdc":
  text=path.read_text(); fm=re.match(r"\A---\r?\n(.*?)\r?\n---",text,re.S)
  if fm and re.search(r"(?m)^alwaysApply:\s*true\s*$",fm.group(1),re.I): raise SystemExit(f"always-applied pstack rule: {path.relative_to(root)}")
PY
  then rm -rf "$stage"; return 1; fi
  [[ -f $candidate/LICENSE && -f $candidate/THIRD_PARTY_NOTICES.md ]] || { rm -rf "$stage"; log "error: pstack license/support files missing" >&2; return 1; }
  script_hash=$(sha256sum "${BASH_SOURCE[0]%/*}/skills-sync" | cut -d' ' -f1) || { rm -rf "$stage"; return 1; }
  id="$commit-$script_hash"; active="$HOME/.local/share/skills-sync/pstack-pi"; previous=
  if [[ -L $active ]]; then previous=$(readlink "$active"); fi
  publish_deployment "$candidate" "$active" "$DEPLOY_ROOT/pstack-pi" "$id" || { rm -rf "$stage"; return 1; }
  plugin_json=$(omp plugin list --json) || { if [[ -n $previous ]]; then ln -sfn -- "$previous" "$active"; else rm -f "$active"; fi; rm -rf "$stage"; return 1; }
  if jq -e '.npm[]? | select(.name=="pstack-pi" and .enabled==true)' <<< "$plugin_json" >/dev/null; then
    registered=$(jq -r '.npm[] | select(.name=="pstack-pi" and .enabled==true) | .path' <<< "$plugin_json")
    registered_resolved=$(readlink -f "$registered" 2>/dev/null || true)
    active_resolved=$(readlink -f "$active" 2>/dev/null || true)
    if [[ $registered != "$active" && $registered != "$active_resolved" && $registered_resolved != "$active_resolved" ]]; then
      if [[ -n $previous ]]; then ln -sfn -- "$previous" "$active" || log "error: could not restore pstack active link $active" >&2; else rm -f "$active"; fi
      rm -rf "$stage"; log "error: pstack-pi registered from unmanaged path $registered" >&2; return 1
    fi
  else
    if ! omp plugin link "$active" </dev/null; then
      if [[ -n $previous ]]; then ln -sfn -- "$previous" "$active"; else rm -f "$active"; fi
      rm -rf "$stage"; return 1
    fi
  fi
  rm -rf "$stage"
  log "published and linked pstack-pi $id"
}


check_omp_layout() {
  local failed=0 value providers setting path resolved canonical active active_resolved hub_link
  have omp || { log "error: omp is required for --check" >&2; return 1; }
  have jq || { log "error: jq is required for --check" >&2; return 1; }
  value=$(omp config get enabledProviders --json) || { log "error: cannot read enabledProviders" >&2; return 1; }
  providers=$(jq -ce '.value | select(type == "array")' <<< "$value") || { log "error: enabledProviders is not an array" >&2; return 1; }
  if ! jq -e 'index("agents") != null' <<< "$providers" >/dev/null; then
    log "error: enabledProviders missing agents" >&2
    failed=1
  fi
  for setting in skills.enabled skills.enableSkillCommands; do
    value=$(omp config get "$setting" --json) || { log "error: cannot read $setting" >&2; failed=1; continue; }
    if ! jq -e '.value == true' <<< "$value" >/dev/null; then
      log "error: $setting is not true" >&2
      failed=1
    fi
  done
  value=$(omp plugin list --json) || { log "error: cannot list omp plugins" >&2; return 1; }
  path=$(jq -r '.npm[]? | select(.name=="superpowers" and .enabled==true) | .path' <<< "$value" | head -n1)
  canonical=$(readlink -f "$CANONICAL" 2>/dev/null || true)
  resolved=$(readlink -f "$path" 2>/dev/null || true)
  if [[ -z $path || -z $canonical || $resolved != "$canonical" ]]; then
    log "error: enabled superpowers plugin does not resolve to $CANONICAL" >&2
    failed=1
  fi
  path=$(jq -r '.npm[]? | select(.name=="pstack-pi" and .enabled==true) | .path' <<< "$value" | head -n1)
  active="$HOME/.local/share/skills-sync/pstack-pi"
  active_resolved=$(readlink -f "$active" 2>/dev/null || true)
  resolved=$(readlink -f "$path" 2>/dev/null || true)
  if [[ -z $path || -z $active_resolved || $resolved != "$active_resolved" ]]; then
    log "error: enabled pstack-pi plugin does not resolve to $active" >&2
    failed=1
  fi
  if [[ ! -d $HUB ]]; then
    log "error: skills hub missing: $HUB" >&2
    failed=1
  else
    local dest raw
    shopt -s nullglob
    for dest in "$HUB"/*; do
      [[ -L $dest ]] || continue
      if hub_symlink_is_dangling "$dest"; then
        log "error: dangling hub skill $(basename -- "$dest")" >&2
        failed=1
      fi
    done
    shopt -u nullglob
  fi
  hub_link="$HUB/ui-ux-pro-max"
  resolved=$(readlink -f "$hub_link" 2>/dev/null || true)
  if [[ ! -L $hub_link || ! -f $resolved/.skills-sync-owned ]]; then
    log "error: ui-ux-pro-max hub link is not a skills-sync deployment" >&2
    failed=1
  fi
  return "$failed"
}

main() {
  have flock || die "flock required"
  mkdir -p "${XDG_RUNTIME_DIR:-$HOME/.cache}"
  exec 9>"${XDG_RUNTIME_DIR:-$HOME/.cache}/skills-sync.lock"
  flock -n 9 || { log "skip: another skills-sync run is active"; return 0; }
  have git || die "git required"
  cd "$HOME"
  local failed=0
  sync_hub || failed=1
  configure_omp_shared_skills || failed=1
  sync_ui_ux_pro_max || failed=1
  sync_omp_pstack || failed=1
  install_cursor_routing || failed=1
  cleanup_cursor_mirrors || failed=1
  sync_superpowers || failed=1
  return "$failed"
}

