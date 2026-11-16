const authService = require('./auth.service');

// Express 5 forwards errors from async handlers to the error handler.
async function register(req, res) {
  const result = await authService.register(req.body);
  res.status(201).json(result);
}

async function login(req, res) {
  const result = await authService.login(req.body);
  res.json(result);
}

module.exports = { register, login };
