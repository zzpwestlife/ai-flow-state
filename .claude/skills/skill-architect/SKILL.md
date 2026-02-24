---
name: skill-architect
description: The master skill for creating, evolving, and maintaining other skills. It unifies the lifecycle of skills from birth (Forge) to growth (Refine).
version: "1.0.0"
user-invocable: true
allowed-tools:
  - Read
  - Write
  - Edit
  - Bash
  - Glob
  - Grep
---

# Skill Architect

The **Skill Architect** is the meta-skill responsible for the entire lifecycle of your skill library. It allows you to create new skills, record experiences to improve them, and keep them updated.

## 🛠 Core Tools

The architect provides a unified CLI tool located at `${CLAUDE_PLUGIN_ROOT}/scripts/architect.py`.

### 1. Forge (Create New Skill)
Use this when you want to encapsulate a new capability into a reusable skill.

```bash
python3 ${CLAUDE_PLUGIN_ROOT}/scripts/architect.py forge <name> --desc "<description>"
```

**Example:**
```bash
python3 ${CLAUDE_PLUGIN_ROOT}/scripts/architect.py forge "yt-dlp" --desc "A wrapper for video downloading"
```

### 2. Refine (Evolve Existing Skill)
Use this to save "wisdom" (preferences, bug fixes, prompts) into a skill. This updates the `evolution.json` and automatically restitches the `SKILL.md`.

```bash
python3 ${CLAUDE_PLUGIN_ROOT}/scripts/architect.py refine <name> <type> "<content>"
```

**Parameters:**
- `name`: The name of the skill (e.g., `planning-with-files`)
- `type`: One of `preference`, `fix`, `prompt`
- `content`: The text to save

**Example:**
```bash
python3 ${CLAUDE_PLUGIN_ROOT}/scripts/architect.py refine "yt-dlp" "fix" "Use --cookies-from-browser for 403 errors"
```

### 3. Stitch (Manual Update)
Manually force a re-generation of `SKILL.md` from the template and `evolution.json`.

```bash
python3 ${CLAUDE_PLUGIN_ROOT}/scripts/architect.py stitch <name>
```

## 🧠 Evolution Workflow

1.  **Discover**: You encounter an issue or find a better way to use a tool.
2.  **Record**: You use `architect.py refine` to save this insight.
3.  **Apply**: The next time you (or another agent) uses the skill, the `SKILL.md` will contain your insight in the "Learned Experience" section.

## 📂 Structure

Each skill created by Architect follows this structure:

```text
.claude/skills/<skill-name>/
├── SKILL.md          # Generated definition + Learned Experience
├── evolution.json    # The "brain" containing structured experience
└── scripts/          # Helper scripts
```
