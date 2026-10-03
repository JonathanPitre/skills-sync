#!/usr/bin/env bash
set -euo pipefail

ROOT=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)
TMP=$(mktemp -d)
trap 'rm -rf "$TMP"' EXIT
export HOME="$TMP/home"
mkdir -p "$HOME"
export SKILLS_SYNC_SOURCES="$TMP/sources"
 export SKILLS_HUB="$TMP/hub"
HUB=$SKILLS_HUB
mkdir -p "$HUB"
# shellcheck source=../scripts/skills-sync
source "$ROOT/scripts/skills-sync"

fail() { printf 'FAIL: %s\n' "$*" >&2; exit 1; }
assert_file() { [[ -f $1 ]] || fail "expected file: $1"; }

repo="$TMP/matt"
mkdir -p "$repo/skills/productivity/grill-me" "$repo/skills/productivity/grilling"
printf '%s\n' '---' 'name: grill-me' 'disable-model-invocation: true' '---' 'Call Skill grilling.' > "$repo/skills/productivity/grill-me/SKILL.md"
printf '%s\n' '---' 'name: grilling' '---' 'Ask the interview question.' > "$repo/skills/productivity/grilling/SKILL.md"
discovered=$(discover_skills "$repo") || fail 'categorized discovery failed'
[[ $discovered == *$'grill-me\t'"$repo/skills/productivity/grill-me"* ]] || fail 'categorized grill-me not discovered'
ln -s "$repo/skills/grill-me" "$HUB/grill-me"
ln -s "$repo/skills/grilling" "$HUB/grilling"
link_hub_skill grill-me "$repo/skills/productivity/grill-me" "$repo"
link_hub_skill grilling "$repo/skills/productivity/grilling" "$repo"
assert_file "$HUB/grill-me/SKILL.md"
assert_file "$HUB/grilling/SKILL.md"
grep -q 'disable-model-invocation: true' "$HUB/grill-me/SKILL.md" || fail 'grill-me lost explicit-only metadata'
grep -q 'Skill grilling' "$HUB/grill-me/SKILL.md" || fail 'grill-me delegation changed'
printf 'ok: categorized grill-me and grilling repair\n'

mkdir -p "$repo/skills/one/foo" "$repo/skills/two/foo"
printf '%s\n' '---' 'name: foo' '---' > "$repo/skills/one/foo/SKILL.md"
printf '%s\n' '---' 'name: foo' '---' > "$repo/skills/two/foo/SKILL.md"
if discover_skills "$repo" >"$TMP/discovery.out" 2>"$TMP/discovery.err"; then fail 'duplicate discovery unexpectedly succeeded'; fi
[[ ! -s $TMP/discovery.out ]] || fail 'duplicate discovery emitted partial results'
printf 'ok: duplicate discovery fails atomically\n'

auth="$HUB/foo"
mkdir -p "$auth"
printf authored > "$auth/keep.txt"
if link_hub_skill foo "$repo/skills/one/foo" "$repo" 2>"$TMP/ownership.err"; then fail 'authored destination unexpectedly replaced'; fi
assert_file "$auth/keep.txt"
packaged="$TMP/packaged"
mkdir -p "$packaged/foo"
printf packaged > "$packaged/foo/keep.txt"
if link_hub_skill foo "$repo/skills/one/foo" "$packaged" 2>"$TMP/packaged.err"; then fail 'packaged source unexpectedly replaced'; fi
assert_file "$packaged/foo/keep.txt"
printf 'ok: authored and packaged content preserved\n'

git init -q --bare "$TMP/origin.git"
git init -q "$repo"
git -C "$repo" config user.email test@example.invalid
git -C "$repo" config user.name test
git -C "$repo" add .
git -C "$repo" commit -qm base
git -C "$repo" remote add origin "$TMP/origin.git"
git -C "$repo" push -q origin HEAD:master
git -C "$repo" update-ref refs/remotes/origin/master HEAD
git -C "$repo" symbolic-ref refs/remotes/origin/HEAD refs/remotes/origin/master
printf dirty >> "$repo/skills/productivity/grill-me/SKILL.md"
if ensure_clone "$TMP/origin.git" "$repo" 2>"$TMP/dirty.err"; then fail 'dirty tracked work unexpectedly accepted'; fi
grep -q dirty "$repo/skills/productivity/grill-me/SKILL.md" || fail 'dirty tracked work was lost'
git -C "$repo" checkout --quiet -- .
git -C "$repo" checkout --quiet -b local-only
git -C "$repo" commit --allow-empty -qm local-only
if ensure_clone "$TMP/origin.git" "$repo" 2>"$TMP/local.err"; then fail 'local-only commit unexpectedly accepted'; fi
[[ $(git -C "$repo" branch --show-current) == local-only ]] || fail 'local branch was discarded'
printf 'ok: dirty and local-only work preserved\n'

