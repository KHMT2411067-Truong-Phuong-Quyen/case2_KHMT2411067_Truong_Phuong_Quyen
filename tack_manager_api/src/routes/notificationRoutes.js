const express = require('express');
const router = express.Router();

const {
  getNotifications,
  markNotificationAsRead,
  markAllNotificationsAsRead,
  getUnreadNotificationCount,
} = require('../controllers/notificationController');

const authMiddleware = require('../middleware/authMiddleware');

// Lấy danh sách thông báo
router.get('/', authMiddleware, getNotifications);

// Đếm thông báo chưa đọc
router.get('/unread-count', authMiddleware, getUnreadNotificationCount);

// Đánh dấu một thông báo đã đọc
router.put('/:id/read', authMiddleware, markNotificationAsRead);

// Đánh dấu tất cả thông báo đã đọc
router.put('/read-all', authMiddleware, markAllNotificationsAsRead);

module.exports = router;