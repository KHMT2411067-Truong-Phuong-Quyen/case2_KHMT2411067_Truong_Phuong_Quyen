const Task = require('../models/Task');
const User = require('../models/User');
const { createBulkNotifications } = require('../services/notificationService');
const { sendEmail } = require('../services/emailService');
const { getTaskRecipients } = require('../services/taskService');
const TaskActivity = require('../models/TaskActivity');

// Lấy danh sách công việc
const getTasks = async (req, res) => {
  try {
    const userId = req.user.userId;


    const tasks = await Task.find({
      $or: [
        { createdBy: userId },
        { assigneeIds: userId },
        { 'sharedWith.userId': userId },
      ],
    })
      .populate('createdBy', 'fullName email')
      .populate('assigneeIds', 'fullName email')
      .populate('primaryAssigneeId', 'fullName email')
      .populate('sharedWith.userId', 'fullName email')
      .sort({ createdAt: -1 });


    return res.status(200).json({
      message: 'Lấy danh sách công việc thành công',
      count: tasks.length,
      tasks,
    });
  } catch (error) {
    console.error('Get tasks error:', error.message);

    return res.status(500).json({
      message: 'Lỗi máy chủ khi lấy danh sách công việc',
    });
  }
};

// Tạo công việc mới
const createTask = async (req, res) => {
  try {
    const {
      title,
      description,
      priority,
      status,
      startDate,
      dueDate,
      assigneeIds = [],
      primaryAssigneeId,
      sharedWith = [],
    } = req.body;


    if (!title || !title.trim()) {
      return res.status(400).json({
        message: 'Vui lòng nhập tên công việc',
      });
    }


    // Kiểm tra tài khoản người được giao và người được chia sẻ
    const allUserIds = [
      ...assigneeIds,
      ...sharedWith.map(item => item.userId),
    ];

    const uniqueUserIds = [...new Set(allUserIds.map(id => id.toString()))];

    const existingUsers = await User.find({
      _id: { $in: uniqueUserIds },
    }).select('_id');

    if (existingUsers.length !== uniqueUserIds.length) {
      return res.status(400).json({
        message: 'Có tài khoản người dùng không tồn tại',
      });
    }


    const creatorId = req.user.userId.toString();

    if (uniqueUserIds.includes(creatorId)) {
      return res.status(400).json({
        message: 'Không thể thêm chính mình vào danh sách người được giao hoặc chia sẻ',
      });
    }


    const assignedIds = assigneeIds.map(id => id.toString());
    const sharedIds = sharedWith.map(item => item.userId.toString());

    if (sharedIds.some(id => assignedIds.includes(id))) {
      return res.status(400).json({
        message: 'Một người không thể vừa được giao vừa được chia sẻ cùng công việc',
      });
    }


    const invalidShare = sharedWith.some(
      item => !['viewer', 'editor'].includes(item.role || 'viewer')
    );

    if (invalidShare) {
      return res.status(400).json({
        message: 'Quyền chia sẻ chỉ được là viewer hoặc editor',
      });
    }


    const priorityMap = {
      'Thấp': 'low',
      'Trung bình': 'medium',
      'Cao': 'high',
    };

    const statusMap = {
      'Chưa thực hiện': 'todo',
      'Đang thực hiện': 'in_progress',
      'Đã hoàn thành': 'completed',
    };


    // Kiểm tra người phụ trách chính
    const finalPrimaryAssigneeId =
      primaryAssigneeId || assigneeIds[0] || null;

    if (
      finalPrimaryAssigneeId &&
      !assigneeIds.map(id => id.toString()).includes(
        finalPrimaryAssigneeId.toString()
      )
    ) {
      return res.status(400).json({
        message: 'Người phụ trách chính phải nằm trong danh sách người được giao',
      });
    }



    const task = await Task.create({
      title: title.trim(),
      description: description || '',
      createdBy: req.user.userId,
      assigneeIds: assigneeIds,
      primaryAssigneeId: finalPrimaryAssigneeId,
      sharedWith: sharedWith,

      priority: priorityMap[priority] || priority || 'medium',
      status: statusMap[status] || status || 'todo',
      startDate: startDate || null,
      dueDate: dueDate || null,
    });


    // Ghi lịch sử tạo công việc
    await logTaskActivity({
      taskId: task._id,
      userId: req.user.userId,
      action: 'created',
      description: `Đã tạo công việc "${task.title}"`,
    });


    // Gửi thông báo và email cho người được giao
    try {
      const assignedUsers = await User.find({
        _id: { $in: assigneeIds },
      });

      if (assignedUsers.length > 0) {
        await createBulkNotifications({
          userIds: assignedUsers.map(user => user._id),
          taskId: task._id,
          type: 'task_assigned',
          title: 'Bạn được giao công việc mới',
          message: `Bạn được giao công việc: ${task.title}`,
        });

        await Promise.all(
          assignedUsers
            .filter(user => user.email)
            .map(user =>
              sendEmail({
                taskId: task._id,
                recipientEmail: user.email,
                subject: 'Bạn được giao công việc mới',
                text: `Xin chào ${user.fullName}, bạn vừa được giao công việc: ${task.title}.`,
              })
            )
        );
      }

      // Gửi thông báo và email cho người được chia sẻ
      const sharedUsers = await User.find({
        _id: { $in: sharedWith.map(item => item.userId) },
      });

      if (sharedUsers.length > 0) {
        await createBulkNotifications({
          userIds: sharedUsers.map(user => user._id),
          taskId: task._id,
          type: 'task_shared',
          title: 'Bạn được chia sẻ công việc',
          message: `Bạn được mời xem hoặc tham gia công việc: ${task.title}`,
        });

        await Promise.all(
          sharedUsers
            .filter(user => user.email)
            .map(user =>
              sendEmail({
                taskId: task._id,
                recipientEmail: user.email,
                subject: 'Bạn được chia sẻ công việc',
                text: `Xin chào ${user.fullName}, bạn vừa được chia sẻ công việc: ${task.title}.`,
              })
            )
        );
      }
    } catch (notificationError) {
      console.error('Task notification error:', notificationError.message);
    }



    return res.status(201).json({
      message: 'Tạo công việc thành công',
      task,
    });
  } catch (error) {
    console.error('Create task error:', error.message);

    return res.status(500).json({
      message: 'Lỗi máy chủ khi tạo công việc',
    });
  }
};

