# ---- Frontend Build Stage ----
FROM node:18-alpine AS frontend-builder

WORKDIR /app

# 复制前端项目和构建脚本
COPY ./lightrag_webui ./lightrag_webui/
COPY ./webui_build.sh ./

# 执行前端构建
RUN chmod +x ./webui_build.sh && ./webui_build.sh

# ---- Python Build Stage ----
FROM python:3.11-alpine AS python-builder

# 安装 Python 相关的构建依赖
RUN apk add --no-cache curl build-base pkgconfig rustup
RUN rustup-init -y --profile minimal
ENV PATH="/root/.cargo/bin:${PATH}"

WORKDIR /app

# The following lines are removed because dependencies are handled by setup.py
# COPY requirements.txt .
# COPY lightrag/api/requirements.txt ./lightrag/api/
# RUN pip install --user --no-cache-dir -r requirements.txt
# RUN pip install --user --no-cache-dir -r lightrag/api/requirements.txt

# Install some base packages that are frequently used
RUN pip install --user --no-cache-dir \
    nano-vectordb networkx openai ollama tiktoken \
    pypdf2 python-docx python-pptx openpyxl

# ---- Final Stage ----
FROM python:3.11-alpine

WORKDIR /app

# 设置时区和安装 Playwright 依赖
RUN apk add --no-cache tzdata && \
    cp /usr/share/zoneinfo/Asia/Shanghai /etc/localtime && \
    echo "Asia/Shanghai" > /etc/timezone && \
    apk del tzdata
RUN apk add --no-cache \
    nss eudev libxscrnsaver libxtst ttf-freefont gtk+3.0 gdk-pixbuf libdrm \
    libxkbcommon libxcomposite libxdamage libxrandr alsa-lib at-spi2-core xvfb-run

# 从 Python 构建阶段复制依赖
COPY --from=python-builder /root/.local /root/.local
ENV PATH="/root/.local/bin:${PATH}"

# 复制后端代码
COPY ./lightrag ./lightrag
COPY setup.py .

# 从前端构建阶段复制构建好的UI
COPY --from=frontend-builder /app/lightrag/api/webui /app/lightrag/api/webui

# 安装项目
RUN pip install --no-cache-dir ".[api]"

# 创建数据目录
RUN mkdir -p /app/data/rag_storage /app/data/inputs
ENV WORKING_DIR=/app/data/rag_storage
ENV INPUT_DIR=/app/data/inputs

EXPOSE 9621

ENTRYPOINT ["python", "-m", "lightrag.api.lightrag_server"]