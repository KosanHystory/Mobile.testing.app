import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:wigga/dashboard.dart'; // Pastikan import ini ada dan benar
import 'package:wigga/register.dart';
void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Cyber Login App',
      theme: ThemeData(
        brightness: Brightness.dark,
        primaryColor: const Color(0xFF00FFFF),
        scaffoldBackgroundColor: Colors.black,
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.black,
          foregroundColor: Color(0xFF00FFFF),
        ),
        textTheme: const TextTheme(
          bodyLarge: TextStyle(color: Color(0xFF00FFFF)),
          bodyMedium: TextStyle(color: Color(0xFF00FFFF)),
          titleLarge: TextStyle(color: Color(0xFF00FF00), fontWeight: FontWeight.bold),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Color.fromARGB((255 * 0.1).round(), 0, 255, 255),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10.0),
            borderSide: const BorderSide(color: Color(0xFF00FFFF), width: 1.0),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10.0),
            borderSide: const BorderSide(color: Color(0xFF00FFFF), width: 1.0),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10.0),
            borderSide: const BorderSide(color: Color(0xFF00FFFF), width: 2.0),
          ),
          labelStyle: const TextStyle(color: Color(0xFF00FFFF)),
          hintStyle: const TextStyle(color: Colors.white70),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF00FFFF),
            foregroundColor: Colors.black,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10.0),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 15),
            textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
        ),
      ),
      home: const LoginPage(),
    );
  }
}

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  String _message = '';
  bool _isConnecting = false;

  Future<void> _login() async {
    setState(() {
      _isConnecting = true;
      _message = '';
    });

    final username = _usernameController.text;
    final password = _passwordController.text;

    try {
      final response = await http.post(
        Uri.parse('http://192.168.1.17/TGS/login.php'), // Sesuaikan dengan URL login.php Anda
        headers: <String, String>{
          'Content-Type': 'application/json; charset=UTF-8',
        },
        body: jsonEncode(<String, String>{ // Menggunakan jsonEncode untuk mengubah Map menjadi string JSON
          'username': username,
          'password': password,
        }),
      );
      print('Response Status Code: ${response.statusCode}');
      print('Response Body: ${response.body}');
      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        if (data['status'] == 'success') {
          setState(() {
            _message = 'Login berhasil!';
          });
          // Navigasi ke DashboardScreen
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const DashboardPage()),
          );
        } else {
          setState(() {
            _message = data['message'] ?? 'Login gagal, coba lagi.';
          });
        }
      } else {
        setState(() {
          _message = 'Error: ${response.statusCode}. Gagal terhubung ke server.';
        });
      }
    } catch (e) {
      setState(() {
        _message = 'Error koneksi: $e';
      });
    } finally {
      setState(() {
        _isConnecting = false;
      });
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
    return Scaffold(
      body: Stack(
        children: [
          // Background dengan CustomPaint untuk grid overlay
          CustomPaint(
            painter: GridOverlayPainter(),
            child: Container(), // Container kosong agar painter bisa menggambar
          ),
          Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  maxWidth: 400, // Lebar maksimum form
                  minHeight: MediaQuery.of(context).size.height * 0.7, // Minimal tinggi form
                ),
                child: IntrinsicHeight( // Agar Column menyesuaikan tinggi child-nya
                  child: Container(
                    padding: const EdgeInsets.all(24.0),
                    decoration: BoxDecoration(
                      color: Color.fromARGB((255 * 0.15).round(), 0, 255, 255), // Warna latar belakang form
                      borderRadius: BorderRadius.circular(15.0),
                      border: Border.all(color: const Color(0xFF00FFFF), width: 2.0),
                      boxShadow: [
                        BoxShadow(
                          color: Color.fromARGB((255 * 0.4).round(), 0, 255, 255),
                          blurRadius: 20.0,
                          spreadRadius: 5.0,
                        ),
                      ],
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      mainAxisSize: MainAxisSize.min, // Sesuaikan tinggi dengan konten
                      children: [
                        Text(
                          'CYBER WIGGA',
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            color: const Color(0xFF00FF00), // Warna teks hijau cyber
                            fontSize: 32,
                            letterSpacing: 3,
                          ),
                        ),
                        const SizedBox(height: 30.0),
                        TextField(
                          controller: _usernameController,
                          decoration: const InputDecoration(
                            labelText: 'Username',
                            prefixIcon: Icon(Icons.person, color: Color(0xFF00FFFF)),
                          ),
                          style: const TextStyle(color: Colors.white),
                        ),
                        const SizedBox(height: 20.0),
                        TextField(
                          controller: _passwordController,
                          obscureText: true,
                          decoration: const InputDecoration(
                            labelText: 'Password',
                            prefixIcon: Icon(Icons.lock, color: Color(0xFF00FFFF)),
                          ),
                          style: const TextStyle(color: Colors.white),
                        ),
                        const SizedBox(height: 20.0),
                        _isConnecting
                            ? const CircularProgressIndicator(
                                valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF00FFFF)),
                              )
                            : Container(), // Kosong jika tidak connecting

                        _message.isNotEmpty
                            ? Padding(
                                padding: const EdgeInsets.symmetric(vertical: 10.0),
                                child: Text(
                                  _message,
                                  style: TextStyle(
                                    color: _message.contains('berhasil') ? Colors.greenAccent : Colors.redAccent,
                                    fontSize: 14,
                                  ),
                                ),
                              )
                            : Container(), // Kosong jika tidak ada pesan

                        const SizedBox(height: 30.0),
                        ElevatedButton(
                          onPressed: _isConnecting ? null : _login,
                          child: const Text('Login'),
                        ),
                        const SizedBox(height: 15.0), // Spasi antara tombol login dan register

                        TextButton(
                          onPressed: () {
                            // Navigasi ke halaman Register
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (context) => const RegisterPage()),
                            );
                          },
                          child: const Text(
                            'Go to Register',
                            style: TextStyle(color: Color(0xFF00FFFF)),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// Painter untuk Grid Overlay di background
class GridOverlayPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final Paint paint = Paint()
      ..color = Color.fromARGB((255 * 0.1).round(), 0, 255, 255) // Warna garis grid
      ..strokeWidth = 1.0; // Ketebalan garis

    const double gridSize = 50.0; // Ukuran kotak grid

    // Gambar garis vertikal
    for (double i = 0; i < size.width; i += gridSize) {
      canvas.drawLine(Offset(i, 0), Offset(i, size.height), paint);
    }

    // Gambar garis horizontal
    for (double i = 0; i < size.height; i += gridSize) {
      canvas.drawLine(Offset(0, i), Offset(size.width, i), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return false; // Grid tidak perlu digambar ulang kecuali ukuran berubah
  }
}
