const express = require('express');
const cors = require('cors');
const client = require('prom-client');
const taskRoutes = require('./routes/taskRoutes');
const { errorHandler, notFoundHandler } = require('./middleware/errorHandler');

// Collect default Node.js metrics (CPU, memory, event loop lag, etc.)
client.collectDefaultMetrics();

// Custom metric: HTTP request counter
const httpRequestCounter = new client.Counter({
  name: 'http_requests_total',
  help: 'Total number of HTTP requests',
  labelNames: ['method', 'route', 'status_code'],
});

function createApp() {
  const app = express();

  app.use(cors());
  app.use(express.json());

  // Track every request — must come before routes so it actually wraps them
  app.use((req, res, next) => {
    res.on('finish', () => {
      httpRequestCounter.inc({
        method: req.method,
        route: req.route?.path || req.path,
        status_code: res.statusCode,
      });
    });
    next();
  });

  app.get('/metrics', async (req, res) => {
    res.set('Content-Type', client.register.contentType);
    res.end(await client.register.metrics());
  });

  // Health check — this is the endpoint your monitoring/orchestrator should poll
  app.get('/health', (req, res) => {
    res.status(200).json({
      status: 'ok',
      uptime: process.uptime(),
      timestamp: new Date().toISOString(),
    });
  });

  app.get('/', (req, res) => {
    res.status(200).json({ message: 'TaskFlow API', docs: '/health, /api/tasks' });
  });

  app.use('/api/tasks', taskRoutes);

  app.use(notFoundHandler);
  app.use(errorHandler);

  return app;
}

module.exports = createApp;