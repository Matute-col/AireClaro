const express = require('express');
const helmet = require('helmet');
const cors = require('cors');
const env = require('./config/env');
const { globalLimiter } = require('./middleware/rateLimit');
const { notFound, errorHandler } = require('./middleware/errorHandler');
const authRoutes = require('./modules/auth/auth.routes');

const app = express();

app.disable('x-powered-by');
app.use(helmet());
app.use(cors({ origin: env.CORS_ORIGIN }));
app.use(express.json({ limit: '100kb' }));

const api = express.Router();
api.use(globalLimiter);

api.get('/health', (req, res) => {
  res.json({ status: 'ok' });
});

api.use('/auth', authRoutes);

app.use('/api', api);

app.use(notFound);
app.use(errorHandler);

module.exports = app;
