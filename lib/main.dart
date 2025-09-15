import 'dart:io';
import 'package:flutter/material.dart';
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

class ControlPage extends StatefulWidget {
  const ControlPage({Key? key}) : super(key: key);

  @override
  _ControlPageState createState() => _ControlPageState();
}

class _ControlPageState extends State<ControlPage> {
  String _statusMessage = "Siap kirim perintah.";

  // Ganti dengan IP lokal ESP32 atau IP publik router Anda
  final String _esp32Ip = "192.168.1.10";
  final int _esp32Port = 80;

  Future<void> _sendCommand(String command) async {
    setState(() {
      _statusMessage = "Mengirim perintah...";
    });
    try {
      final socket = await Socket.connect(_esp32Ip, _esp32Port, timeout: const Duration(seconds: 5));
      socket.write("$command\n"); // Kirim perintah diikuti baris baru
      await socket.flush();

      // Baca respons dari ESP32
      final response = await socket.first.timeout(const Duration(seconds: 5));
      final String responseString = String.fromCharCodes(response);

      setState(() {
        _statusMessage = responseString.trim();
      });

      await socket.close();
    } on SocketException catch (e) {
      setState(() {
        _statusMessage = "Koneksi gagal: ${e.message}";
      });
      print(e);
    } on TimeoutException {
      setState(() {
        _statusMessage = "Koneksi timeout.";
      });
    } catch (e) {
      setState(() {
        _statusMessage = "Terjadi kesalahan: $e";
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Kontrol ESP32 via Wi-Fi'),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
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
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 20),
                    ),
                    child: const Text('HIDUPKAN', style: TextStyle(fontSize: 16)),
                  ),
                  ElevatedButton(
                    onPressed: () => _sendCommand("LED_OFF"),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 20),
                    ),
                    child: const Text('MATIKAN', style: TextStyle(fontSize: 16)),
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