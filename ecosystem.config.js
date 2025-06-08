module.exports = {
  apps: [{
    name: 'chat-app',
    script: 'app.js',
    cwd: '/opt/chat-app',
    instances: 1,
    exec_mode: 'fork',
    env: {
      NODE_ENV: 'production',
      PORT: 3000
    }
  }]
};
