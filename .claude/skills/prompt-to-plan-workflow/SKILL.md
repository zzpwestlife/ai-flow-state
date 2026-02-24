---
name: prompt-to-plan-workflow
description: |
  Complete workflow for transforming user requests into structured plans using
  /optimize-prompt and /planning-with-files skills. Use when: (1) user request
  is vague or lacks technical details, (2) task requires multi-step planning
  (>3 phases), (3) need to ensure requirements clarity before execution,
  (4) working with projects that have constitution.md or strict quality standards.
  Covers the handoff pattern between prompt optimization and file-based planning,
  including user confirmation checkpoints and Constitution Check integration.
author: Claude Code
version: 1.0.0
date: 2026-02-13
---

# Prompt-to-Plan Workflow

## Problem
User requests often lack sufficient detail for direct execution, leading to:
- Misaligned implementations that don't meet actual needs
- Missing edge cases or quality requirements
- Skipped planning steps that cause rework
- Unclear success criteria

## Context / Trigger Conditions
Use this workflow when:
1. **Vague Requirements**: User says "add a feature" without specifying types, edge cases, or validation
2. **Complex Tasks**: Task involves >3 distinct phases or affects multiple files
3. **Quality-Critical Projects**: Project has `constitution.md`, `AGENTS.md`, or strict code standards
4. **First-Time Features**: Adding functionality to unfamiliar codebase
5. **User Mentions Planning**: User says "create a plan" or invokes `/optimize-prompt`

**Specific Triggers**:
- User runs `/optimize-prompt` command
- User asks "how should I implement X?"
- Task description lacks examples or expected behavior
- Project has planning templates (task_plan.md, findings.md, progress.md)

## Solution

### Phase 1: Prompt Optimization (Skill: `/optimize-prompt`)

**Step 1**: Invoke `/optimize-prompt` with user's request
```
/optimize-prompt "user's original request" @relevant-file.ext
```

**Step 2**: System generates structured prompt with:
- XML-tagged sections (<task>, <context>, <instruction>, <constraints>, <examples>)
- Explicit requirements and anti-patterns
- Verification criteria
- Expected input/output format

**Step 3**: User confirmation checkpoint
- Use `AskUserQuestion` to provide arrow-key choices:
  - "满意，进入规划"
  - "满意，结束"
  - "不满意，需要修改"
- If user chooses "满意，进入规划", use `RunCommand(requires_approval=False)` to execute `/planning-with-files plan`.
- **Critical**: Use `AskUserQuestion` for the decision, then `RunCommand` for zero-friction execution.

### Phase 2: File-Based Planning (Skill: `/planning-with-files:plan`)

**Step 4**: If user approves, invoke planning skill
```
/planning-with-files:plan
```

**Step 5**: System creates three planning files:
- `task_plan.md` - Roadmap with Constitution Check gate
- `findings.md` - Research discoveries and technical decisions
- `progress.md` - Session log with 5-Question Reboot Check

**Step 6**: Constitution Check (if project has constitution.md)
```markdown
## Constitution Check
**GATE: Must pass before technical design.**

- [ ] **Simplicity (Art. 1):** Use stdlib? Avoid over-abstraction?
- [ ] **Test First (Art. 2):** Plan includes tests before implementation?
- [ ] **Clarity (Art. 3):** Errors handled? No global state?
- [ ] **Core Logic (Art. 4):** Business logic decoupled from interfaces?
- [ ] **Security (Art. 11):** Inputs validated? No sensitive data leakage?
```

**Step 7**: Phase breakdown (typical structure)
- Phase 1: Requirements & Discovery
- Phase 2: Test-First Development (TDD red phase)
- Phase 3: Implementation (TDD green phase)
- Phase 4: Testing & Verification
- Phase 5: Delivery

### Phase 3: Execution (Follow task_plan.md)

**Step 8**: Execute phases sequentially
- Mark each phase `in_progress` when starting
- Update `progress.md` with actions taken and files modified
- Log errors in Error Log table
- Mark phases `complete` when verified

**Step 9**: Continuous documentation
- Update `findings.md` when discovering non-obvious solutions
- Record test results in `progress.md` Test Results table
- Maintain 5-Question Reboot Check for session resumability

### Phase 4: Handoff

**Step 10**: After completing all phases
- Update `task_plan.md` Current Phase to final phase
- Mark all phases as `[x] complete`
- Generate delivery report with:
  - Deliverables checklist
  - Constitution compliance verification
  - Test results summary
- **Reflective Handoff (Menu)**:
  - Use `AskUserQuestion` to present options (Changelog > Commit > README > Done).
  - Recommended Next Step: `/changelog-generator`

## Verification

