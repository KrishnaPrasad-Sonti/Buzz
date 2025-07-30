import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:shared_preferences/shared_preferences.dart';


class MakeFriendPage extends StatefulWidget {
  final String username;
  const MakeFriendPage({super.key, required this.username});

  @override
  State<MakeFriendPage> createState() => _MakeFriendPageState();
}

class _MakeFriendPageState extends State<MakeFriendPage> {
  String? scannedResult;
  List<String> contacts = [];

  @override
  void initState() {
    super.initState();
    _loadContacts();
  }

  Future<void> _loadContacts() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      contacts = prefs.getStringList('contacts') ?? [];
    });
  }

  Future<void> _saveContact(String newUsername) async {
    final prefs = await SharedPreferences.getInstance();

    if (contacts.contains(newUsername)) {
      _showInfoDialog("Already in contacts");
      return;
    }

    if (contacts.length >= 10) {
      _showInfoDialog("Contact limit reached (10)");
      return;
    }

    contacts.add(newUsername);
    await prefs.setStringList('contacts', contacts);

    if (!mounted) return;
    _showInfoDialog("Added $newUsername to contacts");
  }

  void _showQRDialog() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Your QR Code"),
        content: QrImageView(
          data: widget.username,
          version: QrVersions.auto,
          size: 200.0,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Close"),
          ),
        ],
      ),
    );
  }

  void _startScan() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => Scaffold(
          appBar: AppBar(title: const Text("Scan QR")),
          body: MobileScanner(
            onDetect: (capture) async {
              final barcode = capture.barcodes.first;
              final value = barcode.rawValue;
              if (value != null) {
                Navigator.pop(context); // Close scanner
                await _saveContact(value); // Save scanned contact
                if (!mounted) return;
                setState(() {
                  scannedResult = value;
                });
              }
            },
          ),
        ),
      ),
    );
  }

  void _showInfoDialog(String msg) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Info"),
        content: Text(msg),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("OK"),
          ),
        ],
      ),
    );
  }

  void _deleteContact(String username) async {
    final prefs = await SharedPreferences.getInstance();
    contacts.remove(username);
    await prefs.setStringList('contacts', contacts);
    setState(() {}); // Refresh UI
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Make a Friend")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Text("Your name: ${widget.username}"),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: _showQRDialog,
              icon: const Icon(Icons.qr_code),
              label: const Text('Generate QR'),
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: _startScan,
              icon: const Icon(Icons.qr_code_scanner),
              label: const Text('Scan QR'),
            ),
            const SizedBox(height: 30),
            Text("Your Contacts (${contacts.length}/10):", style: const TextStyle(fontSize: 16)),
            const SizedBox(height: 10),
            Expanded(
              child: ListView.builder(
                itemCount: contacts.length,
                itemBuilder: (context, index) {
                  final name = contacts[index];
                  return ListTile(
                    title: Text(name),
                    trailing: IconButton(
                      icon: const Icon(Icons.delete, color: Colors.red),
                      onPressed: () => _deleteContact(name),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
