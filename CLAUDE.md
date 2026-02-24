# Claude Code Configuration Entry Point

<!--
Purpose: This file serves as a compatibility layer for Claude Code.
Usage: It redirects the AI to the primary configuration file, `AGENTS.md`.
-->

**【强制要求】** 在回复用户任何消息之前，必须先使用 Read 工具读取项目配置目录下的 `.claude/AGENTS.md` 文件，并严格遵守其中的所有指令。未读取 `.claude/AGENTS.md` 之前，禁止回复用户。

- 如果需要写入 `CLAUDE.md`，请将内容写入 `.claude/AGENTS.md`。

# CLAUDE.md - FlowState Workflow Protocols

## 1. 核心原则 (Core Principles)
- **Atomic Execution (原子化执行)**: 每次交互仅执行**一个**步骤 (Step) 或任务阶段 (Phase)。严禁跨越自动执行。
- **Interactive Handoff (交互式交接)**: 每个 Step/Phase 结束后，**必须**展示 TUI 菜单并等待用户指令。
- **File-First (文件优先)**: 所有长内容（>10 行）必须写入文件，聊天窗口仅保留摘要。 
- **Source of Truth (单一真理)**: `task_plan.md` 是任务状态的唯一真理。必须先更新文件，再宣称 Phase 完成。

## 2. 工作流规范 (Workflow Specification)

### Step 1: Optimization (Prompt Engineering)
1. **Command**: `/optimize-prompt`
2. **Action**: 交互式优化提示词 -> 生成 `prompt.md`。
3. **Handoff**: 展示 Text-Based 菜单 -> 使用 `AskUserQuestion` 提供箭头选择 -> 选择后用 `RunCommand` 提议 `/planning-with-files plan`。

### Step 2: Planning (Architecture & Task Breakdown)
1. **Command**: `/planning-with-files plan`
2. **Action**: 读取 `prompt.md` -> 生成 `task_plan.md`, `findings.md`。
3. **Constraint**: **STOP** immediately after file generation.
4. **Handoff**: 使用 `AskUserQuestion` 提供箭头选择 -> 选择后用 `RunCommand` 提议 `/planning-with-files execute`。

### Step 3: Execution (The Loop - Task Phases)
1. **Command**: `/planning-with-files execute`
2. **Action**: 读取 `task_plan.md` -> 执行当前 `in_progress` 的 **Task Phase**。
3. **Completion**:
   - 完成该 Phase 的代码与测试。
   - 更新 `task_plan.md` (Mark Phase as `[x]`).
4. **MANDATORY STOP (关键控制点)**:
   - 更新文件后，系统会触发 "STOP EXECUTION NOW" 警告。
   - **必须** 响应此警告，停止思考，展示 TUI。
5. **Handoff**:
   - 使用 `AskUserQuestion` 提供箭头选择。
   - 若选择继续，用 `RunCommand` 提议 `/planning-with-files execute`。

## 3. TUI 交互标准 (Interaction Standards)

**Universal Rule**: 每一个工作流步骤 (Step) 结束后，**必须**展示 TUI 菜单并等待用户指令。严禁自动跳过。所有菜单必须支持**中英双语**。

### 3.1 Step 1: Optimization -> Planning
- **Trigger**: `prompt.md` 生成完毕。
- **Menu Options**:
  1. **Start Planning**
     - **Label**: `Start Planning (进入规划阶段)`
     - **Action**: Propose `/planning-with-files plan`
  2. **Refine Prompt**
     - **Label**: `Refine Prompt (继续优化)`
     - **Action**: Wait for user input

### 3.2 Step 2: Planning -> Execution
- **Trigger**: `task_plan.md` 生成完毕。
- **Menu Options**:
  1. **Execute Plan**
     - **Label**: `Execute Plan (开始执行计划)`
     - **Action**: Propose `/planning-with-files execute`
  2. **Review Plan**
     - **Label**: `Review Plan (审查计划)`
     - **Action**: Wait for user input

### 3.3 Step 3: Execution Loop (Phase Handoff)
- **Trigger**: 单个 Task Phase 完成 (Phase Completed)。
- **Menu Options**:
  1. **Continue Execution**
     - **Label**: `Continue Execution (Start Next Phase)`
     - **Description**: `开始 [Next Phase Title]` (Dynamic)
     - **Action**: Propose `/planning-with-files execute`
  2. **Pause / Review**
     - **Label**: `Pause / Review`
     - **Description**: `暂停执行，审查代码`
     - **Action**: Wait for user input

### 3.4 Step 3 -> Step 4: Execution Done -> Review
- **Trigger**: 所有 Phase 完成 (All Phases Complete)。
- **Menu Options**:
  1. **Proceed to Code Review**
     - **Label**: `Proceed to Code Review (进入代码审查)`
     - **Action**: Propose `/review-code`
  2. **Generate Changelog**
     - **Label**: `Generate Changelog (生成变更日志)`
     - **Action**: Propose `/changelog-generator`

### 3.5 Step 4: Review -> Changelog
- **Trigger**: 代码审查报告生成完毕。
- **Menu Options**:
  1. **Generate Changelog**
     - **Label**: `Generate Changelog (生成变更日志)`
     - **Action**: Propose `/changelog-generator`
  2. **Fix Issues**
     - **Label**: `Fix Issues (修复问题)`
     - **Action**: Wait for user input

### 3.6 Step 5: Changelog -> Commit
- **Trigger**: CHANGELOG.md 更新完毕。
- **Menu Options**:
  1. **Generate Commit Message**
     - **Label**: `Generate Commit Message (生成提交信息)`
     - **Action**: Propose `/commit-message-generator`
  2. **Edit Changelog**
     - **Label**: `Edit Changelog (编辑日志)`
     - **Action**: Wait for user input

## 4. 验证与强制机制 (Enforcement)
- **Hook Verification**: 每次 `Write` 操作后，`check-complete.sh` 会自动运行。
- **Stop Signal**: 如果脚本检测到 Task Phase 完成，会输出 `🛑 STOP EXECUTION NOW 🛑` 并显示下一阶段名称。
- **Protocol**: 见到此信号，**必须**立即停止当前推理链，使用 `AskUserQuestion` 展示 TUI 菜单。
