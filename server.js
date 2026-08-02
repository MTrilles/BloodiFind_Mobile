const express = require('express');
const mysql = require('mysql2/promise');
const crypto = require('crypto');
const jwt = require('jsonwebtoken');
const cors = require('cors');
const nodemailer = require('nodemailer');
require('dotenv').config();
const os = require('os'); // Added for IP detection in restore link

const app = express();
const PORT = process.env.PORT || 36512;

// ========== MIDDLEWARE ==========
app.use(cors());
app.use(express.json());

app.use((req, res, next) => {
  if (!req.path.startsWith('/api/verify-email')) {
    res.setHeader('Content-Type', 'application/json');
  }
  next();
});

const pool = mysql.createPool({
  host: process.env.DB_HOST || 'localhost',
  user: process.env.DB_USER || 'root',
  password: process.env.DB_PASSWORD || 'kramallijem6',
  database: process.env.DB_NAME || 'bloodifind',
  waitForConnections: true,
  connectionLimit: 10,
  queueLimit: 0
});

const JWT_SECRET = process.env.JWT_SECRET || 'your-secret-key';

function generateSalt(length = 16) {
  const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789';
  let result = '';
  const randomBytes = crypto.randomBytes(length);
  for (let i = 0; i < length; i++) {
    result += chars[randomBytes[i] % chars.length];
  }
  return result;
}

/**
 * Hashes password into format: scrypt:32768:8:1$salt$hash
 */
const hashPasswordScrypt = (password) => {
  return new Promise((resolve, reject) => {
    const salt = generateSalt(16);
    const N = 32768; // CPU/memory cost
    const r = 8;     // Block size
    const p = 1;     // Parallelization
    const keyLen = 64; // Output length
    const maxmem = 64 * 1024 * 1024;

    crypto.scrypt(password, salt, keyLen, { N, r, p, maxmem }, (err, derivedKey) => {
      if (err) return reject(err);
      const hash = derivedKey.toString('hex');
      const result = `scrypt:${N}:${r}:${p}$${salt}$${hash}`;
      resolve(result);
    });
  });
};

/**
 * Verifies a password against the stored scrypt string
 */
const verifyPasswordScrypt = (password, storedHashString) => {
  return new Promise((resolve, reject) => {
    try {
      if (!storedHashString) return resolve(false);

      const parts = storedHashString.split('$');
      if (parts.length !== 3) return resolve(false);

      const params = parts[0].split(':');
      if (params[0] !== 'scrypt') return resolve(false);

      const N = parseInt(params[1], 10);
      const r = parseInt(params[2], 10);
      const p = parseInt(params[3], 10);
      const salt = parts[1];
      const originalHash = parts[2];
      const originalHashBuffer = Buffer.from(originalHash, 'hex');
      const keyLen = originalHashBuffer.length;

      const maxmem = 128 * N * r * 2;

      crypto.scrypt(password, salt, keyLen, { N, r, p, maxmem }, (err, derivedKey) => {
        if (err) {
            console.error("Scrypt Verify Error:", err);
            return resolve(false);
        }
        const match = crypto.timingSafeEqual(originalHashBuffer, derivedKey);
        resolve(match);
      });
    } catch (e) {
      console.error("Password verify error", e);
      resolve(false);
    }
  });
};

const logActivity = async (userId, action, details = null, req = null) => {
  try {
    const connection = await pool.getConnection();
    const ipAddress = req ? (req.headers['x-forwarded-for'] || req.ip) : null;
    const cleanIp = ipAddress && ipAddress.includes('::ffff:') ? ipAddress.replace('::ffff:', '') : ipAddress;

    await connection.execute(
      `INSERT INTO activity_logs (user_id, action, details, ip_address)
       VALUES (?, ?, ?, ?)`,
      [userId, action, details, cleanIp]
    );

    connection.release();
    console.log(`📝 Logged Action: [${action}] User ID: ${userId}`);
  } catch (error) {
    console.error('❌ Error logging activity:', error.message);
  }
};

// ========== EMAIL CONFIGURATION ==========
const transporter = nodemailer.createTransport({
  service: 'gmail',
  auth: {
    user: 'bloodifind.app@gmail.com',
    pass: 'gvvh euyc gppp irii'
  }
});

const checkHealthRestriction = async (userId) => {
  try {
    const [restrictions] = await pool.execute(
      `SELECT reason FROM user_health_restriction WHERE user_id = ? AND is_active = 1 LIMIT 1`,
      [userId]
    );
    if (restrictions.length > 0) {
      return restrictions[0]; // Returns { reason: '...' } - Active restriction found
    }
    return null; // NO active restriction found (Correct behavior for unrestricted)
  } catch (error) {
    console.error('Error checking health restriction:', error);
    // ⚠️ CRITICAL FIX: Throw the error to let the caller handle it as a 500 server error,
    // instead of returning an object that triggers the 403 restriction logic.
    throw new Error('Database query failed during restriction check.');
  }
};

const checkActiveRequests = async (userId) => {
  try {
    const [requests] = await pool.execute(
      // The user might be the requester OR the donor in an active status
      `SELECT id, status
       FROM chat_requests
       WHERE (requester_id = ? OR donor_id = ?)
       AND status IN ('Pending', 'Ongoing')
       LIMIT 1`,
      [userId, userId]
    );

    if (requests.length > 0) {
      return requests[0]; // Returns active request details
    }
    return null;
  } catch (error) {
    console.error('Error checking active requests:', error);
    throw new Error('Database query failed during active request check.');
  }
};

async function testConnection() {
  try {
    const connection = await pool.getConnection();
    console.log('✅ Connected to MySQL database');
    connection.release();
    return true;
  } catch (err) {
    console.error('❌ Database connection failed:', err.message);
    return false;
  }
}

// Initialize Database Tables
async function initializeDatabase() {
  try {
    const connection = await pool.getConnection();

    // Users table
    await connection.execute(`
          CREATE TABLE IF NOT EXISTS users (
            id INT AUTO_INCREMENT PRIMARY KEY,
            first_name VARCHAR(100) NOT NULL,
            last_name VARCHAR(100) NOT NULL,
            email VARCHAR(255) UNIQUE NOT NULL,
            password VARCHAR(255) NOT NULL,
            phone VARCHAR(11),
            blood_type ENUM('A+', 'A-', 'B+', 'B-', 'AB+', 'AB-', 'O+', 'O-'),
            barangay VARCHAR(100),
            city VARCHAR(100) DEFAULT 'Santa Cruz',
            is_donor BOOLEAN DEFAULT FALSE,
            is_available BOOLEAN DEFAULT FALSE,
            is_verified BOOLEAN DEFAULT FALSE,
            created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
            updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
          )
        `);

    // Add is_verified column if it doesn't exist (Backward compatibility)
    try {
      await connection.execute(`
        ALTER TABLE users ADD COLUMN is_verified BOOLEAN DEFAULT FALSE
      `);
      console.log('ℹ️ Added is_verified column to users table');
    } catch (err) {
      if (err.code !== 'ER_DUP_FIELDNAME') {
        console.log('ℹ️ Column check: ', err.message);
      }
    }

    // Blood requests table (Existing, general requests)
    await connection.execute(`
      CREATE TABLE IF NOT EXISTS blood_requests (
        id INT AUTO_INCREMENT PRIMARY KEY,
        patient_id INT,
        blood_type ENUM('A+', 'A-', 'B+', 'B-', 'AB+', 'AB-', 'O+', 'O-') NOT NULL,
        units INT NOT NULL,
        hospital VARCHAR(255) NOT NULL,
        urgency ENUM('low', 'medium', 'high', 'critical') DEFAULT 'medium',
        status ENUM('pending', 'approved', 'fulfilled', 'cancelled') DEFAULT 'pending',
        notes TEXT,
        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
        fulfilled_at TIMESTAMP NULL,
        FOREIGN KEY (patient_id) REFERENCES users(id)
      )
    `);

    await connection.execute(`
          CREATE TABLE IF NOT EXISTS password_resets (
            id INT AUTO_INCREMENT PRIMARY KEY,
            email VARCHAR(255) NOT NULL,
            otp VARCHAR(6) NOT NULL,
            expires_at TIMESTAMP NOT NULL,
            created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
          )
        `);

    // Notifications table
    await connection.execute(`
      CREATE TABLE IF NOT EXISTS notifications (
        id INT AUTO_INCREMENT PRIMARY KEY,
        user_id INT,
        title VARCHAR(255) NOT NULL,
        message TEXT NOT NULL,
        type ENUM('info', 'warning', 'success', 'error') DEFAULT 'info',
        is_read BOOLEAN DEFAULT FALSE,
        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
        FOREIGN KEY (user_id) REFERENCES users(id)
      )
    `);

    // Messages table
    await connection.execute(`
          CREATE TABLE IF NOT EXISTS messages (
            id INT AUTO_INCREMENT PRIMARY KEY,
            sender_id INT NOT NULL,
            receiver_id INT NOT NULL,
            message TEXT NOT NULL,
            is_read BOOLEAN DEFAULT FALSE,
            created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
            FOREIGN KEY (sender_id) REFERENCES users(id),
            FOREIGN KEY (receiver_id) REFERENCES users(id)
          )
        `);

    // NEW: Chat Request table for Recipient/Donor specific requests
    await connection.execute(`
        CREATE TABLE IF NOT EXISTS chat_requests (
            id INT AUTO_INCREMENT PRIMARY KEY,
            requester_id INT NOT NULL,
            donor_id INT NOT NULL,
            blood_type ENUM('A+', 'A-', 'B+', 'B-', 'AB+', 'AB-', 'O+', 'O-') NOT NULL,
            status ENUM('Pending', 'Declined', 'Ongoing', 'Cancelled', 'Completed') DEFAULT 'Pending',
            notes TEXT,
            requester_completed BOOLEAN DEFAULT FALSE,
            donor_completed BOOLEAN DEFAULT FALSE,
            created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
            updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
            FOREIGN KEY (requester_id) REFERENCES users(id),
            FOREIGN KEY (donor_id) REFERENCES users(id),
            -- Ensures a specific chat pair can only have one active request
            UNIQUE KEY uk_chat_request (requester_id, donor_id, status)
        )
    `);


    connection.release();
    console.log('✅ Database tables initialized successfully');
  } catch (error) {
    console.error('❌ Database initialization error:', error);
  }
}

