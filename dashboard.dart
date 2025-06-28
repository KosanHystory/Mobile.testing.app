import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:async'; // Untuk Timer.periodic
import 'package:wigga/main.dart'; // Pastikan import ini ada dan benar untuk MyApp/LoginPage Anda
import 'package:wigga/creator.dart'; // Import halaman creator_page.dart

// --- Model Data untuk Sensor Ruangan ---
// Sesuaikan dengan struktur JSON yang akan dikembalikan oleh get_data.php Anda
class RoomData {
  final String roomId;
  final String roomName;
  final double currentTemp;
  final double minTemp;
  final double maxTemp;
  final double avgTemp;
  final String status;
  bool isLightOn; // Bisa berubah
  final String lastUpdate; // Menambahkan ini untuk timestamp

  RoomData({
    required this.roomId,
    required this.roomName,
    required this.currentTemp,
    required this.minTemp,
    required this.maxTemp,
    required this.avgTemp,
    required this.status,
    required this.isLightOn,
    required this.lastUpdate,
  });

  factory RoomData.fromJson(Map<String, dynamic> json) {
    return RoomData(
      roomId: json['room_id'] ?? '', // Default ke string kosong jika null
      roomName: json['room_name'] ?? 'Unknown Room', // Default ke 'Unknown Room' jika null
      currentTemp: (json['current_temp'] as num?)?.toDouble() ?? 0.0,
      minTemp: (json['min_temp'] as num?)?.toDouble() ?? 0.0,
      maxTemp: (json['max_temp'] as num?)?.toDouble() ?? 0.0,
      avgTemp: (json['avg_temp'] as num?)?.toDouble() ?? 0.0,
      status: json['status'] ?? 'offline',
      isLightOn: json['is_light_on'] ?? false,
      lastUpdate: json['last_update'] ?? 'N/A',
    );
  }
}

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  List<RoomData> _rooms = [];
  bool _isLoading = true;
  String? _errorMessage;
  late Timer _timer; // Deklarasi Timer

  // Daftar nama ruangan yang ingin ditampilkan
  final List<String> _desiredRoomNames = [
    "ruang kerja",
    "ruang tengah",
    "ruang kontrol",
    "kantor"
  ];

  @override
  void initState() {
    super.initState();
    _fetchData(); // Panggil fetch data segera setelah widget dibuat
    // Atur timer untuk memanggil _fetchData setiap 5 detik
    _timer = Timer.periodic(const Duration(seconds: 5), (Timer t) => _fetchData());
  }

  @override
  void dispose() {
    _timer.cancel(); // Pastikan timer dibatalkan saat widget dibuang
    super.dispose();
  }

  Future<void> _fetchData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // Sesuaikan URL ini berdasarkan lingkungan Anda:
      // - Untuk Aplikasi Web (Chrome/Browser di komputer yang sama dengan server PHP):
      //   Gunakan 'http://localhost/TGS/get_data.php' atau 'http://127.0.0.1/TGS/get_data.php'
      // - Untuk Android Emulator:
      //   Gunakan 'http://10.0.2.2/TGS/get_data.php'
      // - Untuk Perangkat Fisik (Android/iOS) atau iOS Simulator:
      //   Gunakan 'http://[ALAMAT_IP_KOMPUTER_ANDA]/TGS/get_data.php' (misal: 192.168.1.X)
      final response = await http.get(Uri.parse('http://192.168.1.17/TGS/get_data.php'));


      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = json.decode(response.body);

        if (responseData['status'] == 'success' && responseData['data'] is List) {
          List<RoomData> fetchedRooms = (responseData['data'] as List)
              .map((roomJson) => RoomData.fromJson(roomJson))
              .toList();

          setState(() {
            // Filter ruangan berdasarkan daftar _desiredRoomNames
            _rooms = fetchedRooms
                .where((room) => _desiredRoomNames.contains(room.roomName))
                .toList();
            _isLoading = false;
          });
        } else {
          setState(() {
            _errorMessage = responseData['message'] ?? 'Gagal memuat data: Format tidak sesuai atau status bukan sukses.';
            _isLoading = false;
          });
        }
      } else {
        setState(() {
          _errorMessage = 'Error koneksi: Status code ${response.statusCode}';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Error koneksi: ${e.toString()}. Pastikan server berjalan dan URL benar.';
        _isLoading = false;
      });
    }
  }

  // --- Fungsi Baru: Mengontrol Status Lampu ---
  Future<void> _toggleLightStatus(String roomId, bool currentStatus) async {
    // 1. Update UI secara optimistik (langsung di-update tanpa menunggu respons server)
    setState(() {
      int index = _rooms.indexWhere((room) => room.roomId == roomId);
      if (index != -1) {
        _rooms[index].isLightOn = !currentStatus; // Ubah status lokal
      }
    });

    try {
      // Sesuaikan URL ini berdasarkan lingkungan Anda:
      // - Untuk Aplikasi Web (Chrome/Browser di komputer yang sama dengan server PHP):
      //   Gunakan 'http://localhost/TGS/lampu.php' atau 'http://127.0.0.1/TGS/lampu.php'
      // - Untuk Android Emulator:
      //   Gunakan 'http://10.0.2.2/TGS/lampu.php'
      // - Untuk Perangkat Fisik (Android/iOS) atau iOS Simulator:
      //   Gunakan 'http://[ALAMAT_IP_KOMPUTER_ANDA]/TGS/lampu.php' (misal: 192.168.1.X)
      final response = await http.post(
        Uri.parse('http://192.168.1.17/TGS/lampu.php'), // URL ke file PHP baru
        headers: <String, String>{
          'Content-Type': 'application/json; charset=UTF-8',
        },
        body: jsonEncode(<String, dynamic>{
          'room_id': roomId,
          'is_light_on': !currentStatus ? 1 : 0, // Kirim 1 untuk ON, 0 untuk OFF
        }),
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = json.decode(response.body);
        if (responseData['status'] != 'success') {
          // Jika server melaporkan kegagalan, kembalikan status UI
          _revertLightStatus(roomId, currentStatus, responseData['message'] ?? 'Gagal memperbarui lampu.');
        }
        // Jika sukses, biarkan UI tetap terupdate secara optimistik
      } else {
        // Jika status code bukan 200, kembalikan status UI
        _revertLightStatus(roomId, currentStatus, 'Error server: ${response.statusCode}');
      }
    } catch (e) {
      // Jika terjadi error jaringan, kembalikan status UI
      _revertLightStatus(roomId, currentStatus, 'Gagal koneksi: ${e.toString()}');
    }
  }

  // Fungsi untuk mengembalikan status lampu di UI jika ada kegagalan dari server
  void _revertLightStatus(String roomId, bool originalStatus, String errorMessage) {
    setState(() {
      int index = _rooms.indexWhere((room) => room.roomId == roomId);
      if (index != -1) {
        _rooms[index].isLightOn = originalStatus; // Kembalikan status asli
      }
      _errorMessage = errorMessage; // Tampilkan pesan error
    });
    // Anda bisa menambahkan SnackBar atau dialog untuk menampilkan errorMessage
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Gagal: $errorMessage'),
        backgroundColor: Colors.red,
      ),
    );
  }

  // --- Widget untuk UI ---

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0E17), // Warna latar belakang gelap
      appBar: AppBar(
        title: const Text(
          'MONEYTORING',
          style: TextStyle(
            color: Color(0xFF00C3FF),
            fontWeight: FontWeight.bold,
            letterSpacing: 2,
          ),
        ),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: Color(0xFFE74C3C)), // Warna merah untuk logout
            onPressed: () {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => const LoginPage()),
              );
            },
          ),
        ],
      ),
      body: Stack(
        children: [
          // Overlay grid latar belakang
          CustomPaint(
            painter: GridOverlayPainter(),
            child: Container(), // Container kosong agar CustomPaint memiliki ukuran
          ),
          // Konten utama
          _isLoading
              ? const Center(
                  child: CircularProgressIndicator(
                    color: Color(0xFF00C3FF), // Warna loading cyber
                  ),
                )
              : _errorMessage != null
                  ? Center(
                      child: Text(
                        _errorMessage!,
                        style: const TextStyle(color: Colors.redAccent, fontSize: 16),
                        textAlign: TextAlign.center,
                      ),
                    )
                  : SingleChildScrollView(
                      padding: const EdgeInsets.all(16.0),
                      child: Center(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.center, // Pusatkan konten secara horizontal
                          children: [
                            const SizedBox(height: 20),
                            // Menggunakan Wrap untuk tata letak kartu yang responsif
                            Wrap(
                              alignment: WrapAlignment.center, // Pusatkan kartu jika ada ruang
                              spacing: 16.0, // Spasi horizontal antar kartu
                              runSpacing: 16.0, // Spasi vertikal antar baris kartu
                              children: _rooms.map((room) {
                                return _buildCyberBox(room);
                              }).toList(),
                            ),
                            const SizedBox(height: 30), // Spasi di bawah Wrap
                            // Tombol baru untuk Creator This App
                            ElevatedButton(
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(builder: (context) =>  CreatorPage()), // Menggunakan const karena CreatorPage sekarang const
                                );
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF00C3FF), // Warna latar belakang tombol
                                padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 15),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                shadowColor: const Color(0xFF00C3FF).withAlpha((255 * 0.5).round()), // Perbaikan withOpacity
                                elevation: 10,
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min, // Agar lebar tombol sesuai konten
                                children: [
                                  const Icon(Icons.person, color: Colors.black87), // Contoh ikon orang
                                  const SizedBox(width: 10),
                                  const Text(
                                    'Creator This App',
                                    style: TextStyle(
                                      color: Colors.black87, // Warna teks tombol
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
        ],
      ),
    );
  }

  // Widget untuk setiap "Cyber Box" ruangan
  Widget _buildCyberBox(RoomData room) {
    Color statusColor = Colors.grey; // Default abu-abu
    String statusText = "Offline";

    if (room.status.toLowerCase() == 'online' || room.currentTemp > 0) { // Logika status sederhana
      if (room.currentTemp < 18) {
        statusColor = const Color(0xFF00BFFF); // Biru terang untuk dingin
        statusText = "Cool";
      } else if (room.currentTemp >= 18 && room.currentTemp <= 28) {
        statusColor = const Color(0xFF00FF00); // Hijau untuk normal
        statusText = "Optimal";
      } else {
        statusColor = const Color(0xFFE74C3C); // Merah untuk panas
        statusText = "Hot";
      }
    } else {
      statusColor = Colors.grey;
      statusText = "Offline";
    }

    return Container(
      width: 180, // Ukuran kotak yang lebih ringkas
      padding: const EdgeInsets.all(12.0),
      decoration: BoxDecoration(
        color: const Color(0xFF1A2130), // Warna dasar kotak
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFF00C3FF), width: 1.0), // Border cyber
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF00C3FF).withAlpha((255 * 0.2).round()), // Perbaikan withOpacity
            blurRadius: 8,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Flexible( // Menggunakan Flexible agar tidak overflow
                child: Text(
                  room.roomName,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: const Color(0xFF00C3FF),
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                  overflow: TextOverflow.ellipsis, // Tambahkan ini jika nama ruangan sangat panjang
                ),
              ),
              Row(
                children: [
                  Container(
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(
                      color: statusColor,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    statusText,
                    style: TextStyle(
                      color: statusColor,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const Divider(color: Colors.white24, height: 16),
          _buildSensorInfo(Icons.thermostat, 'TEMPERATURE', [
            _buildTempDisplay(room.currentTemp),
            _buildTempStats('Min', room.minTemp),
            _buildTempStats('Max', room.maxTemp),
            _buildTempStats('Avg', room.avgTemp),
          ]),
          const SizedBox(height: 12),
          // --- KONTROL LAMPU ---
          _buildSensorInfo(Icons.lightbulb, 'LIGHTING', [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildValueDisplay(
                  room.isLightOn ? 'ON' : 'OFF',
                  room.isLightOn ? Colors.amberAccent : Colors.grey,
                ),
                IconButton(
                  icon: Icon(
                    room.isLightOn ? Icons.toggle_on : Icons.toggle_off,
                    color: room.isLightOn ? Colors.amberAccent : Colors.grey,
                    size: 36,
                  ),
                  onPressed: () {
                    // Panggil fungsi untuk mengontrol lampu
                    _toggleLightStatus(room.roomId, room.isLightOn);
                  },
                ),
              ],
            ),
          ]),
          // --- AKHIR KONTROL LAMPU ---
          const SizedBox(height: 12),
          _buildSensorInfo(Icons.update, 'LAST UPDATE', [
            _buildValueDisplay(room.lastUpdate, Colors.white70, fontSize: 12), // Tampilan waktu lebih kecil
          ]),
        ],
      ),
    );
  }

  // Wrapper untuk setiap bagian informasi sensor
  Widget _buildSensorInfo(IconData icon, String title, List<Widget> children) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: const Color(0xFF00FFFF), size: 20), // Icon lebih kecil
              const SizedBox(width: 8), // Spasi lebih kecil
              // Menggunakan Flexible di sini juga untuk title sensor
              Flexible(
                child: Text(
                  title,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        color: const Color(0xFF00FFFF),
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        letterSpacing: 0.5,
                      ),
                ),
              ),
            ],
          ),
          const Divider(color: Colors.white24, height: 10), // Divider lebih halus
          const SizedBox(height: 8),
          ...children,
        ],
      ),
    );
  }

  Widget _buildTempStats(String label, double value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            '$label:',
            style: const TextStyle(color: Colors.white70, fontSize: 14),
          ),
          Text(
            '${value.toStringAsFixed(1)}°C',
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
          ),
        ],
      ),
    );
  }

  Widget _buildTempDisplay(double value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Text(
        '${value.toStringAsFixed(1)}°C',
        style: const TextStyle(
          color: Color(0xFF00FF00), // Warna hijau terang untuk suhu utama
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildValueDisplay(String value, Color color, {double fontSize = 14}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Text(
        value,
        style: TextStyle(
          color: color,
          fontSize: fontSize,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}

// GridOverlayPainter (sama seperti sebelumnya, dengan perbaikan garis horizontal)
class GridOverlayPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final Paint paint = Paint()
      ..color = const Color.fromARGB(25, 0, 255, 255) // 10% opacity dari #00FFFF
      ..strokeWidth = 1.0;

    const double gridSize = 50.0; // Ukuran kotak grid

    // Gambar garis vertikal
    for (double i = 0; i < size.width; i += gridSize) {
      canvas.drawLine(Offset(i, 0), Offset(i, size.height), paint);
    }

    // Gambar garis horizontal (sudah diperbaiki)
    for (double i = 0; i < size.height; i += gridSize) {
      canvas.drawLine(Offset(0, i), Offset(size.width, i), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return false;
  }
}
