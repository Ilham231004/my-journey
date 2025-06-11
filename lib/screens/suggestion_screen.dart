import 'package:flutter/material.dart';

class SuggestionScreen extends StatelessWidget {
  const SuggestionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Saran & Kesan')), 
      body: Center(
        child: Card(
          elevation: 3,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Text('Saran:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.teal)),
                SizedBox(height: 8),
                Text('Sudah mantap pak!', style: TextStyle(fontSize: 16)),
                SizedBox(height: 24),
                Text('Kesan:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.teal)),
                SizedBox(height: 8),
                Text('Mata kuliah Teknologi dan Pemrograman Mobile memberikan pengalaman belajar yang sangat bermanfaat dalam memahami konsep dasar hingga penerapan aplikasi mobile. Materi yang diajarkan cukup relevan dengan kebutuhan industri saat ini, terutama dalam pengembangan aplikasi berbasis Android. Praktikum dan tugas-tugas yang diberikan juga membantu mahasiswa untuk lebih memahami implementasi kode secara langsung, sehingga menambah wawasan dan keterampilan teknis.', style: TextStyle(fontSize: 16)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
