const bcrypt = require('bcryptjs');
const User = require('../models/User');

const createDefaultUser = async () => {
  const email = 'tumocare@gmail.com';
  const password = 'tumocare@123';

  const existing = await User.findOne({ email });
  if (!existing) {
    const hashedPassword = await bcrypt.hash(password, 10);
    await new User({ email, password: hashedPassword }).save();
    console.log('✅ Default user created');
  } else {
    console.log('ℹ️ Default user already exists');
  }
};

module.exports = createDefaultUser;
