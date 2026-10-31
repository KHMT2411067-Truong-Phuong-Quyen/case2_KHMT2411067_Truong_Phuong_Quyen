const Task = require('../models/Task');

// Lấy danh sách công việc của người dùng đang đăng nhập
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

module.exports = { getTasks };