// Auth Middleware
const authenticateToken = async (req, res, next) => {
  const authHeader = req.headers['authorization'];
  const token = authHeader && authHeader.split(' ')[1];

  if (!token) return res.status(401).json({ success: false, error: 'Access token required' });

  try {
    const decoded = jwt.verify(token, JWT_SECRET);
    const [users] = await pool.execute('SELECT * FROM users WHERE id = ?', [decoded.userId]);

    if (users.length === 0) return res.status(401).json({ success: false, error: 'User not found' });

    req.user = users[0];
    next();
  } catch (error) {
    return res.status(403).json({ success: false, error: 'Invalid token' });
  }
};

const emailAdminArchivedTemplate = (firstName) => `
<!DOCTYPE html><html><head>
    <style>
        body { font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif; background-color: #F9FAFB; margin: 0; padding: 0; }
        .email-container { max-width: 600px; margin: 40px auto; background: #ffffff; border-radius: 12px; overflow: hidden; box-shadow: 0 4px 10px rgba(0,0,0,0.05); border: 1px solid #e5e7eb; }
        .header { background-color: #ffffff; padding: 30px; text-align: center; border-bottom: 4px solid #8B0000; }
        .brand-name { color: #8B0000; font-size: 24px; font-weight: 600; margin: 0; }
        .content { padding: 40px 30px; text-align: center; color: #333333; }
        .h1 { font-size: 22px; font-weight: 600; margin-bottom: 20px; color: #111; }
        .text { font-size: 16px; line-height: 1.6; color: #6B7280; margin-bottom: 30px; }
        .footer { background-color: #F9FAFB; padding: 20px; text-align: center; font-size: 12px; color: #9CA3AF; border-top: 1px solid #e5e7eb; }
    </style></head><body>
    <div class="email-container">
        <div class="header">
            <div class="brand-name">Bloodifind</div>
        </div>
        <div class="content">
            <div class="h1">Account Archived</div>
            <p class="text">
                Hi ${firstName},<br><br>
                Your Bloodifind account has been archived by the administrator due to policy violations or inactivity.
            </p>
            <p class="text">
                If you believe this is a mistake or wish to recover your account, please contact our support team immediately.
            </p>
        </div>
        <div class="footer">
            &copy; 2025 Bloodifind. All rights reserved.
        </div>
    </div></body></html>
`;

// HTML Template for User Self-Archive (With Restore Link)
const emailUserRestorationTemplate = (firstName, restoreUrl) => `
<!DOCTYPE html><html><head>
    <style>
        body { font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif; background-color: #F9FAFB; margin: 0; padding: 0; }
        .email-container { max-width: 600px; margin: 40px auto; background: #ffffff; border-radius: 12px; overflow: hidden; box-shadow: 0 4px 10px rgba(0,0,0,0.05); border: 1px solid #e5e7eb; }
        .header { background-color: #ffffff; padding: 30px; text-align: center; border-bottom: 4px solid #8B0000; }
        .brand-name { color: #8B0000; font-size: 24px; font-weight: 600; margin: 0; }
        .content { padding: 40px 30px; text-align: center; color: #333333; }
        .h1 { font-size: 22px; font-weight: 600; margin-bottom: 20px; color: #111; }
        .text { font-size: 16px; line-height: 1.6; color: #6B7280; margin-bottom: 30px; }
        .btn-restore { display: inline-block; background-color: #8B0000; color: #ffffff !important; text-decoration: none; padding: 14px 32px; border-radius: 8px; font-weight: 600; font-size: 16px; transition: background 0.3s; }
        .btn-restore:hover { background-color: #a60000; }
        .footer { background-color: #F9FAFB; padding: 20px; text-align: center; font-size: 12px; color: #9CA3AF; border-top: 1px solid #e5e7eb; }
    </style></head><body>
    <div class="email-container">
        <div class="header">
            <div class="brand-name">Bloodifind</div>
        </div>
        <div class="content">
            <div class="h1">Account Deactivated</div>
            <p class="text">
                Hi ${firstName},<br><br>
                You have successfully deactivated your account. Your profile is now hidden from the platform.
            </p>
            <p class="text">
                If you change your mind, you can restore your account within the next <strong>30 days</strong> by clicking the button below.
            </p>

            <a href="${restoreUrl}" class="btn-restore">Restore My Account</a>

            <p class="text" style="margin-top: 20px; font-size: 14px;">
                After 30 days, this link will expire.
            </p>
        </div>
        <div class="footer">
            &copy; 2025 Bloodifind. All rights reserved.
        </div>
    </div></body></html>
`;

// ========== ROUTES ==========

// Test endpoint
app.get('/api/test', async (req, res) => {
  try {
    const isConnected = await testConnection();
    if (isConnected) {
      res.json({
        success: true,
        message: 'API is working!',
        database: 'Connected',
        timestamp: new Date().toISOString()
      });
    } else {
      res.status(500).json({
        success: false,
        message: 'API is working but database is disconnected'
      });
    }
  } catch (error) {
    res.status(500).json({
      success: false,
      error: 'Server error: ' + error.message
    });
  }
});

