const Task = require('../models/Task');

// Lấy danh sách công việc
const getTasks = async (req, res) => {
  try {
    const userId = req.user.userId;

    const tasks = await Task.find({
      $or: [
        { createdBy: userId },
        { assigneeIds: userId },
      ],
    })
      .populate('createdBy', 'fullName email')
      .populate('assigneeIds', 'fullName email')
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
    } = req.body;


    if (!title || !title.trim()) {
      return res.status(400).json({
        message: 'Vui lòng nhập tên công việc',
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

    const task = await Task.create({
      title: title.trim(),
      description: description || '',
      createdBy: req.user.userId,
      assigneeIds: assigneeIds,
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
        createdBy: req.user.userId,
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

      module.exports = {
        getTasks,
        createTask,
        updateTask,
        deleteTask,
      };