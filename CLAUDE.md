# LightRAG 项目记忆文件

## 项目概述
LightRAG是一个基于图的快速RAG(检索增强生成)系统，支持多种LLM和嵌入模型，具有Web UI和API服务功能。

## 开发工作流程

### 分支管理
- **main分支**: 与上游HKUDS/LightRAG保持同步
- **feature/patch-improvements**: 我们的改进功能分支，包含60+commits的增强功能

### 上游同步流程
1. 仅更新main分支与上游保持同步
2. 保留我们的workflow文件(.github/workflows/)，删除上游新增的workflow文件
3. 将feature/patch-improvements分支rebase到最新的main分支
4. 确保所有改进功能保持完整性

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