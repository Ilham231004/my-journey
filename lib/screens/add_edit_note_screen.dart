import 'dart:io';
import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:image_picker/image_picker.dart';
import 'package:geolocator/geolocator.dart';
import '../models/note.dart';
import '../services/notification_service.dart';

class AddEditNoteScreen extends StatefulWidget {
  final int? noteKey;
  const AddEditNoteScreen({super.key, this.noteKey});

  @override
  State<AddEditNoteScreen> createState() => _AddEditNoteScreenState();
}

class _AddEditNoteScreenState extends State<AddEditNoteScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _contentController = TextEditingController();
  final _budgetController = TextEditingController();
  final _latitudeController = TextEditingController();
  final _longitudeController = TextEditingController();
  String _currency = 'IDR';
  String _imagePath = '';
  double? _latitude;
  double? _longitude;
  DateTime _dateTime = DateTime.now();
  bool _loading = false;
  String _zonaWaktu = 'WIB';
  final List<String> _currencies = [
    "IDR", "AUD", "BGN", "BRL", "CAD", "CHF", "CNY", "CZK", "DKK", "EUR", "GBP", "HKD", "HUF", "ILS", "INR", "ISK", "JPY", "KRW", "MXN", "MYR", "NOK", "NZD", "PHP", "PLN", "RON", "SEK", "SGD", "THB", "TRY", "USD", "ZAR"
  ];
  final List<String> _zonaList = ['WIB', 'WITA', 'WIT'];

  @override
  void initState() {
    super.initState();
    if (widget.noteKey != null) _loadNote();
  }

  Future<void> _loadNote() async {
    var box = await Hive.openBox<Note>('notes');
    final note = box.get(widget.noteKey);
    if (note != null) {
      _titleController.text = note.title;
      _contentController.text = note.content;
      _budgetController.text = note.budget.toString();
      _currency = note.currency;
      _imagePath = note.imagePath;
      _latitude = note.latitude;
      _longitude = note.longitude;
      _latitudeController.text = note.latitude.toString();
      _longitudeController.text = note.longitude.toString();
      _dateTime = note.dateTime;
      _zonaWaktu = note.zonaWaktu;
      setState(() {});
    }
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery);
    if (picked != null) {
      setState(() { _imagePath = picked.path; });
    }
  }

  Future<void> _getCurrentLocation() async {
    try {
      final pos = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
      setState(() {
        _latitude = pos.latitude;
        _longitude = pos.longitude;
        _latitudeController.text = pos.latitude.toString();
        _longitudeController.text = pos.longitude.toString();
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Gagal mendapatkan lokasi')));
    }
  }

  Future<void> _saveNote() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() { _loading = true; });
    var box = await Hive.openBox<Note>('notes');
    final note = Note(
      title: _titleController.text,
      content: _contentController.text,
      imagePath: _imagePath,
      latitude: _latitude ?? 0,
      longitude: _longitude ?? 0,
      dateTime: _dateTime,
      budget: double.tryParse(_budgetController.text) ?? 0,
      currency: _currency,
      zonaWaktu: _zonaWaktu,
    );
    int noteId;
    if (widget.noteKey == null) {
      noteId = await box.add(note);
    } else {
      noteId = widget.noteKey!;
      await box.put(noteId, note);
      // Cancel reminder lama jika update
      await NotificationService.cancelReminder(noteId);
    }
    // Jadwalkan notifikasi reminder jika tanggal di masa depan
    if (_dateTime.isAfter(DateTime.now())) {
      await NotificationService.scheduleNoteReminder(
        id: noteId,
        title: 'Reminder Perjalanan',
        body: 'Catatan: "+_titleController.text+" pada ${_dateTime.toLocal()} sudah dekat!',
        scheduledDate: _dateTime,
      );
    }
    if (!mounted) return;
    Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.noteKey == null ? 'Tambah Catatan' : 'Edit Catatan')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Card(
                elevation: 3,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                child: Padding(
                  padding: const EdgeInsets.all(18.0),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            CircleAvatar(
                              backgroundColor: Colors.teal[100],
                              child: Icon(Icons.edit_location_alt, color: Colors.teal[700]),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                widget.noteKey == null ? 'Tambah Catatan' : 'Edit Catatan',
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 22),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 18),
                        TextFormField(
                          controller: _titleController,
                          decoration: const InputDecoration(labelText: 'Judul'),
                          validator: (v) => v == null || v.isEmpty ? 'Wajib diisi' : null,
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: _contentController,
                          decoration: const InputDecoration(labelText: 'Isi Catatan'),
                          maxLines: 3,
                          validator: (v) => v == null || v.isEmpty ? 'Wajib diisi' : null,
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            ElevatedButton.icon(
                              onPressed: _pickImage,
                              icon: const Icon(Icons.image),
                              label: const Text('Pilih Gambar'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.teal,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              ),
                            ),
                            const SizedBox(width: 12),
                            _imagePath.isNotEmpty
                                ? ClipRRect(
                                    borderRadius: BorderRadius.circular(10),
                                    child: Image.file(File(_imagePath), width: 60, height: 60, fit: BoxFit.cover),
                                  )
                                : const SizedBox(),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: TextFormField(
                                controller: _budgetController,
                                decoration: const InputDecoration(labelText: 'Budget'),
                                keyboardType: TextInputType.number,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: DropdownButtonFormField<String>(
                                value: _currency,
                                items: _currencies.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
                                onChanged: (v) => setState(() => _currency = v ?? 'IDR'),
                                decoration: const InputDecoration(labelText: 'Mata Uang'),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Icon(Icons.calendar_today, color: Colors.teal[700]),
                            const SizedBox(width: 8),
                            Text('Tanggal & Jam: ${_dateTime.toString().substring(0, 16)}'),
                            const Spacer(),
                            ElevatedButton(
                              onPressed: () async {
                                final picked = await showDatePicker(
                                  context: context,
                                  initialDate: _dateTime,
                                  firstDate: DateTime(2000),
                                  lastDate: DateTime(2100),
                                );
                                if (picked != null) {
                                  final time = await showTimePicker(
                                    context: context,
                                    initialTime: TimeOfDay.fromDateTime(_dateTime),
                                  );
                                  if (time != null) {
                                    setState(() {
                                      _dateTime = DateTime(picked.year, picked.month, picked.day, time.hour, time.minute);
                                    });
                                  }
                                }
                              },
                              child: const Text('Pilih'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.teal,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: TextFormField(
                                controller: _latitudeController,
                                decoration: const InputDecoration(labelText: 'Latitude'),
                                keyboardType: TextInputType.number,
                                onChanged: (v) => _latitude = double.tryParse(v),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: TextFormField(
                                controller: _longitudeController,
                                decoration: const InputDecoration(labelText: 'Longitude'),
                                keyboardType: TextInputType.number,
                                onChanged: (v) => _longitude = double.tryParse(v),
                              ),
                            ),
                            const SizedBox(width: 8),
                            IconButton(
                              icon: const Icon(Icons.my_location),
                              tooltip: 'Gunakan Lokasi Sekarang',
                              onPressed: _getCurrentLocation,
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        DropdownButtonFormField<String>(
                          value: _zonaWaktu,
                          items: _zonaList.map((z) => DropdownMenuItem(value: z, child: Text(z))).toList(),
                          onChanged: (v) => setState(() => _zonaWaktu = v ?? 'WIB'),
                          decoration: const InputDecoration(labelText: 'Zona Waktu'),
                        ),
                        const SizedBox(height: 20),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            onPressed: _saveNote,
                            icon: const Icon(Icons.save),
                            label: Text(widget.noteKey == null ? 'Simpan' : 'Update'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.teal,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              textStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
    );
  }
}
