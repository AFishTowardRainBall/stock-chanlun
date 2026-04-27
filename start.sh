#!/bin/bash

# ChanStock 一键启动脚本
# 同时启动后端 API 服务和前端开发服务器

set -e

echo "🚀 启动 ChanStock 服务..."

# 获取项目根目录
PROJECT_ROOT="$(cd "$(dirname "$0")" && pwd)"

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

# 启动后端
echo "📦 启动后端服务 (端口 8000)..."
cd "$PROJECT_ROOT/backend"
python run_server.py &
BACKEND_PID=$!

# 等待后端启动
sleep 2

# 启动前端
echo "🎨 启动前端服务 (端口 5173)..."
cd "$PROJECT_ROOT/frontend"
npm run dev &
FRONTEND_PID=$!

echo ""
echo "✅ 服务已启动:"
echo "   - 后端 API: http://localhost:8000"
echo "   - API 文档: http://localhost:8000/docs"
echo "   - 前端 PC:  http://localhost:5173"
echo "   - 前端移动: http://localhost:5173/m/"
echo ""
echo "按 Ctrl+C 停止所有服务"

# 等待所有后台进程
wait