// User Registration
app.post('/api/register', async (req, res) => {
  try {
    const { firstName, lastName, email, password, phone, bloodType, barangay, isDonor, isAvailable } = req.body;

    if (!firstName || !lastName || !email || !password) {
      return res.status(400).json({ success: false, error: 'Missing required fields' });
    }

    const [existingUsers] = await pool.execute('SELECT id FROM users WHERE email = ?', [email]);
    if (existingUsers.length > 0) {
      return res.status(400).json({ success: false, error: 'User already exists with this email' });
    }

    const hashedPassword = await hashPasswordScrypt(password);

    const isDonorBool = isDonor === 'Donor' || isDonor === true || isDonor === 'true' || isDonor === 1;
    const isAvailableBool = isAvailable === 'Available' || isAvailable === true || isAvailable === 'true' || isAvailable === 1;

    const [result] = await pool.execute(
      `INSERT INTO users (first_name, last_name, email, password, phone, blood_type, barangay, is_donor, is_available, is_verified)
       VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, FALSE)`,
      [firstName, lastName, email, hashedPassword, phone, bloodType, barangay, isDonorBool, isAvailableBool]
    );

    await logActivity(result.insertId, 'REGISTER', 'User created an account', req);

    // Generate Verification Token (expires in 1 day)
    const verificationToken = jwt.sign({ email: email }, JWT_SECRET, { expiresIn: '1d' });

    // -------------------------------------------------------------------------
    // ⚠️ IMPORTANT: REPLACE THIS WITH YOUR COMPUTER'S IPv4 ADDRESS
    const MY_IPV4_ADDRESS = '192.168.68.108';
    // -------------------------------------------------------------------------

    const verificationLink = `http://${MY_IPV4_ADDRESS}:${PORT}/api/verify-email?token=${verificationToken}`;

    // HELPER: Capitalize First Name
    const formattedFirstName = firstName
      .toLowerCase()
      .split(' ')
      .map(word => word.charAt(0).toUpperCase() + word.slice(1))
      .join(' ');

    // ========== EMAIL CONFIGURATION START ==========
    const mailOptions = {
      from: 'bloodifind.app@gmail.com',
      to: email,
      subject: 'Verify Your BloodiFind Account',
      html: `
        <html>
          <head>
            <style>
              body { font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif; background-color: #F9FAFB; margin: 0; padding: 0; }
              .email-container { max-width: 600px; margin: 40px auto; background: #ffffff; border-radius: 12px; overflow: hidden; box-shadow: 0 4px 10px rgba(0,0,0,0.05); border: 1px solid #e5e7eb; }
              .header { background-color: #ffffff; padding: 30px; text-align: center; border-bottom: 4px solid #8B0000; }
              .brand-name { color: #8B0000; font-size: 24px; font-weight: 600; margin: 0; }
              .content { padding: 40px 30px; text-align: center; color: #333333; }
              .h1 { font-size: 22px; font-weight: 600; margin-bottom: 20px; color: #111; }
              .text { font-size: 16px; line-height: 1.6; color: #6B7280; margin-bottom: 30px; }
              .btn-verify { display: inline-block; background-color: #8B0000; color: #ffffff !important; text-decoration: none; padding: 14px 32px; border-radius: 8px; font-weight: 600; font-size: 16px; transition: background 0.3s; }
              .btn-verify:hover { background-color: #a60000; }
              .footer { background-color: #F9FAFB; padding: 20px; text-align: center; font-size: 12px; color: #9CA3AF; border-top: 1px solid #e5e7eb; }
            </style>
          </head>
          <body>
            <div class="email-container">
              <div class="header">
                <div class="brand-name">Bloodifind</div>
              </div>

              <div class="content">
                <div class="h1">Verify your email address</div>
                <p class="text">
                  Hi ${formattedFirstName},<br><br>
                  Thank you for joining Bloodifind. To start connecting with donors and helping save lives, please verify your email address by clicking the button below.
                </p>

                <a href="${verificationLink}" class="btn-verify">Verify Email & Login</a>

                <p class="text" style="margin-top: 30px; font-size: 14px;">
                  If you didn't create an account, you can safely ignore this email.
                </p>
              </div>

              <div class="footer">
                &copy; 2025 Bloodifind. All rights reserved.<br>
                Sitio Mapagmahal, Brgy. Pagsawitan, Sta. Cruz, Laguna
              </div>
            </div>
          </body>
        </html>
      `
    };
    // ========== EMAIL CONFIGURATION END ==========

    await transporter.sendMail(mailOptions);

    res.status(201).json({
          success: true,
          message: 'Registration successful. Verification email sent.',
          user: { id: result.insertId, firstName, lastName, email }
        });

      } catch (error) {
        console.error('Registration error:', error);
        res.status(500).json({ success: false, error: 'Internal server error: ' + error.message });
      }
    });

// Verify Email Endpoint
app.get('/api/verify-email', async (req, res) => {
  const { token } = req.query;

  // Custom Error Page Design
  const errorHtml = (message) => `
    <html>
      <head>
        <title>Verification Failed</title>
        <meta name="viewport" content="width=device-width, initial-scale=1">
        <style>
          body { font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif; background-color: #F9FAFB; margin: 0; display: flex; align-items: center; justify-content: center; height: 100vh; }
          .container { background: white; padding: 40px; border-radius: 16px; box-shadow: 0 4px 20px rgba(0,0,0,0.05); text-align: center; max-width: 400px; width: 90%; }
          .icon { font-size: 64px; color: #EF4444; margin-bottom: 20px; }
          h1 { color: #111; font-size: 24px; margin: 0 0 10px; }
          p { color: #6B7280; font-size: 16px; line-height: 1.5; }
        </style>
      </head>
      <body>
        <div class="container">
          <div class="icon">&#9888;</div> <h1>Verification Failed</h1>
          <p>${message}</p>
        </div>
      </body>
    </html>
  `;

  if (!token) return res.status(400).send(errorHtml("Invalid verification link."));

  try {
    const decoded = jwt.verify(token, JWT_SECRET);
    const email = decoded.email;

    // 1. Get User ID for logging
    const [users] = await pool.execute('SELECT id, first_name FROM users WHERE email = ?', [email]);

    // 2. Update User
    await pool.execute('UPDATE users SET is_verified = TRUE WHERE email = ?', [email]);

    // 3. LOGGING
    if (users.length > 0) {
        await logActivity(users[0].id, 'VERIFY_ACCOUNT', 'User verified email address', req);
    }

    res.setHeader('Content-Type', 'text/html');
    res.send(`
      <!DOCTYPE html>
      <html>
        <head>
          <title>Email Verified</title>
          <meta name="viewport" content="width=device-width, initial-scale=1">
          <style>
            body { font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif; background-color: #F9FAFB; margin: 0; display: flex; align-items: center; justify-content: center; height: 100vh; }
            .container { background: white; padding: 50px 40px; border-radius: 16px; box-shadow: 0 10px 25px rgba(0,0,0,0.05); text-align: center; max-width: 400px; width: 90%; border-top: 5px solid #8B0000; }
            .icon-circle { width: 80px; height: 80px; background-color: #DEF7EC; border-radius: 50%; display: flex; align-items: center; justify-content: center; margin: 0 auto 24px; }
            .checkmark { font-size: 40px; color: #046C4E; }
            h1 { color: #1F2937; font-size: 26px; font-weight: 700; margin: 0 0 12px; }
            p { color: #6B7280; font-size: 16px; line-height: 1.6; margin-bottom: 30px; }
            .btn { display: inline-block; background-color: #8B0000; color: white; text-decoration: none; padding: 12px 32px; border-radius: 8px; font-weight: 600; font-size: 16px; transition: background 0.3s; }
            .btn:hover { background-color: #a60000; }
            .footer { margin-top: 30px; font-size: 12px; color: #9CA3AF; }
          </style>
        </head>
        <body>
          <div class="container">
            <div class="icon-circle">
              <span class="checkmark">&#10003;</span>
            </div>
            <h1>Email Verified!</h1>
            <p>Your account has been successfully activated. You can now return to the app and log in.</p>

            <div class="footer">
              &copy; 2025 Bloodifind
            </div>
          </div>
        </body>
      </html>
    `);

  } catch (error) {
    console.error('Verification error:', error);
    res.setHeader('Content-Type', 'text/html');
    res.status(400).send(errorHtml("The verification link is invalid or has expired."));
  }
});

// User Login
app.post('/api/login', async (req, res) => {
  try {
    const { email, password } = req.body;

    // 1. Fetch user including archived fields
    const [users] = await pool.execute(
      'SELECT * FROM users WHERE email = ?',
      [email]
    );

    if (users.length === 0) {
      return res.status(400).json({ success: false, error: 'Invalid email or password' });
    }

    const user = users[0];

    // 2. Verify Password
    const isPasswordValid = await verifyPasswordScrypt(password, user.password);

    if (!isPasswordValid) {
      return res.status(400).json({ success: false, error: 'Invalid email or password' });
    }

    // NEW: ARCHIVED ACCOUNT CHECK
    if (user.is_archived) {
          console.log(`🔒 Login attempt for archived user: ${user.id}`);

          let errorMessage = "This account has been archived.";

          // Query activity logs
          const [logs] = await pool.execute(
            `SELECT action, user_id, created_at FROM activity_logs
             WHERE user_id = ? AND action IN ('ADMIN_ARCHIVE', 'USER_ARCHIVE')
             ORDER BY created_at DESC LIMIT 1`,
            [user.id]
          );

          if (logs.length > 0) {
            const logEntry = logs[0];

            if (logEntry.action === 'ADMIN_ARCHIVE') {
              errorMessage = "Account deactivated by admin. Check email or contact support.";
            }
        else if (logEntry.action === 'USER_ARCHIVE') {
          // Check if 30-day restoration period has expired
          if (user.archived_at) {
                      const archivedAt = new Date(user.archived_at);
                      const now = new Date();
                      const diffTime = Math.abs(now - archivedAt);
                      const diffDays = Math.ceil(diffTime / (1000 * 60 * 60 * 24));

                      if (diffDays >= 30) {
                        errorMessage = "Your restoration link has expired. Please contact support.";
                      } else {
                        errorMessage = "Your account is deactivated. Please check your email for more information.";
                      }
                    } else {
                      errorMessage = "Your account is deactivated. Please check your email for more information";
                    }
                  }
                } else {
                  errorMessage = "Your account is deactivated. Please check your email for more information.";
                }

                return res.status(403).json({ success: false, error: errorMessage });
              }
    // ---------------------------------------------------------

    if (!user.is_verified) {
      return res.status(403).json({ success: false, error: 'Please verify your email before logging in.' });
    }

    await logActivity(user.id, 'LOGIN', 'User logged in via mobile app', req);

    const isDonorString = user.is_donor ? 'Donor' : 'Recipient';
    const isAvailableString = user.is_available ? 'Available' : 'Unavailable';
    const token = jwt.sign({ userId: user.id }, JWT_SECRET, { expiresIn: '24h' });

    res.json({
      success: true,
      message: 'Login successful',
      token: token,
      user: {
        id: user.id,
        firstName: user.first_name,
        lastName: user.last_name,
        email: user.email,
        bloodType: user.blood_type,
        barangay: user.barangay,
        city: user.city,
        isDonor: isDonorString,
        isAvailable: isAvailableString
      }
    });
  } catch (error) {
    console.error('Login error:', error);
    res.status(500).json({ success: false, error: 'Internal server error' });
  }
});

