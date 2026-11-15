require('dotenv').config();

const { remindUpcomingTasks } = require('./services/taskService');

const app = require('./app');
const connectDB = require('./config/database');

const PORT = process.env.PORT || 3000;


const startServer = async () => {
  await connectDB();

  // Chạy kiểm tra nhắc hạn ngay khi server khởi động
  await remindUpcomingTasks();

  // Tự động kiểm tra mỗi giờ
  setInterval(async () => {
    await remindUpcomingTasks();
  }, 60 * 60 * 1000);

  app.listen(PORT, () => {
    console.log(`Server is running on port ${PORT}`);
  });
};

startServer();