const mongoose = require('mongoose');

const emailLogSchema = new mongoose.Schema(
{
taskId: {
type: mongoose.Schema.Types.ObjectId,
ref: 'Task',
default: null,
},

recipientEmail: {
  type: String,
  required: true,
  trim: true,
  lowercase: true,
},

subject: {
  type: String,
  required: true,
  trim: true,
},

status: {
  type: String,
  enum: ['pending', 'sent', 'failed'],
  default: 'pending',
},

errorMessage: {
  type: String,
  default: '',
},

sentAt: {
  type: Date,
  default: null,
},

},
{
timestamps: true,
collection: 'email_logs',
}
);

module.exports = mongoose.model('EmailLog', emailLogSchema);