app.get('/api/donors', authenticateToken, async (req, res) => {
  try {
    const { blood_type, barangay, search } = req.query;
    const currentUserId = req.user.id;

    let query = `
          SELECT
            id,
            first_name as firstName,
            last_name as lastName,
            CONCAT(first_name, ' ', last_name) as name,
            blood_type as bloodType,
            email,
            phone,
            city,
            barangay,
            is_available as isAvailable,
            is_donor as isDonor,
            is_archived,
            created_at as createdAt
          FROM users
          WHERE id != ?
          AND (is_admin = 0 OR is_admin IS NULL)
        `;

    const params = [currentUserId];

    // Filters
    if (blood_type && blood_type !== 'All') {
      query += ' AND blood_type = ?';
      params.push(blood_type);
    }

    if (barangay && barangay !== 'All') {
      query += ' AND barangay = ?';
      params.push(barangay);
    }

    if (search) {
      query += ' AND (CONCAT(first_name, " ", last_name) LIKE ? OR blood_type LIKE ? OR barangay LIKE ?)';
      const searchParam = `%${search}%`;
      params.push(searchParam, searchParam, searchParam);
    }

    query += ' ORDER BY first_name, last_name';

    const [donors] = await pool.execute(query, params);

    // Convert boolean values to string for frontend
    const donorsWithStringValues = donors.map(donor => ({
      ...donor,
      isAvailable: donor.isAvailable ? 'Available' : 'Unavailable',
      isDonor: donor.isDonor ? 'Donor' : 'Recipient'
    }));

    res.json({
      success: true,
      data: donorsWithStringValues,
      count: donors.length
    });
  } catch (error) {
    console.error('Get donors error:', error);
    res.status(500).json({
      success: false,
      error: 'Internal server error: ' + error.message
    });
  }
});

app.get('/api/profile', authenticateToken, async (req, res) => {
  try {
    const [users] = await pool.execute(
      `SELECT
        id,
        first_name,
        last_name,
        email,
        phone,
        blood_type,
        barangay,
        city,
        is_donor,
        is_available,
        created_at
       FROM users WHERE id = ?`,
      [req.user.id]
    );

    if (users.length === 0) {
      return res.status(404).json({
        success: false,
        error: 'User not found'
      });
    }

    const user = users[0];

    // Convert boolean to string for frontend
    const isDonorString = user.is_donor ? 'Donor' : 'Recipient';
    const isAvailableString = user.is_available ? 'Available' : 'Unavailable';

    // Return data with exact database field names
    const userData = {
      id: user.id,
      first_name: user.first_name || '',
      last_name: user.last_name || '',
      email: user.email || '',
      phone: user.phone || '',
      blood_type: user.blood_type || 'Not specified',
      barangay: user.barangay || '',
      city: user.city || 'Santa Cruz',
      is_donor: isDonorString, // Return as string
      is_available: isAvailableString, // Return as string
      created_at: user.created_at
    };

    res.json({
      success: true,
      data: userData
    });
  } catch (error) {
    console.error('❌ Get profile error:', error);
    res.status(500).json({
      success: false,
      error: 'Internal server error: ' + error.message
    });
  }
});

// Update User Profile
app.put('/api/profile', authenticateToken, async (req, res) => {
  try {
    const userId = req.user.id;

    // 1. Fetch current user data
    const [currentUsers] = await pool.execute('SELECT * FROM users WHERE id = ?', [userId]);
    if (currentUsers.length === 0) return res.status(404).json({ success: false, error: 'User not found' });
    const currentUser = currentUsers[0];

    // 2. Destructure body and normalize booleans
    const { firstName, lastName, phone, bloodType, barangay, isAvailable, isDonor } = req.body;

    const newFirstName = firstName !== undefined ? firstName : currentUser.first_name;
    const newLastName = lastName !== undefined ? lastName : currentUser.last_name;
    const newPhone = phone !== undefined ? phone : currentUser.phone;
    const newBloodType = bloodType !== undefined ? bloodType : currentUser.blood_type;
    const newBarangay = barangay !== undefined ? barangay : currentUser.barangay;

    let newIsAvailable = currentUser.is_available;
    if (isAvailable !== undefined) {
         newIsAvailable = isAvailable === 'Available' || isAvailable === true || isAvailable === 'true' || isAvailable === 1;
    }

    let newIsDonor = currentUser.is_donor;
    if (isDonor !== undefined) {
        newIsDonor = isDonor === 'Donor' || isDonor === true || isDonor === 'true' || isDonor === 1;
    }

    // =======================================================
    // ⚠️ CHECK 1: ACTIVE REQUEST CHECK (Blocks ANY role change)
    // =======================================================
    if (newIsDonor !== currentUser.is_donor) { // Only check if the role is actually changing
        const activeRequest = await checkActiveRequests(userId);
        if (activeRequest) {
            const reason = `Active Donation Status (${activeRequest.status})`;
            return res.status(403).json({
                success: false,
                error: `Role switch denied. You have an active request status (${activeRequest.status}). Please complete or cancel it first.`,
                reason: reason
            });
        }
    }
    // =======================================================


    // =======================================================
    // ⚠️ CHECK 2: HEALTH RESTRICTION CHECK (Blocks switch TO Donor)
    // =======================================================
    if (newIsDonor === true) {
      const restriction = await checkHealthRestriction(userId);
      if (restriction) {
        return res.status(403).json({
            success: false,
            error: `Role switch denied. You are restricted from being a Donor due to: ${restriction.reason}`,
            reason: restriction.reason
        });
      }
    }
    // =======================================================

    // 4. Update Database
    await pool.execute(
      `UPDATE users SET first_name=?, last_name=?, phone=?, blood_type=?, barangay=?, is_available=?, is_donor=? WHERE id=?`,
      [newFirstName, newLastName, newPhone, newBloodType, newBarangay, newIsAvailable, newIsDonor, userId]
    );

    // 5. --- LOGGING LOGIC ---
    if (isDonor !== undefined && newIsDonor !== currentUser.is_donor) {
       const roleLabel = newIsDonor ? 'Donor' : 'Recipient';
       await logActivity(userId, 'ROLE_SWITCH', `User switched role to ${roleLabel}`, req);
    }

    if (isAvailable !== undefined && newIsAvailable !== currentUser.is_available) {
       const availLabel = newIsAvailable ? 'Available' : 'Unavailable';
       await logActivity(userId, 'AVAILABILITY_SWITCH', `User is now ${availLabel}`, req);
    }

    const infoChanged = (firstName && firstName !== currentUser.first_name) ||
                        (lastName && lastName !== currentUser.last_name) ||
                        (phone && phone !== currentUser.phone) ||
                        (bloodType && bloodType !== currentUser.blood_type) ||
                        (barangay && barangay !== currentUser.barangay);

    if (infoChanged) {
       await logActivity(userId, 'USER_UPDATE_INFO', 'User updated profile details', req);
    }

    // 6. Return response
    const [updatedUsers] = await pool.execute('SELECT * FROM users WHERE id = ?', [userId]);
    const updatedUser = updatedUsers[0];
    const isDonorString = updatedUser.is_donor ? 'Donor' : 'Recipient';
    const isAvailableString = updatedUser.is_available ? 'Available' : 'Unavailable';

    res.json({
      success: true,
      message: 'Profile updated successfully',
      data: {
        id: updatedUser.id,
        firstName: updatedUser.first_name,
        lastName: updatedUser.last_name,
        isDonor: isDonorString,
        isAvailable: isAvailableString,
      }
    });

  } catch (error) {
    console.error('Update profile error:', error);
    // Catches database connection failure or thrown DB check errors (HTTP 500)
    res.status(500).json({ success: false, error: 'Internal server error' });
  }
});

app.post('/api/messages/send', authenticateToken, async (req, res) => {
  try {
    const senderId = req.user.id;
    // Frontend sends 'receiverId', 'message'
    const { receiverId, message } = req.body;

    if (!receiverId || !message) {
      return res.status(400).json({
        success: false,
        error: 'Receiver ID and message content are required'
      });
    }

    // Insert into database
    const [result] = await pool.execute(
      `INSERT INTO messages (sender_id, receiver_id, message)
       VALUES (?, ?, ?)`,
      [senderId, receiverId, message]
    );

    const now = new Date();

    // Log the activity
    await logActivity(senderId, 'SEND_MESSAGE', `Sent message to User ${receiverId}`, req);

    res.json({
      success: true,
      data: {
        id: result.insertId,
        senderId,
        receiverId,
        message,
        is_read: false,
        created_at: now.toISOString(),
        status: 'sent'
      }
    });

  } catch (error) {
    console.error('Send message error:', error);
    res.status(500).json({ success: false, error: error.message });
  }
});

