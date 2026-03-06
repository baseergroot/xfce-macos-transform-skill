---
name: xfce-macos-transform
description: >
  Generate a full or partial XFCE-to-macOS customization workflow, including either a copy-paste prompt,
  a ready-to-run bash script, or live tuning commands. Use when users ask to make XFCE look like macOS,
  request macOS-style theming/rice, or need fixes for panel/layout/font/menu issues after applying themes.
  Preserve existing menu entries and shortcut launchers by default unless the user explicitly asks to replace them.
---

# XFCE macOS Transform

Provide one of these outputs:
- Codex/AI prompt for another agent.
- Ready-to-run bash script.
- Live command sequence for in-session fixes.

## Workflow

1. Determine target mode.
- Ask for `prompt`, `script`, or `live fixes` only if unclear.
- If unclear, provide both prompt and script.

2. Detect environment safely before changing panel/menu.
- Read current panel IDs and plugin IDs first.
- Preserve existing menu plugin and launcher shortcuts by default.
- Treat dock/menu replacement as opt-in.

3. Choose scope.
- Full transform: GTK, icons, cursor, dock, panel, wallpaper, fonts, compositor, launcher, desktop cleanup.
- Partial transform: apply only requested components.
- Repair mode: fix layout, font, panel duplication, and scaling without replacing user shortcuts.

4. Build robust commands/scripts.
- Use `set -euo pipefail`.
- Add dependency checks and idempotent guards.
- Create backup under `~/.config/xfce4-backup-YYYYMMDD-HHMMSS`.
- Use non-fatal fallbacks for unstable network assets (cursor/wallpaper/theme download).
- Avoid hard-failing on optional `xfconf` properties; create them when needed.

5. Validate outcome.
- Re-read key settings after apply (`xsettings`, `xfce4-panel`, `xfwm4`).
- Report what changed and what was skipped.

## References

- For component implementation details, read `references/components.md`.
- For a direct runnable baseline script, reuse or adapt `scripts/xfce-macos-transform.sh`.

## Output Conventions

- If output is a script, write to `./outputs/xfce-macos-transform.sh`.
- Include run instructions:
  - `chmod +x ./outputs/xfce-macos-transform.sh`
  - `./outputs/xfce-macos-transform.sh`
- Always warn the user to log out/in after panel/theme changes.
