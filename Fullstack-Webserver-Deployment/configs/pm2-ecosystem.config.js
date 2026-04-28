// pm2-ecosystem.config.js
// PM2 process configuration for the Nexus Node.js application.
//
// Usage:
//   pm2 start pm2-ecosystem.config.js
//   pm2 reload pm2-ecosystem.config.js   (zero-downtime reload)
//
// After first start, save and set up boot:
//   pm2 save
//   pm2 startup systemd

module.exports = {
  apps: [
    {
      name: 'myapp',
      script: './index.js',
      cwd: '/var/www/myapp',

      // Restart policy
      watch: false,                    // Don't watch files in production
      max_restarts: 10,                // Max crash restarts before giving up
      restart_delay: 3000,             // Wait 3s between restarts
      autorestart: true,               // Auto-restart on crash

      // Environment
      env: {
        NODE_ENV: 'production',
        PORT: 3000,
      },

      // Logging
      out_file: '/var/log/pm2/myapp-out.log',
      error_file: '/var/log/pm2/myapp-error.log',
      merge_logs: true,
      log_date_format: 'YYYY-MM-DD HH:mm:ss Z',

      // Graceful shutdown
      kill_timeout: 5000,              // Wait 5s for graceful shutdown before SIGKILL
      listen_timeout: 3000,            // Time to wait for app to be ready
    },
  ],
};
