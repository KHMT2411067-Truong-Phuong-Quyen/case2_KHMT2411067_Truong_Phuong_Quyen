const bcrypt = require('bcryptjs');
const jwt = require('jsonwebtoken');
const User = require('../models/User');

// Đăng ký tài khoản
const register = async (req, res) => {
try {
const { fullName, email, password } = req.body;

if (!fullName || !email || !password) {
  return res.status(400).json({
    message: 'Vui lòng nhập đầy đủ họ tên, email và mật khẩu',
  });
}

if (password.length < 6) {
  return res.status(400).json({
    message: 'Mật khẩu phải có ít nhất 6 ký tự',
  });
}

const normalizedEmail = email.trim().toLowerCase();

const existingUser = await User.findOne({
  email: normalizedEmail,
});

if (existingUser) {
  return res.status(409).json({
    message: 'Email đã được đăng ký',
  });
}

const passwordHash = await bcrypt.hash(password, 10);

const user = await User.create({
  fullName: fullName.trim(),
  email: normalizedEmail,
  passwordHash,
});

return res.status(201).json({
  message: 'Đăng ký thành công',
  user: {
    id: user._id,
    fullName: user.fullName,
    email: user.email,
  },
});

} catch (error) {
console.error('Register error:', error.message);

return res.status(500).json({
  message: 'Lỗi máy chủ khi đăng ký',
});

}
};

// Đăng nhập
const login = async (req, res) => {
try {
const { email, password } = req.body;

if (!email || !password) {
  return res.status(400).json({
    message: 'Vui lòng nhập email và mật khẩu',
  });
}

const normalizedEmail = email.trim().toLowerCase();

const user = await User.findOne({
  email: normalizedEmail,
});

if (!user) {
  return res.status(401).json({
    message: 'Email hoặc mật khẩu không chính xác',
  });
}

const isPasswordValid = await bcrypt.compare(
  password,
  user.passwordHash
);

if (!isPasswordValid) {
  return res.status(401).json({
    message: 'Email hoặc mật khẩu không chính xác',
  });
}

const token = jwt.sign(
  { userId: user._id.toString() },
  process.env.JWT_SECRET,
  { expiresIn: '1d' }
);

return res.status(200).json({
  message: 'Đăng nhập thành công',
  token,
  user: {
    id: user._id,
    fullName: user.fullName,
    email: user.email,
  },
});

} catch (error) {
console.error('Login error:', error.message);

return res.status(500).json({
  message: 'Lỗi máy chủ khi đăng nhập',
});

}
};

module.exports = { register, login };