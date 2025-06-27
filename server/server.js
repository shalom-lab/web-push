const express = require('express');
const bodyParser = require('body-parser');
const fs = require('fs');
const path = require('path');
const webpush = require('web-push');
const cors = require('cors');
const helmet = require('helmet');
const compression = require('compression');
require('dotenv').config();

const app = express();
const PORT = process.env.PORT || 3000;

// 中间件
app.use(helmet());
app.use(compression());
app.use(cors({
  origin: process.env.ALLOWED_ORIGINS ? process.env.ALLOWED_ORIGINS.split(',') : '*',
  credentials: true
}));
app.use(bodyParser.json({ limit: '10mb' }));
app.use(bodyParser.urlencoded({ extended: true, limit: '10mb' }));

// 文件路径
const SUB_FILE = path.join(__dirname, 'subscriptions.json');
const LOG_FILE = path.join(__dirname, 'push-logs.json');

// 确保文件存在
function ensureFile(filePath, defaultContent = '[]') {
  if (!fs.existsSync(filePath)) {
    fs.writeFileSync(filePath, defaultContent, 'utf-8');
  }
}

ensureFile(SUB_FILE);
ensureFile(LOG_FILE);

// 读取订阅列表
const getSubs = () => {
  try {
    const data = fs.readFileSync(SUB_FILE, 'utf-8');
    return JSON.parse(data || '[]');
  } catch (error) {
    console.error('读取订阅文件失败:', error);
    return [];
  }
};

// 保存订阅
const saveSub = (sub) => {
  try {
    const subs = getSubs();
    const existingIndex = subs.findIndex(s => s.endpoint === sub.endpoint);
    
    if (existingIndex === -1) {
      subs.push({
        ...sub,
        createdAt: new Date().toISOString(),
        lastUsed: new Date().toISOString()
      });
    } else {
      // 更新现有订阅
      subs[existingIndex] = {
        ...sub,
        createdAt: subs[existingIndex].createdAt,
        lastUsed: new Date().toISOString()
      };
    }
    
    fs.writeFileSync(SUB_FILE, JSON.stringify(subs, null, 2));
    return true;
  } catch (error) {
    console.error('保存订阅失败:', error);
    return false;
  }
};

// 记录推送日志
const logPush = (subscription, success, error = null) => {
  try {
    const logs = JSON.parse(fs.readFileSync(LOG_FILE, 'utf-8') || '[]');
    logs.push({
      endpoint: subscription.endpoint,
      success,
      error: error ? error.message : null,
      timestamp: new Date().toISOString()
    });
    
    // 只保留最近1000条日志
    if (logs.length > 1000) {
      logs.splice(0, logs.length - 1000);
    }
    
    fs.writeFileSync(LOG_FILE, JSON.stringify(logs, null, 2));
  } catch (error) {
    console.error('记录日志失败:', error);
  }
};

// 设置 VAPID
const vapidPublicKey = process.env.VAPID_PUBLIC_KEY;
const vapidPrivateKey = process.env.VAPID_PRIVATE_KEY;
const vapidEmail = process.env.VAPID_EMAIL || 'your-email@example.com';

if (!vapidPublicKey || !vapidPrivateKey) {
  console.error('❌ 缺少 VAPID 密钥配置');
  console.error('请设置环境变量: VAPID_PUBLIC_KEY, VAPID_PRIVATE_KEY');
  process.exit(1);
}

webpush.setVapidDetails(`mailto:${vapidEmail}`, vapidPublicKey, vapidPrivateKey);

// 路由
app.get('/', (req, res) => {
  res.json({
    message: 'Web Push Notification Server',
    version: '1.0.0',
    endpoints: {
      subscribe: '/subscribe',
      notify: '/notify',
      status: '/status'
    }
  });
});

