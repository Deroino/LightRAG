# LightRAG 项目记忆文件

## Important Guidelines

- 未得到用户允许，不允许私自撰写文档
- 未得到用户允许，不允许自行推送代码

## 项目概述
LightRAG是一个基于图的快速RAG(检索增强生成)系统，支持多种LLM和嵌入模型，具有Web UI和API服务功能。

## Project Notes

- @webui_build.sh @lightrag_webui/ 前端项目路径为上述路径，当前端进行修改时，使用该脚本进行重新构建以确保生效
- Docker构建问题已修复: Vite配置循环依赖(vite.config.ts导入constants时使用相对路径, constants.ts导入Button时避免@/别名)

## 开发工作流程

### 分支管理
- **main分支**: 与上游HKUDS/LightRAG保持同步
- **feature/patch-improvements**: 我们的改进功能分支，包含60+commits的增强功能

### 上游同步流程
1. 仅更新main分支与上游保持同步
2. 保留我们的workflow文件(.github/workflows/)，删除上游新增的workflow文件
3. 将feature/patch-improvements分支rebase到最新的main分支
4. 确保所有改进功能保持完整性

### Rebase冲突处理原则
- 代码冲突：优先选择我们分支的改进版本(结构化日志、新功能支持等)
- 工作流冲突：跳过上游工作流修改，保持我们的配置
- 文档冲突：合并内容，保留重要信息
- 配置冲突：采用上游更新的配置格式和组织方式

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

### Docker构建修复
**问题**: Vite配置中的循环依赖导致Docker构建失败
- vite.config.ts导入`@/lib/constants`
- constants.ts导入`@/components/ui/Button`使用`@/`别名
- 在Docker构建环境中形成循环依赖

**解决方案**:
- lightrag_webui/vite.config.ts:3 修改为`import { webuiPrefix } from './src/lib/constants'`
- lightrag_webui/src/lib/constants.ts:1 修改为`import { ButtonVariantType } from '../components/ui/Button'`
- 使用相对路径替代TypeScript路径别名避免循环依赖

## 主要改进功能(feature/patch-improvements分支)
- SiliconCloud LLM支持
- 增强的管道状态处理
- 调度器和文档重试功能
- LLM绑定选项改进
- Docker构建修复
- 各种API和配置增强

## 构建和部署
- 支持Docker部署，配置文件为docker-compose.yml
- Web UI位于lightrag_webui目录
- API服务器端点: http://localhost:9621
- 支持多种存储后端: PostgreSQL, Redis, MongoDB, Neo4j等

## 配置要点
- 环境配置使用.env文件
- 支持多种LLM后端: openai, ollama, azure_openai, lollms
- 支持多种嵌入模型后端
- 工作空间隔离支持多实例部署

## AI 团队配置

根据项目技术栈，我们配置了以下 AI 专家团队来帮助您：

- **`backend-developer`**: 负责处理所有通用的 Python 和 FastAPI 后端任务。
- **`api-architect`**: 专注于设计、审查和改进 FastAPI 的 API 接口。
- **`react-component-architect`**: 领导 React 前端组件的设计和实现。
- **`tailwind-frontend-expert`**: 专门负责所有 Tailwind CSS 相关的样式和布局工作。
- **`code-reviewer`**: 在合并前对代码进行严格审查，确保质量和一致性。
- **`performance-optimizer`**: 识别和修复前后端的性能瓶颈。
- **`code-archaeologist`**: 当需要理解复杂或遗留代码时，由他进行分析和文档化。
