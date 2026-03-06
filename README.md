# xfce-macos-transform (Codex Skill)

Pure skill package for AI agents (Codex-style) to transform or tune XFCE into a macOS-like desktop.

This repository intentionally contains skill instructions and references only. It does not ship a fixed installer script.

## What It Does

- Generates one of these outputs:
- A copy-paste prompt
- A generated bash script
- Live command steps for in-session fixes
- Handles full transforms and partial fixes (layout, panel, fonts, dock, menu duplication).
- Preserves existing XFCE menu entries and launcher shortcuts by default.

## Install

```bash
CODEX_HOME="${CODEX_HOME:-$HOME/.codex}"
mkdir -p "$CODEX_HOME/skills"
git clone https://github.com/baseergroot/xfce-macos-transform-skill.git \
  "$CODEX_HOME/skills/xfce-macos-transform"
```

## Installation Example

Example end-to-end install and quick check:

```bash
CODEX_HOME="${CODEX_HOME:-$HOME/.codex}"
mkdir -p "$CODEX_HOME/skills"
git clone https://github.com/baseergroot/xfce-macos-transform-skill.git \
  "$CODEX_HOME/skills/xfce-macos-transform"
ls -la "$CODEX_HOME/skills/xfce-macos-transform"
```

## Use

In your agent chat, ask:

- `make XFCE look like macOS`
- `fix my XFCE macOS layout and keep my existing menu shortcuts`
- `only apply macOS icon theme and dock`

The skill should auto-trigger from intent, or you can invoke it explicitly with `$xfce-macos-transform` if your client supports explicit skill calls.

## Usage Examples

Auto-trigger examples:

- `make XFCE look like macOS but keep my existing MX menu shortcuts`
- `my panel layout looks broken after theming, fix only panel and font`
- `apply only icons + cursor, no dock replacement`

Explicit skill invocation examples (if supported by your client):

- `$xfce-macos-transform make XFCE look like macOS Sonoma style`
- `$xfce-macos-transform fix font size, panel position, and duplicate menus`
- `$xfce-macos-transform generate a safe bash script for Ubuntu XFCE`

## Repository Layout

- `SKILL.md`: Trigger description and execution workflow.
- `agents/openai.yaml`: UI metadata for skill lists/chips.
- `references/components.md`: Component-level implementation guidance used by the skill.

## Notes

- Target environments are Debian/Ubuntu-family XFCE setups unless adapted in the generated output.
- Always review generated commands/scripts before running on your system.
