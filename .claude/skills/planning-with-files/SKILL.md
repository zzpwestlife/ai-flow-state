name: planning-with-files
version: "2.13.0"
description: Implements Manus-style file-based planning for complex tasks. Creates task_plan.md, findings.md, and progress.md. Use when starting complex multi-step tasks, research projects, or any task requiring >5 tool calls. Supports output directory argument.
user-invocable: true
allowed-tools:
  - Read
  - Write
  - Edit
  - Bash
  - Glob
  - Grep
  - webfetch
  - websearch_web_search_exa
  - AskUserQuestion
  - RunCommand
  - LS
hooks:
  PostToolUse:
    - matcher: "Write|Edit|SearchReplace|Bash|RunCommand"
      hooks:
        - type: command
          command: |
            # Find project root by walking up to find .claude
            d="$PWD"; ROOT_DIR=""; while [ "$d" != "/" ]; do if [ -d "$d/.claude" ]; then ROOT_DIR="$d"; break; fi; d=$(dirname "$d"); done; if [ -z "$ROOT_DIR" ]; then ROOT_DIR="$PWD"; fi
            
            SCRIPT_DIR="$ROOT_DIR/.claude/skills/planning-with-files/scripts"
            CHECK_SCRIPT="$SCRIPT_DIR/check-complete.sh"
            
            # Fallback logic if script not found via relative path
            if [ ! -f "$CHECK_SCRIPT" ]; then
                if [ -f "$HOME/.claude/skills/planning-with-files/scripts/check-complete.sh" ]; then
                    CHECK_SCRIPT="$HOME/.claude/skills/planning-with-files/scripts/check-complete.sh"
                fi
            fi
            
            # Attempt to find task_plan.md in current dir, immediate subdirs, or project root
            # Prioritize the most recently modified file to catch the one just written
            if [ -n "$CLAUDE_OS_IS_MACOS" ] || [ "$(uname)" = "Darwin" ]; then
                # macOS find doesn't support -printf, use stat for sorting if possible, or simple find
                PLAN_FILE=$(find . -maxdepth 3 -name task_plan.md -not -path '*/.*' -exec stat -f "%m %N" {} + | sort -rn | head -n 1 | cut -d' ' -f2-)
            else
                # Linux find
                PLAN_FILE=$(find . -maxdepth 3 -name task_plan.md -not -path '*/.*' -printf "%T@ %p\n" | sort -rn | head -n 1 | cut -d' ' -f2-)
            fi
            
            # Fallback if find failed or returned nothing
            if [ -z "$PLAN_FILE" ]; then
                PLAN_FILE=$(find . -maxdepth 2 -name task_plan.md -not -path '*/.*' 2>/dev/null | head -n 1)
            fi

            if [ -z "$PLAN_FILE" ]; then
                if [ -f "$ROOT_DIR/task_plan.md" ]; then
                    PLAN_FILE="$ROOT_DIR/task_plan.md"
                else
                    PLAN_FILE="task_plan.md"
                fi
            fi
            
            # Run check script safely
            if [ -f "$CHECK_SCRIPT" ]; then
                OUTPUT=$(sh "$CHECK_SCRIPT" "$PLAN_FILE" 2>/dev/null || true)
            else
                OUTPUT=""
            fi
            
            # Concise output: only show status if changed or complete
            if [ -n "$OUTPUT" ]; then
                echo "Planning Status Updated: [View Status](file://${ROOT_DIR}/.claude/tmp/planning_status.md)"
            fi

            if echo "$OUTPUT" | grep -q "ALL PHASES COMPLETE"; then
              echo ""
              echo "<system-reminder>"
              echo "✅ SYSTEM NOTICE: All phases in task_plan.md are complete."
              echo "👉 ACTION REQUIRED: Present the TUI Menu for completion (全部完成)."
              echo "  1. Use 'AskUserQuestion' to present choices:"
              echo "     - Label: 'Proceed to Code Review', Description: '进入代码审查 (/review-code)'"
              echo "     - Label: 'Generate Changelog', Description: '生成变更日志 (/changelog-generator)'"
              echo "  2. Use 'RunCommand' to propose the chosen next step."
              echo "</system-reminder>"
            elif echo "$OUTPUT" | grep -q "EVENT: PHASE_COMPLETE"; then
              NEXT_PHASE=$(echo "$OUTPUT" | grep "NEXT_PHASE:" | cut -d':' -f2- | sed 's/^ *//')
              if [ -z "$NEXT_PHASE" ]; then NEXT_PHASE="Next Phase"; fi
              echo ""
              echo "<system-reminder>"
              echo "🛑 STOP! EXECUTION PAUSE REQUIRED 🛑"
              echo "Phase completed. You MUST STOP NOW."
              echo "👉 ACTION REQUIRED: Present the TUI Menu for Phase Completion."
              echo "  1. Use 'AskUserQuestion' to present these exact choices:"
              echo "     - Label: 'Continue Execution (Start Next Phase)'"
              echo "       Description: '开始 ${NEXT_PHASE}'"
              echo "     - Label: 'Pause / Review'"
              echo "       Description: '暂停执行，审查代码'"
              echo "  2. If 'Continue' is selected, use 'RunCommand' to propose /planning-with-files execute."
              echo "</system-reminder>"
            elif echo "$OUTPUT" | grep -q "EVENT: PLAN_READY"; then
              FIRST_PHASE=$(grep "^### Phase" "$PLAN_FILE" | head -n 1 | sed 's/^### //')
              if [ -z "$FIRST_PHASE" ]; then FIRST_PHASE="Phase 1"; fi
              echo ""
              echo "<system-reminder>"
              echo "ℹ️ SYSTEM NOTICE: Plan detected (0 phases complete)."
              echo "If you have finished creating/updating the plan:"
              echo "👉 STOP IMMEDIATELY. Do not start Phase 1."
              echo "👉 Use 'AskUserQuestion' to present arrow-key choices:"
              echo "     - Label: 'Execute Plan (Start Phase 1)'"
              echo "       Description: '开始执行计划: ${FIRST_PHASE}'"
              echo "     - Label: 'Review Plan'"
              echo "       Description: '审查计划 (Review task_plan.md)'"
              echo "👉 If 'Execute' is selected, use 'RunCommand' to propose /planning-with-files execute."
              echo "</system-reminder>"
            fi
  Stop:
    - hooks:
        - type: command
          command: |
            SCRIPT_DIR="${CLAUDE_PLUGIN_ROOT:-$HOME/.claude/skills/planning-with-files}/scripts"

            IS_WINDOWS=0
            if [ "${OS-}" = "Windows_NT" ]; then
              IS_WINDOWS=1
            else
              UNAME_S="$(uname -s 2>/dev/null || echo '')"
              case "$UNAME_S" in
                CYGWIN*|MINGW*|MSYS*) IS_WINDOWS=1 ;;
              esac
            fi
            
            # Check completion status on session stop
            sh "$SCRIPT_DIR/check-complete.sh" "task_plan.md" 2>/dev/null | grep -q "ALL PHASES COMPLETE"
            if [ $? -eq 0 ]; then
                echo ""
                echo "🎉 **Plan Execution Complete!**"
                echo "👉 Please run \`/review-code\` to proceed."
            fi

            if [ "$IS_WINDOWS" -eq 1 ]; then
              if command -v pwsh >/dev/null 2>&1; then
                pwsh -ExecutionPolicy Bypass -File "$SCRIPT_DIR/check-complete.ps1" 2>/dev/null ||
                powershell -ExecutionPolicy Bypass -File "$SCRIPT_DIR/check-complete.ps1" 2>/dev/null ||
                sh "$SCRIPT_DIR/check-complete.sh"
              else
                powershell -ExecutionPolicy Bypass -File "$SCRIPT_DIR/check-complete.ps1" 2>/dev/null ||
                sh "$SCRIPT_DIR/check-complete.sh"
              fi
            else
              sh "$SCRIPT_DIR/check-complete.sh"
            fi
