const express = require("express");
const router = express.Router();
const attendanceController = require("../controllers/attendanceController");
const authMiddleware = require("../middleware/authMiddleware");
const roleMiddleware = require("../middleware/roleMiddleware");
const upload = require("../middleware/uploadMiddleware");

// All routes require authentication
router.use(authMiddleware);

// Student attendance routes
router.post("/mark", roleMiddleware.isStudent, attendanceController.markAttendance);
router.post("/mark/face", 
  upload.single("image"), 
  roleMiddleware.isStudent, 
  attendanceController.markAttendanceWithFace
);
router.get("/history", roleMiddleware.isStudent, attendanceController.getAttendanceHistory);
router.get("/today", roleMiddleware.isStudent, attendanceController.getTodayAttendance);
router.get("/stats", roleMiddleware.isStudent, attendanceController.getAttendanceStats);
router.get("/semester/:semesterNo", roleMiddleware.isStudent, attendanceController.getSemesterAttendance);

module.exports = router;