// 2. Get Chat History with a specific user
app.get('/api/messages/chat/:otherUserId', authenticateToken, async (req, res) => {
  try {
    const currentUserId = req.user.id;
    const otherUserId = req.params.otherUserId;

    // Mark messages as read
    await pool.execute(
      'UPDATE messages SET is_read = TRUE WHERE sender_id = ? AND receiver_id = ?',
      [otherUserId, currentUserId]
    );

    // Fetch conversation with Delete Logic Applied
    const [messages] = await pool.execute(`
      SELECT m.*,
        DATE_FORMAT(m.created_at, '%Y-%m-%dT%H:%i:%s.000Z') as formatted_date
      FROM messages m
      -- Join to check if user deleted this conversation
      LEFT JOIN deleted_conversations dc ON (dc.user_id = ? AND dc.partner_id = ?)
      WHERE (
        (m.sender_id = ? AND m.receiver_id = ?)
        OR
        (m.sender_id = ? AND m.receiver_id = ?)
      )
      -- Only show messages created AFTER the "last deleted" timestamp
      AND (dc.last_deleted_at IS NULL OR m.created_at > dc.last_deleted_at)
      ORDER BY m.created_at ASC
    `, [
      currentUserId, otherUserId, // For deleted_conversations join
      currentUserId, otherUserId, // For message matching (1)
      otherUserId, currentUserId  // For message matching (2)
    ]);

    res.json({ success: true, data: messages });
  } catch (error) {
    console.error('Get chat error:', error);
    res.status(500).json({ success: false, error: 'Internal server error' });
  }
});

// 3. Get List of Conversations (Inbox)
app.get('/api/messages/conversations', authenticateToken, async (req, res) => {
  try {
    const userId = req.user.id;

    const query = `
      SELECT
        u.id as other_user_id,
        u.first_name,
        u.last_name,
        u.blood_type,
        u.is_donor,  -- CRITICAL: Fetches the role (1=Donor, 0=Recipient) from DB
        COALESCE(cn.nickname, CONCAT(u.first_name, ' ', u.last_name)) as display_name,
        COALESCE(cn.nickname, NULL) as nickname,
        m.message as last_message,
        m.created_at,
        m.sender_id,
        m.is_read
      FROM users u
      JOIN messages m ON (
        (m.sender_id = u.id AND m.receiver_id = ?) OR
        (m.sender_id = ? AND m.receiver_id = u.id)
      )
      -- Join for Nicknames
      LEFT JOIN contact_nicknames cn ON (cn.user_id = ? AND cn.partner_id = u.id)
      -- Join to check Archive status
      LEFT JOIN archived_chats ac ON (ac.user_id = ? AND ac.partner_id = u.id)
      -- Join to check Deletion status
      LEFT JOIN deleted_conversations dc ON (dc.user_id = ? AND dc.partner_id = u.id)
      WHERE m.id IN (
        SELECT MAX(id)
        FROM messages
        WHERE sender_id = ? OR receiver_id = ?
        GROUP BY CASE
          WHEN sender_id = ? THEN receiver_id
          ELSE sender_id
        END
      )
      -- FILTER: Only show chats that are NOT archived
      AND ac.user_id IS NULL
      -- FILTER: Only show chats not deleted by user
      AND (dc.last_deleted_at IS NULL OR m.created_at > dc.last_deleted_at)
      ORDER BY m.created_at DESC
    `;

    const [conversations] = await pool.execute(query, [
      userId, userId, userId, userId, userId, userId, userId, userId
    ]);

    res.json({ success: true, data: conversations });
  } catch (error) {
    console.error('Get conversations error:', error);
    res.status(500).json({ success: false, error: 'Internal server error' });
  }
});

app.post('/api/forgot-password', async (req, res) => {
  try {
    const { email } = req.body;

    // Check if user exists
    const [users] = await pool.execute('SELECT id, first_name FROM users WHERE email = ?', [email]);

    if (users.length === 0) {
      return res.status(404).json({
        success: false,
        error: 'Email is not registered to this app.'
      });
    }

    const user = users[0];

    // Generate 6-digit OTP
    const otp = Math.floor(100000 + Math.random() * 900000).toString();

    // Set expiration (15 minutes from now)
    const expiresAt = new Date(Date.now() + 15 * 60 * 1000);

    // Save OTP to database (delete old OTPs for this email first)
    await pool.execute('DELETE FROM password_resets WHERE email = ?', [email]);
    await pool.execute(
      'INSERT INTO password_resets (email, otp, expires_at) VALUES (?, ?, ?)',
      [email, otp, expiresAt]
    );

    // Send Email
    const mailOptions = {
      from: 'bloodifind.app@gmail.com',
      to: email,
      subject: 'BloodiFind - Password Reset OTP',
      html: `
        <div style="font-family: Arial, sans-serif; padding: 20px;">
          <h2>Password Reset Request</h2>
          <p>Hi ${user.first_name},</p>
          <p>You requested to reset your password. Your OTP code is:</p>
          <h1 style="color: #EF4444; letter-spacing: 5px;">${otp}</h1>
          <p>This code expires in 15 minutes.</p>
          <p>If you did not request this, please ignore this email.</p>
        </div>
      `
    };

    await transporter.sendMail(mailOptions);

    res.json({ success: true, message: 'OTP sent to your email.' });

  } catch (error) {
    console.error('Forgot password error:', error);
    res.status(500).json({ success: false, error: 'Internal server error' });
  }
});

// 2. Verify OTP
app.post('/api/verify-otp', async (req, res) => {
  try {
    const { email, otp } = req.body;

    const [records] = await pool.execute(
      'SELECT * FROM password_resets WHERE email = ? AND otp = ? AND expires_at > NOW()',
      [email, otp]
    );

    if (records.length === 0) {
      return res.status(400).json({
        success: false,
        error: 'Invalid OTP.'
      });
    }

    res.json({ success: true, message: 'OTP Verified' });

  } catch (error) {
    console.error('Verify OTP error:', error);
    res.status(500).json({ success: false, error: 'Internal server error' });
  }
});

// 3. Reset Password
app.post('/api/reset-password-final', async (req, res) => {
  try {
    const { email, newPassword, otp } = req.body;

    const [records] = await pool.execute(
      'SELECT * FROM password_resets WHERE email = ? AND otp = ? AND expires_at > NOW()',
      [email, otp]
    );

    if (records.length === 0) {
      return res.status(400).json({ success: false, error: 'Session expired or invalid OTP.' });
    }

    const hashedPassword = await hashPasswordScrypt(newPassword);

    await pool.execute('UPDATE users SET password = ? WHERE email = ?', [hashedPassword, email]);
    await pool.execute('DELETE FROM password_resets WHERE email = ?', [email]);

    // Fetch user ID for logging
    const [users] = await pool.execute('SELECT id FROM users WHERE email = ?', [email]);
    if (users.length > 0) {
        await logActivity(users[0].id, 'PASSWORD_RESET', 'User reset their password via OTP', req);
    }

    res.json({ success: true, message: 'Password reset successfully.' });

  } catch (error) {
    console.error('Reset password error:', error);
    res.status(500).json({ success: false, error: 'Internal server error' });
  }
});

// Blood Requests
app.post('/api/blood-requests', authenticateToken, async (req, res) => {
  try {
    const { bloodType, units, hospital, urgency, notes } = req.body;
    const userId = req.user.id;

    const [result] = await pool.execute(
      `INSERT INTO blood_requests (patient_id, blood_type, units, hospital, urgency, notes, status)
       VALUES (?, ?, ?, ?, ?, ?, 'pending')`,
      [userId, bloodType, units, hospital, urgency, notes]
    );

    res.json({
      success: true,
      message: 'Blood request submitted successfully',
      requestId: result.insertId
    });
  } catch (error) {
    console.error('Blood request error:', error);
    res.status(500).json({
      success: false,
      error: 'Internal server error: ' + error.message
    });
  }
});

// Get Blood Requests
app.get('/api/blood-requests', authenticateToken, async (req, res) => {
  try {
    const [requests] = await pool.execute(`
      SELECT
        br.id,
        CONCAT(u.first_name, ' ', u.last_name) as patient_name,
        br.blood_type,
        br.units,
        br.hospital,
        br.urgency,
        br.status,
        br.notes,
        br.created_at as requested_at,
        br.fulfilled_at
      FROM blood_requests br
      JOIN users u ON br.patient_id = u.id
      WHERE br.patient_id = ?
      ORDER BY br.created_at DESC
    `, [req.user.id]);

    res.json({
      success: true,
      data: requests
    });
  } catch (error) {
    console.error('Get blood requests error:', error);
    res.status(500).json({
      success: false,
      error: 'Internal server error: ' + error.message
    });
  }
});