---

# Planning with Files

Work like Manus: Use persistent markdown files as your "working memory on disk."

You are an expert software architect and project manager, specializing in "Planning-with-Files" methodology.

**CORE DIRECTIVE**: You must adhere to the protocols defined in `/CLAUDE.md`.

Your goal is to execute complex coding tasks by maintaining a PERSISTENT STATE in a `task_plan.md` file.

## Modes

1.  **Plan** (Default): Create or update planning files (`task_plan.md`, `findings.md`, `progress.md`).
    -   **Arguments**: `[output_dir]` (Optional)
    -   **VISUAL**: Start output with `[✔ Optimize] → [➤ Plan] → [Execute] → [Review] → [Changelog] → [Commit]`
    -   **DIRECTORY CONTEXT**:
        -   **CRITICAL**: If `output_dir` is provided, you **MUST** create all files (`task_plan.md`, `findings.md`, `progress.md`) INSIDE that directory.
        -   Example: `output_dir` = "fib" -> Create `fib/task_plan.md`, `fib/findings.md`.
        -   **DO NOT** create files in the root directory if `output_dir` is specified.
        -   If `output_dir` is provided, **Read** `prompt.md` from that directory (if it exists).
        -   All planning files (`task_plan.md`, `findings.md`, `progress.md`) **MUST** be created in `output_dir` (if provided) or current directory.
    -   **PHASE 0: SOCRATIC INTERVIEW (Mandatory)**:
        -   Before generating the plan, you **MUST** pause and consider: "Do I have enough context to build a solid architectural plan?"
        -   If unsure about *Tech Stack*, *Testing Strategy*, *Edge Cases*, or *User Preferences*, use `AskUserQuestion` **IMMEDIATELY**.
        -   **Format**: Use the TUI-style format:
            ```
            ────────────────────────────────────────────────────────────────────────────────
            ←  ☐ Tech Stack  ☐ Architecture  ☐ Testing  ✔ Plan Generation  →
            
            为了确保方案的稳健性，我需要确认以下关键点：
            
            1. [Question 1]
               [Description]
            2. [Question 2]
               [Description]
            ...
            ────────────────────────────────────────────────────────────────────────────────
            ```
    -   **GOAL**: ONLY create/update the plan.
    -   **FORBIDDEN**: DO NOT execute any tasks. DO NOT create code files (except plan files).
    -   **STOP**: Terminate immediately after writing the plan files.
