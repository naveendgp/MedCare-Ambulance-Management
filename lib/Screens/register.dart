import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:hive_flutter/hive_flutter.dart';

class Register extends StatefulWidget {
  const Register({super.key});

  @override
  State<Register> createState() => _Register();
}

class _Register extends State<Register> {
  bool isLogin = true;
  bool isLoading = false;
  String? errorMessage;

  final _formKey = GlobalKey<FormState>();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _nameController = TextEditingController();

  late Box userBox;

  @override
  void initState() {
    super.initState();
    _initHive();
  }

  Future<void> _initHive() async {
    await Hive.initFlutter();
    userBox = await Hive.openBox('users');
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  // Check if user exists in Hive
  bool _userExists(String email, String password) {
    final user = userBox.get(email);
    if (user != null && user['password'] == password) {
      return true;
    }
    return false;
  }

  // Register user in Hive
  Future<void> _registerUser(String name, String email, String password) async {
    await userBox.put(email, {
      'name': name,
      'email': email,
      'password': password,
    });
  }

  // Sign in method using Hive
  Future<void> _signIn() async {
    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    await Future.delayed(Duration(milliseconds: 500));
    if (_userExists(_emailController.text, _passwordController.text)) {
      // Store current user email to Hive
      await Hive.box('users').put('current_user_email', _emailController.text);
      Navigator.pushReplacementNamed(context, "/home");
    } else {
      setState(() {
        errorMessage =
            "Invalid email or password. Please sign up if you don't have an account.";
      });
    }
    setState(() {
      isLoading = false;
    });
  }

  // Register method using Hive
  Future<void> _register() async {
    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    await Future.delayed(Duration(milliseconds: 500));
    if (_emailController.text.isNotEmpty &&
        _passwordController.text.length >= 6 &&
        _nameController.text.isNotEmpty) {
      if (userBox.containsKey(_emailController.text)) {
        setState(() {
          errorMessage = "User already exists. Please login.";
        });
      } else {
        await _registerUser(
          _nameController.text,
          _emailController.text,
          _passwordController.text,
        );
        Navigator.pushReplacementNamed(context, "/home");
      }
    } else {
      setState(() {
        errorMessage = "Registration failed. Please check your details.";
      });
    }
    setState(() {
      isLoading = false;
    });
  }

  // Dummy reset password method
  Future<void> _resetPassword() async {
    if (_emailController.text.isEmpty ||
        !RegExp(
          r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$',
        ).hasMatch(_emailController.text)) {
      setState(() {
        errorMessage = 'Please enter a valid email address for password reset';
      });
      return;
    }

    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    await Future.delayed(Duration(seconds: 1));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Password reset email (simulated) sent.'),
        backgroundColor: Colors.green,
      ),
    );
    setState(() {
      isLoading = false;
    });
  }

  // Navigate to driver login
  void _navigateToDriverLogin() {
    Navigator.pushNamed(context, "/driverLogin");
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Colors.blue.shade200, Colors.blue.shade800],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.local_hospital_rounded,
                      size: 100,
                      color: Colors.white,
                    ),
                    const SizedBox(height: 20),
                    Text(
                      'MedCare',
                      style: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    Text(
                      'Ambulance Management System',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.white.withOpacity(0.8),
                      ),
                    ),
                    const SizedBox(height: 40),
                    Container(
                      width: double.infinity,
                      constraints: BoxConstraints(maxWidth: 400),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.2),
                            blurRadius: 15,
                            spreadRadius: 1,
                          ),
                        ],
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(24.0),
                        child: Form(
                          key: _formKey,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                isLogin ? 'Welcome Back' : 'Create Account',
                                style: TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.blue.shade800,
                                ),
                              ),
                              const SizedBox(height: 5),
                              Text(
                                isLogin
                                    ? 'Sign in to continue'
                                    : 'Sign up to get started',
                                style: TextStyle(
                                  color: Colors.grey.shade600,
                                  fontSize: 14,
                                ),
                              ),
                              const SizedBox(height: 20),
                              if (errorMessage != null)
                                Container(
                                  width: double.infinity,
                                  padding: EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: Colors.red.shade50,
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(
                                      color: Colors.red.shade200,
                                    ),
                                  ),
                                  child: Text(
                                    errorMessage!,
                                    style: TextStyle(
                                      color: Colors.red.shade800,
                                      fontSize: 14,
                                    ),
                                  ),
                                ),
                              if (errorMessage != null)
                                const SizedBox(height: 20),
                              if (!isLogin) ...[
                                TextFormField(
                                  controller: _nameController,
                                  decoration: InputDecoration(
                                    labelText: 'Full Name',
                                    prefixIcon: Icon(Icons.person),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    focusedBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(10),
                                      borderSide: BorderSide(
                                        color: Colors.blue.shade800,
                                      ),
                                    ),
                                  ),
                                  validator: (value) {
                                    if (value == null || value.isEmpty) {
                                      return 'Please enter your name';
                                    }
                                    return null;
                                  },
                                ),
                                const SizedBox(height: 20),
                              ],
                              TextFormField(
                                controller: _emailController,
                                decoration: InputDecoration(
                                  labelText: 'Email',
                                  prefixIcon: Icon(Icons.email),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(10),
                                    borderSide: BorderSide(
                                      color: Colors.blue.shade800,
                                    ),
                                  ),
                                ),
                                keyboardType: TextInputType.emailAddress,
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return 'Please enter your email';
                                  }
                                  if (!RegExp(
                                    r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$',
                                  ).hasMatch(value)) {
                                    return 'Please enter a valid email';
                                  }
                                  return null;
                                },
                              ),
                              const SizedBox(height: 20),
                              TextFormField(
                                controller: _passwordController,
                                obscureText: true,
                                decoration: InputDecoration(
                                  labelText: 'Password',
                                  prefixIcon: Icon(Icons.lock),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(10),
                                    borderSide: BorderSide(
                                      color: Colors.blue.shade800,
                                    ),
                                  ),
                                ),
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return 'Please enter your password';
                                  }
                                  if (!isLogin && value.length < 6) {
                                    return 'Password must be at least 6 characters';
                                  }
                                  return null;
                                },
                              ),
                              const SizedBox(height: 15),
                              if (isLogin)
                                Align(
                                  alignment: Alignment.centerRight,
                                  child: TextButton(
                                    onPressed: _resetPassword,
                                    child: Text(
                                      'Forgot Password?',
                                      style: TextStyle(
                                        color: Colors.blue.shade800,
                                      ),
                                    ),
                                  ),
                                ),
                              const SizedBox(height: 20),
                              SizedBox(
                                width: double.infinity,
                                height: 50,
                                child: ElevatedButton(
                                  onPressed:
                                      isLoading
                                          ? null
                                          : () {
                                            if (_formKey.currentState!
                                                .validate()) {
                                              isLogin ? _signIn() : _register();
                                            }
                                          },
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.blue.shade800,
                                    foregroundColor: Colors.white,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    elevation: 3,
                                  ),
                                  child:
                                      isLoading
                                          ? CircularProgressIndicator(
                                            color: Colors.white,
                                            strokeWidth: 2,
                                          )
                                          : Text(
                                            isLogin ? 'Login' : 'Sign Up',
                                            style: TextStyle(fontSize: 16),
                                          ),
                                ),
                              ),
                              const SizedBox(height: 20),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    isLogin
                                        ? "Don't have an account? "
                                        : "Already have an account? ",
                                    style: TextStyle(
                                      color: Colors.grey.shade700,
                                    ),
                                  ),
                                  TextButton(
                                    onPressed: () {
                                      setState(() {
                                        isLogin = !isLogin;
                                        errorMessage = null;
                                      });
                                    },
                                    child: Text(
                                      isLogin ? 'Sign Up' : 'Login',
                                      style: TextStyle(
                                        color: Colors.blue.shade800,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 20),
                              // Driver login section
                              Divider(
                                color: Colors.grey.shade300,
                                thickness: 1,
                              ),
                              const SizedBox(height: 20),
                              Center(
                                child: Text(
                                  'Are you a driver?',
                                  style: TextStyle(
                                    color: Colors.grey.shade700,
                                    fontSize: 14,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 15),
                              SizedBox(
                                width: double.infinity,
                                height: 50,
                                child: ElevatedButton.icon(
                                  onPressed: _navigateToDriverLogin,
                                  icon: Icon(Icons.drive_eta),
                                  label: Text('Driver Login'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.green.shade700,
                                    foregroundColor: Colors.white,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    elevation: 2,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