// Change Password
app.post('/api/change-password', authenticateToken, async (req, res) => {
  try {
    const { currentPassword, newPassword } = req.body;
    const userId = req.user.id;

    const [users] = await pool.execute('SELECT password FROM users WHERE id = ?', [userId]);
    const user = users[0];

    // Using Scrypt Verify for current password
    const isCurrentPasswordValid = await verifyPasswordScrypt(currentPassword, user.password);

    if (!isCurrentPasswordValid) {
      return res.status(400).json({ success: false, error: 'Current password is incorrect' });
    }

    // Using Scrypt Hash for new password
    const hashedNewPassword = await hashPasswordScrypt(newPassword);

    await pool.execute('UPDATE users SET password = ? WHERE id = ?', [hashedNewPassword, userId]);
    await logActivity(userId, 'PASSWORD_CHANGE', 'User changed their password', req);

    res.json({ success: true, message: 'Password updated successfully' });
  } catch (error) {
    console.error('Change password error:', error);
    res.status(500).json({ success: false, error: 'Internal server error: ' + error.message });
  }
});

app.get('/api/activity-logs', authenticateToken, async (req, res) => {
  try {
    const userId = req.user.id;

    // Pagination Params
    const page = parseInt(req.query.page) || 1;
    const limit = 20;
    const offset = (page - 1) * limit;

    // Optional Filters (Matches web version logic)
    const search = req.query.search ? req.query.search.trim() : '';
    const actionsParam = req.query.actions || '';
    const selectedActions = actionsParam ? actionsParam.split(',') : [];

    // 1. Build Dynamic Query
    let baseQuery = `FROM activity_logs l WHERE l.user_id = ?`;
    let queryParams = [userId];

    // Search Filter
    if (search) {
      baseQuery += ` AND (l.details LIKE ? OR l.action LIKE ?)`;
      queryParams.push(`%${search}%`, `%${search}%`);
    }

    // Action Type Filter
    if (selectedActions.length > 0) {
      const placeholders = selectedActions.map(() => '?').join(',');
      baseQuery += ` AND l.action IN (${placeholders})`;
      queryParams.push(...selectedActions);
    }

    // 2. Get Total Count
    const [countRows] = await pool.execute(`SELECT COUNT(*) as total ${baseQuery}`, queryParams);
    const totalLogs = countRows[0].total;
    const totalPages = Math.ceil(totalLogs / limit);

    // 3. Fetch Data
    const dataSql = `
        SELECT l.id, l.action, l.details, l.ip_address, l.created_at
        ${baseQuery}
        ORDER BY l.created_at DESC
        LIMIT ? OFFSET ?
    `;

    queryParams.push(limit.toString(), offset.toString());

    const [logs] = await pool.execute(dataSql, queryParams);

    // 4. Return JSON
    res.json({
      success: true,
      data: logs,
      pagination: {
        current_page: page,
        total_pages: totalPages,
        total_logs: totalLogs
      }
    });

  } catch (error) {
    console.error('Get logs error:', error);
    res.status(500).json({ success: false, error: 'Internal server error' });
  }
});

// GET list of conversations (Inbox) - Duplicates removed, kept for simplicity
app.get('/api/messages/conversations', authenticateToken, async (req, res) => {
  try {
    const userId = req.user.id;

    const query = `
      SELECT
        u.id as other_user_id,
        u.first_name,
        u.last_name,
        u.blood_type,
        u.is_donor,
        COALESCE(cn.nickname, CONCAT(u.first_name, ' ', u.last_name)) as display_name,
        COALESCE(cn.nickname, NULL) as nickname,
        m.message as last_message,
        m.created_at,
        m.sender_id,
        m.is_read
      FROM users u
      JOIN messages m ON (
        (m.sender_id = u.id AND m.receiver_id = ?) OR
        (m.sender_id = ? AND m.receiver_id = u.id)
      )
      -- Join for Nicknames
      LEFT JOIN contact_nicknames cn ON (cn.user_id = ? AND cn.partner_id = u.id)
      -- Join to check Archive status
      LEFT JOIN archived_chats ac ON (ac.user_id = ? AND ac.partner_id = u.id)
      -- Join to check Deletion status
      LEFT JOIN deleted_conversations dc ON (dc.user_id = ? AND dc.partner_id = u.id)
      WHERE m.id IN (
        SELECT MAX(id)
        FROM messages
        WHERE sender_id = ? OR receiver_id = ?
        GROUP BY CASE
          WHEN sender_id = ? THEN receiver_id
          ELSE sender_id
        END
      )
      -- Filter out archived chats
      AND ac.user_id IS NULL
      -- Filter out messages sent before the user "deleted" the conversation
      AND (dc.last_deleted_at IS NULL OR m.created_at > dc.last_deleted_at)
      ORDER BY m.created_at DESC
    `;

    const [conversations] = await pool.execute(query, [
      userId, userId, userId, userId, userId, userId, userId, userId
    ]);

    res.json({ success: true, data: conversations });
  } catch (error) {
    console.error('Get conversations error:', error);
    res.status(500).json({ success: false, error: 'Internal server error' });
  }
});

// NEW: Set Nickname
app.post('/api/messages/nickname', authenticateToken, async (req, res) => {
  try {
    const userId = req.user.id;
    const { partnerId, nickname } = req.body;

    // Upsert (Insert or Update) nickname
    await pool.execute(`
      INSERT INTO contact_nicknames (user_id, partner_id, nickname)
      VALUES (?, ?, ?)
      ON DUPLICATE KEY UPDATE nickname = VALUES(nickname)
    `, [userId, partnerId, nickname]);

    await logActivity(userId, 'SET_NICKNAME', `Set nickname for user ${partnerId}`, req);
    res.json({ success: true, message: 'Nickname updated' });
  } catch (error) {
    console.error('Nickname error:', error);
    res.status(500).json({ success: false, error: 'Server error' });
  }
});

// NEW: Archive Conversation
app.post('/api/messages/archive', authenticateToken, async (req, res) => {
  try {
    const userId = req.user.id;
    const { partnerId } = req.body;

    await pool.execute(`
      INSERT IGNORE INTO archived_chats (user_id, partner_id) VALUES (?, ?)
    `, [userId, partnerId]);

    await logActivity(userId, 'ARCHIVE_CHAT', `Archived chat with ${partnerId}`, req);
    res.json({ success: true, message: 'Conversation archived' });
  } catch (error) {
    console.error('Archive error:', error);
    res.status(500).json({ success: false, error: 'Server error' });
  }
});

// NEW: Delete Conversation (Clear History)
app.post('/api/messages/delete', authenticateToken, async (req, res) => {
  try {
    const userId = req.user.id;
    const { partnerId } = req.body;

    // We don't actually delete the rows (to preserve them for the other user).
    // Instead, we mark a timestamp. Messages before this time are hidden for this user.
    await pool.execute(`
      INSERT INTO deleted_conversations (user_id, partner_id, last_deleted_at)
      VALUES (?, ?, NOW())
      ON DUPLICATE KEY UPDATE last_deleted_at = NOW()
    `, [userId, partnerId]);

    await logActivity(userId, 'DELETE_CHAT', `Cleared history with ${partnerId}`, req);
    res.json({ success: true, message: 'Conversation deleted' });
  } catch (error) {
    console.error('Delete chat error:', error);
    res.status(500).json({ success: false, error: 'Server error' });
  }
});

// NEW: Report User
app.post('/api/users/report', authenticateToken, async (req, res) => {
  try {
    const reporterId = req.user.id;
    const { reportedUserId, reason, description } = req.body;

    await pool.execute(`
      INSERT INTO user_reports (reporter_id, reported_user_id, reason, description)
      VALUES (?, ?, ?, ?)
    `, [reporterId, reportedUserId, reason, description]);

    await logActivity(reporterId, 'REPORT_USER', `Reported user ${reportedUserId}`, req);
    res.json({ success: true, message: 'User reported successfully' });
  } catch (error) {
    console.error('Report user error:', error);
    res.status(500).json({ success: false, error: 'Server error' });
  }
});

app.get('/api/messages/archived', authenticateToken, async (req, res) => {
  try {
    const userId = req.user.id;
    // We use INNER JOIN on archived_chats to ONLY get archived ones
    const query = `
      SELECT
        u.id as other_user_id,
        u.first_name,
        u.last_name,
        u.blood_type,
        COALESCE(cn.nickname, CONCAT(u.first_name, ' ', u.last_name)) as display_name,
        m.message as last_message,
        m.created_at
      FROM users u
      JOIN messages m ON (
        (m.sender_id = u.id AND m.receiver_id = ?) OR
        (m.sender_id = ? AND m.receiver_id = u.id)
      )
      JOIN archived_chats ac ON (ac.user_id = ? AND ac.partner_id = u.id)
      LEFT JOIN contact_nicknames cn ON (cn.user_id = ? AND cn.partner_id = u.id)
      WHERE m.id IN (
        SELECT MAX(id) FROM messages
        WHERE sender_id = ? OR receiver_id = ?
        GROUP BY CASE WHEN sender_id = ? THEN receiver_id ELSE sender_id END
      )
      ORDER BY m.created_at DESC
    `;
    const [chats] = await pool.execute(query, [userId, userId, userId, userId, userId, userId, userId]);
    res.json({ success: true, data: chats });
  } catch (error) {
    console.error(error);
    res.status(500).json({ success: false, error: 'Server error' });
  }
});