2.  **Execute** (Triggered by arg `execute` or command `/planning-with-files execute`):
    -   **Arguments**: `execute [output_dir]`
    -   **VISUAL**: Start output with `[✔ Optimize] → [✔ Plan] → [➤ Execute] → [Review] → [Changelog] → [Commit]`
    -   **DIRECTORY CONTEXT**:
        -   If `output_dir` is provided, look for `task_plan.md` in that directory.
        -   Execute tasks relative to the project root, but update status in `output_dir/task_plan.md` and `output_dir/progress.md`.
    -   **SILENT MODE / FILE-FIRST OUTPUT**:
        -   To keep the chat window clean, **ALL** intermediate detailed outputs MUST be saved to files in `{output_dir}`.
        -   **Scenarios**:
            -   **Detailed Analysis/Thinking**: If your analysis exceeds 10 lines, write it to `{output_dir}/analysis_phase_[X].md` (or similar) and only provide a summary + link in chat.
            -   **Long Command Output**: If a command is expected to produce verbose output (logs, test results), redirect it: `cmd > {output_dir}/run_[name].log`.
            -   **Scratchpad**: Use `{output_dir}/scratchpad.md` for temporary notes or drafts.
        -   **Rule**: "Don't print it if you can file it."
        -   **Format**: When referencing these files, use the format: `[View Analysis](file://{absolute_path})`.
    -   **SINGLE PHASE GUARANTEE (STRICT)**:
        -   You are authorized to complete **EXACTLY ONE (1)** phase per turn.
        -   **NEVER** chain multiple phases. **NEVER** "just do the next one".
        -   **VIOLATION**: Executing >1 phase triggers a critical workflow failure.
    -   **ATOMIC EXECUTION (NON-NEGOTIABLE)**:
  -   You must execute **ONE TASK PHASE AT A TIME**.
  -   **SINGLE SOURCE OF TRUTH**: You cannot claim a phase is complete in the chat unless `task_plan.md` is updated.
  -   **VERIFICATION FIRST**: Before outputting "Phase X Complete", you MUST invoke `Write` or `SearchReplace` to update `task_plan.md` (mark items `[x]` and status `complete`).
  -   **PHASE GATE**: The transition between phases is **GATED**. You need explicit user permission to pass.
  -   **FATAL ERROR WARNING**: Any attempt to proceed to the next phase (e.g., running commands for Phase X+1) in the same turn as completing Phase X is a **CRITICAL ALIGNMENT FAILURE**.
  -   **MANDATORY STOP**: When you update `task_plan.md` to mark a phase as `complete` or `pending` -> `in_progress`:
            1.  **Call the Tool** (`Write`/`SearchReplace`).
            2.  **STOP GENERATING**. Do not output "Moving to next phase". Do not output "Ready for Phase X+1".
            3.  **WAIT** for the System Reminder from the PostToolUse hook.
            4.  **ONLY THEN** present the TUI Menu.
    -   **INTERACTIVE HANDOFF (MANDATORY)**:
        -   You MUST pause after updating `progress.md` and present options.
        -   **Use `AskUserQuestion`** to present the menu:
            -   "Continue Execution (Start next phase)"
            -   "Pause / Review"
        -   **Action**:
            -   If "Continue": use `RunCommand` to propose `/planning-with-files execute`.
            -   If "Pause": Wait for user instructions.

