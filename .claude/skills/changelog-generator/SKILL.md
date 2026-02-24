---
name: "changelog-generator"
description: "在用户请求生成变更日志、Changelog 或总结差异时触发，提取 Git 差异并辅助生成 CHANGELOG.md。"
---

# 变更日志生成器 (Changelog Generator)

本 Skill 提供了一个辅助脚本 `changelog_agent.py`，用于支持 AI Agent 完成变更日志的生成工作流。

## 工作流 (Workflow)

生成 Changelog 的过程由 AI Agent 驱动，脚本仅作为工具使用：

1.  **获取差异 (Fetch Diff)**: Agent 运行脚本获取当前代码与主分支的差异。
2.  **分析总结 (Analyze & Summarize)**: Agent 读取脚本输出的差异内容，利用 AI 能力分析代码变更的语义，生成高质量的 Changelog 内容。
3.  **更新文件 (Update File)**: Agent 将生成的内容写入 `CHANGELOG.md`。

## 用法 (Usage)

### 获取代码差异 (Get Git Diff)

获取当前分支（包括未提交的变更）与主分支 (`main` 或 `master`) 之间的所有代码差异。

- **命令**: `python3 .claude/skills/changelog-generator/scripts/changelog_agent.py`
- **输出**: 标准输出 (stdout) 显示完整的 `git diff` 内容。Agent 应读取此输出进行分析。

## 示例 (Examples)

**Agent 操作流程示例**:

1.  Agent 收到用户请求："生成 Changelog"。
2.  Agent 运行：`python3 .claude/skills/changelog-generator/scripts/changelog_agent.py`
3.  Agent 获取到 Diff 输出，分析发现新增了登录功能。
4.  Agent 编辑 `CHANGELOG.md`，添加 "## [Unreleased] - ✨ 新增用户登录功能..."。

## 前置条件 (Prerequisites)

- 确保项目是一个 Git 仓库。
- 确保 `changelog_agent.py` 存在于 `.claude/skills/changelog-generator/scripts/` 目录下。

## 工具脚本

- `scripts/changelog_agent.py`: 获取差异。

## 参考资料

- `references/conventional-commits.md`: 约定式提交与 Changelog 分类参考。

## 测试策略

- **触发测试**：请求“生成 Changelog”“变更日志”“总结差异”应触发；无关请求不触发。
- **功能测试**：脚本输出 diff。
- **性能对比**：对话轮次减少。
