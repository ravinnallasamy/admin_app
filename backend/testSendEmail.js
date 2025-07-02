const nodemailer = require('nodemailer');
require('dotenv').config();

async function testSendEmail() {
  try {
    const transporter = nodemailer.createTransport({
      service: 'gmail',
      auth: {
        user: process.env.EMAIL_USER,
        pass: process.env.EMAIL_PASS,
      },
    });

    const info = await transporter.sendMail({
      from: `"Tumocare Support" <${process.env.EMAIL_USER}>`,
      to: 'tumocare@gmail.com', // Replace with your test email
      subject: 'Test Email',
      text: 'This is a test email from Tumocare',
    });

    console.log('✅ Email sent:', info.response);
  } catch (err) {
    console.error('❌ Failed to send email:', err.message);
  }
}

testSendEmail();
