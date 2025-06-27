const vapidPublicKey = '【填入你的公钥】';
const serverUrl = 'https://your-server.com'; // 填你的推送服务地址

function urlBase64ToUint8Array(base64String) {
  const padding = '='.repeat((4 - base64String.length % 4) % 4);
  const base64 = (base64String + padding).replace(/-/g, '+').replace(/_/g, '/');
  const rawData = atob(base64);
  return Uint8Array.from([...rawData].map(char => char.charCodeAt(0)));
}

function showStatus(message, type = 'success') {
  const statusEl = document.getElementById('status');
  statusEl.textContent = message;
  statusEl.className = `status ${type}`;
  statusEl.style.display = 'block';
  
  if (type === 'success') {
    setTimeout(() => {
      statusEl.style.display = 'none';
    }, 3000);
  }
}

document.getElementById('subscribe').addEventListener('click', async () => {
  try {
    // 检查浏览器支持
    if (!('serviceWorker' in navigator) || !('PushManager' in window)) {
      showStatus('❌ 您的浏览器不支持推送通知', 'error');
      return;
    }

    // 请求通知权限
    const permission = await Notification.requestPermission();
    if (permission !== 'granted') {
      showStatus('❌ 必须允许通知权限才能订阅', 'error');
      return;
    }

    // 注册 Service Worker
    const reg = await navigator.serviceWorker.register('sw.js');
    console.log('Service Worker 注册成功:', reg);

    // 订阅推送
    const sub = await reg.pushManager.subscribe({
      userVisibleOnly: true,
      applicationServerKey: urlBase64ToUint8Array(vapidPublicKey)
    });

    console.log('推送订阅成功:', sub);

    // 发送订阅信息到服务器
    const response = await fetch(serverUrl + '/subscribe', {
      method: 'POST',
      body: JSON.stringify(sub),
      headers: { 'Content-Type': 'application/json' }
    });

    if (!response.ok) {
      throw new Error(`服务器响应错误: ${response.status}`);
    }

    const result = await response.json();
    showStatus('✅ 订阅成功！您将收到推送通知', 'success');
    
    // 更新按钮状态
    const btn = document.getElementById('subscribe');
    btn.textContent = '已订阅';
    btn.disabled = true;
    btn.style.background = '#4CAF50';

  } catch (error) {
    console.error('订阅失败:', error);
    showStatus(`❌ 订阅失败: ${error.message}`, 'error');
  }
});

// 检查是否已经订阅
async function checkSubscription() {
  try {
    if ('serviceWorker' in navigator && 'PushManager' in window) {
      const reg = await navigator.serviceWorker.getRegistration();
      if (reg) {
        const sub = await reg.pushManager.getSubscription();
        if (sub) {
          const btn = document.getElementById('subscribe');
          btn.textContent = '已订阅';
          btn.disabled = true;
          btn.style.background = '#4CAF50';
        }
      }
    }
  } catch (error) {
    console.error('检查订阅状态失败:', error);
  }
}

// 页面加载时检查订阅状态
document.addEventListener('DOMContentLoaded', checkSubscription); 