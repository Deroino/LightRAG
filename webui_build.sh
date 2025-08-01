#!/bin/sh

# LightRAG WebUI 构建脚本
# 用于重新打包前端项目

set -e  # 遇到错误立即退出

# 获取脚本所在目录（更兼容的方式）
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
OUTPUT_DIR="$SCRIPT_DIR/lightrag/api/webui"

echo "🔧 开始构建 LightRAG WebUI..."
echo "📁 工作目录: $SCRIPT_DIR"
echo "📂 输出目录: $OUTPUT_DIR"

# 切换到项目目录
cd "$SCRIPT_DIR/lightrag_webui"

# 检查是否存在 package.json
if [ ! -f "package.json" ]; then
    echo "❌ 错误: 未找到 package.json 文件"
    echo "请确保在 lightrag_webui 目录中运行此脚本"
    exit 1
fi

# 清理之前的构建输出
echo "🧹 清理之前的构建输出..."
if [ -d "$OUTPUT_DIR" ]; then
    echo "删除目录: $OUTPUT_DIR"
    rm -rf "$OUTPUT_DIR"
    echo "✅ 清理完成"
else
    echo "输出目录不存在，跳过清理"
fi

echo "📦 正在安装依赖..."
if ! npm install; then
    echo "❌ 依赖安装失败"
    exit 1
fi

echo "🏗️  正在构建项目..."
# 优先使用 bun 构建，如果失败则使用 vite
BUILD_SUCCESS=false

if command -v bunx >/dev/null 2>&1; then
    echo "检测到 bun，使用 bun 构建..."
    if npm run build; then
        BUILD_SUCCESS=true
    else
        echo "⚠️  bun 构建失败，尝试使用 vite..."
    fi
fi

if [ "$BUILD_SUCCESS" = false ]; then
    echo "使用 vite 构建..."
    if npm run build-no-bun; then
        BUILD_SUCCESS=true
    else
        echo "❌ vite 构建也失败了"
        exit 1
    fi
fi

# 检查构建输出目录
if [ -d "$OUTPUT_DIR" ]; then
    echo "✅ 构建成功完成!"
    echo "📂 构建输出目录: $OUTPUT_DIR"
    
    # 显示构建文件大小统计
    echo ""
    echo "📊 构建文件统计:"
    if command -v du >/dev/null 2>&1; then
        du -sh "$OUTPUT_DIR"/* 2>/dev/null | head -10 || echo "无法获取文件大小统计"
    else
        ls -la "$OUTPUT_DIR/"
    fi
    
    # 显示总大小
    echo ""
    echo "📏 总构建大小:"
    if command -v du >/dev/null 2>&1; then
        du -sh "$OUTPUT_DIR" 2>/dev/null || echo "无法获取总大小"
    fi
else
    echo "❌ 构建输出目录不存在"
    exit 1
fi

echo ""
echo "🎉 前端重新打包完成!"