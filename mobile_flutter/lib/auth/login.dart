import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../screens/home_screen.dart';
import '../screens_admin/admin_home_screen.dart'; // Import the new Admin Home
import '../providers/auth_provider.dart';

class Login extends StatefulWidget {
  const Login({super.key});

  @override
  State<Login> createState() => _LoginState();
}

class _LoginState extends State<Login> {
  final _formKey = GlobalKey<FormState>();

  // Renamed controllers to be generic for both modes
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  bool _obscurePassword = true;
  bool _rememberMe = false;
  bool _isCheckingAuth = true;
  bool _isAdminLogin = false; // Toggle state

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final auth = context.read<AuthProvider>();

      if (auth.savedEmail != null) {
        _usernameController.text = auth.savedEmail!;
        if (mounted) {
          setState(() => _rememberMe = auth.rememberMe);
        }
      }
      final isLoggedIn = await auth.tryAutoLogin();

      if (!mounted) return;

      if (isLoggedIn) {
        _navigateBasedOnRole(auth.user?.adminLevel ?? 0);
      } else {
        setState(() => _isCheckingAuth = false);
      }
    });
  }

  void _navigateBasedOnRole(int adminLevel) {
    final isAdmin = adminLevel > 0;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) =>
            isAdmin ? const AdminHomeScreen() : const HomeScreen(),
      ),
    );
  }

  Future<void> _performLogin() async {
    if (!_formKey.currentState!.validate()) return;

    final identifier = _usernameController.text.trim();
    final password = _passwordController.text.trim();
    final auth = context.read<AuthProvider>();

    final success = await auth.login(
      identifier,
      password,
      remember: _rememberMe,
    );

    if (!mounted) return;

    if (success) {
      final adminLevel = auth.user?.adminLevel ?? 0;
      _navigateBasedOnRole(adminLevel);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _isAdminLogin
                ? 'Invalid Admin Credentials'
                : 'Invalid Student ID or LRN',
          ),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isCheckingAuth) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final size = MediaQuery.of(context).size;
    final isLoading = context.watch<AuthProvider>().isLoading;
    final theme = Theme.of(context);

    return Scaffold(
      body: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        child: Container(
          width: double.infinity,
          height: double.infinity,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                theme.colorScheme.primary,
                theme.colorScheme.primaryContainer,
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              // Background Decor
              Positioned(top: -80, left: -60, child: _buildCircleDecor(220)),
              Positioned(top: 40, right: -20, child: _buildCircleDecor(96)),

              // Login Card
              Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 32,
                  ),
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      maxWidth: size.width < 500 ? size.width : 420,
                    ),
                    child: Card(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      elevation: 16,
                      color: Colors.white,
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            const SizedBox(height: 6),

                            // Logo Area
                            Center(
                              child: Column(
                                children: [
                                  CircleAvatar(
                                    radius: 36,
                                    backgroundColor:
                                        theme.colorScheme.primaryContainer,
                                    child: Icon(
                                      Icons.school,
                                      size: 36,
                                      color: theme.colorScheme.primary,
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                  const Text(
                                    'ISUVENTRA',
                                    style: TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 18),

                            // Role Toggle
                            Container(
                              decoration: BoxDecoration(
                                color: Colors.grey.shade100,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: Colors.grey.shade300),
                              ),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: _buildRoleButton('Student', false),
                                  ),
                                  Expanded(
                                    child: _buildRoleButton('Admin', true),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 18),

                            // Form
                            Form(
                              key: _formKey,
                              child: Column(
                                children: [
                                  // Username / Student ID Field
                                  TextFormField(
                                    controller: _usernameController,
                                    keyboardType: _isAdminLogin
                                        ? TextInputType.emailAddress
                                        : TextInputType.text,
                                    decoration: InputDecoration(
                                      prefixIcon: Icon(
                                        _isAdminLogin
                                            ? Icons.email_outlined
                                            : Icons.badge_outlined,
                                      ),
                                      labelText: _isAdminLogin
                                          ? 'Email Address'
                                          : 'Student ID',
                                      hintText: _isAdminLogin
                                          ? 'admin@isu.edu.ph'
                                          : '25-XXXX',
                                      border: const OutlineInputBorder(),
                                    ),
                                    validator: (value) {
                                      if (value == null ||
                                          value.trim().isEmpty) {
                                        return _isAdminLogin
                                            ? 'Please enter your Email'
                                            : 'Please enter your Student ID';
                                      }
                                      return null;
                                    },
                                    enabled: !isLoading,
                                  ),
                                  const SizedBox(height: 12),

                                  // Password / LRN Field
                                  TextFormField(
                                    controller: _passwordController,
                                    obscureText: _obscurePassword,
                                    keyboardType: _isAdminLogin
                                        ? TextInputType.text
                                        : TextInputType.number,
                                    decoration: InputDecoration(
                                      prefixIcon: const Icon(
                                        Icons.lock_outline,
                                      ),
                                      labelText: _isAdminLogin
                                          ? 'Password'
                                          : 'LRN (Password)',
                                      border: const OutlineInputBorder(),
                                      suffixIcon: IconButton(
                                        icon: Icon(
                                          _obscurePassword
                                              ? Icons.visibility_off
                                              : Icons.visibility,
                                        ),
                                        onPressed: () => setState(
                                          () => _obscurePassword =
                                              !_obscurePassword,
                                        ),
                                      ),
                                    ),
                                    validator: (value) {
                                      if (value == null || value.isEmpty) {
                                        return _isAdminLogin
                                            ? 'Please enter password'
                                            : 'Please enter your LRN';
                                      }
                                      if (!_isAdminLogin && value.length < 6) {
                                        return 'LRN must be at least 6 characters';
                                      }
                                      return null;
                                    },
                                    enabled: !isLoading,
                                  ),
                                  const SizedBox(height: 10),

                                  Row(
                                    children: [
                                      Checkbox(
                                        value: _rememberMe,
                                        onChanged: (v) => setState(
                                          () => _rememberMe = v ?? false,
                                        ),
                                      ),
                                      const SizedBox(width: 4),
                                      const Text('Remember me'),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 6),

                            // Submit Button
                            SizedBox(
                              height: 48,
                              child: ElevatedButton(
                                onPressed: isLoading ? null : _performLogin,
                                style: ElevatedButton.styleFrom(
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  backgroundColor: theme.colorScheme.primary,
                                  foregroundColor: theme.colorScheme.onPrimary,
                                ),
                                child: isLoading
                                    ? SizedBox(
                                        width: 24,
                                        height: 24,
                                        child: CircularProgressIndicator(
                                          color: theme.colorScheme.onPrimary,
                                          strokeWidth: 2,
                                        ),
                                      )
                                    : const Text(
                                        'Sign In',
                                        style: TextStyle(fontSize: 16),
                                      ),
                              ),
                            ),
                            const SizedBox(height: 12),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRoleButton(String title, bool isForAdmin) {
    final isSelected = _isAdminLogin == isForAdmin;
    return GestureDetector(
      onTap: () {
        setState(() {
          _isAdminLogin = isForAdmin;
          _formKey.currentState?.reset(); // Clear errors when switching
          _usernameController.clear();
          _passwordController.clear();
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(6),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: Colors.black12,
                    blurRadius: 4,
                    offset: Offset(0, 1),
                  ),
                ]
              : [],
        ),
        child: Text(
          title,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            color: isSelected ? Colors.black87 : Colors.black54,
          ),
        ),
      ),
    );
  }

  Widget _buildCircleDecor(double size) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          colors: [
            const Color.fromRGBO(255, 255, 255, 0.06),
            const Color.fromRGBO(255, 255, 255, 0.02),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
    );
  }
}
