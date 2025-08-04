# CLAUDE.md - LightRAG 项目指南

本文档为 LightRAG 项目的开发者提供高级概述和常用命令，旨在帮助团队成员快速上手。

## 1. 代码架构

LightRAG 是一个采用前后端分离架构的检索增强生成（RAG）服务。

### 后端 (`lightrag/`)

后端使用 **Python** 和 **FastAPI** 构建，负责所有核心 RAG 逻辑。

-   **`lightrag/api/`**: 项目的核心 API 服务层。
    -   `lightrag_server.py`: FastAPI 应用的主入口点。
    -   `routers/`: 定义了不同功能的 API 路由，如文档管理、查询处理等。
-   **`lightrag/llm/`**: 封装了与多种 LLM（如 OpenAI, Ollama, Azure OpenAI）的交互逻辑。
-   **`lightrag/kg/`**: 实现了与多种知识存储后端的集成，包括向量数据库 (FAISS, Milvus, Qdrant) 和图数据库 (Neo4j)。
-   **`lightrag/` (根目录)**: 包含 RAG 的核心抽象和数据处理流程。

### 前端 (`lightrag_webui/`)

前端是一个使用 **React** 和 **TypeScript** 构建的单页应用（SPA），为用户提供了一个可视化的操作界面。

-   **`src/`**: 包含所有 React 组件、页面和业务逻辑。
-   **`vite.config.ts`**: 使用 **Vite** 作为构建和开发工具。
-   **`package.json`**: 定义了前端依赖和脚本命令。
-   **UI**: 使用 **Tailwind CSS** 和 **Shadcn/ui** 组件库构建界面。

### 部署与测试

-   **`Dockerfile`, `docker-compose.yml`**: 支持使用 Docker 进行容器化部署。
-   **`k8s-deploy/`**: 提供了 Kubernetes 的部署脚本。
-   **`tests/`**: 包含了后端的单元测试和集成测试。

## 2. 开发工作流

本项目是上游仓库的 fork。为保持同步和管理自定义修改，请遵循以下工作流：

-   **分支策略**:
    -   `main` 分支：此分支作为上游仓库的镜像，用于跟踪官方更新。请勿直接在此分支上开发。
    -   `patch-improve` 分支：这是我们的主要开发分支，所有新功能和修复都在此分支上进行。

-   **同步上游更新**:
    1.  首先，确保你的 `main` 分支跟踪了上游仓库。
    2.  拉取上游的最新变更到本地 `main` 分支。
    3.  切换到 `patch-improve` 分支。
    4.  将 `patch-improve` 分支 rebase 到更新后的 `main` 分支上，以包含上游的最新代码：
        ```bash
        git rebase main
        ```

-   **构建与测试**:
    -   项目的构建和测试主要通过 **GitHub Actions** 自动化完成。
    -   通常情况下，不需要在本地执行完整的测试套件，可以依赖 CI 的结果。

## 3. 常用开发命令

以下是在开发过程中常用的命令。

### 后端 (Python)

在项目根目录下执行：

-   **安装依赖**:
    ```bash
    pip install -e ".[api]"
    ```
-   **运行开发服务器**:
    ```bash
    uvicorn lightrag.api.lightrag_server:app --reload --port 8000
    ```
-   **运行测试**:
    ```bash
    pytest tests/
    ```
-   **代码风格检查与格式化**:
    ```bash
    ruff check .
    ruff format .
    ```

### 前端 (React)

需要先进入 `lightrag_webui` 目录：

```bash
cd lightrag_webui
```

-   **安装依赖**:
    ```bash
    # 如果使用 bun
    bun install

    # 如果使用 npm
    npm install
    ```
-   **运行开发服务器**:
    ```bash
    # 如果使用 bun
    bun run dev

    # 如果使用 npm
    npm run dev
    ```
-   **构建生产版本**:
    ```bash
    # 如果使用 bun
    bun run build

    # 如果使用 npm
    npm run build
    ```
-   **代码风格检查**:
    ```bash
    # 如果使用 bun
    bun run lint

    # 如果使用 npm
    npm run lint
    ```
