const usersService = require('./users.service');

async function getMe(req, res) {
  const user = await usersService.getById(req.user.id);
  res.json({ user });
}

async function updateMe(req, res) {
  const user = await usersService.updateProfile(req.user.id, req.body);
  res.json({ user });
}

module.exports = { getMe, updateMe };
