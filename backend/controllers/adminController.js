const Admin = require("../models/Admin");
const crypto = require("crypto");

function hashPassword(password) {
  return crypto.createHash("sha256").update(password + "neurofit_admin_salt_2026").digest("hex");
}

exports.login = async (req, res) => {
  try {
    const { email, password } = req.body;
    if (!email || !password) {
      return res.status(400).json({ success: false, message: "Email and password are required" });
    }
    const admin = await Admin.findOne({ email: email.toLowerCase().trim() });
    if (!admin) {
      return res.status(401).json({ success: false, message: "Invalid admin credentials" });
    }
    const inputHash = hashPassword(password);
    if (admin.passwordHash !== inputHash) {
      return res.status(401).json({ success: false, message: "Invalid admin credentials" });
    }
    admin.lastLogin = new Date();
    await admin.save();
    console.log(`🔑 Admin logged in successfully: ${admin.email} (${admin.role})`);
    res.json({
      success: true,
      message: "Admin authentication successful",
      data: {
        id: admin._id,
        email: admin.email,
        name: admin.name,
        role: admin.role,
        lastLogin: admin.lastLogin
      }
    });
  } catch (err) {
    console.error("Error in admin login:", err.message);
    res.status(500).json({ success: false, message: err.message });
  }
};

exports.seedAdmin = async (req, res) => {
  try {
    const { email, password, name } = req.body;
    const adminEmail = (email || "rohitsengar02@gmail.com").toLowerCase().trim();
    const adminPass = password || "RUdra@602";
    const passwordHash = hashPassword(adminPass);
    const admin = await Admin.findOneAndUpdate(
      { email: adminEmail },
      {
        email: adminEmail,
        passwordHash,
        name: name || "Rohit Sengar (Super Admin)",
        role: "superadmin",
        isActive: true,
        updatedAt: new Date()
      },
      { upsert: true, new: true }
    );
    console.log(`✅ SuperAdmin seeded in MongoDB Atlas admins collection: ${admin.email}`);
    res.json({ success: true, message: "SuperAdmin seeded successfully", data: { email: admin.email, name: admin.name } });
  } catch (err) {
    res.status(500).json({ success: false, message: err.message });
  }
};
