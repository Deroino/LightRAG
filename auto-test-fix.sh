#!/bin/bash

# LightRAG 自动测试修复脚本
# 功能：停止现有进程 -> 构建前端 -> 启动服务（完全非阻塞）

set -e  # 遇到错误时退出

echo "=== LightRAG 自动测试修复脚本开始 ==="
echo "时间: $(date '+%Y-%m-%d %H:%M:%S')"
echo

# 第一步：查找并杀掉 lightrag-server 进程
echo ">>> 第一步：停止现有的 lightrag-server 进程"
LIGHTRAG_PIDS=$(pgrep -f "lightrag-server" || true)

if [ -n "$LIGHTRAG_PIDS" ]; then
    echo "发现 lightrag-server 进程: $LIGHTRAG_PIDS"
    echo "正在停止进程..."
    
    # 先尝试优雅关闭 (SIGTERM)
    kill $LIGHTRAG_PIDS || true
    sleep 3
    
    # 检查进程是否仍在运行
    REMAINING_PIDS=$(pgrep -f "lightrag-server" || true)
    if [ -n "$REMAINING_PIDS" ]; then
        echo "进程仍在运行，强制杀掉..."
        kill -9 $REMAINING_PIDS || true
        sleep 1
    fi
    
    echo "✅ lightrag-server 进程已停止"
else
    echo "ℹ️  未发现运行中的 lightrag-server 进程"
fi
echo

# 第二步：执行前端构建
echo ">>> 第二步：构建前端项目"
if [ -f "./webui_build.sh" ]; then
    echo "正在执行 webui_build.sh..."
    sudo chmod +x ./webui_build.sh
    ./webui_build.sh
    echo "✅ 前端构建完成"
else
    echo "❌ 错误：找不到 webui_build.sh 脚本"
    exit 1
fi
echo

echo
# 新增：安装 Python 依赖
echo ">>> 新增步骤：安装 Python 依赖"
if [ -f "requirements.txt" ]; then
    echo "正在从 requirements.txt 安装依赖..."
    pip3 install -r requirements.txt
    echo "✅ Python 依赖安装完成"
else
    echo "⚠️  警告：找不到 requirements.txt 文件，跳过依赖安装"
fi

# 第三步：非阻塞启动 lightrag-server
echo ">>> 第三步：启动 lightrag-server 服务"
if [ -f "lightrag/api/lightrag_server.py" ]; then
    echo "正在启动 lightrag-server..."
    
    # 使用 nohup 非阻塞启动，日志重定向到 auto-test-fix.log
    nohup python3 -m lightrag.api.lightrag_server > auto-test-fix.log 2>&1 &
    SERVER_PID=$!
    
    echo "✅ lightrag-server 已启动"
    echo "进程ID: $SERVER_PID"
    echo "日志文件: auto-test-fix.log"
    echo "可以使用以下命令查看日志:"
    echo "  tail -f auto-test-fix.log"
else
    echo "❌ 错误：找不到 lightrag/api/lightrag_server.py 文件"
    exit 1
fi

echo
echo "=== LightRAG 自动测试修复脚本完成 ==="
echo "时间: $(date '+%Y-%m-%d %H:%M:%S')"
echo "服务已在后台启动，请检查日志文件 auto-test-fix.log"