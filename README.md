# Web Push PWA System

一个完整的 Web Push 通知系统，包含 PWA 客户端和 Node.js 推送服务器。

## 📁 项目结构

```
webpush-pwa-system/
├── client/          # GitHub Pages 上的 PWA 网页（静态）
│   ├── index.html   # 主页面
│   ├── main.js      # 客户端逻辑
│   ├── sw.js        # Service Worker
│   └── manifest.json # PWA 配置
├── server/          # Node.js 推送服务（Docker 部署）
│   ├── server.js    # 服务器主文件
│   ├── package.json # 依赖配置
│   ├── Dockerfile   # Docker 配置
│   └── .env         # 环境变量
└── .github/workflows/notify.yml # GitHub Actions 通知
```

## 🚀 快速开始

### 1. 生成 VAPID 密钥

```bash
# 安装 web-push 工具
npm install -g web-push

# 生成密钥对
web-push generate-vapid-keys
```

### 2. 配置服务器

1. 进入 `server` 目录
2. 复制 `.env.example` 到 `.env`
3. 填入你的 VAPID 密钥：

```env
VAPID_PUBLIC_KEY=你的公钥
VAPID_PRIVATE_KEY=你的私钥
VAPID_EMAIL=your-email@example.com
```

### 3. 启动服务器

```bash
cd server
npm install
npm start
```

### 4. 配置客户端

编辑 `client/main.js`：

```javascript
const vapidPublicKey = '你的公钥';
const serverUrl = 'http://localhost:3000'; // 开发环境
```

### 5. 部署

#### 服务器部署（Docker）

```bash
cd server
docker build -t web-push-server .
docker run -p 3000:3000 --env-file .env web-push-server
```

#### 客户端部署（GitHub Pages）

1. 将 `client` 目录推送到 GitHub 仓库
2. 在仓库设置中启用 GitHub Pages
3. 更新 `serverUrl` 为你的服务器地址

## 📱 PWA 功能

- ✅ 可安装到桌面
- ✅ 离线支持
- ✅ 推送通知
- ✅ 现代化 UI
- ✅ 响应式设计

## 🔧 API 接口

### 订阅通知
```http
POST /subscribe
Content-Type: application/json

{
  "endpoint": "推送端点",
  "keys": {
    "p256dh": "公钥",
    "auth": "认证密钥"
  }
}
```

### 发送通知
```http
POST /notify
Content-Type: application/json

{
  "title": "通知标题",
  "body": "通知内容",
  "data": {
    "url": "点击跳转链接"
  }
}
```

### 获取状态
```http
GET /status
```

### 获取 VAPID 公钥
```http
GET /vapidPublicKey
```

## 🤖 GitHub Actions 集成

### 配置 Secrets

在 GitHub 仓库设置中添加：

- `PUSH_SERVER_URL`: 推送服务器地址
- `PUSH_API_KEY`: API 密钥（可选）

### 手动触发

在 Actions 页面可以手动触发通知，支持自定义标题和内容。

## 🔒 安全配置

### CORS 设置

在 `.env` 中配置允许的域名：

```env
ALLOWED_ORIGINS=https://yourdomain.com,https://www.yourdomain.com
```

### 环境变量

- `VAPID_PUBLIC_KEY`: VAPID 公钥
- `VAPID_PRIVATE_KEY`: VAPID 私钥
- `VAPID_EMAIL`: 联系邮箱
- `PORT`: 服务器端口（默认 3000）
- `ALLOWED_ORIGINS`: 允许的域名

## 🐛 故障排除

### 常见问题

1. **通知权限被拒绝**
   - 检查浏览器设置
   - 确保使用 HTTPS（生产环境）

2. **订阅失败**
   - 检查 VAPID 密钥配置
   - 确认服务器地址正确

3. **推送失败**
   - 检查订阅是否过期
   - 查看服务器日志

### 调试模式

```bash
# 服务器调试
cd server
npm run dev

# 查看日志
docker logs <container-id>
```

## 📊 监控

访问 `/status` 端点查看：

- 活跃订阅数量
- 推送成功率
- 服务器状态
- 内存使用情况

## 🔄 更新日志

### v1.0.0
- 初始版本
- 基础推送功能
- PWA 支持
- GitHub Actions 集成

## 📄 许可证

MIT License

## 🤝 贡献

欢迎提交 Issue 和 Pull Request！

## 📞 支持

如有问题，请创建 GitHub Issue。 