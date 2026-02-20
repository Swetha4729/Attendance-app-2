import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> with SingleTickerProviderStateMixin {
  final emailCtrl = TextEditingController();
  final passCtrl = TextEditingController();
  String role = 'STUDENT';
  
  late final AnimationController _animationController;
  late final Animation<double> _fadeAnimation;
  late final Animation<double> _slideAnimation;
  late final Animation<double> _scaleAnimation;
  
  bool _isAnimationInitialized = false;

  @override
  void initState() {
    super.initState();
    
    // Initialize animation controller immediately
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.0, 0.6, curve: Curves.easeOut),
      ),
    );
    
    _slideAnimation = Tween<double>(begin: 50.0, end: 0.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.2, 0.8, curve: Curves.easeOut),
      ),
    );
    
    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.4, 1.0, curve: Curves.elasticOut),
      ),
    );
    
    // Mark animation as initialized
    _isAnimationInitialized = true;
    
    // Start animation after build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_animationController.isDismissed) {
        _animationController.forward();
      }
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();

    return Scaffold(
      backgroundColor: const Color(0xFFF6F2FA),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: _isAnimationInitialized
              ? AnimatedBuilder(
                  animation: _animationController,
                  builder: (context, child) {
                    return Transform.translate(
                      offset: Offset(0, _slideAnimation.value),
                      child: Opacity(
                        opacity: _fadeAnimation.value,
                        child: Transform.scale(
                          scale: _scaleAnimation.value,
                          child: child,
                        ),
                      ),
                    );
                  },
                  child: _buildLoginForm(context, auth),
                )
              : _buildLoginForm(context, auth), // Show static form while animating
        ),
      ),
    );
  }

  Widget _buildLoginForm(BuildContext context, AuthProvider auth) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 20,
            offset: const Offset(0, 8),
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Animated Welcome Text
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 500),
            child: Text(
              'Welcome Back',
              key: const ValueKey('welcome'),
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.bold,
                color: Colors.deepPurple.shade800,
              ),
            ),
          ),

          const SizedBox(height: 6),

          // Subtitle with fade animation
          _isAnimationInitialized
              ? FadeTransition(
                  opacity: CurvedAnimation(
                    parent: _animationController,
                    curve: const Interval(0.3, 0.6, curve: Curves.easeIn),
                  ),
                  child: const Text(
                    'Login to continue',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.grey,
                      fontSize: 14,
                    ),
                  ),
                )
              : const Text(
                  'Login to continue',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.grey,
                    fontSize: 14,
                  ),
                ),

          const SizedBox(height: 32),

          // Email Field with slide animation
          _isAnimationInitialized
              ? SlideTransition(
                  position: Tween<Offset>(
                    begin: const Offset(-0.5, 0),
                    end: Offset.zero,
                  ).animate(
                    CurvedAnimation(
                      parent: _animationController,
                      curve: const Interval(0.2, 0.5, curve: Curves.easeOut),
                    ),
                  ),
                  child: FadeTransition(
                    opacity: CurvedAnimation(
                      parent: _animationController,
                      curve: const Interval(0.2, 0.5, curve: Curves.easeIn),
                    ),
                    child: _buildEmailField(),
                  ),
                )
              : _buildEmailField(),

          const SizedBox(height: 16),

          // Password Field with slide animation
          _isAnimationInitialized
              ? SlideTransition(
                  position: Tween<Offset>(
                    begin: const Offset(0.5, 0),
                    end: Offset.zero,
                  ).animate(
                    CurvedAnimation(
                      parent: _animationController,
                      curve: const Interval(0.3, 0.6, curve: Curves.easeOut),
                    ),
                  ),
                  child: FadeTransition(
                    opacity: CurvedAnimation(
                      parent: _animationController,
                      curve: const Interval(0.3, 0.6, curve: Curves.easeIn),
                    ),
                    child: _buildPasswordField(),
                  ),
                )
              : _buildPasswordField(),

          const SizedBox(height: 20),

          // Role Dropdown with slide animation
          _isAnimationInitialized
              ? SlideTransition(
                  position: Tween<Offset>(
                    begin: const Offset(-0.5, 0),
                    end: Offset.zero,
                  ).animate(
                    CurvedAnimation(
                      parent: _animationController,
                      curve: const Interval(0.4, 0.7, curve: Curves.easeOut),
                    ),
                  ),
                  child: FadeTransition(
                    opacity: CurvedAnimation(
                      parent: _animationController,
                      curve: const Interval(0.4, 0.7, curve: Curves.easeIn),
                    ),
                    child: _buildRoleDropdown(),
                  ),
                )
              : _buildRoleDropdown(),

          const SizedBox(height: 30),

          // Login Button with scale animation
          _isAnimationInitialized
              ? ScaleTransition(
                  scale: Tween<double>(begin: 0.8, end: 1.0).animate(
                    CurvedAnimation(
                      parent: _animationController,
                      curve: const Interval(0.6, 1.0, curve: Curves.elasticOut),
                    ),
                  ),
                  child: FadeTransition(
                    opacity: CurvedAnimation(
                      parent: _animationController,
                      curve: const Interval(0.6, 0.9, curve: Curves.easeIn),
                    ),
                    child: _buildLoginButton(context, auth),
                  ),
                )
              : _buildLoginButton(context, auth),
        ],
      ),
    );
  }

  Widget _buildEmailField() {
    return TextField(
      controller: emailCtrl,
      decoration: InputDecoration(
        labelText: 'Email',
        labelStyle: TextStyle(
          color: Colors.grey.shade600,
        ),
        prefixIcon: Icon(
          Icons.email_outlined,
          color: Colors.deepPurple.shade500,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: Colors.deepPurple.shade500,
            width: 2,
          ),
        ),
        filled: true,
        fillColor: Colors.grey.shade50,
      ),
    );
  }

  Widget _buildPasswordField() {
    return TextField(
      controller: passCtrl,
      obscureText: true,
      decoration: InputDecoration(
        labelText: 'Password',
        labelStyle: TextStyle(
          color: Colors.grey.shade600,
        ),
        prefixIcon: Icon(
          Icons.lock_outline,
          color: Colors.deepPurple.shade500,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: Colors.deepPurple.shade500,
            width: 2,
          ),
        ),
        filled: true,
        fillColor: Colors.grey.shade50,
      ),
    );
  }

  Widget _buildRoleDropdown() {
    return DropdownButtonFormField<String>(
      value: role,
      items: const [
        DropdownMenuItem(
          value: 'STUDENT',
          child: Text('STUDENT'),
        ),
        DropdownMenuItem(
          value: 'STAFF',
          child: Text('STAFF'),
        ),
      ],
      onChanged: (value) {
        setState(() => role = value!);
      },
      decoration: InputDecoration(
        prefixIcon: Icon(
          Icons.person_outline,
          color: Colors.deepPurple.shade500,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: Colors.deepPurple.shade500,
            width: 2,
          ),
        ),
        filled: true,
        fillColor: Colors.grey.shade50,
      ),
      dropdownColor: Colors.white,
      borderRadius: BorderRadius.circular(12),
      icon: Icon(
        Icons.arrow_drop_down,
        color: Colors.deepPurple.shade500,
      ),
    );
  }

  Widget _buildLoginButton(BuildContext context, AuthProvider auth) {
    return SizedBox(
      height: 50,
      child: ElevatedButton(
        onPressed: auth.isLoading
            ? null
            : () async {

                print("🚀 Login button pressed");
                print("📧 Email: ${emailCtrl.text.trim()}");
                print("👤 Role: $role");

                final ok = await auth.login(
                  emailCtrl.text.trim(),
                  passCtrl.text.trim(),
                  role,
                );

                print("✅ Login result from provider: $ok");

                if (!mounted) return;

                if (ok) {

                  print("➡️ Navigating to dashboard");

                  if (role == 'STUDENT') {
                    Navigator.pushReplacementNamed(context, '/student-dashboard');
                  } else {
                    Navigator.pushReplacementNamed(context, '/staff-dashboard');
                  }
                } else {
                  
                  print("❌ Login failed — showing snackbar");

                  ScaffoldMessenger.of(context).showSnackBar(
                    //const SnackBar(content: Text("Login failed")),
                    SnackBar(content: Text(auth.errorMessage ?? "Login failed")),
                  );
                }
              },
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.deepPurple,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(25),
          ),
          elevation: 4,
          shadowColor: Colors.deepPurple.withOpacity(0.4),
        ),
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 300),
          transitionBuilder: (child, animation) {
            return ScaleTransition(
              scale: animation,
              child: child,
            );
          },
          child: auth.isLoading
              ? const SizedBox(
                  key: ValueKey('loader'),
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.5,
                    valueColor: AlwaysStoppedAnimation(Colors.white),
                  ),
                )
              : const Text(
                  'Login',
                  key: ValueKey('text'),
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
        ),
      ),
    );
  }
}