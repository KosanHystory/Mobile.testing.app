// lib/creator_page.dart
import 'package:flutter/material.dart';

class CreatorInfo {
  final String imageName;
  final String name;
  final String npm;

  const CreatorInfo({required this.imageName, required this.name, required this.npm});
}

class CreatorPage extends StatelessWidget {
  const CreatorPage({super.key});

  // Data creator
  final List<CreatorInfo> creators = const [
    CreatorInfo(imageName: 'rifqi.png', name: 'Rifqi Wahid Dhohiri', npm: '23316023'),
    CreatorInfo(imageName: 'agi.png', name: 'Argya Juang Ramadhan', npm: '23316042'),
    CreatorInfo(imageName: 'isna.png', name: 'Isna Hidayatul Lestari', npm: '23316056'),
    CreatorInfo(imageName: 'gug.png', name: 'Muhammad Alivia', npm: '23316024'),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Creator This App'),
        backgroundColor: const Color(0xFF0A0E17),
        foregroundColor: const Color(0xFF00C3FF),
      ),
      backgroundColor: const Color(0xFF0A0E17),
      body: Center( // Pusatkan GridView
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: GridView.count(
            shrinkWrap: true, // Agar GridView hanya mengambil ruang yang dibutuhkan
            crossAxisCount: 2, // 2 kolom per baris
            crossAxisSpacing: 30.0, // Spasi horizontal antar item
            mainAxisSpacing: 30.0, // Spasi vertikal antar item
            childAspectRatio: 0.8, // Rasio aspek item (lebar/tinggi) untuk mengakomodasi gambar dan teks
            children: creators.map((creator) {
              return Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Image.asset(
                    'assets/${creator.imageName}', // Sesuaikan path gambar Anda
                    width: 89, // Ukuran gambar lebih besar
                    height: 89, // Ukuran gambar lebih besar
                    fit: BoxFit.cover, // Menjaga rasio aspek gambar
                  ),
                  const SizedBox(height: 15), // Spasi setelah gambar
                  Text(
                    creator.name, // Nama Creator
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Color(0xFF00C3FF),
                      fontSize: 18, // Ukuran font sedikit lebih besar
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8), // Spasi setelah nama
                  Text(
                    'NPM: ${creator.npm}', // NPM Creator
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 14, // Ukuran font NPM sedikit lebih besar
                    ),
                  ),
                ],
              );
            }).toList(),
          ),
        ),
      ),
    );
  }
}