// 2. Unarchive Chat
app.post('/api/messages/unarchive', authenticateToken, async (req, res) => {
  try {
    const userId = req.user.id;
    const { partnerId } = req.body;
    await pool.execute('DELETE FROM archived_chats WHERE user_id = ? AND partner_id = ?', [userId, partnerId]);
    await logActivity(userId, 'UNARCHIVE_CHAT', `Unarchived chat with ${partnerId}`, req);
    res.json({ success: true, message: 'Chat unarchived' });
  } catch (error) {
    res.status(500).json({ success: false, error: 'Server error' });
  }
});

// ---------------------------------------------------------
// FIX: Final, Correct implementation of Get Other User Profile
// ---------------------------------------------------------
app.get('/api/users/:id', authenticateToken, async (req, res) => {
  try {
    const [users] = await pool.execute(
      'SELECT id, first_name, last_name, blood_type, is_donor FROM users WHERE id = ?',
      [req.params.id]
    ); //

    if (users.length === 0) {
      return res.status(404).json({ success: false, error: 'User not found' });
    } //

    const user = users[0]; //

    // Convert the database boolean/int (user.is_donor) to the desired string
    const isDonorValue = user.is_donor == 1 || user.is_donor === true ? 'Donor' : 'Recipient'; //

    res.json({
        success: true,
        data: {
            ...user,
            is_donor: isDonorValue // CRITICAL: Forces the string value
        }
    }); //

  } catch (error) {
    console.error('Get user public profile error:', error);
    res.status(500).json({ success: false, error: 'Server error' });
  }
});


// NEW: Request Initiation (Recipient -> Donor)
app.post('/api/requests/initiate', authenticateToken, async (req, res) => {
    try {
        const recipientId = req.user.id;
        const { donorId, notes } = req.body;

        // 1. Check if the current user (requester) is a Recipient
        if (req.user.is_donor) {
             return res.status(403).json({ success: false, error: 'Only Recipients can initiate a request.' });
        }

        // **CRITICAL FIX 1: Check for ANY active request by the Recipient**
        const [activeRequestsByRecipient] = await pool.execute(
            `SELECT id FROM chat_requests WHERE requester_id = ? AND status IN ('Pending', 'Ongoing')`,
            [recipientId]
        );

        if (activeRequestsByRecipient.length > 0) {
            return res.status(400).json({
                success: false,
                error: 'You already have an active blood request (Pending or Ongoing). Please complete or cancel it before requesting again.'
            });
        }
        // ----------------------------------------------------------------------

        // **CRITICAL FIX 2: Check if the TARGET Donor has ANY active request (Pending or Ongoing)**
        const [targetDonorActiveRequests] = await pool.execute(
            `SELECT id, status FROM chat_requests WHERE donor_id = ? AND status IN ('Pending', 'Ongoing')`,
            [donorId]
        );

        if (targetDonorActiveRequests.length > 0) {
            const status = targetDonorActiveRequests[0].status;
            return res.status(400).json({
                success: false,
                error: `This donor is currently committed to an active request (${status}). Please try again later or contact a different donor.`
            });
        }
        // ----------------------------------------------------------------------


        // 3. Fetch Recipient Blood Type
        const [recipient] = await pool.execute('SELECT blood_type FROM users WHERE id = ?', [recipientId]);
        if (recipient.length === 0) {
             return res.status(404).json({ success: false, error: 'Recipient not found.' });
        }

        // 4. Insert the new request
        const [result] = await pool.execute(
            `INSERT INTO chat_requests (requester_id, donor_id, status, notes, blood_type)
             VALUES (?, ?, 'Pending', ?, ?)`,
            [recipientId, donorId, notes, recipient[0].blood_type]
        );

        await logActivity(recipientId, 'REQUEST_DONATION', `Requested donation from Donor ${donorId}`, req);

        res.json({
            success: true,
            message: 'Donation request sent (Pending)',
            requestId: result.insertId,
            status: 'Pending',
            bloodType: recipient[0].blood_type
        });

    } catch (error) {
        console.error('Initiate request error:', error);
        res.status(500).json({ success: false, error: 'Internal server error' });
    }
});


// NEW: Update Request Status (Accept/Decline/Cancel/Complete)
app.post('/api/requests/:requestId/update', authenticateToken, async (req, res) => {
    try {
        const userId = req.user.id;
        const requestId = req.params.requestId;
        const { action } = req.body; // 'Accept', 'Decline', 'Cancel', 'Complete'

        let newStatus;
        let logAction;

        // Fetch request details needed for checks and completion logic
        const [requestDetails] = await pool.execute('SELECT requester_id, donor_id, status FROM chat_requests WHERE id = ?', [requestId]);
        if (requestDetails.length === 0) return res.status(404).json({ success: false, error: 'Request not found' });

        const currentRequestStatus = requestDetails[0].status;
        const isRequester = requestDetails[0].requester_id === userId;
        const isDonor = requestDetails[0].donor_id === userId;


        if (action === 'Accept' && isDonor) {
            // 1. Block if the request is not 'Pending' (prevent accepting an already accepted/declined request)
            if (currentRequestStatus !== 'Pending') {
                return res.status(400).json({
                    success: false,
                    error: `Cannot accept a request with status: ${currentRequestStatus}.`
                });
            }

            // **CRITICAL FIX: Check for ANY request where Donor is currently 'Ongoing'**
            const [ongoingRequestsByDonor] = await pool.execute(
                `SELECT id FROM chat_requests WHERE donor_id = ? AND status = 'Ongoing'`,
                [userId]
            );

            if (ongoingRequestsByDonor.length > 0) {
                 return res.status(400).json({
                    success: false,
                    error: 'You are currently committed to an ongoing donation. Please complete or cancel it before accepting a new request.'
                });
            }
            // If check passes, set to Ongoing
            newStatus = 'Ongoing';
            logAction = 'REQUEST_ACCEPTED';

        } else if (action === 'Decline') {
            newStatus = 'Declined';
            logAction = 'REQUEST_DECLINED';
        } else if (action === 'Cancel') {
            newStatus = 'Cancelled';
            logAction = 'REQUEST_CANCELLED';
        } else if (action === 'Complete') {
            // Check if BOTH users have "completed"
            const [currentCompletionStatus] = await pool.execute('SELECT requester_completed, donor_completed FROM chat_requests WHERE id = ?', [requestId]);
            if (currentCompletionStatus.length === 0) return res.status(404).json({ success: false, error: 'Request not found' });

            let requesterCompleted = currentCompletionStatus[0].requester_completed;
            let donorCompleted = currentCompletionStatus[0].donor_completed;

            if (isRequester) requesterCompleted = 1;
            if (isDonor) donorCompleted = 1;

            newStatus = (requesterCompleted && donorCompleted) ? 'Completed' : 'Ongoing';

            await pool.execute(
                `UPDATE chat_requests SET requester_completed = ?, donor_completed = ? WHERE id = ?`,
                [requesterCompleted, donorCompleted, requestId]
            );

            // If fully completed, update status
            if (newStatus === 'Completed') {
                await pool.execute(`UPDATE chat_requests SET status = 'Completed' WHERE id = ?`, [requestId]);
                logAction = 'REQUEST_COMPLETED';
            } else {
                return res.json({ success: true, message: `Status updated to 'Ongoing' (Waiting for other party)`, newStatus: 'Ongoing' });
            }

        } else {
            return res.status(400).json({ success: false, error: 'Invalid action or permission denied' });
        }


        // Final Status Update (for non-Complete actions)
        if (action !== 'Complete') {
            await pool.execute(`UPDATE chat_requests SET status = ? WHERE id = ?`, [newStatus, requestId]);
        }

        await logActivity(userId, logAction, `Updated request ${requestId} to ${newStatus}`, req);

        res.json({ success: true, message: `Request status changed to ${newStatus}`, newStatus: newStatus });
    } catch (error) {
        console.error('Update request status error:', error);
        res.status(500).json({ success: false, error: 'Internal server error' });
    }
});


// NEW: Get all relevant requests for the current chat
app.get('/api/requests/chat/:partnerId', authenticateToken, async (req, res) => {
    try {
        const userId = req.user.id;
        const partnerId = req.params.partnerId;

        // Fetch ALL requests involving these two users, ordered by creation date
        const [requests] = await pool.execute(`
            SELECT
                id,
                requester_id,
                donor_id,
                blood_type,
                status,
                notes,
                created_at,
                requester_completed,
                donor_completed
            FROM chat_requests
            WHERE (requester_id = ? AND donor_id = ?)
            OR (requester_id = ? AND donor_id = ?)
            ORDER BY created_at DESC
        `, [userId, partnerId, partnerId, userId]);

        res.json({ success: true, data: requests });
    } catch (error) {
        console.error('Get chat requests error:', error);
        res.status(500).json({ success: false, error: 'Internal server error' });
    }
});


