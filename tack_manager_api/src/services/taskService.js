const Task = require('../models/Task');
const User = require('../models/User');


const EmailLog = require('../models/EmailLog');
const Notification = require('../models/Notification');


const getTaskRecipients = async (taskId) => {
  const task = await Task.findById(taskId)
    .populate('createdBy', 'fullName email')
    .populate('assigneeIds', 'fullName email')
    .populate('sharedWith.userId', 'fullName email');

  if (!task) {
    throw new Error('Không tìm thấy công việc');
  }

  const recipients = new Map();

  const addUser = (user) => {
    if (user && user._id && user.email) {
      recipients.set(user._id.toString(), user);
    }
  };

  addUser(task.createdBy);

  task.assigneeIds.forEach(addUser);

  task.sharedWith.forEach((item) => {
    addUser(item.userId);
  });

  return Array.from(recipients.values());
};


const remindUpcomingTasks = async () => {
  try {
    const now = new Date();
    const reminderTime = new Date(
      now.getTime() + 24 * 60 * 60 * 1000
    );

    const tasks = await Task.find({
      dueDate: {
        $gt: now,
        $lte: reminderTime,
      },
      status: { $ne: 'completed' },
      reminderSentAt: null,
    });

    for (const task of tasks) {
      try {
        const recipients = await getTaskRecipients(task._id);

        const message =
          `Công việc "${task.title}" sắp đến hạn hoàn thành. Vui lòng kiểm tra tiến độ công việc.`;

        let allEmailsSent = true;

        for (const user of recipients) {
          // Kiểm tra email nhắc hạn đã gửi thành công chưa
          const existingEmail = await EmailLog.findOne({
            taskId: task._id,
            recipientEmail: user.email,
            subject: 'Nhắc nhở công việc sắp đến hạn',
            status: 'sent',
          });

          if (!existingEmail && user.email) {
            const result = await require('./emailService').sendEmail({
              taskId: task._id,
              recipientEmail: user.email,
              subject: 'Nhắc nhở công việc sắp đến hạn',
              text: `Xin chào ${user.fullName}, ${message}`,
            });

            if (!result.success) {
              allEmailsSent = false;
            }
          }

          // Tránh tạo thông báo trùng
          const existingNotification = await Notification.findOne({
            userId: user._id,
            taskId: task._id,
            type: 'task_due_reminder',
          });

          if (!existingNotification) {
            await require('./notificationService').createBulkNotifications({
              userIds: [user._id],
              taskId: task._id,
              type: 'task_due_reminder',
              title: 'Nhắc nhở công việc sắp đến hạn',
              message,
            });
          }
        }

        // Chỉ đánh dấu khi email đã gửi thành công
        if (allEmailsSent) {
          task.reminderSentAt = new Date();
          await task.save();
        }

      } catch (error) {
        console.error(
          `Reminder error for task ${task._id}:`,
          error.message
        );
      }
    }

    console.log(
      `Đã kiểm tra ${tasks.length} công việc sắp đến hạn.`
    );

  } catch (error) {
    console.error(
      'Remind upcoming tasks error:',
      error.message
    );
  }
};



module.exports = {
  getTaskRecipients,
  remindUpcomingTasks,
};