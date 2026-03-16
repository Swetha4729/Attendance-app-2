import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../providers/staff_provider.dart';

class ModifyAttendanceScreen extends StatefulWidget {
  const ModifyAttendanceScreen({super.key});

  @override
  State<ModifyAttendanceScreen> createState() =>
      _ModifyAttendanceScreenState();
}

class _ModifyAttendanceScreenState extends State<ModifyAttendanceScreen>
    with SingleTickerProviderStateMixin {
  final String classId = "CSE3A";
  final String className = "CSE – III A";
  final String subjectName = "Data Structures";

  final List<String> statusOptions = ["Present", "Absent", "OD"];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<StaffProvider>().loadStudents(classId);
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<StaffProvider>();

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: Text('BATCH ADJUSTMENT', 
          style: GoogleFonts.inter(fontWeight: FontWeight.w900, letterSpacing: 1.5, fontSize: 13, color: const Color(0xFF0F172A))),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Color(0xFF0F172A), size: 18),
        ),
      ),
      body: provider.loading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF4F46E5)))
          : _buildContent(provider),
    );
  }

  Widget _buildContent(StaffProvider provider) {
    return Column(
      children: [
        _buildHeader(provider),
        Expanded(child: _buildStudentList(provider)),
        _buildActionFooter(provider),
      ],
    );
  }

  Widget _buildHeader(StaffProvider provider) {
    final presentCount = provider.students
        .where((s) => s["status"].toString().toLowerCase() == "present")
        .length;

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.all(24),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFF4F46E5),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [BoxShadow(color: const Color(0xFF4F46E5).withOpacity(0.2), blurRadius: 20, offset: const Offset(0, 8))],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: Colors.white12, borderRadius: BorderRadius.circular(12)),
            child: const Icon(Icons.tune_rounded, color: Colors.white, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(className, style: GoogleFonts.inter(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w900)),
                Text('$subjectName • $presentCount Verified', style: GoogleFonts.inter(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.w500)),
              ],
            ),
          )
        ],
      ),
    ).animate().fadeIn().slideY(begin: -0.1);
  }

  Widget _buildStudentList(StaffProvider provider) {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      itemCount: provider.students.length,
      itemBuilder: (_, index) {
        final student = provider.students[index];
        return _studentTile(index, student).animate(delay: (200 + (index * 40)).ms).fadeIn().slideX(begin: 0.05);
      },
    );
  }

  Widget _studentTile(int index, Map<String, dynamic> student) {
    final status = student["status"]?.toString() ?? "Absent";
    final color = _statusColor(status);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFF1F5F9)),
      ),
      child: Row(
        children: [
          Container(
            width: 32, height: 32,
            decoration: BoxDecoration(color: color.withOpacity(0.1), shape: BoxShape.circle),
            child: Center(child: Text("${index + 1}", style: GoogleFonts.inter(color: color, fontWeight: FontWeight.w900, fontSize: 12))),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(student["name"], style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 15, color: const Color(0xFF1E293B))),
                Text(student["roll"] ?? "No ID", style: const TextStyle(fontSize: 11, color: Color(0xFF94A3B8))),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            decoration: BoxDecoration(color: const Color(0xFFF8FAFC), borderRadius: BorderRadius.circular(12)),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: statusOptions.contains(status) ? status : statusOptions[1], // fallback to Absent
                items: statusOptions
                    .map((s) => DropdownMenuItem(
                          value: s,
                          child: Text(s, style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w900, color: _statusColor(s))),
                        ))
                    .toList(),
                onChanged: (val) {
                  setState(() {
                    context.read<StaffProvider>().students[index]["status"] = val;
                  });
                },
              ),
            ),
          )
        ],
      ),
    );
  }

  Widget _buildActionFooter(StaffProvider provider) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Color(0xFFF1F5F9))),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('DISCARD', style: GoogleFonts.inter(fontWeight: FontWeight.w900, color: const Color(0xFF94A3B8), letterSpacing: 1.5, fontSize: 12)),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            flex: 2,
            child: Container(
              height: 56,
              decoration: BoxDecoration(
                color: const Color(0xFF0F172A),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [BoxShadow(color: const Color(0xFF0F172A).withOpacity(0.2), blurRadius: 15, offset: const Offset(0, 5))],
              ),
              child: ElevatedButton(
                onPressed: () async {
                  await provider.saveAttendance(provider.students);
                  if (!mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: const Text('Synchronization Complete'),
                      backgroundColor: const Color(0xFF0F172A),
                      behavior: SnackBarBehavior.floating,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    )
                  );
                },
                style: ElevatedButton.styleFrom(backgroundColor: Colors.transparent, shadowColor: Colors.transparent, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
                child: Text('COMMIT CHANGES', style: GoogleFonts.inter(fontWeight: FontWeight.w900, color: Colors.white, fontSize: 12, letterSpacing: 1)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Color _statusColor(String status) {
    switch (status.toLowerCase()) {
      case "present": return const Color(0xFF10B981);
      case "absent": return const Color(0xFFEF4444);
      case "od": return const Color(0xFF3B82F6);
      default: return Colors.grey;
    }
  }
}
