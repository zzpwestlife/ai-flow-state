# Coding Standards & Collaboration

## 1. Tech Stack & Environment
- **Languages**: Go, PHP, Python, Shell
- **Tools**: Claude Code, MCP, Docker

## 2. AI Collaboration Instructions
### 2.1 Execution Guidelines
Apply "Simplicity Principle" to the execution itself.
- **Discovery**: Clarify needs and define scope (Iteration Scoping).
- **Read First**: Always read relevant files and context before modifying.
- **TDD**: Implement with Test-Driven Development where applicable.
- **Surgical Changes**: If task requires modifying > 3 files, verify against the plan.
- **Self-Verification**: Manually verify changes (run tests, check output) before handing off.
- **Delivery**: List verification results.

### 2.2 Quality Assurance
- **Code Quality Principles**:
  - **Demand Elegance**: For non-trivial changes, pause and ask "Is there a more elegant way?". If a fix feels hacky, stop and redesign.
  - **Readability First**: Prioritize readability; make the simplest necessary changes.
  - **Strict Typing**: No `any` type (or equivalent); define explicit types. No `eslint-disable` or `@ts-ignore`.
  - **Clean Code**: Delete unused code immediately; do not comment it out.
  - **Reuse First**: Check for existing implementations/utils before writing new code.
- **Naming & Style**:
  - **Conventions**: Follow language-specific standards (Go: Tabs, Python: 4 spaces/snake_case). For JS/TS, use 2 spaces.
  - **Naming**: Use camelCase for variables (unless language demands otherwise) and verb-first function names (e.g., `getUserById`).
- **Surgical Changes**: Touch only what you must. Clean up only your own mess.
- **Autonomous Bug Fixing**:
  - When given a bug report: **Just fix it**. Don't ask for hand-holding.
  - Point at logs, errors, failing tests -> then resolve them.
  - Zero context switching required from the user.
- **Risk Review**: List potential broken functionality and suggest test coverage.
- **Test Writing**: Prioritize table-driven tests.
- **Production Mindset**: Handle edge cases; do not assume "happy path".

### 2.3 Code Review Workflow
- Pre‑flight: read `constitution.md` and the language annex under `docs/constitution/`.
- Scope guard: if a change touches more than 3 files or crosses multiple modules, run a planning step (/plan) first and define acceptance criteria.
- Mode selection: use `.claude/commands/review-code.md` to choose between Diff Mode (incremental) or Full Path Review.
- Static analysis: run language‑specific checks (Go: go vet, Python: flake8, PHP: manual read).
- Module metadata check: ensure each module directory has a README that states Role/Logic/Constraints and lists submodules; ensure source files start with three header lines (INPUT/OUTPUT/POS). Record missing items in the review report.
- Evidence‑based: only call online documentation (e.g., Context7) when local specs and annexes are insufficient.
- SubAgent usage: delegate heavy searches to SubAgents to preserve current session context and avoid context window overload.
- Delivery hygiene: after review and fixes, clean temporary artifacts and ensure `.gitignore` prevents local outputs from being committed.
