require('dotenv').config();
const express = require('express');
const mongoose = require('mongoose');
const cors = require('cors');
const helmet = require('helmet');
const rateLimit = require('express-rate-limit');

const authRoutes = require('./routes/auth');

const app = express();

// ======= MIDDLEWARE =======
app.use(express.json());
app.use(helmet());

// ✅ Development CORS setup – allow all origins (restrict in production)
app.use(cors({
  origin: '*',
  methods: ['GET', 'POST', 'PUT', 'DELETE', 'OPTIONS'],
  allowedHeaders: ['Content-Type', 'Authorization'],
}));

// ✅ Rate limiting to prevent abuse
const limiter = rateLimit({
  windowMs: 15 * 60 * 1000, // 15 minutes
  max: 100,
  standardHeaders: true,
  legacyHeaders: false,
});
app.use(limiter);

// ======= DATABASE CONNECTION =======
mongoose.connect(process.env.MONGO_URI, {
  useNewUrlParser: true,
  useUnifiedTopology: true,
})
.then(async () => {
  console.log('✅ MongoDB connected');

  // ✅ Create default user if not present
  const User = require('./models/User');
  const bcrypt = require('bcryptjs');
  const defaultEmail = 'tumocare@gmail.com';
  const defaultPassword = 'tumocare@123';

  const existingUser = await User.findOne({ email: defaultEmail });
  if (!existingUser) {
    const hashedPassword = await bcrypt.hash(defaultPassword, 10);
    await User.create({ email: defaultEmail, password: hashedPassword });
    console.log('✅ Default user created');
  }
})
.catch(err => {
  console.error('❌ MongoDB connection error:', err.message);
});

// ======= ROUTES =======
app.use('/api', authRoutes); // All auth routes under /api/login, /api/register, etc.

// ======= SERVER START =======
const PORT = process.env.PORT || 5000;
app.listen(PORT, () => {
  console.log(`🚀 Server running at http://localhost:${PORT}`);
});
