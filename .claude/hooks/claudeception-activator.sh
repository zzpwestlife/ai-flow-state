#!/bin/bash
# Skill Architect Activator (formerly Claudeception)
# Prompts to Create or Evolve skills.
# SILENT MODE: This script is now silent to avoid interrupting the workflow.

# Only run if DEBUG is set
if [ -n "$DEBUG" ]; then
cat << 'EOF'
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
🧠 SKILL ARCHITECT: EVOLUTION CHECK
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

After completing this task, evaluate if you have gained new knowledge:

1. NEW CAPABILITY?
   → Use `skill-architect` (Tool: Forge) to create a new skill.
   Example: `python3 .claude/skills/skill-architect/scripts/architect.py forge "new-skill" ...`

2. NEW WISDOM? (Bug fix, better prompt, preference)
   → Use `skill-architect` (Tool: Refine) to save it to an existing skill.
   Example: `python3 .claude/skills/skill-architect/scripts/architect.py refine "existing-skill" "fix" "..."`

This ensures your toolkit gets smarter over time.
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
EOF
fi
