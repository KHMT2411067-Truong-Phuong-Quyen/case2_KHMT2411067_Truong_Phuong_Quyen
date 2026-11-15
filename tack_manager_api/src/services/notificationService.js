const Notification = require('../models/Notification');

// Tạo thông báo cho một người dùng
const createNotification = async ({
  userId,
  taskId = null,
  type,
  title,
  message,
}) => {
  try {
    const notification = await Notification.create({
      userId,
      taskId,
      type,
      title,
      message,
    });

    return notification;
  } catch (error) {
    console.error('Create notification error:', error.message);
    throw error;
  }
};

// Tạo thông báo cho nhiều người dùng
const createBulkNotifications = async ({
  userIds,
  taskId = null,
  type,
  title,
  message,
}) => {
  try {
    if (!userIds || userIds.length === 0) {
      return [];
    }

    const notifications = userIds.map((userId) => ({
      userId,
      taskId,
      type,
      title,
      message,
    }));

    return await Notification.insertMany(notifications);
  } catch (error) {
    console.error('Create bulk notifications error:', error.message);
    throw error;
  }
};

module.exports = {
  createNotification,
  createBulkNotifications,
};