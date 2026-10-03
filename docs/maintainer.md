# Maintainer notes

Colleague install is OMP-only ([README.md](../README.md)). This file is the rest of the updater.

## Harness behavior on the author machine

`scripts/skills-sync` still:

- gap-fills hub links into Claude, Codex, Copilot, OpenCode, Gemini, Hermes, Pi, and Grok skill dirs when those directories can be created
- copies Superpowers into `~/.cursor/plugins/local/superpowers` and writes `~/.cursor/rules/workflow-routing.mdc`
- removes hub mirrors from `~/.cursor/skills` (Cursor loads Superpowers/pstack as plugins, not hub copies)
- registers Superpowers with each adapter that is on PATH (`apply_claude`, `apply_pi`, `apply_omp`, …)
- skips a harness whose binary is missing

Cursor marketplace pstack remains Cursor-managed. This package does not replace it with the carrying fork.

## oh-my-pstack carrying fork

Upstream [shrimpwtf/oh-my-pstack](https://github.com/shrimpwtf/oh-my-pstack) last pushed 2026-09-01. OMP pstack-pi is cloned from **https://github.com/JonathanPitre/oh-my-pstack.git** (public fork).

Merged onto fork `main` with a merge commit:

- [shrimpwtf/oh-my-pstack#4](https://github.com/shrimpwtf/oh-my-pstack/pull/4) — port pstack 0.15.2

**Not merged** (conflicted with #4; do not silently resolve):

- [shrimpwtf/oh-my-pstack#5](https://github.com/shrimpwtf/oh-my-pstack/pull/5) — OMP Task / `skill://` compatibility
- [shrimpwtf/oh-my-pstack#1](https://github.com/shrimpwtf/oh-my-pstack/pull/1) — Pi portable router

Local clone with remotes: `~/Work/oh-my-pstack` (`origin` = fork, `upstream` = shrimpwtf). Rebase or merge `upstream/main` when it moves, then re-attempt #5 and #1 as merge commits.

`ensure_clone` uses latest GitHub release if one exists, otherwise the default branch. This fork has no releases, so it tracks `main`.

## Hub health

Each hub sync removes updater-owned **dangling** hub symlinks (broken targets or a tab in `readlink`) except packaged `/usr/share/*` links and authored directories. It then gap-fills, then removes harness mirrors that pointed at a missing hub name.

## Layout

| Path | Role |
| --- | --- |
| `scripts/skills-sync` | updater |
| `scripts/skills-sync-integrations.sh` | OMP/Cursor/pstack/ui-ux-pro-max |
| `config/skills-sync/sources` | git skill sources |
| `config/skills-sync/*.service,*.timer` | systemd user units |
| `tests/skills-sync.sh` | installer-independent tests |
