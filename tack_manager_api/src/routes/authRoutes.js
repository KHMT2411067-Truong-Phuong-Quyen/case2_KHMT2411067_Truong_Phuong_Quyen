const express = require('express');
const router = express.Router();

const {
  register,
  login,
  updateProfile,
  changePassword,
  getUsers,
} = require('../controllers/authController');

router.post('/register', register);
router.post('/login', login);
router.put('/profile', updateProfile);
router.put('/change-password', changePassword);

const authMiddleware = require('../middleware/authMiddleware');

router.get('/users', authMiddleware, getUsers);

module.exports = router;