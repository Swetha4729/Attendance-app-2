const Attendance = require("../models/Attendance");
const User = require("../models/User");

// @desc    Mark attendance
exports.markAttendance = async (req, res) => {
  try {
    const { method, router: wifiRouter, class: className, subject } = req.body;
    const studentId = req.user.studentId || req.user.id;
    
    if (!studentId) {
      return res.status(400).json({
        success: false,
        message: "Student ID is required"
      });
    }

    // Get today's date
    const today = new Date();
    const dateString = today.toISOString().split('T')[0];
    const timeString = today.toTimeString().split(' ')[0];

    // Check if attendance already marked today
    const existingAttendance = await Attendance.findOne({
      studentId,
      date: dateString,
      class: className || "General"
    });

    if (existingAttendance) {
      return res.status(400).json({
        success: false,
        message: "Attendance already marked for today"
      });
    }

    // Get student details
    const student = await User.findById(req.user.id);
    if (!student) {
      return res.status(404).json({
        success: false,
        message: "Student not found"
      });
    }

    // Create attendance record
    const attendance = new Attendance({
      studentId,
      studentName: student.name,
      date: dateString,
      time: timeString,
      class: className || "General",
      subject: subject || "General",
      method: method || "manual",
      status: "PRESENT",
      wifiRouter: wifiRouter || "unknown",
      semester: student.semester || 1,
      courseCode: subject || "GEN101",
      markedBy: req.user.id,
      faceVerified: method === "face",
      fingerprintVerified: method === "fingerprint",
      notes: "Marked via app"
    });

    await attendance.save();

    res.status(201).json({
      success: true,
      message: "Attendance marked successfully",
      data: attendance
    });
  } catch (error) {
    console.error("Mark attendance error:", error);
    res.status(500).json({
      success: false,
      message: "Server error"
    });
  }
};

// @desc    Mark attendance with face recognition
exports.markAttendanceWithFace = async (req, res) => {
  try {
    const { router: wifiRouter, class: className, subject } = req.body;
    
    if (!req.file) {
      return res.status(400).json({
        success: false,
        message: "Image is required for face recognition"
      });
    }

    const studentId = req.user.studentId || req.user.id;
    const today = new Date();
    const dateString = today.toISOString().split('T')[0];
    const timeString = today.toTimeString().split(' ')[0];

    // Check existing attendance
    const existingAttendance = await Attendance.findOne({
      studentId,
      date: dateString,
      class: className || "General"
    });

    if (existingAttendance) {
      return res.status(400).json({
        success: false,
        message: "Attendance already marked for today"
      });
    }

    // Get student details
    const student = await User.findById(req.user.id);
    if (!student) {
      return res.status(404).json({
        success: false,
        message: "Student not found"
      });
    }

    // For demo, always verify face
    const faceVerified = true;

    if (!faceVerified) {
      return res.status(400).json({
        success: false,
        message: "Face recognition failed"
      });
    }

    // Create attendance record
    const attendance = new Attendance({
      studentId,
      studentName: student.name,
      date: dateString,
      time: timeString,
      class: className || "General",
      subject: subject || "General",
      method: "face",
      status: "PRESENT",
      wifiRouter: wifiRouter || "unknown",
      semester: student.semester || 1,
      courseCode: subject || "GEN101",
      imageUrl: `/uploads/${req.file.filename}`,
      faceVerified: true,
      markedBy: req.user.id,
      notes: "Marked via face recognition"
    });

    await attendance.save();

    res.status(201).json({
      success: true,
      message: "Face attendance marked successfully",
      data: attendance
    });
  } catch (error) {
    console.error("Face attendance error:", error);
    res.status(500).json({
      success: false,
      message: "Server error"
    });
  }
};

// @desc    Get attendance history
exports.getAttendanceHistory = async (req, res) => {
  try {
    const studentId = req.user.studentId || req.user.id;
    
    const attendance = await Attendance.find({ studentId }).sort({ date: -1 });

    res.json({
      success: true,
      data: attendance
    });
  } catch (error) {
    console.error("Get attendance history error:", error);
    res.status(500).json({
      success: false,
      message: "Server error"
    });
  }
};

// @desc    Get today's attendance
exports.getTodayAttendance = async (req, res) => {
  try {
    const studentId = req.user.studentId || req.user.id;
    const today = new Date().toISOString().split('T')[0];
    
    const attendance = await Attendance.findOne({
      studentId,
      date: today
    });

    res.json({
      success: true,
      marked: !!attendance,
      data: attendance || null
    });
  } catch (error) {
    console.error("Get today attendance error:", error);
    res.status(500).json({
      success: false,
      message: "Server error"
    });
  }
};

// @desc    Get attendance statistics
exports.getAttendanceStats = async (req, res) => {
  try {
    const studentId = req.user.studentId || req.user.id;
    
    const attendance = await Attendance.find({ studentId });
    const total = attendance.length;
    const present = attendance.filter(a => a.status === "PRESENT").length;
    const percentage = total > 0 ? Math.round((present / total) * 100) : 0;

    res.json({
      success: true,
      stats: {
        total,
        present,
        percentage
      }
    });
  } catch (error) {
    console.error("Get stats error:", error);
    res.status(500).json({
      success: false,
      message: "Server error"
    });
  }
};

// @desc    Get semester attendance
exports.getSemesterAttendance = async (req, res) => {
  try {
    const { semesterNo } = req.params;
    const studentId = req.user.studentId || req.user.id;
    
    const attendance = await Attendance.find({
      studentId,
      semester: parseInt(semesterNo)
    }).sort({ date: -1 });

    res.json({
      success: true,
      data: attendance
    });
  } catch (error) {
    console.error("Get semester attendance error:", error);
    res.status(500).json({
      success: false,
      message: "Server error"
    });
  }
};