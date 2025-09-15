import 'dart:io';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:async';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ESP32 Wi-Fi Control',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const ControlPage(),
    );
  }
}

// ---------------------- Halaman Kontrol (ControlPage) ----------------------

class ControlPage extends StatefulWidget {
  const ControlPage({Key? key}) : super(key: key);

  @override
  _ControlPageState createState() => _ControlPageState();
}

class _ControlPageState extends State<ControlPage> {
  String _statusMessage = "Siap kirim perintah.";
  String _esp32Ip = "";
  final int _esp32Port = 80;

  @override
  void initState() {
    super.initState();
    _loadIpAddress();
  }

  Future<void> _loadIpAddress() async {
    final prefs = await SharedPreferences.getInstance();
    if (mounted) { // Pengecekan mounted
      setState(() {
        _esp32Ip = prefs.getString('esp32Ip') ?? '';
      });
    }
  }

  Future<void> _sendCommand(String command) async {
    if (_esp32Ip.isEmpty) {
      if (mounted) { // Pengecekan mounted
        setState(() {
          _statusMessage = "IP Address belum diatur. Silakan ke Pengaturan.";
        });
      }
      return;
    }

    if (mounted) { // Pengecekan mounted
      setState(() {
        _statusMessage = "Mengirim perintah...";
      });
    }
    
    try {
      final socket = await Socket.connect(_esp32Ip, _esp32Port, timeout: const Duration(seconds: 5));
      socket.write("$command\n");
      await socket.flush();
      final response = await socket.first.timeout(const Duration(seconds: 5));
      final String responseString = String.fromCharCodes(response);

      if (mounted) { // Pengecekan mounted
        setState(() {
          _statusMessage = responseString.trim();
        });
      }

      await socket.close();
    } on SocketException catch (e) {
      if (mounted) { // Pengecekan mounted
        setState(() {
          _statusMessage = "Koneksi gagal: ${e.message}";
        });
      }
    } on TimeoutException {
      if (mounted) { // Pengecekan mounted
        setState(() {
          _statusMessage = "Koneksi timeout.";
        });
      }
    } catch (e) {
      if (mounted) { // Pengecekan mounted
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
        title: const Text('Kontrol ESP32'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const SettingsPage()),
              ).then((_) {
                _loadIpAddress();
              });
            },
          ),
        ],
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              Text("IP ESP32: $_esp32Ip", style: const TextStyle(fontSize: 16, fontStyle: FontStyle.italic)),
              const SizedBox(height: 20),
              Text(
                _statusMessage,
                style: const TextStyle(fontSize: 18),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 30),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: <Widget>[
                  ElevatedButton(
                    onPressed: () => _sendCommand("LED_ON"),
                    child: const Text('HIDUPKAN'),
                  ),
                  ElevatedButton(
                    onPressed: () => _sendCommand("LED_OFF"),
                    child: const Text('MATIKAN'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ---------------------- Halaman Pengaturan (SettingsPage) ----------------------

class SettingsPage extends StatefulWidget {
  const SettingsPage({Key? key}) : super(key: key);

  @override
  _SettingsPageState createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  final _ipController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadIpAddress();
  }

  Future<void> _loadIpAddress() async {
    final prefs = await SharedPreferences.getInstance();
    if (mounted) { // Pengecekan mounted
      _ipController.text = prefs.getString('esp32Ip') ?? '';
    }
  }

  Future<void> _saveIpAddress() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('esp32Ip', _ipController.text);
    if (mounted) { // Pengecekan mounted
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('IP Address berhasil disimpan!'))
      );
      Navigator.pop(context);
    }
  }

  @override
  void dispose() {
    _ipController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Pengaturan'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            const Text(
              'Masukkan IP Address ESP32:',
              style: TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _ipController,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                labelText: 'IP Address',
                hintText: 'misalnya: 192.168.1.10',
              ),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _saveIpAddress,
              child: const Text('Simpan IP'),
            ),
          ],
        ),
      ),
    );
  }
}