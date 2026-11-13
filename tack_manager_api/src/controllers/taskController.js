const Task = require('../models/Task');
const User = require('../models/User');


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

    const task = await Task.findOneAndUpdate(
      {
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
      },


      {
        title: title?.trim(),
        description: description ?? '',
        priority: priorityMap[priority] || priority,
        status: statusMap[status] || status,
        startDate: startDate || null,
        dueDate: dueDate || null,
      },
      { new: true, runValidators: true }
    );

    if (!task) {
      return res.status(404).json({
        message: 'Không tìm thấy công việc hoặc bạn không có quyền sửa',
      });
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
          const task = await Task.findOneAndDelete({
            _id: req.params.id,
            createdBy: req.user.userId,
          });

          if (!task) {
            return res.status(404).json({
              message: 'Không tìm thấy công việc hoặc bạn không có quyền xóa',
            });
          }

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

          sharedUser.role = role;
          await task.save();

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


     module.exports = {
       getTasks,
       createTask,
       updateTask,
       deleteTask,
       updateSharePermission,
       revokeShareAccess,
     };