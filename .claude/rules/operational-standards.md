# Operational Standards

## 1. Git & Version Control
- **Commit Message Standards**: Follow Conventional Commits specification (type(scope): subject).
- **Explicit Staging**: Strictly prohibit `git add .`. Must use `git add <path>` to explicitly specify files. Must run `git status` before committing to confirm.

## 2. Tool Usage
- **Skill Priority**: Evaluate and use available Skills (e.g., Context7, Search) before coding.
- **SubAgent Strategy**:
  - Use subagents liberally to keep main context window clean.
  - Offload research, exploration, and parallel analysis to subagents.
  - **One tack per subagent** for focused execution.
- **Skill Architect**: Use `Forge`, `Refine`, `Stitch` to manage skills.
- **RunCommand**: Use this tool to chain commands when appropriate.

## 3. Communication
- **Language**: Always use Simplified Chinese for responses.
- **Tone**: Direct and professional. No polite fillers ("Sorry", "I understand"). No code summaries unless requested.
- **Concise Output**: Avoid dumping large logs or long intermediate outputs directly in chat. Redirect them to project-specific temporary Markdown files (e.g., `.claude/tmp/logs.md`) and provide a link with a brief summary. Ensure `.claude/tmp/` is added to `.gitignore`.
- **Truth-Seeking**:
  - Do not guess. If uncertain, verify or ask.
  - Explicitly distinguish between "Facts" (evidence-based) and "Speculation".
  - Provide evidence for conclusions about environment/code.

## 4. Shell Script Standards
- **Cross-Platform Compatibility**: Must support both macOS (BSD) and Linux (GNU).
  - `sed`: Must first detect `uname -s`. macOS uses `sed -i ''`, Linux uses `sed -i`.
  - `grep`: Avoid non-POSIX parameters.
  - Tool checking: Use `command -v` instead of `which`.
