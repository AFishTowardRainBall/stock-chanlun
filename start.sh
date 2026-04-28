#!/bin/bash

# ChanStock 一键启动脚本
# 同时启动后端 API 服务和前端开发服务器

set -e

BACKEND_PORT=8000
FRONTEND_PORT=5173

echo "🚀 启动 ChanStock 服务..."

# 获取项目根目录
PROJECT_ROOT="$(cd "$(dirname "$0")" && pwd)"

# 终止占用指定端口的进程
kill_port() {
    local port=$1
    local name=$2
    local pid=$(lsof -ti:$port 2>/dev/null || true)

    if [ ! -z "$pid" ]; then
        echo "⚠️  发现 $name 占用端口 $port (PID: $pid)，正在终止..."
        kill $pid 2>/dev/null || true
        sleep 1
        # 确认是否终止成功
        if [ ! -z "$(lsof -ti:$port 2>/dev/null || true)" ]; then
            echo "🔨 强制终止 $name..."
            kill -9 $pid 2>/dev/null || true
            sleep 1
        fi
        echo "✅ $name 已终止"
    fi
}

# 清理函数
cleanup() {
    echo ""
    echo "🛑 停止所有服务..."
    if [ ! -z "$BACKEND_PID" ]; then
        kill $BACKEND_PID 2>/dev/null || true
    fi
    if [ ! -z "$FRONTEND_PID" ]; then
        kill $FRONTEND_PID 2>/dev/null || true
    fi
    exit 0
}

# 捕获 Ctrl+C
trap cleanup SIGINT SIGTERM

# 检查并终止已运行的服务
echo "🔍 检查端口占用..."
kill_port $BACKEND_PORT "后端服务"
kill_port $FRONTEND_PORT "前端服务"

# 启动后端
echo "📦 启动后端服务 (端口 $BACKEND_PORT)..."
cd "$PROJECT_ROOT/backend"
python run_server.py &
BACKEND_PID=$!

# 等待后端启动
sleep 2

# 检查后端是否启动成功
if ! kill -0 $BACKEND_PID 2>/dev/null; then
    echo "❌ 后端服务启动失败"
    exit 1
fi

# 启动前端
echo "🎨 启动前端服务 (端口 $FRONTEND_PORT)..."
cd "$PROJECT_ROOT/frontend"
npm run dev &
FRONTEND_PID=$!

echo ""
echo "✅ 服务已启动:"
echo "   - 后端 API: http://localhost:$BACKEND_PORT"
echo "   - API 文档: http://localhost:$BACKEND_PORT/docs"
echo "   - 前端 PC:  http://localhost:$FRONTEND_PORT"
echo "   - 前端移动: http://localhost:$FRONTEND_PORT/m/"
echo ""
echo "按 Ctrl+C 停止所有服务"

# 等待所有后台进程
wait
