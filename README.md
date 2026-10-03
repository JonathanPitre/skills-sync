# 🔄 skills-sync

Daily sync of a shared **Oh My Pi (OMP)** skill hub, plus Superpowers and a carrying **pstack-pi** fork.

Clone, run `./install.sh`, then `skills-sync --check`. Cursor, Claude, Pi, and other harness adapters still run on machines that have those binaries; see [docs/maintainer.md](docs/maintainer.md). Name collisions live in [docs/conflicts.md](docs/conflicts.md).

## 📦 What you get

- Hub at `~/.agents/skills` from the git sources in `config/skills-sync/sources`
- OMP `enabledProviders` includes `agents`
- OMP plugins: Superpowers (canonical clone) and **pstack-pi** from [JonathanPitre/oh-my-pstack](https://github.com/JonathanPitre/oh-my-pstack)
- Daily systemd user timer after the first successful sync

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

**Repository:** [nicolas-found42/mattpocock-skills-omp](https://github.com/nicolas-found42/mattpocock-skills-omp)

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

**Repository:** [DietrichGebert/ponytail](https://github.com/DietrichGebert/ponytail)

| Skill | What it is for |
| --- | --- |
| `ponytail` | Laziness protocol: smallest change that works |
| `ponytail-audit` | Hunt over-engineering in a codebase |
| `ponytail-debt` | Name and cut tech-debt that is not earning its keep |
| `ponytail-gain` | Keep a change that actually pays for itself |
| `ponytail-help` | How to invoke the ponytail family |
| `ponytail-review` | Diff review that only hunts complexity |

### 🗞️ last30days (hub)

**Repository:** [mvanhorn/last30days-skill](https://github.com/mvanhorn/last30days-skill)

| Skill | What it is for |
| --- | --- |
| `last30days` | What people actually said about a topic in the last 30 days |

### 🎨 Anthropic (hub)

**Repository:** [anthropics/skills](https://github.com/anthropics/skills)

| Skill | What it is for |
| --- | --- |
| `frontend-design` | Distinctive, intentional UI direction |

### 🛠️ jnsahaj (hub)

**Repository:** [jnsahaj/skills](https://github.com/jnsahaj/skills)

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

**Source:** [ui-ux-pro-max-cli](https://www.npmjs.com/package/ui-ux-pro-max-cli) on npm (generated locally; no GitHub skill tree).

| Skill | What it is for |
| --- | --- |
| `ui-ux-pro-max` | Local UI/UX research (a11y, layout, type, color, stack) |

### 🦸 Superpowers (OMP plugin)

Automatic default for ordinary development.

**Repository:** [obra/superpowers](https://github.com/obra/superpowers)

| Skill | What it is for |
| --- | --- |
| `brainstorming` | You MUST use this before any creative work - creating features, building components, adding functionality, or modifying behavior. Explore… |
| `diagnosing-superpowers` | Use when a superpowers session went wrong and your human partner wants to know why — repeated work, ignored plans, stumbles, poor results… |
| `dispatching-parallel-agents` | Use when facing 2+ independent tasks that can be worked on without shared state or sequential dependencies |
| `executing-plans` | Use when executing an implementation plan in the current session as the implementer yourself — your human partner chose inline execution,… |
| `finishing-a-development-branch` | Use when implementation is complete, all tests pass, and you need to decide how to integrate the work |
| `receiving-code-review` | Use when receiving code review feedback, before implementing suggestions, especially if feedback seems unclear or technically questionabl… |
| `requesting-code-review` | Use when completing tasks, implementing major features, or before merging to verify work meets requirements |
| `subagent-driven-development` | Use when executing implementation plans with independent tasks in the current session |
| `systematic-debugging` | Use when encountering any bug, test failure, or unexpected behavior, before proposing fixes |
| `test-driven-development` | Use when implementing any feature or bugfix, before writing implementation code |
| `using-git-worktrees` | Use when starting feature work that needs isolation from current workspace or before executing implementation plans - ensures an isolated… |
| `using-superpowers` | Use when starting any conversation - establishes how to find and use skills, requiring skill invocation before ANY response including cla… |
| `verification-before-completion` | Use when about to claim work is complete, fixed, or passing, before committing or creating PRs - requires running verification commands a… |
| `writing-plans` | Use when you have a spec or requirements for a multi-step task, before touching code |
| `writing-skills` | Use when creating new skills, editing existing skills, or verifying skills work before deployment |

### 🧱 pstack-pi (OMP plugin)

Explicit-only. Open after a request for pstack, `/poteto-mode`, or a named pstack skill.

**Repository:** [JonathanPitre/oh-my-pstack](https://github.com/JonathanPitre/oh-my-pstack)

| Skill | What it is for |
| --- | --- |
| `architect` | Sketch types, signatures, and module structure before code, then stay in the loop while implementation fills in. Use for /architect, 'arc… |
| `arena` | Spawn N parallel candidates at the same task, pick a base, graft the strongest parts of the losers into it. Use for /arena, 'arena this',… |
| `automate-me` | Use for "automate me", "create/update/refresh my -mode skill", "turn/capture my preferences or working style into a skill", or want… |
| `blast-radius` | Find what a change could break somewhere else before it ships, beyond the diff, and prove the one fact it's safe because of by running re… |
| `bro` | Restate the last message in plain human language, with no jargon. |
| `create-verification-skill` | Generate a project-local verification skill that drives your app the way a user does — any language, framework, or platform. Use for /cre… |
| `figure-it-out` | Design an auditable playbook when no narrower one fits: a large migration, an ambitious multi-part change, or work a human reviews after… |
| `how` | Use for "how does X work", code walkthroughs before changing something, and placement / ownership / layering questions ("where should… |
| `interrogate` | Use for "interrogate", "adversarial review", "multi-model review", "challenge this", "stress test this code", "find blind spot… |
| `maintain-verification-skill` | Periodic pass that keeps a project's verification skill and feature map honest: parallel source readers per feature, one live session dri… |
| `make-bot-ui` | Build a custom page, dashboard, or buttons that wake an agent through a webhook. Use when connecting a UI to an automation, collecting a… |
| `no-comments` | Spawn Comment Sicko, fix accepted findings, and offer encodings for claimed constraints. |
| `orchestrate-omp` | Coordinate OMP subagents on substantial work. Use when parallel discovery, specialist review, or clearly partitioned implementation will… |
| `poteto-mode` | poteto's agent style for concise, detailed responses, deliberate subagents, unslopped prose, simple code, and verified work. Use for pote… |
| `principle-attack-the-premise` | Apply when two or more fixes that share one premise have failed the same gate. Take a census of which actors hold the imbalance before th… |
| `principle-boundary-discipline` | Apply when wiring validation, error handling, or framework adapters. Concentrate guards at system boundaries (CLI, config, network, exter… |
| `principle-build-the-lever` | Apply to any non-trivial work, not just bulk work: edits, migrations, analyses, checks. Build the tool that does it or proves it (codemod… |
| `principle-encode-lessons-in-structure` | Apply when you catch yourself writing the same instruction a second time, or notice a recurring correction. Encode the rule as a lint, me… |
| `principle-exhaust-the-design-space` | Apply when facing a novel UI interaction or architectural decision with no precedent in the codebase. Build 2-3 competing prototypes and… |
| `principle-experience-first` | Apply when product, UX, or feature-scope tradeoffs come up. Choose user delight over implementation convenience; ship fewer polished feat… |
| `principle-fix-root-causes` | Apply when debugging. Trace each symptom to its root cause and fix it there; reproduce first, ask why until you reach it, resist nil-chec… |
| `principle-foundational-thinking` | Apply before writing logic: choosing core types and data structures, sequencing scaffold-vs-feature work, asking what concurrent actors s… |
| `principle-guard-the-context-window` | Apply when context is filling up: large outputs, long files, repeated reads, fan-out planning. Route bulk to subagents; keep summaries in… |
| `principle-laziness-protocol` | Apply when refactoring, evaluating diff size, or tempted to add abstractions, layers, or signal threading. Bias toward deletion and the s… |
| `principle-make-operations-idempotent` | Apply when designing commands, lifecycle steps, or processing loops that run amid crashes, restarts, and retries. Converge to the same en… |
| `principle-migrate-callers-then-delete-legacy-apis` | Apply when introducing a new internal API while old callers still exist. Migrate callers and delete the old API in the same wave instead… |
| `principle-minimize-reader-load` | Apply when reviewing or shaping code that's hard to trace. Count layers between question and answer, and hidden state in the reader's hea… |
| `principle-model-the-domain` | Apply when writing stateful logic, or when code branches a lot or repeats a shape assumption across files. Encode the domain in a structu… |
| `principle-never-block-on-the-human` | Apply when tempted to ask 'should I do X?' on reversible work. Proceed, present the result, let the human course-correct after the fact;… |
| `principle-outcome-oriented-execution` | Apply during planned rewrites and migrations with explicit phase boundaries. Converge on the target architecture; don't preserve smooth i… |
| `principle-prove-it-works` | Apply after completing a task, before declaring done. Verify against the real artifact (run the feature, read the actual value, inspect t… |
| `principle-redesign-from-first-principles` | Apply when integrating a new requirement into an existing design. Redesign as if the requirement had been a foundational assumption from… |
| `principle-separate-before-serializing-shared-state` | Apply when concurrent actors might write to the same file, branch, key, or state object. Eliminate the sharing first; serialize structura… |
| `principle-sequence-verifiable-units` | Apply to multi-step work (sweeps, migrations, runs of similar edits) and to how you stack commits and PRs. Break work into small units th… |
| `principle-subtract-before-you-add` | Apply when sequencing an addition, refactor, or rewrite. Remove dead code, redundant validators, and stub references first, then build on… |
| `principle-test-behavior-not-implementation` | Apply when you write, change, or keep a test. Call the code the way its users do and assert the result they observe against a literal exp… |
| `principle-type-system-discipline` | Apply when designing types, reviewing a function signature, or writing code in any statically-typed language. Make illegal states unrepre… |
| `pstack-pi` | Pi runtime adapter for poteto-mode. Maps canonical pstack roles and lifecycle protocols to Pi-compatible task agents, batching, isolation… |
| `recall` | Reconstruct your recent working context from your own chat history, live state, and the shared record (user reports, prior fixes, inciden… |
| `reflect` | Spawn three parallel review subagents over the active transcript, surface learnings, and route each to a concrete edit on an existing ski… |
| `reproduce-and-fix-issues` | Reproduce triaged Slack bugs through a configured app-control adapter, verify existing fixes, and open a bounded draft pull request only… |
| `setup-benny` | Configure Benny and prepare its triage and repro automations. Use when installing Benny or changing its Slack, tracker, repository, routi… |
| `setup-pstack` | Configure which host-supported roles, models, and reasoning budgets pstack uses per workflow role. Detects the live host inventory and wr… |
| `show-me-your-work` | Keep a reviewable decision trail for long-running or unattended work: a TSV log with one row per decision (what, why, evidence, result).… |
| `swarm` | Fan out N parallel workers, drain them, and return one report. Use for /swarm, 'swarm this', or parallel coverage, races, gauntlets, and… |
| `tdd` | Use only when the user explicitly asks for TDD, a failing test, or a regression test, OR when the bug has an obvious cheap local test tar… |
| `teach` | Explain a body of work plainly so a person actually understands it. Runs the `how` and `why` skills and weaves what they find into one cl… |
| `technical-writing` | Layered technical-writing standard: Diátaxis structure, Google developer style sentences, STE instruction rules, Global English syntax. U… |
| `triage-issue-reports` | Triage Slack issue reports with one thread-only verdict, evidence review, cause-aware routing, tracker dedupe, and fail-closed ticket cre… |
| `typescript-best-practices` | TypeScript best practices. Use when reading or editing any .ts or .tsx file. |
| `unslop` | Cut AI tells from any writing. Must always apply. |
| `why` | Use for 'why does X work this way', 'why we picked Y', design rationale, regressions, postmortems, or data-backed thresholds. Discovers a… |
