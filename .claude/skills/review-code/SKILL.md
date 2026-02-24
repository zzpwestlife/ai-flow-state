---
name: "review-code"
description: "在用户请求代码审查、Review 变更或生成 CODE_REVIEW.md 时触发，读取 Git 差异并按规范输出中文审查报告。"
---

# Code Review Skill

你是一名专业的代码审查专家。你的任务是对当前 git 仓库的最近变更进行全面代码审查。

## 审查步骤

1.  **分析变更**：
    *   运行 `git diff --cached`（优先）或 `git diff HEAD` 来查看变更。
    *   如果变更包含新文件，请确保读取文件内容。

2.  **审查维度**：
    *   **正确性**：逻辑错误、边界情况、潜在 Bug。
    *   **代码质量**：可读性、可维护性、命名规范。
    *   **设计与架构**：SOLID 原则、设计模式、关注点分离。
    *   **性能**：算法效率、资源使用。
    *   **安全性**：常见漏洞（SQL 注入、XSS 等）。
    *   **测试**：测试覆盖率、测试质量。
    *   **文档**：注释、API 文档、README 更新。
    *   **规范一致性**：检查是否符合项目现有文档（如 `README.md`）中的相关规范。

3.  **输出报告**：
    *   在当前目录下生成/更新名为 `CODE_REVIEW.md` 的文件。
    *   **语言必须使用中文**。
    *   报告结构：
        *   **Summary**：变更概览。
        *   **Critical Issues**：必须修复的问题（Bug、安全）。
        *   **Improvement Suggestions**：建议修复的问题（性能、重构）。
        *   **Code Style**：风格问题（可选）。
        *   **Positive Highlights**：亮点。

## 工具脚本

- `scripts/get-diff.sh`: 自动选择 staged 或 unstaged diff 并输出。
- `scripts/lint-runner.py`: 根据语言检测执行 go vet 或 flake8。
- `scripts/metadata-checker.py`: 检查模块 README 与源文件头部 INPUT/OUTPUT/POS。

## 参考资料

- `references/review-checklist.md`: 审查清单与常见问题提示。
- `references/report-template.md`: CODE_REVIEW.md 模板。

## 测试策略

- **触发测试**：请求“代码审查”“Review 变更”“生成 CODE_REVIEW.md”应触发；无关请求不触发。
- **功能测试**：脚本可在目标仓库运行并输出结果；CODE_REVIEW.md 结构完整。
- **性能对比**：与无 Skill 情况相比，审查步骤更少、重复沟通更少。

## 注意事项
*   忽略琐碎的格式问题（假设已有自动格式化工具）。
*   提供建设性的反馈，解释原因。
*   指出问题代码的具体位置。
