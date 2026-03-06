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

## Use

In your agent chat, ask:

- `make XFCE look like macOS`
- `fix my XFCE macOS layout and keep my existing menu shortcuts`
- `only apply macOS icon theme and dock`

The skill should auto-trigger from intent, or you can invoke it explicitly with `$xfce-macos-transform` if your client supports explicit skill calls.

## Repository Layout

- `SKILL.md`: Trigger description and execution workflow.
- `agents/openai.yaml`: UI metadata for skill lists/chips.
- `references/components.md`: Component-level implementation guidance used by the skill.

## Notes

- Target environments are Debian/Ubuntu-family XFCE setups unless adapted in the generated output.
- Always review generated commands/scripts before running on your system.
