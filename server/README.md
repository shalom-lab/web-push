# Web Push Server 部署指南

## 🚀 快速开始

### 方法一：一键部署（推荐）

```bash
# 给脚本执行权限
chmod +x quick-start.sh deploy.sh manage.sh

# 一键启动
./quick-start.sh
```

### 方法二：手动部署

```bash
# 1. 生成 VAPID 密钥
npm install
node generate-keys.js

# 2. 配置环境变量
cp .env.example .env
# 编辑 .env 文件，填入生成的密钥

# 3. 启动服务
docker-compose up -d --build
```

## 📋 脚本说明

### quick-start.sh - 快速启动脚本
```bash
./quick-start.sh
```
- 自动检查环境
- 生成 VAPID 密钥
- 一键启动服务
- 适合首次部署

### deploy.sh - 完整部署脚本
```bash
./deploy.sh          # 完整部署
./deploy.sh update   # 更新服务
./deploy.sh backup   # 备份数据
./deploy.sh logs     # 查看日志
./deploy.sh status   # 查看状态
./deploy.sh stop     # 停止服务
./deploy.sh restart  # 重启服务
```

### manage.sh - 服务管理脚本
```bash
./manage.sh start    # 启动服务
./manage.sh stop     # 停止服务
./manage.sh restart  # 重启服务
./manage.sh status   # 查看状态
./manage.sh logs     # 查看日志
./manage.sh backup   # 备份数据
./manage.sh restore <dir>  # 恢复数据
./manage.sh update   # 更新服务
./manage.sh clean    # 清理数据
./manage.sh help     # 显示帮助
```

## 🔧 配置说明

### 环境变量 (.env)
```env
# VAPID 密钥配置
VAPID_PUBLIC_KEY=你的公钥
VAPID_PRIVATE_KEY=你的私钥
VAPID_EMAIL=your-email@example.com

# 服务器配置
PORT=3000

# 允许的域名（CORS）
ALLOWED_ORIGINS=*

# 日志级别
LOG_LEVEL=info
```

### Docker 配置
- **端口**: 3000
- **内存限制**: 512M
- **CPU限制**: 0.5核
- **时区**: Asia/Shanghai
- **健康检查**: 30秒间隔

## 📊 监控和日志

### 查看服务状态
```bash
# 查看容器状态
docker-compose ps

# 查看服务健康状态
curl http://localhost:3000/status

# 使用管理脚本
./manage.sh status
```

### 查看日志
```bash
# 实时日志
docker-compose logs -f

# 最近100行日志
./manage.sh logs

# 查看特定容器日志
docker-compose logs web-push-server
```

## 🔄 数据管理

### 备份数据
```bash
# 自动备份
./manage.sh backup

# 手动备份
docker-compose exec web-push-server cat /app/subscriptions.json > backup-subscriptions.json
docker-compose exec web-push-server cat /app/push-logs.json > backup-logs.json
```

### 恢复数据
```bash
# 从备份恢复
./manage.sh restore backup_20231201_120000

# 手动恢复
docker cp backup-subscriptions.json web-push-server:/app/subscriptions.json
docker cp backup-logs.json web-push-server:/app/push-logs.json
```

## 🔒 安全配置

### 防火墙设置
```bash
# Ubuntu/Debian
sudo ufw allow 3000

# CentOS/RHEL
sudo firewall-cmd --permanent --add-port=3000/tcp
sudo firewall-cmd --reload
```

### HTTPS 配置（推荐）
```bash
# 安装 Nginx
sudo apt install nginx

# 配置反向代理
sudo nano /etc/nginx/sites-available/web-push
```

Nginx 配置示例：
```nginx
server {
    listen 80;
    server_name your-domain.com;
    
    location / {
        proxy_pass http://localhost:3000;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        proxy_cache_bypass $http_upgrade;
    }
}
```

## 🐛 故障排除

### 常见问题

1. **端口被占用**
```bash
# 检查端口占用
sudo netstat -tlnp | grep :3000

# 修改端口
# 编辑 docker-compose.yml 中的 ports 部分
```

2. **权限问题**
```bash
# 修复权限
sudo chown -R $USER:$USER .
chmod +x *.sh
```

3. **内存不足**
```bash
# 查看资源使用
docker stats

# 调整内存限制
# 编辑 docker-compose.yml 中的 deploy.resources.limits
```

4. **服务无法启动**
```bash
# 查看详细错误
docker-compose logs

# 检查环境变量
docker-compose exec web-push-server env

# 进入容器调试
docker-compose exec web-push-server sh
```

### 日志分析
```bash
# 查看错误日志
docker-compose logs | grep ERROR

# 查看最近的推送记录
docker-compose exec web-push-server cat /app/push-logs.json | jq '.[-10:]'

# 查看订阅统计
docker-compose exec web-push-server cat /app/subscriptions.json | jq 'length'
```

## 📈 性能优化

### 资源监控
```bash
# 实时监控
docker stats web-push-server

# 查看资源使用历史
docker stats --no-stream web-push-server
```

### 性能调优
```bash
# 调整内存限制
# 编辑 docker-compose.yml
deploy:
  resources:
    limits:
      memory: 1G  # 增加内存
      cpus: '1.0' # 增加CPU

# 重启服务
docker-compose up -d
```

## 🔄 更新和维护

### 更新服务
```bash
# 自动更新
./manage.sh update

# 手动更新
git pull
docker-compose build --no-cache
docker-compose up -d
```

### 清理资源
```bash
# 清理未使用的镜像
docker image prune -f

# 清理未使用的容器
docker container prune -f

# 清理所有未使用的资源
docker system prune -f
```

## 📞 支持

如果遇到问题：
1. 查看日志：`./manage.sh logs`
2. 检查状态：`./manage.sh status`
3. 查看本文档的故障排除部分
4. 创建 GitHub Issue 