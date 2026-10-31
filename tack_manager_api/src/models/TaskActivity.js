const mongoose = require('mongoose');

const taskActivitySchema = new mongoose.Schema(
{
taskId: {
type: mongoose.Schema.Types.ObjectId,
ref: 'Task',
required: true,
},

userId: {
  type: mongoose.Schema.Types.ObjectId,
  ref: 'User',
  required: true,
},

action: {
  type: String,
  required: true,
  trim: true,
},

description: {
  type: String,
  default: '',
},

metadata: {
  type: mongoose.Schema.Types.Mixed,
  default: {},
},

},
{
timestamps: true,
collection: 'task_activities',
}
);

module.exports = mongoose.model('TaskActivity', taskActivitySchema);