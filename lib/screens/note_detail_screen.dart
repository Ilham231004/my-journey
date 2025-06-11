import 'dart:async';
import 'dart:io';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../models/note.dart';
import 'package:geolocator/geolocator.dart';
import 'package:sensors_plus/sensors_plus.dart';

class NoteDetailScreen extends StatefulWidget {
  final int noteKey;
  const NoteDetailScreen({super.key, required this.noteKey});

  @override
  State<NoteDetailScreen> createState() => _NoteDetailScreenState();
}

class _NoteDetailScreenState extends State<NoteDetailScreen> {
  Note? note;
  bool _loading = true;
  String? _currencyResult;
  String? _currencyError;
  List<LatLng>? _routePoints;
  String _selectedZona = '';
  String _convertedTime = '';
  final List<String> _zonaList = ['WIB', 'WITA', 'WIT'];
  double? _heading;
  LatLng? _userPosition;
  StreamSubscription<dynamic>? _compassSubscription;

  @override
  void initState() {
    super.initState();
    _loadNote();
    _compassSubscription = magnetometerEvents.listen((event) {
      // event: [x, y, z] in microteslas
      // Heading (azimuth) = atan2(y, x) in radians, convert to degrees
      final x = event.x;
      final y = event.y;
      double heading = (180 / pi) * atan2(x, y);
      setState(() {
        _heading = heading;
      });
    });
  }

  @override
  void dispose() {
    _compassSubscription?.cancel();
    super.dispose();
  }

  Future<void> _loadNote() async {
    var box = await Hive.openBox<Note>('notes');
    setState(() {
      note = box.get(widget.noteKey);
      _loading = false;
      if (note != null) {
        _selectedZona = note!.zonaWaktu;
        _convertedTime = _convertTime(note!.dateTime, note!.zonaWaktu, _selectedZona);
      }
    });
  }

  String _convertTime(DateTime dt, String fromZone, String toZone) {
    // WIB = UTC+7, WITA = UTC+8, WIT = UTC+9
    int fromOffset = 7, toOffset = 7;
    if (fromZone == 'WITA') fromOffset = 8;
    if (fromZone == 'WIT') fromOffset = 9;
    if (toZone == 'WITA') toOffset = 8;
    if (toZone == 'WIT') toOffset = 9;
    final converted = dt.add(Duration(hours: toOffset - fromOffset));
    return '${converted.hour.toString().padLeft(2, '0')}:${converted.minute.toString().padLeft(2, '0')} $toZone';
  }

  Future<void> _convertCurrency(String from, String to, double amount) async {
    setState(() { _currencyResult = null; _currencyError = null; });
    try {
      final url = 'https://api.frankfurter.app/latest?amount=$amount&from=$from&to=$to';
      final resp = await http.get(Uri.parse(url));
      if (resp.statusCode == 200) {
        final data = json.decode(resp.body);
        final rate = data['rates'][to];
        setState(() {
          _currencyResult = '$amount $from = $rate $to';
        });
      } else {
        setState(() { _currencyError = 'Gagal konversi mata uang'; });
      }
    } catch (e) {
      setState(() { _currencyError = 'Gagal konversi mata uang'; });
    }
  }

