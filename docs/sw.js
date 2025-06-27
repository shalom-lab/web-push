// Service Worker for Web Push Notifications
self.addEventListener('install', event => {
  console.log('Service Worker 安装成功');
  self.skipWaiting();
});

self.addEventListener('activate', event => {
  console.log('Service Worker 激活成功');
  event.waitUntil(self.clients.claim());
});

self.addEventListener('push', event => {
  console.log('收到推送消息:', event);
  
  let data = {
    title: '新通知',
    body: '您有一条新消息',
    icon: 'images/icon.png',
    badge: 'images/badge.png',
    tag: 'default',
    requireInteraction: false,
    actions: [
      {
        action: 'open',
        title: '查看',
        icon: 'images/action-open.png'
      },
      {
        action: 'close',
        title: '关闭',
        icon: 'images/action-close.png'
      }
    ]
  };

  if (event.data) {
    try {
      const pushData = event.data.json();
      data = { ...data, ...pushData };
    } catch (error) {
      console.error('解析推送数据失败:', error);
      data.body = event.data.text() || data.body;
    }
  }

  const options = {
    body: data.body,
    icon: data.icon,
    badge: data.badge,
    tag: data.tag,
    requireInteraction: data.requireInteraction,
    actions: data.actions,
    data: data.data || {},
    vibrate: [200, 100, 200],
    sound: data.sound,
    silent: data.silent || false
  };

  event.waitUntil(
    self.registration.showNotification(data.title, options)
  );
});

self.addEventListener('notificationclick', event => {
  console.log('通知被点击:', event);
  
  event.notification.close();

  if (event.action === 'close') {
    return;
  }

  // 默认行为或点击"查看"按钮
  event.waitUntil(
    self.clients.matchAll({ type: 'window' }).then(clientList => {
      // 如果已经有打开的窗口，聚焦到第一个
      for (const client of clientList) {
        if (client.url.includes(self.location.origin) && 'focus' in client) {
          return client.focus();
        }
      }
      
      // 如果没有打开的窗口，打开新窗口
      if (self.clients.openWindow) {
        return self.clients.openWindow('/');
      }
    })
  );
});

self.addEventListener('notificationclose', event => {
  console.log('通知被关闭:', event);
});

// 处理后台同步
self.addEventListener('sync', event => {
  console.log('后台同步:', event);
  if (event.tag === 'background-sync') {
    event.waitUntil(doBackgroundSync());
  }
});

async function doBackgroundSync() {
  try {
    // 这里可以执行后台同步任务
    console.log('执行后台同步任务');
  } catch (error) {
    console.error('后台同步失败:', error);
  }
} 