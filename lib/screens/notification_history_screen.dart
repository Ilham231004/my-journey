import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class NotificationHistoryScreen extends StatefulWidget {
  const NotificationHistoryScreen({super.key});

  @override
  State<NotificationHistoryScreen> createState() => _NotificationHistoryScreenState();
}

class _NotificationHistoryScreenState extends State<NotificationHistoryScreen> {
  List<PendingNotificationRequest> _pending = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadNotifications();
  }

  Future<void> _loadNotifications() async {
    final plugin = FlutterLocalNotificationsPlugin();
    final pending = await plugin.pendingNotificationRequests();
    setState(() {
      _pending = pending;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('History Notifikasi')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _pending.isEmpty
              ? const Center(child: Text('Belum ada notifikasi terjadwal.'))
              : ListView.builder(
                  itemCount: _pending.length,
                  itemBuilder: (context, i) {
                    final n = _pending[i];
                    return ListTile(
                      title: Text(n.title ?? '-'),
                      subtitle: Text(n.body ?? ''),
                      trailing: Text('ID: ${n.id}'),
                    );
                  },
                ),
    );
  }
}