// Cập nhật công việc
const updateTask = async (req, res) => {
  try {
    const {
      title,
      description,
      priority,
      status,
      startDate,
      dueDate,
    } = req.body;

    const priorityMap = {
      'Thấp': 'low',
      'Trung bình': 'medium',
      'Cao': 'high',
    };

    const statusMap = {
      'Chưa thực hiện': 'todo',
      'Đang thực hiện': 'in_progress',
      'Đã hoàn thành': 'completed',
    };

    // Tìm công việc và kiểm tra quyền chỉnh sửa
    const task = await Task.findOne({
      _id: req.params.id,
      $or: [
        { createdBy: req.user.userId },
        {
          sharedWith: {
            $elemMatch: {
              userId: req.user.userId,
              role: 'editor',
            },
          },
        },
      ],
    });

    if (!task) {
      return res.status(404).json({
        message: 'Không tìm thấy công việc hoặc bạn không có quyền sửa',
      });
    }

    // Lưu trạng thái cũ để so sánh
    const oldStatus = task.status;

    const oldValues = {
      title: task.title,
      description: task.description,
      priority: task.priority,
      startDate: task.startDate?.toISOString() || null,
      dueDate: task.dueDate?.toISOString() || null,
    };

    // Cập nhật các trường được gửi lên
    if (title !== undefined) task.title = title.trim();
    if (description !== undefined) task.description = description;
    if (priority !== undefined) {
      task.priority = priorityMap[priority] || priority;
    }
    if (status !== undefined) {
      task.status = statusMap[status] || status;
    }
    if (startDate !== undefined) task.startDate = startDate || null;
    if (dueDate !== undefined) task.dueDate = dueDate || null;

    await task.save();

    // Kiểm tra thông tin quan trọng có thay đổi không
    const changedFields = [];

    if (oldValues.title !== task.title) changedFields.push('tên công việc');
    if (oldValues.description !== task.description) changedFields.push('mô tả');
    if (oldValues.priority !== task.priority) changedFields.push('độ ưu tiên');

    if (oldValues.startDate !== (task.startDate?.toISOString() || null)) {
      changedFields.push('ngày bắt đầu');
    }

    if (oldValues.dueDate !== (task.dueDate?.toISOString() || null)) {
      changedFields.push('hạn hoàn thành');
    }


    // Kiểm tra công việc vừa chuyển sang hoàn thành
    const justCompleted =
      oldStatus !== 'completed' && task.status === 'completed';

      // Ghi lịch sử cập nhật công việc
      if (changedFields.length > 0 || oldStatus !== task.status) {
        const activityChanges = [...changedFields];

        if (oldStatus !== task.status) {
          activityChanges.push('trạng thái');
        }

        await logTaskActivity({
          taskId: task._id,
          userId: req.user.userId,
          action: justCompleted ? 'completed' : 'updated',
          description: justCompleted
            ? `Đã hoàn thành công việc "${task.title}"`
            : `Đã cập nhật ${activityChanges.join(', ')} của công việc "${task.title}"`,
          metadata: {
            changedFields: activityChanges,
            oldStatus,
            newStatus: task.status,
          },
        });
      }


    try {
      const recipients = await getTaskRecipients(task._id);
      const userIds = recipients.map(user => user._id);

      // Thông báo khi thông tin công việc thay đổi
      if (changedFields.length > 0) {
        const message = `Công việc "${task.title}" đã được cập nhật: ${changedFields.join(', ')}.`;

        await createBulkNotifications({
          userIds,
          taskId: task._id,
          type: 'task_updated',
                    title: 'Công việc đã được cập nhật',
                    message,
                  });

                  await Promise.all(
                    recipients
                      .filter(user => user.email)
                      .map(user =>
                        sendEmail({
                          taskId: task._id,
                          recipientEmail: user.email,
                          subject: 'Công việc đã được cập nhật',
                          text: message,
                        })
                      )
                  );
                }

                // Thông báo khi công việc hoàn thành
                if (justCompleted) {
                  const message = `Công việc "${task.title}" đã được đánh dấu hoàn thành.`;

                  await createBulkNotifications({
                    userIds,
                    taskId: task._id,
                    type: 'task_completed',
                    title: 'Công việc đã hoàn thành',
                    message,
                  });

                  await Promise.all(
                    recipients
                      .filter(user => user.email)
                      .map(user =>
                        sendEmail({
                          taskId: task._id,
                          recipientEmail: user.email,
                          subject: 'Công việc đã hoàn thành',
                          text: message,
                        })
                      )
                  );
                }
              } catch (notificationError) {
                console.error('Task update notification error:', notificationError.message);
              }

              return res.status(200).json({
                message: 'Cập nhật công việc thành công',
                task,
              });
            } catch (error) {
              console.error('Update task error:', error.message);

              return res.status(500).json({
                message: 'Lỗi máy chủ khi cập nhật công việc',
              });
            }
          };


      // Xóa công việc
      const deleteTask = async (req, res) => {
        try {
          const task = await Task.findOne({
            _id: req.params.id,
            createdBy: req.user.userId,
          });

          if (!task) {
            return res.status(404).json({
              message: 'Không tìm thấy công việc hoặc bạn không có quyền xóa',
            });
          }

          // Ghi lịch sử trước khi xóa
          await logTaskActivity({
            taskId: task._id,
            userId: req.user.userId,
            action: 'deleted',
            description: `Đã xóa công việc "${task.title}"`,
          });

          await task.deleteOne();

          return res.status(200).json({
            message: 'Xóa công việc thành công',
          });
        } catch (error) {
          console.error('Delete task error:', error.message);

          return res.status(500).json({
            message: 'Lỗi máy chủ khi xóa công việc',
          });
        }
      };


      // Thay đổi quyền chia sẻ
      const updateSharePermission = async (req, res) => {
        try {
          const { userId, role } = req.body;

          if (!['viewer', 'editor'].includes(role)) {
            return res.status(400).json({
              message: 'Quyền chia sẻ không hợp lệ',
            });
          }

          const task = await Task.findOne({
            _id: req.params.id,
            createdBy: req.user.userId,
          });


          if (!task) {
            return res.status(404).json({
              message: 'Không tìm thấy công việc hoặc bạn không có quyền',
            });
          }

          const sharedUser = task.sharedWith.find(
            item => item.userId.toString() === userId
          );

          if (!sharedUser) {
            return res.status(404).json({
              message: 'Không tìm thấy người được chia sẻ',
            });
          }



          const oldRole = sharedUser.role;

          sharedUser.role = role;
          await task.save();

          if (oldRole !== role) {

          // Ghi lịch sử thay đổi quyền chia sẻ
          await logTaskActivity({
            taskId: task._id,
            userId: req.user.userId,
            action: 'share_permission_updated',
            description: `Đã thay đổi quyền chia sẻ của người dùng ${userId} thành ${role}`,
            metadata: {
              sharedUserId: userId,
              oldRole,
              newRole: role,
            },
          });


            try {
              await createBulkNotifications({
                userIds: [userId],
                taskId: task._id,
                type: 'share_permission_updated',
                title: 'Quyền chia sẻ đã thay đổi',
                message: `Quyền của bạn đối với công việc "${task.title}" đã được đổi thành ${role === 'editor' ? 'Người chỉnh sửa' : 'Người xem'}.`,
              });

              const sharedUserAccount = await User.findById(userId);

              if (sharedUserAccount?.email) {
                await sendEmail({
                  taskId: task._id,
                  recipientEmail: sharedUserAccount.email,
                  subject: 'Quyền chia sẻ công việc đã thay đổi',
                  text: `Quyền của bạn đối với công việc "${task.title}" đã được đổi thành ${role === 'editor' ? 'Người chỉnh sửa' : 'Người xem'}.`,
                });
              }
            } catch (notificationError) {
              console.error('Share permission notification error:', notificationError.message);
            }
          }



          return res.status(200).json({
            message: 'Cập nhật quyền chia sẻ thành công',
            task,
          });
        } catch (error) {
          console.error('Update share permission error:', error.message);
          return res.status(500).json({
            message: 'Lỗi máy chủ khi cập nhật quyền chia sẻ',
          });
        }
      };


      // Thu hồi quyền chia sẻ
      const revokeShareAccess = async (req, res) => {
        try {
          const { userId } = req.body;

          if (!userId) {
            return res.status(400).json({
              message: 'Thiếu ID người dùng cần thu hồi quyền',
            });
          }

          const task = await Task.findOne({
            _id: req.params.id,
            createdBy: req.user.userId,
          });

          if (!task) {
            return res.status(404).json({
              message: 'Không tìm thấy công việc hoặc bạn không có quyền',
            });
          }

          const oldLength = task.sharedWith.length;

          task.sharedWith = task.sharedWith.filter(
            item => item.userId.toString() !== userId.toString()
          );

          if (task.sharedWith.length === oldLength) {
            return res.status(404).json({
              message: 'Người dùng không có trong danh sách chia sẻ',
            });
          }

          await task.save();


          // Ghi lịch sử thu hồi quyền chia sẻ
          await logTaskActivity({
            taskId: task._id,
            userId: req.user.userId,
            action: 'share_access_revoked',
            description: `Đã thu hồi quyền chia sẻ của người dùng ${userId}`,
            metadata: {
              revokedUserId: userId,
            },
          });


          try {
            await createBulkNotifications({
              userIds: [userId],
              taskId: task._id,
              type: 'share_access_revoked',
              title: 'Quyền truy cập đã bị thu hồi',
              message: `Bạn không còn quyền truy cập công việc "${task.title}".`,
            });

            const revokedUser = await User.findById(userId);

            if (revokedUser?.email) {
              await sendEmail({
                taskId: task._id,
                recipientEmail: revokedUser.email,
                subject: 'Quyền truy cập công việc đã bị thu hồi',
                text: `Quyền truy cập của bạn đối với công việc "${task.title}" đã bị thu hồi.`,
              });
            }
          } catch (notificationError) {
            console.error('Revoke share notification error:', notificationError.message);
          }


          return res.status(200).json({
            message: 'Đã thu hồi quyền chia sẻ thành công',
            task,
          });
        } catch (error) {
          console.error('Revoke share access error:', error);

          return res.status(500).json({
            message: 'Lỗi máy chủ khi thu hồi quyền chia sẻ',
          });
        }
      };


      // Ghi lịch sử hoạt động của công việc
      const logTaskActivity = async ({
        taskId,
        userId,
        action,
        description,
        metadata = {},
      }) => {
        try {
          await TaskActivity.create({
            taskId,
            userId,
            action,
            description,
            metadata,
          });
        } catch (error) {
          console.error('Log task activity error:', error.message);
        }
      };


     module.exports = {
       getTasks,
       createTask,
       updateTask,
       deleteTask,
       updateSharePermission,
       revokeShareAccess,
     };