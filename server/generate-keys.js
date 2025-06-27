#!/usr/bin/env node

const webpush = require('web-push');
const fs = require('fs');
const path = require('path');

console.log('🔑 生成 VAPID 密钥对...\n');

try {
  const vapidKeys = webpush.generateVAPIDKeys();
  
  console.log('✅ VAPID 密钥生成成功！\n');
  console.log('📋 请将以下内容添加到你的 .env 文件中：\n');
  console.log('='.repeat(50));
  console.log(`VAPID_PUBLIC_KEY=${vapidKeys.publicKey}`);
  console.log(`VAPID_PRIVATE_KEY=${vapidKeys.privateKey}`);
  console.log('VAPID_EMAIL=your-email@example.com');
  console.log('='.repeat(50));
  console.log('\n📝 同时更新 client/main.js 中的 vapidPublicKey：');
  console.log(`const vapidPublicKey = '${vapidKeys.publicKey}';`);
  
  // 检查是否存在 .env 文件
  const envPath = path.join(__dirname, '.env');
  if (fs.existsSync(envPath)) {
    console.log('\n⚠️  检测到现有 .env 文件，请手动更新密钥。');
  } else {
    console.log('\n💡 提示：可以复制 .env.example 到 .env 并填入上述密钥。');
  }
  
  console.log('\n🔒 安全提醒：');
  console.log('- 请妥善保管私钥，不要提交到版本控制');
  console.log('- 生产环境请使用环境变量或密钥管理服务');
  console.log('- 定期轮换密钥以提高安全性');
  
} catch (error) {
  console.error('❌ 生成密钥失败:', error.message);
  process.exit(1);
} 