 const nodemailer = require('nodemailer');
 const EmailLog = require('../models/EmailLog');

 const transporter = nodemailer.createTransport({
   host: process.env.EMAIL_HOST,
   port: Number(process.env.EMAIL_PORT) || 587,
   secure: Number(process.env.EMAIL_PORT) === 465,
   auth: {
     user: process.env.EMAIL_USER,
     pass: process.env.EMAIL_PASS,
   },
 });

 const sendEmail = async ({
   taskId = null,
   recipientEmail,
   subject,
   text,
   html,
 }) => {
   const emailLog = await EmailLog.create({
     taskId,
     recipientEmail,
     subject,
     status: 'pending',
   });


   console.log('Đang gửi email đến:', recipientEmail);


   try {
     await transporter.sendMail({
       from: process.env.EMAIL_USER,
       to: recipientEmail,
       subject,
       text,
       html,
     });

     emailLog.status = 'sent';
     emailLog.sentAt = new Date();
     await emailLog.save();

     return { success: true, emailLog };
   } catch (error) {
     emailLog.status = 'failed';
     emailLog.errorMessage = error.message;
     await emailLog.save();

     console.error('Send email error:', error.message);

     return { success: false, emailLog };
   }
 };

 module.exports = { sendEmail };