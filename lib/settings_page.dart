import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  _SettingsPageState createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  final TextEditingController _dbIpController = TextEditingController();
  String _statusMessage = '';
  final String _esp32DeviceName = "ESP32-101";

  @override
  void initState() {
    super.initState();
    _loadDbIp();
  }

  // Muat IP Address yang tersimpan
  Future<void> _loadDbIp() async {
    final prefs = await SharedPreferences.getInstance();
    final savedIp = prefs.getString('dbIp');
    if (savedIp != null) {
      _dbIpController.text = savedIp;
    } else {
      _dbIpController.text = '192.168.1.10'; // IP Address default server XAMPP
    }
  }

  // Simpan IP Address yang dimasukkan
  Future<void> _saveDbIp(String ip) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('dbIp', ip);
  }

  Future<void> _scanAndReturnEsp32Ip() async {
    setState(() {
      _statusMessage = 'Mencari ESP32 di database...';
    });

    try {
      final dbIp = _dbIpController.text;
      await _saveDbIp(dbIp); // Simpan IP ke memori
      final response = await http.get(
        Uri.parse('http://$dbIp/lampu_api/get_active_esp.php?device_name=$_esp32DeviceName')
      ).timeout(const Duration(seconds: 5));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['status'] == 'success') {
          String esp32Ip = data['ip_address'];
          // Kembali ke halaman sebelumnya dan kirim IP address
          Navigator.pop(context, esp32Ip);
        } else {
          if (mounted) {
            setState(() {
              _statusMessage = 'Gagal menemukan ESP32: ${data['message']}';
            });
          }
        }
      } else {
        if (mounted) {
          setState(() {
            _statusMessage = 'Server tidak merespons. Kode: ${response.statusCode}';
          });
        }
      }
    } on Exception catch (e) {
      if (mounted) {
        setState(() {
          _statusMessage = 'Terjadi kesalahan: $e';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Pengaturan'),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              const Text(
                'Masukkan IP Address XAMPP:',
                style: TextStyle(fontSize: 18),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: _dbIpController,
                keyboardType: TextInputType.url,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  labelText: 'IP Address',
                ),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _scanAndReturnEsp32Ip,
                child: const Text('Cari dan Simpan IP Perangkat'),
              ),
              const SizedBox(height: 20),
              Text(
                _statusMessage,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 16,
                  color: Colors.red,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}