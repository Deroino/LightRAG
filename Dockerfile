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

# 安装 Python 相关的构建依赖，以及所有编译时需要的系统库
RUN apk add --no-cache curl build-base pkgconfig rustup libpcap-dev libxml2-dev libxslt-dev
RUN rustup-init -y --profile minimal
ENV PATH="/root/.cargo/bin:${PATH}"

WORKDIR /app

# 复制所有后端代码和配置文件
COPY ./lightrag ./lightrag
COPY pyproject.toml .
COPY setup.py .

# 在拥有完整编译工具的环境中，彻底安装所有 Python 依赖
RUN pip install --no-cache-dir --break-system-packages ".[api]"

# ---- Final Stage ----
FROM python:3.11-alpine

WORKDIR /app

# 设置时区并安装 *仅运行时* 需要的系统依赖
RUN apk add --no-cache tzdata && \
    cp /usr/share/zoneinfo/Asia/Shanghai /etc/localtime && \
    echo "Asia/Shanghai" > /etc/timezone && \
    apk del tzdata
RUN apk add --no-cache \
    nss eudev libxscrnsaver libxtst ttf-freefont gtk+3.0 gdk-pixbuf libdrm \
    libxkbcommon libxcomposite libxdamage libxrandr alsa-lib at-spi2-core xvfb-run libpcap

# 从 Python 构建阶段复制已经安装好的、完整的 Python 环境
COPY --from=python-builder /root/.local /root/.local
ENV PATH="/root/.local/bin:${PATH}"

# 从 Python 构建阶段复制项目代码
COPY --from=python-builder /app/lightrag /app/lightrag
COPY --from=python-builder /app/setup.py /app/
COPY --from=python-builder /app/pyproject.toml /app/


# 从前端构建阶段复制构建好的UI
COPY --from=frontend-builder /app/lightrag/api/webui /app/lightrag/api/webui

# 创建数据目录
RUN mkdir -p /app/data/rag_storage /app/data/inputs
ENV WORKING_DIR=/app/data/rag_storage
ENV INPUT_DIR=/app/data/inputs

EXPOSE 9621

ENTRYPOINT ["python", "-m", "lightrag.api.lightrag_server"]
