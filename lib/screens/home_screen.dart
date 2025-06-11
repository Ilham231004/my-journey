import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import '../models/note.dart';
import '../services/session_service.dart';
import '../services/notification_service.dart';
import 'add_edit_note_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<Note> _notes = [];
  String _search = '';

  @override
  void initState() {
    super.initState();
    _loadNotes();
  }

  Future<void> _loadNotes() async {
    var box = await Hive.openBox<Note>('notes');
    setState(() {
      _notes = box.values.toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _notes.where((n) => n.title.toLowerCase().contains(_search.toLowerCase())).toList();
    return Scaffold(
      appBar: AppBar(
        title: const Text('MyJourney'),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications),
            tooltip: 'History Notifikasi',
            onPressed: () async {
              await Navigator.pushNamed(context, '/notification_history');
              if (mounted) setState(() {}); // Refresh HomeScreen setelah kembali dari notifikasi
            },
          ),
          IconButton(
            icon: const Icon(Icons.person),
            onPressed: () => Navigator.pushNamed(context, '/profile'),
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              decoration: const InputDecoration(
                labelText: 'Cari catatan berdasarkan judul',
                prefixIcon: Icon(Icons.search),
              ),
              onChanged: (v) => setState(() => _search = v),
            ),
          ),
          Expanded(
            child: filtered.isEmpty
                ? const Center(child: Text('Belum ada catatan'))
                : ListView.builder(
                    itemCount: filtered.length,
                    itemBuilder: (context, i) {
                      final note = filtered[i];
                      return Dismissible(
                        key: Key(note.key.toString()),
                        background: Container(
                          decoration: BoxDecoration(
                            color: Colors.red[400],
                            borderRadius: BorderRadius.circular(18),
                          ),
                          alignment: Alignment.centerLeft,
                          padding: const EdgeInsets.only(left: 20),
                          child: const Icon(Icons.delete, color: Colors.white),
                        ),
                        secondaryBackground: Container(
                          decoration: BoxDecoration(
                            color: Colors.red[400],
                            borderRadius: BorderRadius.circular(18),
                          ),
                          alignment: Alignment.centerRight,
                          padding: const EdgeInsets.only(right: 20),
                          child: const Icon(Icons.delete, color: Colors.white),
                        ),
                        confirmDismiss: (direction) async {
                          return await showDialog(
                            context: context,
                            builder: (ctx) => AlertDialog(
                              title: const Text('Hapus Catatan'),
                              content: const Text('Yakin ingin menghapus catatan ini?'),
                              actions: [
                                TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: const Text('Batal')),
                                TextButton(onPressed: () => Navigator.of(ctx).pop(true), child: const Text('Hapus')),
                              ],
                            ),
                          );
                        },
                        onDismissed: (direction) async {
                          var box = await Hive.openBox<Note>('notes');
                          await box.delete(note.key);
                          await NotificationService.cancelReminder(note.key);
                          _loadNotes();
                          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Catatan dihapus')));
                        },
                        child: Card(
                          elevation: 3,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(18),
                          ),
                          child: ListTile(
                            contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                            leading: CircleAvatar(
                              backgroundColor: Colors.teal[100],
                              child: Icon(Icons.notes, color: Colors.teal[700]),
                            ),
                            title: Text(
                              note.title,
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                            ),
                            subtitle: Text(
                              note.content.length > 50 ? note.content.substring(0, 50) + '...' : note.content,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            trailing: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  note.currency + ' ' + note.budget.toStringAsFixed(0),
                                  style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.teal),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  '${note.dateTime.day}/${note.dateTime.month}',
                                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                                ),
                              ],
                            ),
                            onTap: () => Navigator.pushNamed(context, '/note_detail', arguments: note.key),
                            onLongPress: () async {
                              final result = await Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => AddEditNoteScreen(noteKey: note.key),
                                ),
                              );
                              if (result == true) _loadNotes();
                            },
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final result = await Navigator.pushNamed(context, '/add_note');
          if (result == true) _loadNotes();
        },
        child: const Icon(Icons.add),
        tooltip: 'Tambah Catatan',
      ),
    );
  }
}
