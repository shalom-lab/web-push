#!/bin/bash

# Web Push Server 部署脚本
set -e

echo "🚀 Web Push Server 部署脚本"
echo "================================"

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# 打印带颜色的消息
print_status() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

print_step() {
    echo -e "${BLUE}[STEP]${NC} $1"
}

# 检查 Docker 是否安装
check_docker() {
    print_step "检查 Docker 环境..."
    
    if ! command -v docker &> /dev/null; then
        print_error "Docker 未安装，请先安装 Docker"
        exit 1
    fi
    
    if ! command -v docker-compose &> /dev/null; then
        print_error "Docker Compose 未安装，请先安装 Docker Compose"
        exit 1
    fi
    
    print_status "Docker 环境检查通过"
}

# 生成 VAPID 密钥
generate_keys() {
    print_step "生成 VAPID 密钥..."
    
    if [ ! -f ".env" ]; then
        print_status "创建 .env 文件..."
        cp .env.example .env
    fi
    
    # 检查是否已有密钥
    if grep -q "your_public_key_here" .env; then
        print_status "生成新的 VAPID 密钥..."
        
        # 临时安装依赖
        if [ ! -d "node_modules" ]; then
            print_status "安装依赖..."
            npm install
        fi
        
        # 生成密钥
        node generate-keys.js
        
        print_warning "请手动更新 .env 文件中的密钥"
        print_warning "然后重新运行此脚本"
        exit 0
    else
        print_status "VAPID 密钥已配置"
    fi
}

# 创建必要目录
create_directories() {
    print_step "创建必要目录..."
    
    mkdir -p data
    mkdir -p logs
    
    print_status "目录创建完成"
}

# 构建和启动服务
start_service() {
    print_step "构建和启动服务..."
    
    # 停止现有服务
    if docker-compose ps | grep -q "web-push-server"; then
        print_status "停止现有服务..."
        docker-compose down
    fi
    
    # 构建镜像
    print_status "构建 Docker 镜像..."
    docker-compose build --no-cache
    
    # 启动服务
    print_status "启动服务..."
    docker-compose up -d
    
    # 等待服务启动
    print_status "等待服务启动..."
    sleep 10
    
    # 检查服务状态
    if curl -s http://localhost:3000/status > /dev/null; then
        print_status "✅ 服务启动成功！"
    else
        print_error "❌ 服务启动失败"
        docker-compose logs
        exit 1
    fi
}

# 显示服务信息
show_info() {
    print_step "服务信息"
    echo "================================"
    echo "服务地址: http://localhost:3000"
    echo "状态页面: http://localhost:3000/status"
    echo "API 文档: http://localhost:3000"
    echo ""
    echo "管理命令:"
    echo "  查看状态: docker-compose ps"
    echo "  查看日志: docker-compose logs -f"
    echo "  重启服务: docker-compose restart"
    echo "  停止服务: docker-compose down"
    echo "  更新服务: ./deploy.sh update"
    echo ""
}

# 更新服务
update_service() {
    print_step "更新服务..."
    
    # 拉取最新代码（如果有 git 仓库）
    if [ -d ".git" ]; then
        print_status "拉取最新代码..."
        git pull
    fi
    
    # 重新构建和启动
    docker-compose down
    docker-compose build --no-cache
    docker-compose up -d
    
    print_status "✅ 服务更新完成"
}

# 备份数据
backup_data() {
    print_step "备份数据..."
    
    BACKUP_DIR="backup_$(date +%Y%m%d_%H%M%S)"
    mkdir -p $BACKUP_DIR
    
    if [ -f "subscriptions.json" ]; then
        cp subscriptions.json $BACKUP_DIR/
    fi
    
    if [ -f "push-logs.json" ]; then
        cp push-logs.json $BACKUP_DIR/
    fi
    
    print_status "✅ 数据已备份到 $BACKUP_DIR"
}

# 主函数
main() {
    case "${1:-}" in
        "update")
            check_docker
            update_service
            show_info
            ;;
        "backup")
            backup_data
            ;;
        "logs")
            docker-compose logs -f
            ;;
        "status")
            docker-compose ps
            curl -s http://localhost:3000/status | jq . 2>/dev/null || curl -s http://localhost:3000/status
            ;;
        "stop")
            docker-compose down
            print_status "服务已停止"
            ;;
        "restart")
            docker-compose restart
            print_status "服务已重启"
            ;;
        "")
            check_docker
            generate_keys
            create_directories
            start_service
            show_info
            ;;
        *)
            echo "用法: $0 [update|backup|logs|status|stop|restart]"
            exit 1
            ;;
    esac
}

# 运行主函数
main "$@" 