// 订阅端点
app.post('/subscribe', (req, res) => {
  try {
    const subscription = req.body;
    
    if (!subscription || !subscription.endpoint) {
      return res.status(400).json({ error: '无效的订阅数据' });
    }
    
    const success = saveSub(subscription);
    if (success) {
      console.log('✅ 新订阅:', subscription.endpoint);
      res.json({ 
        message: '订阅成功',
        endpoint: subscription.endpoint 
      });
    } else {
      res.status(500).json({ error: '保存订阅失败' });
    }
  } catch (error) {
    console.error('订阅处理失败:', error);
    res.status(500).json({ error: '服务器内部错误' });
  }
});

// 推送通知端点
app.post('/notify', async (req, res) => {
  try {
    const { title = '任务完成', body = '你有一个新通知', data = {} } = req.body;
    const subs = getSubs();
    
    if (subs.length === 0) {
      return res.json({ message: '没有活跃订阅', sent: 0 });
    }
    
    const payload = JSON.stringify({ title, body, data });
    let sent = 0;
    let failed = 0;
    const failedSubs = [];
    
    console.log(`📤 开始推送 ${subs.length} 个订阅...`);
    
    for (const sub of subs) {
      try {
        await webpush.sendNotification(sub, payload);
        sent++;
        console.log(`✅ 推送成功: ${sub.endpoint}`);
        logPush(sub, true);
      } catch (error) {
        failed++;
        failedSubs.push({ endpoint: sub.endpoint, error: error.message });
        console.error(`❌ 推送失败: ${sub.endpoint}`, error.message);
        logPush(sub, false, error);
        
        // 如果是410错误（订阅过期），从列表中移除
        if (error.statusCode === 410) {
          console.log(`🗑️ 移除过期订阅: ${sub.endpoint}`);
          const allSubs = getSubs();
          const filteredSubs = allSubs.filter(s => s.endpoint !== sub.endpoint);
          fs.writeFileSync(SUB_FILE, JSON.stringify(filteredSubs, null, 2));
        }
      }
    }
    
    const result = {
      message: `推送完成`,
      total: subs.length,
      sent,
      failed,
      failedSubs: failedSubs.slice(0, 10) // 只返回前10个失败项
    };
    
    console.log(`📊 推送结果: ${sent}/${subs.length} 成功`);
    res.json(result);
    
  } catch (error) {
    console.error('推送处理失败:', error);
    res.status(500).json({ error: '服务器内部错误' });
  }
});

// 状态端点
app.get('/status', (req, res) => {
  try {
    const subs = getSubs();
    const logs = JSON.parse(fs.readFileSync(LOG_FILE, 'utf-8') || '[]');
    
    const recentLogs = logs.slice(-10); // 最近10条日志
    const successCount = recentLogs.filter(log => log.success).length;
    const failureCount = recentLogs.filter(log => !log.success).length;
    
    res.json({
      status: 'running',
      subscriptions: subs.length,
      recentActivity: {
        total: recentLogs.length,
        success: successCount,
        failure: failureCount,
        successRate: recentLogs.length > 0 ? (successCount / recentLogs.length * 100).toFixed(2) + '%' : '0%'
      },
      uptime: process.uptime(),
      memory: process.memoryUsage()
    });
  } catch (error) {
    console.error('状态查询失败:', error);
    res.status(500).json({ error: '状态查询失败' });
  }
});

// 获取公钥端点
app.get('/vapidPublicKey', (req, res) => {
  res.json({ publicKey: vapidPublicKey });
});

// 错误处理中间件
app.use((error, req, res, next) => {
  console.error('服务器错误:', error);
  res.status(500).json({ error: '服务器内部错误' });
});

// 404处理
app.use((req, res) => {
  res.status(404).json({ error: '接口不存在' });
});

// 启动服务器
app.listen(PORT, () => {
  console.log(`✅ 推送服务运行中: http://localhost:${PORT}`);
  console.log(`📊 状态页面: http://localhost:${PORT}/status`);
  console.log(`🔑 VAPID 公钥: ${vapidPublicKey.substring(0, 20)}...`);
}); 