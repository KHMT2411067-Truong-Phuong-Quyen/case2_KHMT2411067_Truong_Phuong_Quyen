const Task = require('../models/Task');
const TaskActivity = require('../models/TaskActivity');

// Thống kê công việc
const getStatistics = async (req, res) => {
  try {
    const userId = req.user.userId;

    const [
      totalCreated,
      totalAssigned,
      totalShared,
      todo,
      inProgress,
      completed,
      overdue,
      upcoming,
    ] = await Promise.all([
      Task.countDocuments({ createdBy: userId }),

      Task.countDocuments({
        assigneeIds: userId,
      }),

      Task.countDocuments({
        'sharedWith.userId': userId,
      }),

      Task.countDocuments({
        createdBy: userId,
        status: 'todo',
      }),

      Task.countDocuments({
        createdBy: userId,
        status: 'in_progress',
      }),

      Task.countDocuments({
        createdBy: userId,
        status: 'completed',
      }),

      Task.countDocuments({
        $or: [
          { createdBy: userId },
          { assigneeIds: userId },
          { 'sharedWith.userId': userId },
        ],
        dueDate: { $lt: new Date() },
        status: { $ne: 'completed' },
      }),

      Task.countDocuments({
        $or: [
          { createdBy: userId },
          { assigneeIds: userId },
          { 'sharedWith.userId': userId },
        ],
        dueDate: {
          $gte: new Date(),
          $lte: new Date(Date.now() + 24 * 60 * 60 * 1000),
        },
        status: { $ne: 'completed' },
      }),
    ]);

    return res.status(200).json({
      message: 'Lấy thống kê thành công',
      statistics: {
        totalCreated,
        totalAssigned,
        totalShared,
        byStatus: {
          todo,
          inProgress,
          completed,
        },
        overdue,
        upcoming,
      },
    });
  } catch (error) {
    console.error('Get statistics error:', error);
    return res.status(500).json({
      message: 'Không thể lấy thống kê công việc',
    });
  }
};

// Lấy công việc sắp đến hạn và quá hạn
const getDeadlineTasks = async (req, res) => {
  try {
    const userId = req.user.userId;
    const now = new Date();
    const tomorrow = new Date(
      now.getTime() + 24 * 60 * 60 * 1000
    );

    const userTasks = {
      $or: [
        { createdBy: userId },
        { assigneeIds: userId },
        { 'sharedWith.userId': userId },
      ],
    };

    const [overdueTasks, upcomingTasks] = await Promise.all([
      Task.find({
        ...userTasks,
        dueDate: { $lt: now },
        status: { $ne: 'completed' },
      }).sort({ dueDate: 1 }),

      Task.find({
        ...userTasks,
        dueDate: { $gte: now, $lte: tomorrow },
        status: { $ne: 'completed' },
      }).sort({ dueDate: 1 }),
    ]);

    return res.status(200).json({
      message: 'Lấy danh sách công việc theo hạn thành công',
      overdueTasks,
      upcomingTasks,
    });
  } catch (error) {
    console.error('Get deadline tasks error:', error);
    return res.status(500).json({
          message: 'Không thể lấy danh sách công việc theo hạn',
        });
      }
    };

    // Xem lịch sử hoạt động của công việc
    const getTaskActivities = async (req, res) => {
      try {
        const userId = req.user.userId;
        const { taskId } = req.params;

        const task = await Task.findOne({
          _id: taskId,
          $or: [
            { createdBy: userId },
            { assigneeIds: userId },
            { 'sharedWith.userId': userId },
          ],
        });

        if (!task) {
          return res.status(404).json({
            message: 'Không tìm thấy công việc hoặc bạn không có quyền xem',
          });
        }

        const activities = await TaskActivity.find({ taskId })
          .populate('userId', 'fullName email')
          .sort({ createdAt: -1 });

        return res.status(200).json({
          message: 'Lấy lịch sử hoạt động thành công',
          count: activities.length,
          activities,
        });
      } catch (error) {
        console.error('Get task activities error:', error);
        return res.status(500).json({
          message: 'Không thể lấy lịch sử hoạt động',
        });
      }
    };


    // Lấy lịch sử hoạt động tổng hợp
    const getAllTaskActivities = async (req, res) => {
      try {
        const userId = req.user.userId;

        const activities = await TaskActivity.find({
          userId,
        })
          .populate('userId', 'fullName email')
          .sort({ createdAt: -1 });

        return res.status(200).json({
          message: 'Lấy lịch sử hoạt động thành công',
          count: activities.length,
          activities,
        });
      } catch (error) {
        console.error('Get all task activities error:', error);

        return res.status(500).json({
          message: 'Không thể lấy lịch sử hoạt động',
        });
      }
    };


    module.exports = {
      getStatistics,
      getDeadlineTasks,
      getTaskActivities,
      getAllTaskActivities,
    };

