import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();
  String _message = '';
  bool _isRegistering = false;

  // Pastikan URL API Anda benar
  // - Emulator Android: 'http://10.0.2.2/TGS/register.php'
  // - Perangkat Fisik: 'http://<IP_PC_ANDA>/TGS/register.php' (contoh: http://192.168.1.100/TGS/register.php)
  // - iOS Simulator: 'http://127.0.0.1/TGS/register.php'
  final String apiUrl = 'http://192.168.1.17/TGS/register.php'; // <--- SESUAIKAN INI

  Future<void> _register() async {
    setState(() {
      _isRegistering = true;
      _message = '';
    });

    final username = _usernameController.text;
    final password = _passwordController.text;
    final confirmPassword = _confirmPasswordController.text;

    if (password != confirmPassword) {
      setState(() {
        _message = 'Password dan konfirmasi password tidak cocok.';
        _isRegistering = false;
      });
      return;
    }

    if (username.isEmpty || password.isEmpty) {
      setState(() {
        _message = 'Username dan password tidak boleh kosong.';
        _isRegistering = false;
      });
      return;
    }

  try {
    final response = await http.post(
      Uri.parse(apiUrl),
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
      },
      body: jsonEncode(<String, String>{ // Pastikan ini menggunakan jsonEncode
        'username': username,
        'password': password,
      }),
      );
      

      print('Register Response Status Code: ${response.statusCode}');
      print('Register Response Body: ${response.body}');

      if (response.statusCode == 200 || response.statusCode == 201) { // <--- UBAH BARIS INI
        final Map<String, dynamic> data = json.decode(response.body);
        if (data['status'] == 'success') {
          setState(() {
            _message = 'Registrasi berhasil! Silakan login.';
          });
          // Kembali ke halaman login setelah registrasi berhasil
          Navigator.pop(context);
        } else {
          setState(() {
            _message = data['message'] ?? 'Registrasi gagal, coba lagi.';
          });
        }
      } else {
        setState(() {
          _message = 'Error: ${response.statusCode}. Gagal terhubung ke server. Detail: ${response.body}';
        });
      }
    } catch (e) {
      setState(() {
        _message = 'Error koneksi: $e';
      });
      print('Catch Register Error: $e');
    } finally {
      setState(() {
        _isRegistering = false;
      });
    }
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Register'),
        backgroundColor: Colors.black,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF00FFFF)),
          onPressed: () {
            Navigator.pop(context); // Kembali ke halaman sebelumnya (login)
          },
        ),
      ),
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Background dengan CustomPaint untuk grid overlay
          CustomPaint(
            painter: GridOverlayPainter(), // GridOverlayPainter dari main.dart
            child: Container(),
          ),
          Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  maxWidth: 400,
                  minHeight: MediaQuery.of(context).size.height * 0.6,
                ),
                child: IntrinsicHeight(
                  child: Container(
                    padding: const EdgeInsets.all(24.0),
                    decoration: BoxDecoration(
                      color: Color.fromARGB((255 * 0.15).round(), 0, 255, 255),
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
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'REGISTER NEW ACCOUNT',
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            color: const Color(0xFF00FF00),
                            fontSize: 24,
                            letterSpacing: 2,
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
                        TextField(
                          controller: _confirmPasswordController,
                          obscureText: true,
                          decoration: const InputDecoration(
                            labelText: 'Confirm Password',
                            prefixIcon: Icon(Icons.lock_reset, color: Color(0xFF00FFFF)),
                          ),
                          style: const TextStyle(color: Colors.white),
                        ),
                        const SizedBox(height: 20.0),
                        _isRegistering
                            ? const CircularProgressIndicator(
                                valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF00FFFF)),
                              )
                            : Container(),

                        _message.isNotEmpty
                            ? Padding(
                                padding: const EdgeInsets.symmetric(vertical: 10.0),
                                child: Text(
                                  _message,
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    color: _message.contains('berhasil') ? Colors.greenAccent : Colors.redAccent,
                                    fontSize: 14,
                                  ),
                                ),
                              )
                            : Container(),

                        const SizedBox(height: 30.0),
                        ElevatedButton(
                          onPressed: _isRegistering ? null : _register,
                          child: const Text('Register'),
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

// Reuse GridOverlayPainter from main.dart
// Untuk menghindari duplikasi, Anda bisa memindahkan GridOverlayPainter ke file utilitas terpisah
// atau cukup salin tempel jika Anda yakin tidak akan ada perubahan di painter ini.
// Untuk saat ini, saya asumsikan Anda akan menyalinnya dari main.dart.
class GridOverlayPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final Paint paint = Paint()
      ..color = Color.fromARGB((255 * 0.1).round(), 0, 255, 255)
      ..strokeWidth = 1.0;

    const double gridSize = 50.0;

    for (double i = 0; i < size.width; i += gridSize) {
      canvas.drawLine(Offset(i, 0), Offset(i, size.height), paint);
    }

    for (double i = 0; i < size.height; i += gridSize) {
      canvas.drawLine(Offset(0, i), Offset(size.width, i), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return false;
  }
}