// Logout
app.post('/api/logout', authenticateToken, async (req, res) => {
  try {
    await logActivity(req.user.id, 'LOGOUT', 'User logged out', req);

    res.json({
      success: true,
      message: 'Logged out successfully'
    });
  } catch (error) {
    console.error('Logout log error:', error);
    res.json({ success: true, message: 'Logged out' });
  }
});

// Delete Account
app.delete('/api/profile', authenticateToken, async (req, res) => {
  try {
    await pool.execute('DELETE FROM users WHERE id = ?', [req.user.id]);

    res.json({
      success: true,
      message: 'Account deleted successfully'
    });
  } catch (error) {
    console.error('Delete account error:', error);
    res.status(500).json({
      success: false,
      error: 'Internal server error: ' + error.message
    });
  }
});

// ---------------------------------------------------------
// 2. USER SELF-ARCHIVE (Equivalent to /archive_account)
// ---------------------------------------------------------
app.post('/api/archive-account', authenticateToken, async (req, res) => {
  try {
    const userId = req.user.id;
    const connection = await pool.getConnection();

    // 1. Fetch User Details
    const [users] = await connection.execute('SELECT first_name, email FROM users WHERE id = ?', [userId]);

    if (users.length === 0) {
      connection.release();
      return res.status(404).json({ success: false, error: 'User not found' });
    }

    const user = users[0];

    // 2. Archive Account
    await connection.execute(`
      UPDATE users
      SET is_archived = 1, is_available = 0, archived_at = NOW()
      WHERE id = ?
    `, [userId]);

    connection.release();
    await logActivity(userId, 'USER_ARCHIVE', 'User archived their own account', req);

    // 3. Generate Restoration Token (Valid for 30 Days)
    const restorationToken = jwt.sign({ email: user.email, type: 'restore' }, JWT_SECRET, { expiresIn: '30d' });

    // ⚠️ IMPORTANT: Update this IP to your local IP address same as registration
    let MY_IPV4_ADDRESS = 'localhost';

        const interfaces = os.networkInterfaces();
        for (const name of Object.keys(interfaces)) {
          for (const iface of interfaces[name]) {
            // Skip internal (localhost) and non-IPv4 addresses
            if (iface.family === 'IPv4' && !iface.internal) {
              MY_IPV4_ADDRESS = iface.address;
              break;
            }
          }
        }

        const restoreUrl = `http://${MY_IPV4_ADDRESS}:${PORT}/api/restore-account?token=${restorationToken}`;

    // 4. Send Email
    const mailOptions = {
      from: 'bloodifind.app@gmail.com',
      to: user.email,
      subject: 'Bloodifind - Account Deactivated (Restore Link)',
      html: emailUserRestorationTemplate(user.first_name, restoreUrl)
    };
    await transporter.sendMail(mailOptions);

    res.json({
      success: true,
      message: 'Account archived. Check your email for a restoration link.'
    });

  } catch (error) {
    console.error('Archive account error:', error);
    res.status(500).json({ success: false, error: 'Internal server error: ' + error.message });
  }
});


// ---------------------------------------------------------
// 3. RESTORE ACCOUNT (Equivalent to /restore/<token>)
// ---------------------------------------------------------
app.get('/api/restore-account', async (req, res) => {
  const { token } = req.query;

  // Simple error Page
  const errorHtml = (msg) => `<html><body style="font-family:sans-serif; text-align:center; padding:50px;">
    <h1 style="color:red;">Restoration Failed</h1><p>${msg}</p></body></html>`;

  if (!token) return res.status(400).send(errorHtml("Invalid link."));

  try {
    const decoded = jwt.verify(token, JWT_SECRET);

    // Optional: Check if token type is 'restore'
    if (decoded.type && decoded.type !== 'restore') {
       return res.status(400).send(errorHtml("Invalid token type."));
    }

    const email = decoded.email;
    const connection = await pool.getConnection();

    // 1. Find User
    const [users] = await connection.execute('SELECT * FROM users WHERE email = ?', [email]);

    if (users.length === 0) {
      connection.release();
      return res.status(404).send(errorHtml("User account not found."));
    }

    const user = users[0];

    // 2. Restore Account
    await connection.execute(`
      UPDATE users
      SET is_archived = 0, archived_at = NULL
      WHERE id = ?
    `, [user.id]);

    connection.release();
    await logActivity(user.id, 'USER_RESTORE', 'User restored account via email link');

    // 3. Return Success HTML
    res.setHeader('Content-Type', 'text/html');
        res.send(`
          <!DOCTYPE html>
          <html>
            <head>
              <title>Account Restored</title>
              <meta name="viewport" content="width=device-width, initial-scale=1">
              <style>
                body {
                  font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif;
                  background-color: #F9FAFB;
                  margin: 0;
                  display: flex;
                  align-items: center;
                  justify-content: center;
                  height: 100vh;
                }
                .container {
                  background: white;
                  padding: 40px;
                  border-radius: 16px;
                  box-shadow: 0 10px 25px rgba(0,0,0,0.05);
                  text-align: center;
                  max-width: 400px;
                  width: 90%;
                  border-top: 5px solid #28a745; /* Green for success */
                }
                .icon-circle {
                  width: 80px;
                  height: 80px;
                  background-color: #d4edda;
                  border-radius: 50%;
                  display: flex;
                  align-items: center;
                  justify-content: center;
                  margin: 0 auto 20px;
                }
                .icon {
                  font-size: 40px;
                  color: #28a745;
                }
                h1 {
                  color: #1F2937;
                  margin-bottom: 10px;
                  font-size: 24px;
                }
                p {
                  color: #6B7280;
                  line-height: 1.5;
                  margin-bottom: 20px;
                }
                .footer {
                  font-size: 12px;
                  color: #9CA3AF;
                  margin-top: 30px;
                }
              </style>
            </head>
            <body>
              <div class="container">
                <div class="icon-circle">
                  <span class="icon">&#10003;</span>
                </div>
                <h1>Welcome Back!</h1>
                <p><strong>${user.first_name}</strong>, your account has been successfully restored.</p>
                <p>Your profile is now visible again. You can close this window and log in to the Bloodifind app.</p>

                <div class="footer">
                  &copy; 2025 Bloodifind
                </div>
              </div>
            </body>
          </html>
        `);

  } catch (error) {
    console.error('Restore error:', error);
    res.status(400).send(errorHtml("The restoration link is invalid or has expired (30 days limit)."));
  }
});


// Logout (No changes needed)
app.post('/api/logout', authenticateToken, async (req, res) => {
  try {
    await logActivity(req.user.id, 'LOGOUT', 'User logged out', req);

    res.json({
      success: true,
      message: 'Logged out successfully'
    });
  } catch (error) {
    console.error('Logout log error:', error);
    res.json({ success: true, message: 'Logged out' });
  }
});

// Delete Account (No changes needed)
app.delete('/api/profile', authenticateToken, async (req, res) => {
  try {
    await pool.execute('DELETE FROM users WHERE id = ?', [req.user.id]);

    res.json({
      success: true,
      message: 'Account deleted successfully'
    });
  } catch (error) {
    console.error('Delete account error:', error);
    res.status(500).json({
      success: false,
      error: 'Internal server error: ' + error.message
    });
  }
});

// ========== CATCH ALL UNDEFINED ROUTES ==========
app.use('*', (req, res) => {
  if (!req.originalUrl.includes('verify-email')) {
    res.status(404).json({
      success: false,
      error: 'Route not found',
      path: req.originalUrl,
      method: req.method
    });
  } else {
      res.status(404).send("Page not found");
  }
});

// ========== GLOBAL ERROR HANDLER ==========
app.use((error, req, res, next) => {
  console.error('Global error handler:', error);
  res.status(500).json({
    success: false,
    error: 'Internal server error',
    message: process.env.NODE_ENV === 'development' ? error.message : 'Something went wrong'
  });
});

// Initialize and start server
async function startServer() {
  console.log('🚀 Starting BloodiFind Backend Server...');

  const isConnected = await testConnection();
  if (isConnected) {
    await initializeDatabase();

    app.listen(PORT, '0.0.0.0', () => {
      console.log(`✅ Server running on http://localhost:${PORT}`);
      console.log(`📱 API available at http://10.0.2.2:${PORT} for Android emulator`);
      console.log(`🌐 Test endpoint: http://localhost:${PORT}/api/test`);
    });
  } else {
    console.log('❌ Cannot start server - database connection failed');
    process.exit(1);
  }
}

testConnection();
startServer();