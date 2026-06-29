const express = require('express');

const app = express();
const PORT = process.env.PORT || 3000;

let isReady = false;

app.use(express.json());

app.get('/', (req, res) => {
  res.json({
    status: 'ok',
    version: process.env.APP_VERSION,
    uptime: process.uptime(),
  });
});

app.get('/health', (req, res) => {
  res.json({
    status: 'healthy',
    checks: {
      db: 'ok',
      cache: 'ok',
    },
  });
});

app.get('/ready', (req, res) => {
  if (isReady) {
    res.sendStatus(200);
  } else {
    res.sendStatus(503);
  }
});

const server = app.listen(PORT, () => {
  isReady = true;
  console.log(`Server listening on port ${PORT}`);
});

process.on('SIGTERM', () => {
  console.log('SIGTERM received, shutting down gracefully');
  isReady = false;
  server.close(() => {
    console.log('Server closed');
    process.exit(0);
  });
});
