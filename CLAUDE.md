## Important Guidelines

- 未得到用户允许，不允许私自撰写文档
- 未得到用户允许，不允许自行推送代码

## Project Notes

- @webui_build.sh @lightrag_webui/ 前端项目路径为上述路径，当前端进行修改时，使用该脚本进行重新构建以确保生效

## Workflow Procedures

- 使用 ./auto-test-fix.sh 重启项目时的工作流程：
  - 执行 ./auto-test-fix.sh 脚本
  - 等待10秒钟
  - 查看日志检查项目是否成功启动
  - 等待用户反馈
  - 如果用户报告问题：
    - 首先检查 auto-test-fix.log 是否有错误
    - 如有错误，进行深入分析原因
    - 提供思考结果和修改方案给用户
    - 等待用户反馈
  - 修改完毕后，重新执行 ./auto-test-fix.sh

## AI 团队配置

根据项目技术栈，我们配置了以下 AI 专家团队来帮助您：

- **`backend-developer`**: 负责处理所有通用的 Python 和 FastAPI 后端任务。
- **`api-architect`**: 专注于设计、审查和改进 FastAPI 的 API 接口。
- **`react-component-architect`**: 领导 React 前端组件的设计和实现。
- **`tailwind-frontend-expert`**: 专门负责所有 Tailwind CSS 相关的样式和布局工作。
- **`code-reviewer`**: 在合并前对代码进行严格审查，确保质量和一致性。
- **`performance-optimizer`**: 识别和修复前后端的性能瓶颈。
- **`code-archaeologist`**: 当需要理解复杂或遗留代码时，由他进行分析和文档化。