missing="$TMP/missing"
mkdir -p "$missing/skills"
if discover_skills "$missing" >"$TMP/missing.out" 2>"$TMP/missing.err"; then fail 'empty required source unexpectedly succeeded'; fi
[[ ! -e "$HUB/unavailable" && ! -L "$HUB/unavailable" ]] || fail 'failed source published a link'
origin="$TMP/source-origin.git"; source_dir="$TMP/source-clone"
git init -q --bare "$origin"; git init -q "$source_dir"
mkdir -p "$source_dir/skills/category/exact"
printf '%s\n' '---' 'name: exact' '---' 'Sync parser fixture.' > "$source_dir/skills/category/exact/SKILL.md"
git -C "$source_dir" config user.email test@example.invalid; git -C "$source_dir" config user.name test
git -C "$source_dir" add .; git -C "$source_dir" commit -qm fixture
git -C "$source_dir" remote add origin "$origin"; git -C "$source_dir" push -q origin HEAD:master
git -C "$source_dir" update-ref refs/remotes/origin/master HEAD; git -C "$source_dir" symbolic-ref refs/remotes/origin/HEAD refs/remotes/origin/master
git -C "$source_dir" tag sync-only; git -C "$source_dir" push -q origin refs/tags/sync-only
git -C "$source_dir" config --replace-all remote.origin.fetch '+refs/tags/sync-only:refs/tags/sync-only'
printf '%s\t%s\t%s\n' "$origin" "$source_dir" exact > "$SOURCES"
sync_hub
assert_file "$HUB/exact/SKILL.md"
[[ $(readlink "$HUB/exact") == "$source_dir/skills/category/exact" ]] || fail 'three-field selector linked wrong target'
printf '%s\n' 'ok: three-field hub sync and constrained-refspec branch resolution'
mkdir -p "$source_dir/skills/category/teach" "$source_dir/skills/category/tdd" "$source_dir/skills/category/kept"
printf '%s\n' '---' 'name: teach' '---' 'Excluded collision fixture.' > "$source_dir/skills/category/teach/SKILL.md"
printf '%s\n' '---' 'name: tdd' '---' 'Excluded second collision fixture.' > "$source_dir/skills/category/tdd/SKILL.md"
printf '%s\n' '---' 'name: kept' '---' 'Included source fixture.' > "$source_dir/skills/category/kept/SKILL.md"
git -C "$source_dir" add .; git -C "$source_dir" commit -qm 'add exclusion fixture'; git -C "$source_dir" push -q origin HEAD:master
ln -s "$source_dir/skills/category/teach" "$HUB/teach"; ln -s "$source_dir/skills/category/tdd" "$HUB/tdd"
printf '%s\t%s\t%s\n' "$origin" "$source_dir" '*,!teach,!tdd' > "$SOURCES"
sync_hub
assert_file "$HUB/kept/SKILL.md"
assert_file "$source_dir/skills/category/teach/SKILL.md"
assert_file "$source_dir/skills/category/tdd/SKILL.md"
if [[ -e $HUB/teach || -L $HUB/teach || -e $HUB/tdd || -L $HUB/tdd ]]; then fail 'excluded skills remained in shared hub'; fi
printf '%s\n' 'ok: exact multi-skill source exclusions preserve source files'
printf '%s\t%s\t%s\n' "$origin" "$source_dir" '*,!' > "$SOURCES"
if sync_hub; then fail 'malformed exclusion selector unexpectedly succeeded'; fi
assert_file "$HUB/kept/SKILL.md"
assert_file "$source_dir/skills/category/teach/SKILL.md"
[[ ! -e $HUB/teach && ! -L $HUB/teach ]] || fail 'malformed selector changed excluded link state'
printf '%s\n' 'ok: malformed exclusion selector rejected without changing deployed skills'
 candidate="$TMP/candidate"; active="$HUB/deployed"; generations="$TMP/generations"
mkdir -p "$candidate"
printf active > "$candidate/value.txt"
publish_deployment "$candidate" "$active" "$generations" first
assert_file "$active/value.txt"
if publish_deployment "$TMP/nonexistent" "$active" "$generations" broken 2>"$TMP/publish.err"; then fail 'invalid candidate unexpectedly published'; fi
[[ $(cat "$active/value.txt") == active ]] || fail 'failed publication replaced active generation'
printf 'ok: atomic owned deployment preserves active generation on failure\n'

