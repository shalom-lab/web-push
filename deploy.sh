#!/bin/bash

# Web Push PWA System 部署脚本

set -e

echo "🚀 开始部署 Web Push PWA System..."

# 检查必要的工具
check_requirements() {
    echo "📋 检查系统要求..."
    
    if ! command -v node &> /dev/null; then
        echo "❌ Node.js 未安装，请先安装 Node.js"
        exit 1
    fi
    
    if ! command -v npm &> /dev/null; then
        echo "❌ npm 未安装，请先安装 npm"
        exit 1
    fi
    
    if ! command -v docker &> /dev/null; then
        echo "⚠️  Docker 未安装，将跳过 Docker 部署"
        DOCKER_AVAILABLE=false
    else
        DOCKER_AVAILABLE=true
    fi
    
    echo "✅ 系统要求检查完成"
}

# 生成 VAPID 密钥
generate_keys() {
    echo "🔑 生成 VAPID 密钥..."
    
    if [ ! -f "server/.env" ]; then
        echo "📝 创建 .env 文件..."
        cp server/.env.example server/.env
    fi
    
    cd server
    if [ ! -d "node_modules" ]; then
        echo "📦 安装服务器依赖..."
        npm install
    fi
    
    echo "🔑 运行密钥生成脚本..."
    node generate-keys.js
    cd ..
}

# 启动服务器
start_server() {
    echo "🖥️  启动推送服务器..."
    
    cd server
    
    if [ "$DOCKER_AVAILABLE" = true ] && [ "$1" = "docker" ]; then
        echo "🐳 使用 Docker 启动服务器..."
        docker-compose up -d
        echo "✅ 服务器已启动 (Docker)"
        echo "📊 状态页面: http://localhost:3000/status"
    else
        echo "🖥️  使用 Node.js 启动服务器..."
        npm start &
        SERVER_PID=$!
        echo "✅ 服务器已启动 (PID: $SERVER_PID)"
        echo "📊 状态页面: http://localhost:3000/status"
        echo "💡 按 Ctrl+C 停止服务器"
        
        # 等待服务器启动
        sleep 3
        
        # 检查服务器状态
        if curl -s http://localhost:3000/status > /dev/null; then
            echo "✅ 服务器运行正常"
        else
            echo "❌ 服务器启动失败"
            exit 1
        fi
    fi
    
    cd ..
}

# 显示使用说明
show_usage() {
    echo ""
    echo "📖 使用说明："
    echo "1. 访问 http://localhost:3000 查看服务器状态"
    echo "2. 在 client/index.html 中测试推送功能"
    echo "3. 配置 GitHub Actions 进行自动化通知"
    echo ""
    echo "🔧 常用命令："
    echo "  ./deploy.sh          # 完整部署"
    echo "  ./deploy.sh docker   # Docker 部署"
    echo "  ./deploy.sh keys     # 仅生成密钥"
    echo ""
}

# 主函数
main() {
    case "${1:-}" in
        "keys")
            check_requirements
            generate_keys
            ;;
        "docker")
            check_requirements
            generate_keys
            start_server docker
            show_usage
            ;;
        "")
            check_requirements
            generate_keys
            start_server
            show_usage
            ;;
        *)
            echo "❌ 未知参数: $1"
            echo "用法: $0 [keys|docker]"
            exit 1
            ;;
    esac
}

# 清理函数
cleanup() {
    if [ ! -z "$SERVER_PID" ]; then
        echo "🛑 停止服务器..."
        kill $SERVER_PID 2>/dev/null || true
    fi
}

# 设置信号处理
trap cleanup EXIT INT TERM

# 运行主函数
main "$@" 