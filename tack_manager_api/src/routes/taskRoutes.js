const express = require('express');
const router = express.Router();

const { getTasks } = require('../controllers/taskController');
const authMiddleware = require('../middleware/authMiddleware');

// Chỉ người dùng có JWT hợp lệ mới được lấy danh sách công việc
router.get('/', authMiddleware, getTasks);

module.exports = router;