  Future<void> _showRouteOnMap() async {
    setState(() { });
    try {
      Position pos = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
      setState(() {
        _routePoints = [
          LatLng(pos.latitude, pos.longitude),
          LatLng(note!.latitude, note!.longitude),
        ];
        _userPosition = LatLng(pos.latitude, pos.longitude);
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Gagal mendapatkan lokasi saat ini')));
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    if (note == null) {
      return const Scaffold(body: Center(child: Text('Catatan tidak ditemukan')));
    }
    return Scaffold(
      appBar: AppBar(title: Text(note!.title)),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ListView(
          children: [
            if (note!.imagePath.isNotEmpty)
              ClipRRect(
                borderRadius: BorderRadius.circular(18),
                child: Image.file(
                  File(note!.imagePath),
                  height: 200,
                  fit: BoxFit.cover,
                ),
              ),
            const SizedBox(height: 16),
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        CircleAvatar(
                          backgroundColor: Colors.teal[100],
                          child: Icon(Icons.location_on, color: Colors.teal[700]),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            note!.title,
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 22),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Text(note!.content, style: const TextStyle(fontSize: 16)),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
              child: Column(
                children: [
                  ClipRRect(
                    borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(16), topRight: Radius.circular(16)),
                    child: Container(
                      height: 160,
                      child: FlutterMap(
                        options: MapOptions(
                          initialCenter: LatLng(note!.latitude, note!.longitude),
                          initialZoom: 13.0,
                        ),
                        children: [
                          TileLayer(
                            urlTemplate: "https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png",
                            subdomains: ['a', 'b', 'c'],
                          ),
                          MarkerLayer(
                            markers: [
                              Marker(
                                point: LatLng(note!.latitude, note!.longitude),
                                width: 80.0,
                                height: 80.0,
                                child: const Icon(Icons.location_on, color: Colors.red, size: 40),
                              ),
                              if (_userPosition != null)
                                Marker(
                                  point: _userPosition!,
                                  width: 60.0,
                                  height: 60.0,
                                  child: Transform.rotate(
                                    angle: (_heading ?? 0) * 3.1415926535 / 180,
                                    child: const Icon(Icons.navigation, color: Colors.blue, size: 36),
                                  ),
                                ),
                            ],
                          ),
                          if (_routePoints != null && _routePoints!.length == 2)
                            PolylineLayer(
                              polylines: [
                                Polyline(points: _routePoints!, color: Colors.blue, strokeWidth: 4),
                              ],
                            ),
                        ],
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    child: SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: _showRouteOnMap,
                        icon: const Icon(Icons.directions),
                        label: const Text('Tampilkan Rute dari Lokasi Saya'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.teal,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          textStyle: const TextStyle(fontWeight: FontWeight.bold),
                          elevation: 2,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.calendar_today, color: Colors.teal[700]),
                        const SizedBox(width: 8),
                        Text('Tanggal', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.teal[800])),
                        const SizedBox(width: 8),
                        Text('${note!.dateTime.toLocal().toString().split(' ')[0]}'),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Icon(Icons.access_time, color: Colors.teal[700]),
                        const SizedBox(width: 8),
                        Text('Jam (${note!.zonaWaktu})', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.teal[800])),
                        const SizedBox(width: 8),
                        Text('${note!.dateTime.hour.toString().padLeft(2, '0')}:${note!.dateTime.minute.toString().padLeft(2, '0')}'),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Divider(),
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8.0),
                      child: Text('Konversi Zona Waktu', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.teal[800])),
                    ),
                    DropdownButtonFormField<String>(
                      value: _selectedZona.isNotEmpty ? _selectedZona : null,
                      items: _zonaList.map((z) => DropdownMenuItem(value: z, child: Text(z))).toList(),
                      onChanged: (v) {
                        if (v != null) {
                          setState(() {
                            _selectedZona = v;
                            _convertedTime = _convertTime(note!.dateTime, note!.zonaWaktu, _selectedZona);
                          });
                        }
                      },
                      decoration: const InputDecoration(
                        labelText: 'Pilih Zona Waktu',
                        contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(12))),
                      ),
                    ),
                    if (_selectedZona.isNotEmpty) ...[
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Icon(Icons.schedule, color: Colors.teal[700], size: 20),
                          const SizedBox(width: 8),
                          Text('Jam di $_selectedZona:', style: TextStyle(fontWeight: FontWeight.bold)),
                          const SizedBox(width: 8),
                          Text(_convertedTime),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.monetization_on, color: Colors.teal[700]),
                        const SizedBox(width: 8),
                        Text('Budget:', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.teal[800])),
                        const SizedBox(width: 8),
                        Text('${note!.currency} ${note!.budget}', style: const TextStyle(fontWeight: FontWeight.bold)),
                      ],
                    ),
                    const SizedBox(height: 14),
                    Text('Konversi Mata Uang', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.teal[800])),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<String>(
                      value: note!.currency,
                      items: [
                        "IDR", "AUD", "BGN", "BRL", "CAD", "CHF", "CNY", "CZK", "DKK", "EUR", "GBP", "HKD", "HUF", "ILS", "INR", "ISK", "JPY", "KRW", "MXN", "MYR", "NOK", "NZD", "PHP", "PLN", "RON", "SEK", "SGD", "THB", "TRY", "USD", "ZAR"
                      ].map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
                      onChanged: (v) {
                        if (v != null && v != note!.currency) {
                          _convertCurrency(note!.currency, v, note!.budget);
                        }
                      },
                      decoration: const InputDecoration(
                        labelText: 'Pilih Mata Uang',
                        contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(12))),
                      ),
                    ),
                    if (_currencyResult != null) ...[
                      const SizedBox(height: 8),
                      Text(_currencyResult!, style: const TextStyle(color: Colors.green)),
                    ],
                    if (_currencyError != null) ...[
                      const SizedBox(height: 8),
                      Text(_currencyError!, style: const TextStyle(color: Colors.red)),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
