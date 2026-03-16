import 'dart:convert';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:attendance_app/config/api_config.dart';
import 'package:attendance_app/services/auth_service.dart';
import 'package:attendance_app/config/routes.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:intl/intl.dart';

class StudentDashboard extends StatefulWidget {
  const StudentDashboard({super.key});

  @override
  State<StudentDashboard> createState() => _StudentDashboardState();
}

class _StudentDashboardState extends State<StudentDashboard> {
  Map<String, dynamic>? dashboardData;
  List<dynamic> allAttendance = [];
  List<dynamic> semesterAttendance = [];
  final Map<DateTime, List<dynamic>> _attendanceMap = {};

  bool isLoading = true;
  bool hasError = false;
  String errorMessage = '';

  int selectedSemester = 4;
  DateTime _focusedDay = DateTime.utc(DateTime.now().year, DateTime.now().month, DateTime.now().day);
  DateTime? _selectedDay;

  @override
  void initState() {
    super.initState();
    _selectedDay = _focusedDay;
    fetchDashboardData();
  }

  Future<void> _handleLogout() async {
    AuthService.clearToken();
    Navigator.of(context).pushNamedAndRemoveUntil(Routes.login, (route) => false);
  }

  Future<void> fetchDashboardData() async {
    if (!mounted) return;
    setState(() {
      isLoading = true;
      hasError = false;
    });

    final token = AuthService.getToken();
    if (token == null) {
      _handleLogout();
      return;
    }

    try {
      final headers = {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      };
      final dashRes = await http.get(Uri.parse('${ApiConfig.baseUrl}/student/dashboard'), headers: headers);
      final histRes = await http.get(Uri.parse('${ApiConfig.baseUrl}/attendance/history'), headers: headers);

      if (dashRes.statusCode == 200 && histRes.statusCode == 200) {
        final dashData = jsonDecode(dashRes.body);
        final histData = jsonDecode(histRes.body);

        if (dashData['success'] == true && histData['success'] == true) {
          if (mounted) {
            setState(() {
              dashboardData = dashData['data'];
              allAttendance = histData['data'] ?? [];
              _filterBySemester();
              isLoading = false;
            });
          }
        }
      } else if (dashRes.statusCode == 401) {
        await _handleLogout();
      } else {
        throw Exception('Failed to fetch data');
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          isLoading = false;
          hasError = true;
          errorMessage = e.toString();
        });
      }
    }
  }

  void _filterBySemester() {
    semesterAttendance = allAttendance.where((a) {
      final sem = a['semester']?.toString() ?? '1';
      return sem == selectedSemester.toString();
    }).toList();
    _buildAttendanceMap();
  }

  void _buildAttendanceMap() {
    _attendanceMap.clear();
    for (var record in semesterAttendance) {
      if (record['date'] != null) {
        final parsed = DateTime.tryParse(record['date']);
        if (parsed != null) {
          final normalized = DateTime.utc(parsed.year, parsed.month, parsed.day);
          _attendanceMap.putIfAbsent(normalized, () => []).add(record);
        }
      }
    }
  }

  Map<String, int> _calculateSemesterStats() {
    int total = semesterAttendance.length;
    int present = semesterAttendance.where((a) => a['status'] == 'PRESENT' || a['status'] == 'LATE' || a['status'] == 'OD').length;
    int absent = semesterAttendance.where((a) => a['status'] == 'ABSENT').length;
    int percentage = total > 0 ? ((present / total) * 100).round() : 0;
    return {'total': total, 'present': present, 'absent': absent, 'percentage': percentage};
  }

  List<dynamic>? _getAttendanceForDay(DateTime day) {
    final normalized = DateTime.utc(day.year, day.month, day.day);
    return _attendanceMap[normalized];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC), 
      body: RefreshIndicator(
        onRefresh: fetchDashboardData,
        color: const Color(0xFF4F46E5),
        edgeOffset: 100,
        child: _buildBody(),
      ),
      floatingActionButton: _buildFAB(),
    );
  }

  Widget _buildEliteBackground() {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF4F46E5), Color(0xFF6366F1)], 
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(40),
          bottomRight: Radius.circular(40),
        ),
      ),
    );
  }

  Widget _buildFAB() {
    return Container(
      margin: const EdgeInsets.only(bottom: 24, right: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B), // Dark Navy for contrast in light theme
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(color: const Color(0xFF1E293B).withOpacity(0.2), blurRadius: 20, offset: const Offset(0, 10))
        ],
      ),
      child: FloatingActionButton.extended(
        onPressed: () => Navigator.pushNamed(context, Routes.markAttendance).then((_) => fetchDashboardData()),
        backgroundColor: Colors.transparent,
        elevation: 0,
        label: Text('MARK ATTENDANCE', 
          style: GoogleFonts.inter(fontWeight: FontWeight.w900, color: Colors.white, letterSpacing: 1.2, fontSize: 13)),
        icon: const Icon(Icons.qr_code_scanner_rounded, color: Colors.white, size: 20),
      ),
    ).animate().scale(delay: 800.ms);
  }

  Widget _buildBody() {
    if (isLoading && dashboardData == null) {
      return const Center(child: CircularProgressIndicator(color: Colors.white70));
    }
    return _buildDashboardContent();
  }

  Widget _buildDashboardContent() {
    final stats = _calculateSemesterStats();
    final name = dashboardData?['user']?['name'] ?? 'Scholar';
    final overall = dashboardData?['stats']?['percentage'] ?? 0;

    return CustomScrollView(
      slivers: [
        SliverAppBar(
          expandedHeight: 100,
          backgroundColor: Colors.transparent,
          elevation: 0,
          pinned: false,
          floating: true,
          flexibleSpace: FlexibleSpaceBar(
            background: _buildEliteBackground(),
            collapseMode: CollapseMode.pin,
          ),
          leadingWidth: 70,
          leading: const Padding(
            padding: EdgeInsets.only(left: 20),
            child: CircleAvatar(
              backgroundColor: Colors.white24,
              child: Icon(Icons.shield_rounded, color: Colors.white),
            ),
          ),
          title: Text('STUDENT DASHBOARD', 
            style: GoogleFonts.inter(fontWeight: FontWeight.bold, color: Colors.white.withOpacity(0.9), fontSize: 12, letterSpacing: 1.5)),
          actions: [
            Padding(
              padding: const EdgeInsets.only(right: 15),
              child: IconButton(
                onPressed: _handleLogout,
                icon: const Icon(Icons.power_settings_new_rounded, color: Colors.white),
              ),
            ),
          ],
        ),

        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 32.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Welcome Back!', style: GoogleFonts.inter(color: Colors.black.withOpacity(0.7), fontSize: 13, fontWeight: FontWeight.w500)),
                const SizedBox(height: 4),
                Text(name, 
                  style: GoogleFonts.inter(color: Colors.black, fontSize: 30, fontWeight: FontWeight.w900)),
                const SizedBox(height: 38),

                _buildStatGrid(stats, overall),

                const SizedBox(height: 40),

                _buildCalendarSection(),
                
                const SizedBox(height: 120),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStatGrid(Map<String, int> stats, dynamic overall) {
    return Row(
      children: [
        Expanded(
          child: _buildInfoCard(
            'TOTAL LOAD', 
            '$overall%', 
            Icons.speed_rounded,
            const Color(0xFF4F46E5),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _buildInfoCard(
            'CURR SEM', 
            '${stats['percentage']}%', 
            Icons.auto_graph_rounded,
            const Color(0xFF8B5CF6),
          ),
        ),
      ],
    ).animate().fadeIn(duration: 600.ms).slideY(begin: 0.1);
  }

  Widget _buildInfoCard(String title, String val, IconData icon, Color accentColor) {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(color: const Color(0xFF1E293B).withOpacity(0.03), blurRadius: 20, offset: const Offset(0, 10))
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(color: accentColor.withOpacity(0.1), shape: BoxShape.circle),
            child: Icon(icon, color: accentColor, size: 20),
          ),
          const SizedBox(height: 20),
          Text(val, style: GoogleFonts.inter(color: const Color(0xFF0F172A), fontSize: 24, fontWeight: FontWeight.w900)),
          Text(title, style: GoogleFonts.inter(color: const Color(0xFF64748B), fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 0.8)),
        ],
      ),
    );
  }

  Widget _buildCalendarSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('ACTIVITY LOG', 
              style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w900, color: const Color(0xFF0F172A), letterSpacing: 1)),
            _buildSemesterPicker(),
          ],
        ),
        const SizedBox(height: 20),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(30),
            border: Border.all(color: const Color(0xFFE2E8F0)),
            boxShadow: [
              BoxShadow(color: const Color(0xFF1E293B).withOpacity(0.04), blurRadius: 40, offset: const Offset(0, 15))
            ],
          ),
          child: Column(
            children: [
              TableCalendar(
                firstDay: DateTime.utc(2023, 1, 1),
                lastDay: DateTime.utc(2030, 12, 31),
                focusedDay: _focusedDay,
                selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
                onDaySelected: (selectedDay, focusedDay) {
                  setState(() {
                    _selectedDay = selectedDay;
                    _focusedDay = focusedDay;
                  });
                },
                calendarStyle: CalendarStyle(
                  outsideDaysVisible: false,
                  defaultTextStyle: GoogleFonts.inter(color: const Color(0xFF334155), fontWeight: FontWeight.w500),
                  weekendTextStyle: GoogleFonts.inter(color: Colors.redAccent),
                  todayDecoration: BoxDecoration(color: const Color(0xFF4F46E5).withOpacity(0.1), shape: BoxShape.circle),
                  selectedDecoration: const BoxDecoration(color: Color(0xFF4F46E5), shape: BoxShape.circle),
                  todayTextStyle: const TextStyle(color: Color(0xFF4F46E5), fontWeight: FontWeight.bold),
                ),
                headerStyle: HeaderStyle(
                  formatButtonVisible: false,
                  titleCentered: true,
                  titleTextStyle: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 17, color: const Color(0xFF0F172A)),
                  leftChevronIcon: const Icon(Icons.chevron_left_rounded, color: Color(0xFF64748B)),
                  rightChevronIcon: const Icon(Icons.chevron_right_rounded, color: Color(0xFF64748B)),
                ),
                calendarBuilders: CalendarBuilders(
                  markerBuilder: (context, date, events) {
                    final records = _getAttendanceForDay(date);
                    if (records == null || records.isEmpty) return null;
                    final isPresent = records.every((r) => r['status'] != 'ABSENT');
                    return Container(
                      margin: const EdgeInsets.only(bottom: 6),
                      width: 5,
                      height: 5,
                      decoration: BoxDecoration(
                        color: isPresent ? const Color(0xFF10B981) : const Color(0xFFEF4444),
                        shape: BoxShape.circle,
                      ),
                    );
                  },
                ),
              ),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 30),
                child: Divider(height: 1, color: Color(0xFFF1F5F9)),
              ),
              _buildDayDetailList(),
            ],
          ),
        ).animate().fadeIn(delay: 200.ms).slideY(begin: 0.1),
      ],
    );
  }

  Widget _buildSemesterPicker() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        color: const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(12),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<int>(
          value: selectedSemester,
          items: [1,2,3,4,5,6,7,8].map((e) => DropdownMenuItem(value: e, child: Text('SEM $e', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold)))).toList(),
          onChanged: (val) {
            setState(() {
              selectedSemester = val!;
              _filterBySemester();
            });
          },
          style: GoogleFonts.inter(color: const Color(0xFF4F46E5)),
          icon: const Icon(Icons.keyboard_arrow_down_rounded, color: Color(0xFF4F46E5), size: 16),
        ),
      ),
    );
  }

  Widget _buildDayDetailList() {
    if (_selectedDay == null) return const SizedBox.shrink();
    final records = _getAttendanceForDay(_selectedDay!) ?? [];
    
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: List.generate(8, (index) {
          final period = index + 1;
          final record = records.firstWhere((r) => r['period'] == period, orElse: () => null);
          
          return Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Row(
              children: [
                _buildPeriodAvatar(period, record?['status']),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(record?['subject'] ?? 'Self Study Session', 
                        style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 14, color: const Color(0xFF1E293B))),
                      Text(record?['time'] ?? 'No activity logged', style: GoogleFonts.inter(color: const Color(0xFF94A3B8), fontSize: 10)),
                    ],
                  ),
                ),
                _buildStatusIndicator(record?['status']),
              ],
            ),
          ).animate(delay: (index * 40).ms).fadeIn().slideX(begin: -0.05);
        }),
      ),
    );
  }

  Widget _buildPeriodAvatar(int period, String? status) {
    Color color = const Color(0xFFF1F5F9);
    if (status == 'PRESENT') color = const Color(0xFF10B981).withOpacity(0.08);
    if (status == 'ABSENT') color = const Color(0xFFEF4444).withOpacity(0.08);

    return Container(
      width: 42,
      height: 42,
      decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(12)),
      child: Center(child: Text('$period', style: GoogleFonts.inter(fontWeight: FontWeight.w900, fontSize: 14, color: const Color(0xFF64748B)))),
    );
  }

  Widget _buildStatusIndicator(String? status) {
    if (status == null) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(color: const Color(0xFFF1F5F9), borderRadius: BorderRadius.circular(10)),
        child: Text('PENDING', style: GoogleFonts.inter(fontSize: 8, fontWeight: FontWeight.bold, color: const Color(0xFF94A3B8))),
      );
    }
    
    Color color = status == 'ABSENT' ? const Color(0xFFEF4444) : const Color(0xFF10B981);
    if (status == 'OD') color = const Color(0xFF3B82F6);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
      child: Text(status, style: GoogleFonts.inter(fontSize: 9, fontWeight: FontWeight.w900, color: color, letterSpacing: 0.5)),
    );
  }
}