calls="$TMP/cli-calls"
bindir="$TMP/path"
mkdir -p "$bindir"
export SKILLS_SYNC_CALLS="$calls"
export CANON_PATH="$HOME/.local/share/superpowers"
export PSTACK_PATH="$HOME/.local/share/skills-sync/pstack-pi"
mkdir -p "$CANON_PATH" "$PSTACK_PATH"
dep="$HOME/.local/share/skills-sync/deployments/ui-ux-pro-max/current"
mkdir -p "$dep"
: > "$dep/.skills-sync-owned"
ln -sfn "$dep" "$HUB/ui-ux-pro-max"
cat > "$bindir/npm" << 'EOF'
#!/bin/bash
printf '%s\n' "npm $*" >> "$SKILLS_SYNC_CALLS"
exit 99
EOF
cat > "$bindir/git" << 'EOF'
#!/bin/bash
printf '%s\n' "git $*" >> "$SKILLS_SYNC_CALLS"
exit 99
EOF
cat > "$bindir/omp" << 'EOF'
#!/bin/bash
printf '%s\n' "omp $*" >> "$SKILLS_SYNC_CALLS"
if [[ $1 == config && $2 == set ]]; then exit 99; fi
if [[ $1 == config && $2 == get ]]; then
  case $3 in
    enabledProviders)
      if [[ ${OMP_CHECK_FIXTURE:-} == missing-agents ]]; then printf '%s\n' '{"value":["cursor"]}'; else printf '%s\n' '{"value":["agents"]}'; fi
      ;;
    skills.enabled|skills.enableSkillCommands) printf '%s\n' '{"value":true}' ;;
    *) printf '%s\n' '{"value":null}' ;;
  esac
  exit 0
fi
if [[ $1 == plugin && $2 == list ]]; then
  super="$CANON_PATH"
  [[ ${OMP_CHECK_FIXTURE:-} == bad-plugin ]] && super="/nonexistent/superpowers"
  printf '%s\n' "{\"npm\":[{\"name\":\"superpowers\",\"enabled\":true,\"path\":\"$super\"},{\"name\":\"pstack-pi\",\"enabled\":true,\"path\":\"$PSTACK_PATH\"}]}"
  exit 0
fi
exit 0
EOF
chmod +x "$bindir/npm" "$bindir/git" "$bindir/omp"
: > "$calls"
PATH="$bindir:/usr/bin:/bin" "$ROOT/scripts/skills-sync" --help >"$TMP/help.out"
[[ ! -s $calls ]] || fail "--help invoked external commands: $(cat "$calls")"
grep -q -- '--check' "$TMP/help.out" || fail 'help missing --check'
status=0
PATH="$bindir:/usr/bin:/bin" "$ROOT/scripts/skills-sync" --nope >/dev/null 2>"$TMP/bad.err" || status=$?
[[ $status -eq 2 ]] || fail "unknown argument exited $status"
printf '%s\n' 'ok: help and unknown arguments stay local'
: > "$calls"
if OMP_CHECK_FIXTURE=missing-agents PATH="$bindir:/usr/bin:/bin" "$ROOT/scripts/skills-sync" --check >"$TMP/check-miss.out" 2>"$TMP/check-miss.err"; then fail 'missing agents unexpectedly passed'; fi
grep -q 'enabledProviders missing agents' "$TMP/check-miss.err" || fail 'missing agents did not report drift'
if grep -Eq 'config set|npm |git ' "$calls"; then fail "--check drifted into writes or network: $(cat "$calls")"; fi
: > "$calls"
if OMP_CHECK_FIXTURE=bad-plugin PATH="$bindir:/usr/bin:/bin" "$ROOT/scripts/skills-sync" --check >"$TMP/check-bad.out" 2>"$TMP/check-bad.err"; then fail 'bad plugin path unexpectedly passed'; fi
grep -q 'enabled superpowers plugin does not resolve' "$TMP/check-bad.err" || fail 'bad plugin path did not report drift'
if grep -Eq 'config set|npm |git ' "$calls"; then fail "--check drifted into writes or network: $(cat "$calls")"; fi
: > "$calls"
PATH="$bindir:/usr/bin:/bin" "$ROOT/scripts/skills-sync" --check >"$TMP/check-ok.out" 2>"$TMP/check-ok.err"
if grep -Eq 'config set|npm |git ' "$calls"; then fail "--check drifted into writes or network: $(cat "$calls")"; fi
printf '%s\n' 'ok: --check validates Oh My Pi layout locally'

