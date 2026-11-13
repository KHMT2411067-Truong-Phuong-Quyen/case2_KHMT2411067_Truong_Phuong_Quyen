const express = require('express');
const router = express.Router();

const {
  getTasks,
  createTask,
  updateTask,
  deleteTask,
  updateSharePermission,
  revokeShareAccess,
} = require('../controllers/taskController');

const authMiddleware = require('../middleware/authMiddleware');

router.get('/', authMiddleware, getTasks);
router.post('/', authMiddleware, createTask);
router.put('/:id', authMiddleware, updateTask);
router.delete('/:id', authMiddleware, deleteTask);
router.put('/:id/share', authMiddleware, updateSharePermission);
router.delete('/:id/share', authMiddleware, revokeShareAccess);


module.exports = router;