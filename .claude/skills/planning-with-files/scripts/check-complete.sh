#!/bin/bash
# Check if all phases in task_plan.md are complete
# Tracks state in .claude/tmp/phase_state to detect transitions
# Writes detailed status to .claude/tmp/planning_status.md
# Output to stdout ONLY on significant events (Phase Complete, All Complete)

PLAN_FILE="${1:-task_plan.md}"

# Generate a unique state file path based on the plan file path
# This ensures that different projects/directories have isolated state
PLAN_ABS_PATH=$(cd "$(dirname "$PLAN_FILE")" && pwd)/$(basename "$PLAN_FILE")
PLAN_HASH=$(echo "$PLAN_ABS_PATH" | md5sum 2>/dev/null | awk '{print $1}')
if [ -z "$PLAN_HASH" ]; then
    # Fallback for macOS (md5) or if md5sum is missing
    PLAN_HASH=$(echo "$PLAN_ABS_PATH" | md5 -q 2>/dev/null)
fi
if [ -z "$PLAN_HASH" ]; then
    # Fallback if both fail (unlikely but safe)
    PLAN_HASH="default"
fi

STATE_FILE=".claude/tmp/phase_state_${PLAN_HASH}"
AUDIT_LOG=".claude/audit/planning.log"
STATUS_FILE=".claude/tmp/planning_status.md"

# Ensure dirs exist
mkdir -p "$(dirname "$STATE_FILE")"
mkdir -p "$(dirname "$AUDIT_LOG")"
mkdir -p "$(dirname "$STATUS_FILE")"

if [ ! -f "$PLAN_FILE" ]; then
    # No plan, nothing to do
    exit 0
fi

# --- ANALYSIS ---

# 1. Check Global Status
GLOBAL_COMPLETE=0
if grep -iE "\*\*Status:\*\*.*complete" "$PLAN_FILE" >/dev/null; then
    GLOBAL_COMPLETE=1
fi

# 2. Count phases
TOTAL=$(grep -c "^### Phase" "$PLAN_FILE" || true)

# 3. Count completed phases (regex specific to phase lines)
COMPLETE=$(grep -iE "^### Phase.*(\[complete\]|\[x\])" "$PLAN_FILE" | wc -l | tr -d ' ')

# 4. Count in-progress
IN_PROGRESS=$(grep -ic "\[in_progress\]" "$PLAN_FILE" || true)

# --- STATUS FILE GENERATION ---
{
    echo "# Planning Status"
    echo "Time: $(date)"
    echo "- Total Phases: $TOTAL"
    echo "- Completed: $COMPLETE"
    echo "- In Progress: $IN_PROGRESS"
    echo ""
    echo "## Details"
    grep "^### Phase" "$PLAN_FILE"
} > "$STATUS_FILE"

# --- STATE TRACKING ---

# Load Previous State
PREV_COMPLETE=0
if [ -f "$STATE_FILE" ]; then
    PREV_COMPLETE=$(cat "$STATE_FILE")
    # Basic validation
    if ! [[ "$PREV_COMPLETE" =~ ^[0-9]+$ ]]; then
        PREV_COMPLETE=0
    fi
fi

# Update state file
echo "$COMPLETE" > "$STATE_FILE"

# --- EVENT DETECTION ---

TIMESTAMP=$(date "+%Y-%m-%d %H:%M:%S")

# Case 1: Global Complete or All Phases Complete
if [ "$GLOBAL_COMPLETE" -eq 1 ] || { [ "$TOTAL" -gt 0 ] && [ "$COMPLETE" -ge "$TOTAL" ]; }; then
    echo "ALL PHASES COMPLETE"
    # Log if strictly new
    if [ "$PREV_COMPLETE" -lt "$TOTAL" ]; then
        echo "$TIMESTAMP: All phases completed ($COMPLETE/$TOTAL)" >> "$AUDIT_LOG"
    fi
    exit 0
fi

# Case 2: Phase Completion Event
if [ "$COMPLETE" -gt "$PREV_COMPLETE" ]; then
    echo "$TIMESTAMP: Phase $COMPLETE completed (Previous: $PREV_COMPLETE)" >> "$AUDIT_LOG"
    echo "EVENT: PHASE_COMPLETE"
    
    # Extract next phase title
    NEXT_NUM=$((COMPLETE + 1))
    NEXT_PHASE=$(grep "^### Phase" "$PLAN_FILE" | sed -n "${NEXT_NUM}p" | sed 's/^### //')
    if [ -n "$NEXT_PHASE" ]; then
        echo "NEXT_PHASE: $NEXT_PHASE"
    fi

    echo ""
    echo "🛑🛑🛑 STOP EXECUTION NOW 🛑🛑🛑"
    echo "Phase $COMPLETE is marked as COMPLETE."
    echo "ACTION REQUIRED: You MUST use AskUserQuestion to present the 'Continue Execution' menu."
    echo "Options: [Continue to Phase $(($COMPLETE + 1))] [Pause / Review]"
    echo "DO NOT automatically proceed."
    exit 0
fi

# Case 3: Revert (Log but maybe don't stop execution? Or warn?)
if [ "$COMPLETE" -lt "$PREV_COMPLETE" ]; then
    echo "$TIMESTAMP: Phase reverted to $COMPLETE (Previous: $PREV_COMPLETE)" >> "$AUDIT_LOG"
    # echo "EVENT: PHASE_REVERT"
    # Silent on revert to allow correction without nagging
    exit 0
fi

# Case 4: Plan Ready (Start of Phase 1)
# TOTAL > 0, COMPLETE = 0, IN_PROGRESS = 0
if [ "$TOTAL" -gt 0 ] && [ "$COMPLETE" -eq 0 ] && [ "$IN_PROGRESS" -eq 0 ]; then
    echo "EVENT: PLAN_READY"
    # echo "Details: Plan created/updated, ready for Phase 1."
    exit 0
fi

# Case 5: In Progress (Silent)
# No output = No interruption
exit 0
