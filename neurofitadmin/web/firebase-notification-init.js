// Firebase Cloud Messaging Web Push Client Initializer for NeuroFit Admin
// Credentials dynamically loaded from backend environment variables (No hardcoded keys)
(function () {
  async function fetchConfig() {
    const endpoints = [
      '/api/notifications/firebase-config',
      'http://localhost:5000/api/notifications/firebase-config'
    ];
    for (const url of endpoints) {
      try {
        const res = await fetch(url);
        if (res.ok) {
          const data = await res.json();
          if (data && data.success && data.config) {
            return data;
          }
        }
      } catch (_) {}
    }
    return null;
  }

  async function initPushNotifications() {
    if (!('Notification' in window) || !('serviceWorker' in navigator)) {
      console.log('ℹ️ Web Push Notifications are not supported in this browser environment.');
      return;
    }

    try {
      // 1. Fetch public Firebase web configuration dynamically from backend environment variables
      const serverConfig = await fetchConfig();
      if (!serverConfig || !serverConfig.config || !serverConfig.config.apiKey) {
        console.warn('⚠️ Firebase Web Push config not yet populated in backend .env.');
        return;
      }

      const { config, vapidKey } = serverConfig;

      // 2. Initialize Firebase Web SDK dynamically
      if (!window.firebase.apps.length) {
        window.firebase.initializeApp(config);
      }

      // 3. Register Service Worker with environment config passed via query params
      const swUrl = '/firebase-messaging-sw.js';
      const registration = await navigator.serviceWorker.register(swUrl);
      console.log('✅ FCM Service Worker registered:', registration.scope);

      // 4. Request Notification Permission
      let permission = Notification.permission;
      if (permission === 'default') {
        permission = await Notification.requestPermission();
      }

      if (permission !== 'granted') {
        console.log('ℹ️ Notification permission not granted.');
        return;
      }

      // 5. Retrieve Web Push Token using dynamic VAPID key
      const messaging = window.firebase.messaging();
      const tokenOptions = { serviceWorkerRegistration: registration };
      if (vapidKey) {
        tokenOptions.vapidKey = vapidKey;
      }

      const currentToken = await messaging.getToken(tokenOptions);

      if (currentToken) {
        console.log('📲 FCM Web Push Token registered successfully!');

        // 6. Send Token to Backend & Subscribe to Admin Topics
        const registerEndpoints = [
          '/api/notifications/register-token',
          'http://localhost:5000/api/notifications/register-token'
        ];

        for (const regUrl of registerEndpoints) {
          try {
            const res = await fetch(regUrl, {
              method: 'POST',
              headers: { 'Content-Type': 'application/json' },
              body: JSON.stringify({
                token: currentToken,
                role: 'admin',
                platform: 'web'
              })
            });
            if (res.ok) break;
          } catch (_) {}
        }
      }

      // 7. Foreground message listener with audio alert and system notification
      messaging.onMessage((payload) => {
        const title = payload.notification?.title || payload.data?.title || 'NeuroFit Admin Alert';
        const body = payload.notification?.body || payload.data?.body || 'New update received';

        // Play subtle sound alert
        try {
          const audioCtx = new (window.AudioContext || window.webkitAudioContext)();
          const osc = audioCtx.createOscillator();
          const gain = audioCtx.createGain();
          osc.type = 'sine';
          osc.frequency.setValueAtTime(587.33, audioCtx.currentTime);
          gain.gain.setValueAtTime(0.15, audioCtx.currentTime);
          gain.gain.exponentialRampToValueAtTime(0.01, audioCtx.currentTime + 0.35);
          osc.connect(gain);
          gain.connect(audioCtx.destination);
          osc.start();
          osc.stop(audioCtx.currentTime + 0.35);
        } catch (_) {}

        if (Notification.permission === 'granted') {
          new Notification(title, {
            body: body,
            icon: '/favicon.png',
            badge: '/favicon.png',
            data: payload.data
          });
        }
      });
    } catch (err) {
      console.warn('FCM Web Push notice:', err.message);
    }
  }

  window.addEventListener('load', () => {
    setTimeout(initPushNotifications, 2000);
  });
})();
