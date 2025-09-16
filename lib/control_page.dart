import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:async';
import 'settings_page.dart';
import 'log_page.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ControlPage extends StatefulWidget {
  @override
  _ControlPageState createState() => _ControlPageState();
}

class _ControlPageState extends State<ControlPage> {
  String _esp32Ip = '';
  String _dbIp = ''; // Tambahkan variabel untuk IP database
  final int _esp32Port = 80;
  String _statusMessage = 'Mencari IP ESP32...';
  String _lamp1State = 'OFF';
  String _lamp2State = 'OFF';
  bool _isDeviceReady = false;

  @override
  void initState() {
    super.initState();
    _loadAllIpAddresses(); // Ganti fungsi ini
  }

  // Muat kedua IP Address (ESP32 dan DB) dari shared preferences
  Future<void> _loadAllIpAddresses() async {
    final prefs = await SharedPreferences.getInstance();
    final savedEsp32Ip = prefs.getString('esp32Ip');
    final savedDbIp = prefs.getString('dbIp'); // Ambil IP database

    if (savedEsp32Ip != null && savedEsp32Ip.isNotEmpty) {
      setState(() {
        _esp32Ip = savedEsp32Ip;
        _isDeviceReady = true;
        _statusMessage = 'Perangkat siap di $_esp32Ip';
      });
    } else {
      setState(() {
        _statusMessage = 'IP ESP32 belum ditemukan. Buka Pengaturan.';
      });
    }

    if (savedDbIp != null) {
      _dbIp = savedDbIp;
    }
  }

  // Simpan IP Address ESP32 yang baru didapat
  Future<void> _saveEsp32Ip(String ip) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('esp32Ip', ip);
  }

  // Fungsi untuk menavigasi ke halaman pengaturan dan menunggu hasilnya
  Future<void> _goToSettings() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => SettingsPage()),
    );
    if (result != null) {
      setState(() {
        _esp32Ip = result as String;
        _isDeviceReady = true;
        _statusMessage = 'Perangkat siap di $_esp32Ip';
      });
      _saveEsp32Ip(_esp32Ip);
      _loadAllIpAddresses(); // Muat ulang IP database setelah kembali
    }
  }

  Future<void> _sendCommand(String command, int lampNumber) async {
    if (!_isDeviceReady) {
      if (mounted) {
        setState(() {
          _statusMessage = "Perangkat belum siap. Silakan cari IP di Pengaturan.";
        });
      }
      return;
    }

    if (mounted) {
      setState(() {
        _statusMessage = "Mengirim perintah...";
      });
    }

    try {
      final response = await http.post(
        Uri.parse('http://${_esp32Ip}:${_esp32Port}/command'),
        headers: <String, String>{
          'Content-Type': 'text/plain',
        },
        body: command,
      ).timeout(const Duration(seconds: 5));

      if (mounted) {
        if (response.statusCode == 200) {
          setState(() {
            _statusMessage = response.body;
            if (lampNumber == 1) {
              _lamp1State = command.contains("ON") ? "ON" : "OFF";
            } else if (lampNumber == 2) {
              _lamp2State = command.contains("ON") ? "ON" : "OFF";
            }
          });
        } else {
          setState(() {
            _statusMessage = 'Gagal mengirim perintah. Kode: ${response.statusCode}';
          });
        }
      }
    } on TimeoutException {
      if (mounted) {
        setState(() {
          _statusMessage = "Koneksi timeout. Pastikan ESP32 aktif.";
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _statusMessage = "Terjadi kesalahan: $e";
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Kontrol Lampu'),
        actions: [
          IconButton(
            icon: Icon(Icons.settings),
            onPressed: _goToSettings,
          ),
          IconButton(
            icon: Icon(Icons.list),
            onPressed: () {
              if (_dbIp.isNotEmpty) { // Pastikan IP DB sudah ada
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => LogPage(dbIp: _dbIp)), // Kirim IP DB
                );
              } else {
                setState(() {
                  _statusMessage = 'IP Database belum ditemukan. Buka Pengaturan.';
                });
              }
            },
          ),
        ],
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              Text(
                'Status Lampu 1: $_lamp1State',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: _lamp1State == 'ON' ? Colors.green : Colors.red),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 10),
              Text(
                'Status Lampu 2: $_lamp2State',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: _lamp2State == 'ON' ? Colors.green : Colors.red),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 30),
              Text(
                _statusMessage,
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16),
              ),
              SizedBox(height: 20),
              ElevatedButton(
                onPressed: _isDeviceReady ? () => _sendCommand('LAMP1_ON', 1) : null,
                child: Text('Lampu 1 ON'),
              ),
              ElevatedButton(
                onPressed: _isDeviceReady ? () => _sendCommand('LAMP1_OFF', 1) : null,
                child: Text('Lampu 1 OFF'),
              ),
              SizedBox(height: 20),
              ElevatedButton(
                onPressed: _isDeviceReady ? () => _sendCommand('LAMP2_ON', 2) : null,
                child: Text('Lampu 2 ON'),
              ),
              ElevatedButton(
                onPressed: _isDeviceReady ? () => _sendCommand('LAMP2_OFF', 2) : null,
                child: Text('Lampu 2 OFF'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}