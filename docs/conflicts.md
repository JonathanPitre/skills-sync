# Skill name map

Nothing here is pruned from the hub. This is how to pick the right skill.

| Name | Owner | Use |
| --- | --- | --- |
| `omarchy` | packaged Omarchy (`/usr/share/omarchy/...`) | End-user Hyprland/desktop config. Not present on a non-Omarchy host. |
| `omp` | OMP agent skill | Delegate work to the Oh My Pi terminal agent. |
| `verify-omarchy` | Omarchy **project** skill, not shipped here | Dual-boot / CLI proof for the Omarchy runbook. |
| `grill-me` | hub (explicit-only) | Wrapper: invoke `grilling`. |
| `grilling` | hub | The interview. |
| `diagnosing-bugs` | hub (Matt Pocock) | Hub debug playbook. |
| `systematic-debugging` | Superpowers plugin | Superpowers debug playbook. Both remain. |
| `frontend-design` | Anthropic source | Creative/implementation direction. |
| `ui-ux-pro-max` | npm-generated hub skill | Local UI/UX research. |
| `poteto-mode` and other pstack helpers | pstack-pi plugin | Explicit pstack workflow only. Hidden from auto-invoke. |

Pstack skill names that collide with the hub fail the updater closed. Superpowers vs pstack is routing, not loader isolation: Superpowers stays default until the user asks for pstack / poteto-mode / a named pstack skill.
