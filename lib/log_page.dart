import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class LogPage extends StatefulWidget {
  final String dbIp;
  LogPage({required this.dbIp});

  @override
  _LogPageState createState() => _LogPageState();
}

class _LogPageState extends State<LogPage> {
  List<dynamic> _logs = [];
  String _statusMessage = 'Memuat log...';

  @override
  void initState() {
    super.initState();
    _fetchLogs();
  }

  Future<void> _fetchLogs() async {
    try {
      final response = await http.get(
        Uri.parse('http://${widget.dbIp}/lampu_api/get_logs.php')
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['status'] == 'success') {
          setState(() {
            _logs = data['logs'];
            _statusMessage = _logs.isEmpty ? 'Tidak ada log ditemukan.' : 'Log berhasil dimuat.';
          });
        } else {
          setState(() {
            _statusMessage = 'Gagal memuat log: ${data['message']}';
          });
        }
      } else {
        setState(() {
          _statusMessage = 'Server tidak merespons: ${response.statusCode}';
        });
      }
    } on Exception catch (e) {
      setState(() {
        _statusMessage = 'Terjadi kesalahan: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Log Lampu'),
      ),
      body: _logs.isEmpty
          ? Center(child: Text(_statusMessage))
          : ListView.builder(
              itemCount: _logs.length,
              itemBuilder: (context, index) {
                final log = _logs[index];
                return ListTile(
                  title: Text('Status: ${log['status_lampu']} dari ${log['sumber']}'),
                  subtitle: Text('Menyala: ${log['waktu_menyala']}\nPadam: ${log['waktu_padam']}\nDurasi: ${log['lama_menyala_detik']} detik'),
                );
              },
            ),
    );
  }
}