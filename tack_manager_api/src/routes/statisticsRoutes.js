const express = require('express');
const router = express.Router();

const authMiddleware = require('../middleware/authMiddleware');

const {
  getStatistics,
  getDeadlineTasks,
  getTaskActivities,
  getAllTaskActivities,
} = require('../controllers/statisticsController');

// Thống kê công việc
router.get('/', authMiddleware, getStatistics);

// Công việc sắp đến hạn và quá hạn
router.get('/deadlines', authMiddleware, getDeadlineTasks);

// Lịch sử hoạt động của công việc
router.get('/tasks/:taskId/activities', authMiddleware, getTaskActivities);

// Lịch sử hoạt động tổng hợp
router.get('/activities', authMiddleware, getAllTaskActivities);

module.exports = router;