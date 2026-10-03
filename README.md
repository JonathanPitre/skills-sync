# 🔄 skills-sync

Daily sync of a shared **Oh My Pi (OMP)** skill hub, plus Superpowers and a carrying **pstack-pi** fork.

Clone, run `./install.sh`, then `skills-sync --check`. Cursor, Claude, Pi, and other harness adapters still run on machines that have those binaries; see [docs/maintainer.md](docs/maintainer.md). Name collisions live in [docs/conflicts.md](docs/conflicts.md).

## 📦 What you get

- Hub at `~/.agents/skills` from the git sources in `config/skills-sync/sources`
- OMP `enabledProviders` includes `agents`
- OMP plugins: Superpowers (canonical clone) and **pstack-pi** from [JonathanPitre/oh-my-pstack](https://github.com/JonathanPitre/oh-my-pstack)
- Daily systemd user timer after the first successful sync

Not installed: `omp-token-usage`, lean-ctx MCP, `verify-omarchy`.

## ✅ Prerequisites

Linux with a systemd **user** manager. On PATH: `bash`, `git`, `curl`, `jq`, `flock`, `python3`, `tar`, `sha256sum`, `node`, `npm`. OMP installed. Network to GitHub and npm. Do not use `sudo npm`.

```bash
for bin in bash git curl jq flock python3 tar sha256sum node npm omp; do
  command -v "$bin" >/dev/null || { echo "missing: $bin" >&2; exit 1; }
done
systemctl --user is-system-running
```

## 🚀 Install

```bash
git clone https://github.com/JonathanPitre/skills-sync.git
cd skills-sync
./install.sh
skills-sync --check
```

`install.sh` is idempotent. It copies binaries and units, **merges** `~/.config/skills-sync/sources` (keeps your extra records; two-column rows become `url<TAB>dir<TAB>*`), runs one sync, then enables `skills-sync.timer` only if that sync succeeded.

Disable later: `systemctl --user disable --now skills-sync.timer`.

## 🎯 Using skills in OMP

- Shared hub skills: `/skill:grill-me`, `/skill:frontend-design`, `/skill:ui-ux-pro-max`
- Ordinary work uses Superpowers automatically
- Pstack (including `/skill:poteto-mode`) starts only after an explicit request; do not run a second Superpowers loop on that task
- Fresh OMP session to leave a pstack conversation

`skills-sync --check` is read-only. It must report `agents`, enabled skill commands, Superpowers at `~/.local/share/superpowers`, pstack-pi at the skills-sync deployment, an owned `ui-ux-pro-max` hub link, and no dangling hub symlinks.

## 📚 Skills included

Shipped by this package. Omarchy-packaged skills (`omarchy`, `diagnose-crash`) may already exist on Omarchy hosts; they are not published from this repo.

### 🧠 Matt Pocock (hub)

Excludes `teach` and `tdd` (those stay in pstack-pi only).

| Skill | What it is for |
| --- | --- |
| `ask-matt` | Router: which skill or flow fits this situation |
| `claude-handoff` | Hand the conversation to a fresh background agent |
| `code-review` | Review since a commit/branch along standards and substance |
| `codebase-design` | Design deep modules and their interfaces |
| `diagnosing-bugs` | Hard-bug and performance diagnosis loop |
| `domain-modeling` | Project domain model and glossary |
| `grill-me` | Explicit wrapper that starts `grilling` |
| `grill-with-docs` | Grilling that also writes ADRs and glossary |
| `grilling` | Relentless interview to stress-test a plan |
| `handoff` | Compact the session into a pickup document |
| `implement` | Implement from a spec or tickets |
| `implement-spec` | Implement `/to-spec` + `/to-tickets` |
| `improve-codebase-architecture` | Scan for deepening opportunities, then grill |
| `loop-me` | Grill specs for workflows in this workspace |
| `pr` | Write a PR body from evidence |
| `prototype` | Throwaway prototype to answer a design question |
| `research` | High-trust sources, captured as Markdown |
| `retro` | Retrospective on a coding session |
| `setup-matt-pocock-skills` | One-time tracker, labels, and domain docs |
| `setup-ts-deep-modules` | TypeScript deep-module dependency-cruiser setup |
| `to-questionnaire` | Turn an unanswerable decision into a questionnaire |
| `to-spec` | Synthesize the conversation into a spec |
| `to-tickets` | Break work into tracer-bullet tickets |
| `triage` | Issue/PR triage state machine |
| `wait-what` | Re-pitch the last message that did not land |
| `wayfinder` | Map huge work as decision tickets |
| `wizard` | Interactive bash wizard for human-only steps |
| `writing-beats` | Assemble writing into a journey of beats |
| `writing-for-agents` | Skills, `AGENTS.md`, `CLAUDE.md` |
| `writing-fragments` | Mine raw writing fragments |
| `writing-shape` | Shape raw material into an article |

### 🐴 Ponytail (hub)

| Skill | What it is for |
| --- | --- |
| `ponytail` | Laziness protocol: smallest change that works |
| `ponytail-audit` | Hunt over-engineering in a codebase |
| `ponytail-debt` | Name and cut tech-debt that is not earning its keep |
| `ponytail-gain` | Keep a change that actually pays for itself |
| `ponytail-help` | How to invoke the ponytail family |
| `ponytail-review` | Diff review that only hunts complexity |

### 🗞️ last30days (hub)

| Skill | What it is for |
| --- | --- |
| `last30days` | What people actually said about a topic in the last 30 days |

### 🎨 Anthropic (hub)

| Skill | What it is for |
| --- | --- |
| `frontend-design` | Distinctive, intentional UI direction |

### 🛠️ jnsahaj (hub)

| Skill | What it is for |
| --- | --- |
| `code-refactor-review` | Reuse, composition, consistency, slop |
| `create-draft-pr` | Commit, push, draft PR |
| `ga` | Kick off autonomous work in a parallel clone |
| `ga-pr` | Follow-up work on an existing PR in a parallel session |
| `pit-of-success` | Make the correct path the default |
| `prepare-branch-context` | Diff-from-main context for follow-up work |
| `ux-flow-plan` | UX-first flow trees, then implementation anchors |
| `zero-tech-debt` | Rework as if the intended design existed from day one |

### 🔍 Generated hub skill

| Skill | What it is for |
| --- | --- |
| `ui-ux-pro-max` | Local UI/UX research (a11y, layout, type, color, stack) |

### 🦸 Superpowers (OMP plugin)

Automatic default for ordinary development.

`brainstorming`, `diagnosing-superpowers`, `dispatching-parallel-agents`, `executing-plans`, `finishing-a-development-branch`, `receiving-code-review`, `requesting-code-review`, `subagent-driven-development`, `systematic-debugging`, `test-driven-development`, `using-git-worktrees`, `using-superpowers`, `verification-before-completion`, `writing-plans`, `writing-skills`

### 🧱 pstack-pi (OMP plugin)

Explicit-only. Open after a request for pstack, `/poteto-mode`, or a named pstack skill.

`architect`, `arena`, `automate-me`, `blast-radius`, `bro`, `create-verification-skill`, `figure-it-out`, `how`, `interrogate`, `maintain-verification-skill`, `make-bot-ui`, `no-comments`, `orchestrate-omp`, `poteto-mode`, `principle-attack-the-premise`, `principle-boundary-discipline`, `principle-build-the-lever`, `principle-encode-lessons-in-structure`, `principle-exhaust-the-design-space`, `principle-experience-first`, `principle-fix-root-causes`, `principle-foundational-thinking`, `principle-guard-the-context-window`, `principle-laziness-protocol`, `principle-make-operations-idempotent`, `principle-migrate-callers-then-delete-legacy-apis`, `principle-minimize-reader-load`, `principle-model-the-domain`, `principle-never-block-on-the-human`, `principle-outcome-oriented-execution`, `principle-prove-it-works`, `principle-redesign-from-first-principles`, `principle-separate-before-serializing-shared-state`, `principle-sequence-verifiable-units`, `principle-subtract-before-you-add`, `principle-test-behavior-not-implementation`, `principle-type-system-discipline`, `pstack-pi`, `recall`, `reflect`, `reproduce-and-fix-issues`, `setup-benny`, `setup-pstack`, `show-me-your-work`, `swarm`, `tdd`, `teach`, `technical-writing`, `triage-issue-reports`, `typescript-best-practices`, `unslop`, `why`
