# skills-sync

Shared agent-skill hub for **Oh My Pi (OMP)**. This GitHub repository is **private**; ask for collaborator access, then clone, run `./install.sh`, then `skills-sync --check`.

This README is the colleague path. Cursor, Claude, Pi, and other harness adapters still run on machines that have those binaries; they are documented in [docs/maintainer.md](docs/maintainer.md). Name collisions and look-alike skills are listed in [docs/conflicts.md](docs/conflicts.md).

## What you get

- Hub at `~/.agents/skills` from the git sources in `config/skills-sync/sources`
- OMP `enabledProviders` includes `agents`
- OMP plugins: Superpowers (canonical clone) and **pstack-pi** from the carrying fork [JonathanPitre/oh-my-pstack](https://github.com/JonathanPitre/oh-my-pstack)
- Daily systemd user timer after the first successful sync

Not installed: `omp-token-usage`, lean-ctx MCP, `verify-omarchy`.

## Prerequisites

Linux with a systemd **user** manager. On PATH: `bash`, `git`, `curl`, `jq`, `flock`, `python3`, `tar`, `sha256sum`, `node`, `npm`. OMP installed. Network to GitHub and npm. Do not use `sudo npm`.

```bash
for bin in bash git curl jq flock python3 tar sha256sum node npm omp; do
  command -v "$bin" >/dev/null || { echo "missing: $bin" >&2; exit 1; }
done
systemctl --user is-system-running
```

## Install

```bash
git clone git@github.com:JonathanPitre/skills-sync.git
cd skills-sync
./install.sh
skills-sync --check
```

`install.sh` is idempotent. It copies binaries and units, **merges** `~/.config/skills-sync/sources` (keeps your extra records; two-column rows become `url<TAB>dir<TAB>*`), runs one sync, then enables `skills-sync.timer` only if that sync succeeded.

Disable later: `systemctl --user disable --now skills-sync.timer`.

## Using skills in OMP

- Shared hub skills: `/skill:grill-me`, `/skill:frontend-design`, `/skill:ui-ux-pro-max`
- Ordinary work uses Superpowers automatically
- Pstack (including `/skill:poteto-mode`) starts only after an explicit request; do not run a second Superpowers loop on that task
- Fresh OMP session to leave a pstack conversation

`skills-sync --check` is read-only. It must report `agents`, enabled skill commands, Superpowers at `~/.local/share/superpowers`, pstack-pi at the skills-sync deployment, an owned `ui-ux-pro-max` hub link, and no dangling hub symlinks.
