import 'package:buzz_app/frames/makefriendpage.dart';
import 'package:buzz_app/frames/radorbroadcast.dart';
import 'package:flutter/material.dart';

class DiscoverTab extends StatelessWidget {
  final String username;

  const DiscoverTab({super.key, required this.username});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: Text('Discover - $username', style: const TextStyle(color: Colors.white)),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _buildOptionButton(
              context,
              icon: Icons.qr_code,
              label: "Make a Friend",
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => MakeFriendPage(username: username)
                  ),
                );
              },
            ),
            const SizedBox(height: 30),
            _buildOptionButton(
              context,
              icon: Icons.radar,
              label: "Radar Broadcast",
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) =>  RadarBroadcastPage(username: username)
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOptionButton(BuildContext context, {required IconData icon, required String label, required VoidCallback onPressed}) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.grey[900],
          padding: const EdgeInsets.symmetric(vertical: 20),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        icon: Icon(icon, size: 32),
        label: Text(label, style: const TextStyle(fontSize: 20)),
        onPressed: onPressed,
      ),
    );
  }
}
