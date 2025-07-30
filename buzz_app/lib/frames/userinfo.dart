import 'package:buzz_app/components/broadcast_helper.dart';
import 'package:buzz_app/components/online_user_manager.dart';
import 'package:buzz_app/screens/DiscoverTab.dart';
import 'package:buzz_app/screens/Messages_Tab.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';



class UserInfoPage extends StatefulWidget {
  const UserInfoPage({super.key});

  @override
  State<UserInfoPage> createState() => _UserInfoPageState();
}

class _UserInfoPageState extends State<UserInfoPage> {
  String? _username;

  @override
  void initState() {
    super.initState();
    _checkFirstLaunch();
  }

  Future<void> _checkFirstLaunch() async {
    final prefs = await SharedPreferences.getInstance();
    final savedUsername = prefs.getString('final_username');

    if (savedUsername == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _showUsernameDialog();
      });
    } else {
      setState(() {
        _username = savedUsername;
      });
      startBackgroundBroadcast(savedUsername);
      OnlineUserManager().startListening();
    }
  }
  

  Future<void> _showUsernameDialog() async {
    final controller = TextEditingController();

    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return AlertDialog(
          title: const Text("Enter your username for seamless experience"),
          content: TextField(
            controller: controller,
            decoration: const InputDecoration(hintText: "Username"),
          ),
          actions: [
            ElevatedButton(
              onPressed: () async {
                String input = controller.text.trim();
                if (input.isNotEmpty) {
                  final uuid = const Uuid().v4().substring(0, 4);
                  final finalName = "$input\_$uuid";

                  final prefs = await SharedPreferences.getInstance();
                  await prefs.setString('final_username', finalName);

                  if (context.mounted) Navigator.pop(context);

                  setState(() {
                    _username = finalName;
                  });
                  startBackgroundBroadcast(finalName);
                  OnlineUserManager().startListening();
                }
              },
              child: const Text("Save"),
            )
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: Colors.black,
        appBar: AppBar(
  backgroundColor: Colors.transparent,
  elevation: 0,
  centerTitle: true,
  title: Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      const Text(
        "BUZZ",
        style: TextStyle(
          fontSize: 28,
          fontWeight: FontWeight.bold,
          letterSpacing: 2,
          color: Color.fromARGB(255, 172, 23, 247),
        ),
      ),
      const SizedBox(width: 2),
      Image.asset(
        'assets/icons/black.png',
        width: 40,
        height: 40,
        fit: BoxFit.cover,
        
      ),
    ],
  ),
  bottom: const TabBar(
    tabs: [
      Tab(text: "Discover"),
      Tab(text: "Messages"),
    ],
    labelColor: Colors.white,
    indicatorColor: Color.fromARGB(255, 87, 13, 100),
    unselectedLabelColor: Colors.grey,
  ),
        ),
        body: 
              _username == null ? const Center(
              child: CircularProgressIndicator(
                color: Color.fromARGB(255, 87, 13, 100),
              ),
            ) :  TabBarView(
          children: [
            DiscoverTab(username:_username!),   // These are your separate page widgets
            MessagesTab(username: _username!), // Pass the username here
          ],
      )
      ),
      );
  }}


  