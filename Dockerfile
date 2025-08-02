# ---- Frontend Build Stage ----
FROM node:18-alpine AS frontend-builder

WORKDIR /app

# 复制前端项目和构建脚本
COPY ./lightrag_webui ./lightrag_webui/
COPY ./webui_build.sh ./

# 移除脚本中的 sudo 命令，因为它在 docker build 环境中是不需要的
RUN sed -i 's/sudo //g' ./webui_build.sh
# 执行前端构建
RUN chmod +x ./webui_build.sh && ./webui_build.sh

# ---- Python Build Stage ----
FROM python:3.11-alpine AS python-builder

# 安装所有编译时需要的系统库
RUN apk add --no-cache curl build-base pkgconfig rustup libpcap-dev libxml2-dev libxslt-dev cmake ninja libpq-dev openssl-dev libffi-dev
RUN rustup-init -y --profile minimal
ENV PATH="/root/.cargo/bin:${PATH}"

WORKDIR /app

# 复制所有后端代码和配置文件
COPY ./lightrag ./lightrag
COPY pyproject.toml .
COPY setup.py .

# 定义一个独立的安装目标目录
ENV PACKAGES_DIR=/app/packages
RUN mkdir -p ${PACKAGES_DIR}

# 使用 --target 将所有依赖项明确安装到独立目录中
# 首先预安装 numpy，因为它是一些包的构建时依赖
RUN pip install --no-cache-dir --target=${PACKAGES_DIR} numpy
# 然后安装项目本身及其所有依赖
RUN pip install --no-cache-dir --target=${PACKAGES_DIR} ".[api]"

# ---- Final Stage ----
FROM python:3.11-alpine

WORKDIR /app

# 设置时区并安装 *仅运行时* 需要的系统依赖
RUN apk add --no-cache tzdata libgcc libpq openssl && \
    cp /usr/share/zoneinfo/Asia/Shanghai /etc/localtime && \
    echo "Asia/Shanghai" > /etc/timezone && \
    apk del tzdata

# 定义包目录并将其添加到环境变量
ENV PACKAGES_DIR=/app/packages
ENV PYTHONPATH=${PACKAGES_DIR}
ENV PATH=${PACKAGES_DIR}/bin:${PATH}

# 从构建阶段复制已安装好的、独立的依赖包目录
COPY --from=python-builder ${PACKAGES_DIR} ${PACKAGES_DIR}

# 复制项目源代码
COPY ./lightrag ./lightrag
COPY setup.py .
COPY pyproject.toml .

# 从前端构建阶段复制构建好的UI
COPY --from=frontend-builder /app/lightrag/api/webui /app/lightrag/api/webui

# 创建数据目录
RUN mkdir -p /app/data/rag_storage /app/data/inputs
ENV WORKING_DIR=/app/data/rag_storage
ENV INPUT_DIR=/app/data/inputs

EXPOSE 9621

ENTRYPOINT ["python", "-m", "lightrag.api.lightrag_server"]
