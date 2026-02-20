const Class = require("../models/Class");
const Attendance = require("../models/Attendance");


// ==========================
// GET STAFF CLASSES
// ==========================
exports.getStaffClasses = async (req, res) => {
  try {
    const staffId = req.user.id;

    const classes = await Class.find({ staff: staffId });

    res.json(classes);
  } catch (err) {
    console.error(err);
    res.status(500).json({ message: "Failed to fetch classes" });
  }
};

// ==========================
// GET CLASS ATTENDANCE
// ==========================
exports.getClassAttendance = async (req, res) => {
  try {
    const { classId } = req.params;

    const attendance = await Attendance.find({ class: classId })
      .populate("student", "name rollNo")
      .sort({ date: -1 });

    res.json(attendance);
  } catch (err) {
    res.status(500).json({ message: "Failed to fetch attendance" });
  }
};

// ==========================
// MARK CLASS ATTENDANCE
// ==========================
exports.markClassAttendance = async (req, res) => {
  try {
    const { classId } = req.params;
    const { date, records } = req.body;

    const created = await Attendance.create({
      class: classId,
      staff: req.user.id,
      date,
      records,
    });

    res.status(201).json(created);
  } catch (err) {
    res.status(500).json({ message: "Failed to mark attendance" });
  }
};

// ==========================
// MODIFY ATTENDANCE
// ==========================
exports.modifyAttendance = async (req, res) => {
  try {
    const { attendanceId } = req.params;

    const updated = await Attendance.findByIdAndUpdate(
      attendanceId,
      req.body,
      { new: true }
    );

    res.json(updated);
  } catch (err) {
    res.status(500).json({ message: "Failed to modify attendance" });
  }
};

// ==========================
// GET ATTENDANCE REPORTS
// ==========================
exports.getAttendanceReports = async (req, res) => {
  try {
    const staffId = req.user.id;

    const reports = await Attendance.find({ staff: staffId })
      .populate("class", "name")
      .populate("student", "name");

    res.json(reports);
  } catch (err) {
    res.status(500).json({ message: "Failed to load reports" });
  }
};
