 const Notification = require('../models/Notification');

 // Lấy danh sách thông báo của người dùng
 const getNotifications = async (req, res) => {
   try {
     const notifications = await Notification.find({
       userId: req.user.userId,
     })
       .populate('taskId', 'title status')
       .sort({ createdAt: -1 });

     return res.status(200).json({
       message: 'Lấy danh sách thông báo thành công',
       notifications,
     });
   } catch (error) {
     console.error('Get notifications error:', error.message);
     return res.status(500).json({
       message: 'Lỗi máy chủ khi lấy thông báo',
     });
   }
 };

 // Đánh dấu một thông báo đã đọc
 const markNotificationAsRead = async (req, res) => {
   try {
     const notification = await Notification.findOneAndUpdate(
       {
         _id: req.params.id,
         userId: req.user.userId,
       },
       {
         isRead: true,
       },
       { new: true }
     ).populate('taskId', 'title status');

     if (!notification) {
       return res.status(404).json({
         message: 'Không tìm thấy thông báo',
       });
     }

     return res.status(200).json({
       message: 'Đã đánh dấu thông báo là đã đọc',
       notification,
     });
   } catch (error) {
     console.error('Mark notification as read error:', error.message);
     return res.status(500).json({
       message: 'Lỗi máy chủ khi cập nhật thông báo',
     });
   }
 };

 // Đánh dấu tất cả thông báo đã đọc
 const markAllNotificationsAsRead = async (req, res) => {
   try {
     await Notification.updateMany(
       {
         userId: req.user.userId,
         isRead: false,
       },
       {
         isRead: true,
       }
     );

     return res.status(200).json({
       message: 'Đã đánh dấu tất cả thông báo là đã đọc',
     });
   } catch (error) {
     console.error('Mark all notifications as read error:', error.message);
     return res.status(500).json({
       message: 'Lỗi máy chủ khi cập nhật thông báo',
     });
   }
 };

 // Đếm số thông báo chưa đọc
 const getUnreadNotificationCount = async (req, res) => {
   try {
     const count = await Notification.countDocuments({
       userId: req.user.userId,
       isRead: false,
     });

     return res.status(200).json({
       unreadCount: count,
     });
   } catch (error) {
     console.error('Get unread notification count error:', error.message);
     return res.status(500).json({
       message: 'Lỗi máy chủ khi đếm thông báo chưa đọc',
     });
   }
 };

 module.exports = {
   getNotifications,
   markNotificationAsRead,
   markAllNotificationsAsRead,
   getUnreadNotificationCount,
 };