prefix="$HOME/.local/share/skills-sync/uipro/node_modules/ui-ux-pro-max-cli"
mkdir -p "$prefix"
printf '%s\n' '{"version":"9.9.9"}' > "$prefix/package.json"
hash=$(sha256sum "$ROOT/scripts/skills-sync" | awk 'NR==1 {print $1}')
ugen="$HOME/.local/share/skills-sync/deployments/ui-ux-pro-max/9.9.9-$hash"
mkdir -p "$ugen"
: > "$ugen/.skills-sync-owned"
ln -sfn "$ugen" "$HUB/ui-ux-pro-max"
npm() { printf '%s\n' "npm $*" >> "$TMP/npm-calls"; [[ $1 == view ]] && { printf '%s\n' 9.9.9; return 0; }; return 99; }
publish_deployment() { printf '%s\n' publish >> "$TMP/npm-calls"; return 99; }
: > "$TMP/npm-calls"
sync_ui_ux_pro_max
grep -q 'npm view' "$TMP/npm-calls" || fail 'current UI UX Pro Max did not query the registry version'
if grep -q 'npm install' "$TMP/npm-calls" || grep -qx publish "$TMP/npm-calls"; then fail "current UI UX Pro Max republished: $(cat "$TMP/npm-calls")"; fi
printf '%s\n' 'ok: current UI UX Pro Max skips install and publish'

src="$HOME/.local/src/oh-my-pstack"
mkdir -p "$src"
git init -q "$src"
git -C "$src" config user.email test@example.invalid
git -C "$src" config user.name test
git -C "$src" commit --allow-empty -qm pstack
branch=$(git -C "$src" branch --show-current)
git -C "$src" update-ref "refs/remotes/origin/$branch" HEAD
git -C "$src" symbolic-ref refs/remotes/origin/HEAD "refs/remotes/origin/$branch"
commit=$(git -C "$src" rev-parse HEAD)
pgen="$HOME/.local/share/skills-sync/deployments/pstack-pi/$commit-$hash"
mkdir -p "$pgen"
: > "$pgen/.skills-sync-owned"
rm -rf "$HOME/.local/share/skills-sync/pstack-pi"
ln -sfn "$pgen" "$HOME/.local/share/skills-sync/pstack-pi"
ensure_clone() { printf '%s\n' ensure >> "$TMP/pstack-calls"; return 99; }
omp() { printf '%s\n' '{"npm":[]}'; }
: > "$TMP/pstack-calls"
sync_omp_pstack
if grep -q ensure "$TMP/pstack-calls" || grep -qx publish "$TMP/npm-calls"; then fail 'current pstack republished'; fi
printf '%s\n' 'ok: current pstack-pi skips archive and publish'

valid="$TMP/last30days-real"
mkdir -p "$valid"
printf keep > "$valid/SKILL.md"
ln -sfn -- "$valid" "$HUB/last30days"
ln -s -- $'30days\t/not-a-real-target' "$HUB/las"
authored="$HUB/keep-authored"
mkdir -p "$authored"
printf authored > "$authored/keep.txt"
ln -s -- /usr/share/omarchy/default/agents/skills/omarchy "$HUB/omarchy-packaged"
sweep_dangling_hub_links || fail 'sweep_dangling_hub_links returned nonzero'
[[ -L $HUB/last30days ]] || fail 'valid sibling last30days was removed'
assert_file "$authored/keep.txt"
[[ -L $HUB/omarchy-packaged ]] || fail 'packaged /usr/share link was removed'
if [[ -e $HUB/las || -L $HUB/las ]]; then fail 'tab-corrupted las leftover was kept'; fi
printf '%s\n' 'ok: dangling hub sweep keeps valid, authored, and packaged links'

mkdir -p "$HOME/.claude/skills"
ln -sfn -- "$HUB/last30days" "$HOME/.claude/skills/last30days"
ln -sfn -- "$HUB/grill-wi" "$HOME/.claude/skills/grill-wi"
ln -sfn -- "$TMP/elsewhere" "$HOME/.claude/skills/foreign"
sweep_stale_harness_mirrors || fail 'sweep_stale_harness_mirrors returned nonzero'
[[ -L $HOME/.claude/skills/last30days ]] || fail 'valid hub mirror was removed'
[[ -L $HOME/.claude/skills/foreign ]] || fail 'non-hub harness symlink was removed'
if [[ -e $HOME/.claude/skills/grill-wi || -L $HOME/.claude/skills/grill-wi ]]; then fail 'stale harness mirror was kept'; fi
printf '%s\n' 'ok: stale harness mirrors of missing hub names are removed'

ln -s -- $'30days\t/not-a-real-target' "$HUB/las"
: > "$calls"
if PATH="$bindir:/usr/bin:/bin" "$ROOT/scripts/skills-sync" --check >"$TMP/check-dangle.out" 2>"$TMP/check-dangle.err"; then fail 'dangling hub link unexpectedly passed --check'; fi
grep -q 'dangling hub skill' "$TMP/check-dangle.err" || fail '--check did not report dangling hub skill'
if grep -Eq 'config set|npm |git ' "$calls"; then fail "--check dangling drifted into writes or network: $(cat "$calls")"; fi
rm -- "$HUB/las"
printf '%s\n' 'ok: --check fails closed on dangling hub links'