## FIRST: Check for Previous Session (v2.2.0)

**Before starting work**, check for unsynced context from a previous session:

```bash
# Linux/macOS
$(command -v python3 || command -v python) ${CLAUDE_PLUGIN_ROOT}/scripts/session-catchup.py "$(pwd)"
```

```powershell
# Windows PowerShell
& (Get-Command python -ErrorAction SilentlyContinue).Source "$env:USERPROFILE\.claude\skills\planning-with-files\scripts\session-catchup.py" (Get-Location)
```

If catchup report shows unsynced context:
1. Run `git diff --stat` to see actual code changes
2. Read current planning files
3. Update planning files based on catchup + git diff
4. Then proceed with task

## Workflow Handoff (Zero-Friction + User Control)

**When Planning (Mode 1) is Complete:**
After you have successfully created or updated the planning files (`task_plan.md`, etc.):

1.  **STOP IMMEDIATELY**:
    -   **DO NOT** execute any tasks from the plan yet.
    -   **DO NOT** create project directories or code files yet.
    -   The user **MUST** have the opportunity to review and modify the plan.

2.  **Summary**: Briefly list the created files and the current status (e.g., "Phase 1 Ready").

3.  **Reflective Handoff (Interactive Menu)**:
    -   First, print the Visual Progress Bar:
        `[✔ Optimize] → [✔ Plan] → [➤ Execute] → [Review] → [Changelog]`
    -   Then, use `AskUserQuestion` to present the menu:
        -   **Question**: "Planning Complete. Review `{output_dir}/task_plan.md`. Next step?"
        -   **Options**:
            -   "Execute Plan (Start Phase 1)"
            -   "Modify Plan"
            -   "View Files"

4.  **Action**:
    -   **Option 1 (Execute)**: use `RunCommand` to propose `/planning-with-files execute {output_dir}`.
    -   **Option 2 (Modify)**: Ask the user for specific changes.
    -   **Option 3 (View)**: Use `Read` tool to show file contents.

**When Execution (Mode 2) is Complete:**

### Case A: Single Phase Complete (More phases remain)

1.  **Summary**: Report completion of the current phase.
2.  **Reflective Handoff (Interactive Menu)**:
    -   First, print the Visual Progress Bar:
        `[✔ Phase X] → [➤ Phase X+1]`
    -   Then, use `AskUserQuestion` to present the menu:
        -   **Question**: "Phase [X] Complete. Next step?"
        -   **Options**:
            -   "Continue Execution (Start Phase [X+1])"
            -   "Pause / Review"

3.  **Action**:
    -   **Option 1 (Continue)**: use `RunCommand` to propose `/planning-with-files execute {output_dir}`.
    -   **Option 2 (Pause)**: Wait for user instructions.

### Case B: All Phases Complete (Project Done)

1.  **Summary**: Report project completion.
2.  **Reflective Handoff (Interactive Menu)**:
    -   First, print the Visual Progress Bar:
        `[✔ Execute] → [➤ Changelog] → [Commit] → [Done]`
    -   Then, use `AskUserQuestion` to present the menu:
        -   **Question**: "Project Complete! Next step?"
        -   **Options**:
            -   "Generate Changelog (Recommended)"
            -   "Generate Commit Message"
            -   "Update README"
            -   "Done"

3.  **Action**:
    -   **Option 1 (Changelog)**: use `RunCommand` to propose `/changelog-generator {output_dir}`.
    -   **Option 2 (Commit)**: use `RunCommand` to propose `/commit-message-generator`.
    -   **Option 3 (README)**: Ask user for details or propose an edit.
    -   **Option 4 (Done)**: Output summary and exit.

## Important: Where Files Go

- **Templates** are in `${CLAUDE_PLUGIN_ROOT}/templates/`
- **Your planning files** go in **your project directory** or **{output_dir}** if specified.