### Workflow Completion Checklist
- [ ] `/optimize-prompt` generated structured prompt with examples
- [ ] User explicitly approved plan before execution
- [ ] All three planning files created (task_plan.md, findings.md, progress.md)
- [ ] Constitution Check passed (if applicable)
- [ ] All phases marked complete in task_plan.md
- [ ] Test results documented in progress.md
- [ ] 5-Question Reboot Check answerable

### Quality Gates
- [ ] No phase skipped (especially Phase 2: Test-First)
- [ ] Each phase has "Actions taken" documented
- [ ] Files modified list matches actual changes
- [ ] Error Log filled (even if "尚无错误")

## Example: Complete Workflow Execution

**User Request**: "为 demo_math.py 增加一个 multiply 乘法函数"

**Step 1-3: Prompt Optimization**
```
Assistant: 调用 /optimize-prompt
→ 生成包含 6 个测试场景的结构化 Prompt
→ 询问用户：满意吗？进入规划？
User: "满意，进入规划"
```

**Step 4-7: Planning**
```
Assistant: 调用 /planning-with-files:plan
→ 创建 task_plan.md (Constitution Check ✅ 通过)
→ 创建 findings.md (记录现有代码风格：无类型注解)
→ 创建 progress.md (Phase 1: Requirements & Discovery - complete)
→ 5 阶段规划：Discovery → Test-First → Implementation → Verification → Delivery
```

**Step 8-9: Execution**
```
Phase 2: 编写 pytest 参数化测试 (TDD 红灯)
  ├─ 验证 ImportError: multiply 不存在 ✅
Phase 3: 实现 multiply 函数
  ├─ 添加函数，保持风格一致 ✅
Phase 4: 验证测试通过 (TDD 绿灯)
  ├─ 所有 6 个场景通过 ✅
```

**Step 10: Handoff**
```
Assistant: 生成交付报告
  ├─ Deliverables: demo_math.py ✅, test_demo_math.py ✅
  ├─ Constitution Compliance: 9/9 ✅
  ├─ Test Results: 5/5 passed
  ├─ Optional: pip install pytest
```

## Notes

### Critical Success Factors
1. **User Confirmation**: NEVER auto-proceed from /optimize-prompt to /planning-with-files without explicit user approval
2. **Constitution Check**: If project has constitution.md, this is MANDATORY gate before technical design
3. **TDD Enforcement**: Phase 2 (tests) MUST come before Phase 3 (implementation), even if tests initially fail
4. **Documentation Hygiene**: Update progress.md after EACH phase, not at the end

### Common Pitfalls
- ❌ Skipping prompt optimization when requirements are unclear
- ❌ Auto-proceeding to planning without user buy-in
- ❌ Implementing before writing tests (violates Constitution Art. 2)
- ❌ Forgetting to update progress.md during execution
- ❌ Skipping Constitution Check when constitution.md exists

### Workflow Variations

**Variation 1: Simple Tasks (No Planning Needed)**
```
User: "Fix typo in README"
→ Skip this workflow, execute directly
```

**Variation 2: Planning Only (No Optimization)**
```
User: "I have detailed requirements, just need a plan"
→ Skip /optimize-prompt, go directly to /planning-with-files:plan
```

**Variation 3: Research-Heavy Tasks**
```
User: "Understand how authentication works in this codebase"
→ /optimize-prompt → /planning-with-files:plan
→ Phase 2: Use Task(subagent_type=Explore) for codebase discovery
```

### Integration with Other Skills
- **Prerequisite**: `/optimize-prompt` (Prompt engineering)
- **Core**: `/planning-with-files:plan` (Manus-style planning)
- **Follow-up**: `/claudeception` (Extract learnings after delivery)
- **Parallel**: `constitution.md` (Quality governance)

### Session Recovery
If conversation is interrupted (/clear or context reset):
1. Read `progress.md` → 5-Question Reboot Check
2. Read `task_plan.md` → Current Phase
3. Read `findings.md` → Key decisions made
4. Resume from Current Phase in task_plan.md

### Metrics for Success
- **Planning Quality**: Can answer all 5 Reboot Questions without re-reading full conversation?
- **Execution Alignment**: Zero rework due to misunderstood requirements?
- **Constitution Compliance**: 100% pass rate on Constitution Check items?
- **Documentation Completeness**: All phases have "Actions taken" + "Files modified"?

## References
- Verified through actual execution: 2026-02-13 session (learn-claude-code project)
- Manus Planning System: /planning-with-files:plan skill
- Anthropic Prompt Engineering: XML tags, Few-Shot, Chain-of-Thought
- Project Constitution: constitution.md, AGENTS.md governance
