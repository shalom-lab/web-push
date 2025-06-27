#!/bin/bash

# 快速启动脚本 - 一键部署 Web Push Server
echo "🚀 Web Push Server 快速启动"
echo "================================"

# 检查是否在正确的目录
if [ ! -f "server.js" ]; then
    echo "❌ 请在 server 目录下运行此脚本"
    exit 1
fi

# 检查 Docker
if ! command -v docker &> /dev/null; then
    echo "❌ 请先安装 Docker"
    echo "安装命令: curl -fsSL https://get.docker.com | sh"
    exit 1
fi

if ! command -v docker-compose &> /dev/null; then
    echo "❌ 请先安装 Docker Compose"
    exit 1
fi

echo "✅ Docker 环境检查通过"

# 生成密钥（如果需要）
if [ ! -f ".env" ] || grep -q "your_public_key_here" .env; then
    echo "🔑 生成 VAPID 密钥..."
    
    if [ ! -d "node_modules" ]; then
        echo "📦 安装依赖..."
        npm install
    fi
    
    node generate-keys.js
    echo ""
    echo "⚠️  请手动更新 .env 文件中的密钥，然后重新运行此脚本"
    exit 0
fi

# 创建目录
mkdir -p data logs

# 启动服务
echo "🐳 启动 Docker 服务..."
docker-compose up -d --build

# 等待启动
echo "⏳ 等待服务启动..."
sleep 15

# 检查状态
if curl -s http://localhost:3000/status > /dev/null; then
    echo ""
    echo "🎉 部署成功！"
    echo "================================"
    echo "🌐 服务地址: http://localhost:3000"
    echo "📊 状态页面: http://localhost:3000/status"
    echo "📝 API 文档: http://localhost:3000"
    echo ""
    echo "🔧 管理命令:"
    echo "  查看日志: docker-compose logs -f"
    echo "  重启服务: docker-compose restart"
    echo "  停止服务: docker-compose down"
    echo ""
    echo "📱 客户端配置:"
    echo "  更新 client/main.js 中的 serverUrl 为: http://你的服务器IP:3000"
else
    echo "❌ 服务启动失败"
    echo "查看日志: docker-compose logs"
    exit 1
fi 