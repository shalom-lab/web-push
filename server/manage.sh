#!/bin/bash

# Web Push Server 管理脚本

# 颜色定义
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

print_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_step() {
    echo -e "${BLUE}[STEP]${NC} $1"
}

# 显示帮助信息
show_help() {
    echo "Web Push Server 管理脚本"
    echo "================================"
    echo "用法: $0 [命令]"
    echo ""
    echo "命令:"
    echo "  start     启动服务"
    echo "  stop      停止服务"
    echo "  restart   重启服务"
    echo "  status    查看状态"
    echo "  logs      查看日志"
    echo "  backup    备份数据"
    echo "  restore   恢复数据"
    echo "  update    更新服务"
    echo "  clean     清理数据"
    echo "  help      显示帮助"
    echo ""
}

# 启动服务
start_service() {
    print_step "启动 Web Push Server..."
    docker-compose up -d
    sleep 5
    check_status
}

# 停止服务
stop_service() {
    print_step "停止 Web Push Server..."
    docker-compose down
    print_info "服务已停止"
}

# 重启服务
restart_service() {
    print_step "重启 Web Push Server..."
    docker-compose restart
    sleep 5
    check_status
}

# 检查状态
check_status() {
    print_step "检查服务状态..."
    
    # 检查容器状态
    if docker-compose ps | grep -q "Up"; then
        print_info "✅ 容器运行正常"
    else
        print_error "❌ 容器未运行"
        return 1
    fi
    
    # 检查服务健康状态
    if curl -s http://localhost:3000/status > /dev/null; then
        print_info "✅ 服务响应正常"
        echo ""
        echo "服务信息:"
        curl -s http://localhost:3000/status | jq . 2>/dev/null || curl -s http://localhost:3000/status
    else
        print_error "❌ 服务无响应"
        return 1
    fi
}

# 查看日志
show_logs() {
    print_step "显示服务日志..."
    docker-compose logs -f --tail=100
}

# 备份数据
backup_data() {
    print_step "备份数据..."
    
    BACKUP_DIR="backup_$(date +%Y%m%d_%H%M%S)"
    mkdir -p $BACKUP_DIR
    
    # 备份配置文件
    if [ -f ".env" ]; then
        cp .env $BACKUP_DIR/
        print_info "✅ 配置文件已备份"
    fi
    
    # 备份数据文件
    if [ -f "subscriptions.json" ]; then
        cp subscriptions.json $BACKUP_DIR/
        print_info "✅ 订阅数据已备份"
    fi
    
    if [ -f "push-logs.json" ]; then
        cp push-logs.json $BACKUP_DIR/
        print_info "✅ 推送日志已备份"
    fi
    
    # 备份 Docker 数据
    docker-compose exec web-push-server tar czf /tmp/backup.tar.gz /app/data 2>/dev/null || true
    if [ -f "data" ]; then
        cp -r data $BACKUP_DIR/
        print_info "✅ Docker 数据已备份"
    fi
    
    print_info "✅ 备份完成: $BACKUP_DIR"
}

# 恢复数据
restore_data() {
    print_step "恢复数据..."
    
    if [ -z "$1" ]; then
        print_error "请指定备份目录"
        echo "用法: $0 restore <backup_directory>"
        exit 1
    fi
    
    BACKUP_DIR=$1
    
    if [ ! -d "$BACKUP_DIR" ]; then
        print_error "备份目录不存在: $BACKUP_DIR"
        exit 1
    fi
    
    # 停止服务
    docker-compose down
    
    # 恢复文件
    if [ -f "$BACKUP_DIR/.env" ]; then
        cp $BACKUP_DIR/.env .
        print_info "✅ 配置文件已恢复"
    fi
    
    if [ -f "$BACKUP_DIR/subscriptions.json" ]; then
        cp $BACKUP_DIR/subscriptions.json .
        print_info "✅ 订阅数据已恢复"
    fi
    
    if [ -f "$BACKUP_DIR/push-logs.json" ]; then
        cp $BACKUP_DIR/push-logs.json .
        print_info "✅ 推送日志已恢复"
    fi
    
    if [ -d "$BACKUP_DIR/data" ]; then
        cp -r $BACKUP_DIR/data .
        print_info "✅ Docker 数据已恢复"
    fi
    
    # 重启服务
    docker-compose up -d
    
    print_info "✅ 数据恢复完成"
}

# 更新服务
update_service() {
    print_step "更新服务..."
    
    # 备份当前数据
    backup_data
    
    # 拉取最新代码
    if [ -d ".git" ]; then
        print_info "拉取最新代码..."
        git pull
    fi
    
    # 重新构建
    print_info "重新构建镜像..."
    docker-compose build --no-cache
    
    # 重启服务
    docker-compose up -d
    
    print_info "✅ 服务更新完成"
}

# 清理数据
clean_data() {
    print_warning "⚠️  这将删除所有数据，确定继续吗？(y/N)"
    read -r response
    if [[ "$response" =~ ^([yY][eE][sS]|[yY])$ ]]; then
        print_step "清理数据..."
        
        # 停止服务
        docker-compose down
        
        # 删除数据文件
        rm -f subscriptions.json push-logs.json
        rm -rf data logs
        
        # 删除 Docker 镜像
        docker-compose down --rmi all --volumes --remove-orphans
        
        print_info "✅ 数据清理完成"
    else
        print_info "取消清理操作"
    fi
}

# 主函数
main() {
    case "${1:-}" in
        "start")
            start_service
            ;;
        "stop")
            stop_service
            ;;
        "restart")
            restart_service
            ;;
        "status")
            check_status
            ;;
        "logs")
            show_logs
            ;;
        "backup")
            backup_data
            ;;
        "restore")
            restore_data "$2"
            ;;
        "update")
            update_service
            ;;
        "clean")
            clean_data
            ;;
        "help"|"-h"|"--help")
            show_help
            ;;
        "")
            show_help
            ;;
        *)
            print_error "未知命令: $1"
            show_help
            exit 1
            ;;
    esac
}

# 运行主函数
main "$@" 