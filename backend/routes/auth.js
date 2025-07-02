const express = require('express');
const bcrypt = require('bcryptjs');
const jwt = require('jsonwebtoken');
const User = require('../models/User');
const sendEmail = require('../utils/sendEmail');
const router = express.Router();
require('dotenv').config(); // Ensure this is called in your main server file

// --- Create Default User ---
const createDefaultUser = async () => {
  const defaultEmail = 'tumocare@gmail.com';
  const defaultPassword = 'tumocare@123';

  try {
    const existing = await User.findOne({ email: defaultEmail });
    if (!existing) {
      const hashed = await bcrypt.hash(defaultPassword, 10);
      await User.create({ email: defaultEmail, password: hashed });
      console.log('✅ Default user created');
    } else {
      console.log('ℹ️ Default user already exists');
    }
  } catch (err) {
    console.error('❌ Error creating default user:', err.message);
  }
};
createDefaultUser();

// --- Login Route ---
router.post('/login', async (req, res) => {
  const { email, password } = req.body;

  try {
    const user = await User.findOne({ email });

    if (!user) {
      console.log('⚠️ Email not found:', email);
      return res.status(401).json({ error: 'Invalid credentials' });
    }

    const isMatch = await bcrypt.compare(password, user.password);
    if (!isMatch) {
      console.log('⚠️ Incorrect password for:', email);
      return res.status(401).json({ error: 'Invalid credentials' });
    }

    const token = jwt.sign(
      { userId: user._id },
      process.env.JWT_SECRET,
      { expiresIn: '1h' }
    );

    console.log(`✅ Login successful for: ${email}`);
    res.json({ token });
  } catch (err) {
    console.error('❌ Login error:', err.message);
    res.status(500).json({ error: 'Server error' });
  }
});

// --- Register Route ---
router.post('/register', async (req, res) => {
  const { email, password } = req.body;

  try {
    const existing = await User.findOne({ email });
    if (existing) return res.status(409).json({ error: 'User already exists' });

    const hashed = await bcrypt.hash(password, 10);
    await User.create({ email, password: hashed });

    console.log('✅ New user registered:', email);
    res.status(201).json({ message: 'User registered successfully' });
  } catch (err) {
    console.error('❌ Registration error:', err.message);
    res.status(500).json({ error: 'Server error' });
  }
});

// --- Forgot Password Route ---
router.post('/forgot-password', async (req, res) => {
  const { email } = req.body;

  try {
    const user = await User.findOne({ email });
    if (!user) return res.status(404).json({ error: 'User not found' });

    const token = jwt.sign(
      { userId: user._id },
      process.env.JWT_SECRET,
      { expiresIn: '15m' }
    );

    const resetLink = `http://localhost:3000/reset-password?token=${token}`;
    const html = `
      <p>Hello,</p>
      <p>Click the link below to reset your password:</p>
      <a href="${resetLink}">${resetLink}</a>
      <p>This link will expire in 15 minutes.</p>
    `;

    await sendEmail(user.email, 'Reset Your Password', html);
    console.log('✅ Reset email sent to:', email);
    res.json({ message: 'Reset link sent to email' });
  } catch (err) {
    console.error('❌ Forgot password error:', err.message);
    res.status(500).json({ error: 'Server error' });
  }
});

// --- Reset Password Route ---
router.post('/reset-password', async (req, res) => {
  const { token, newPassword } = req.body;

  try {
    const decoded = jwt.verify(token, process.env.JWT_SECRET);
    const user = await User.findById(decoded.userId);
    if (!user) return res.status(404).json({ error: 'User not found' });

    const hashed = await bcrypt.hash(newPassword, 10);
    user.password = hashed;
    await user.save();

    console.log('✅ Password reset successful for:', user.email);
    res.json({ message: 'Password reset successful' });
  } catch (err) {
    console.error('❌ Reset password error:', err.message);
    res.status(400).json({ error: 'Invalid or expired token' });
  }
});

module.exports = router;
