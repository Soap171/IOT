import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final DatabaseReference _dbRef = FirebaseDatabase.instance.ref();

  String? _userName;
  String? _userEmail;
  bool _isLoading = true;

  // Device states
  bool _fan1State = false;
  bool _fan2State = false;
  bool _bulb1State = false;
  bool _bulb2State = false;

  // Simulate toggling device states
  void _toggleDevice(String deviceName, bool currentState) {
    setState(() {
      switch (deviceName) {
        case "Fan 1":
          _fan1State = !currentState;
          break;
        case "Fan 2":
          _fan2State = !currentState;
          break;
        case "Bulb 1":
          _bulb1State = !currentState;
          break;
        case "Bulb 2":
          _bulb2State = !currentState;
          break;
      }
    });
  }

  @override
  void initState() {
    super.initState();
    _fetchUserData();
  }

  Future<void> _fetchUserData() async {
    try {
      User? currentUser = _auth.currentUser;

      if (currentUser != null) {
        _userEmail = currentUser.email;
        String uid = currentUser.uid;

        // Loop through all users to find matching UID
        DataSnapshot snapshot = await _dbRef.child('users').get();
        if (snapshot.exists) {
          Map<dynamic, dynamic> users = snapshot.value as Map<dynamic, dynamic>;
          for (var userKey in users.keys) {
            Map<dynamic, dynamic> userData = users[userKey];
            if (userData['userId'] == uid) {
              setState(() {
                _userName = userData['name'];
              });
              break;
            }
          }
        }
      }
    } catch (e) {
      print('Error fetching user data: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  // Log out function
  void _logout() {
    _auth.signOut();
    Navigator.pop(context); // Navigate back to the login page
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(
          title: Text('IoT Dashboard', style: GoogleFonts.poppins()),
          backgroundColor: const Color.fromARGB(255, 3, 48, 86),
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text('IoT Dashboard', style: GoogleFonts.poppins()),
        backgroundColor: const Color.fromARGB(255, 3, 48, 86),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: _logout,
            tooltip: 'Logout',
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Welcome Card
            Card(
              elevation: 4,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Welcome, $_userName',
                      style: GoogleFonts.poppins(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Email: $_userEmail',
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        color: Colors.grey,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Fan 1
            _buildDeviceCard(
              deviceName: "Fan 1",
              isOn: _fan1State,
              toggleCallback: () => _toggleDevice("Fan 1", _fan1State),
            ),
            const SizedBox(height: 10),

            // Fan 2
            _buildDeviceCard(
              deviceName: "Fan 2",
              isOn: _fan2State,
              toggleCallback: () => _toggleDevice("Fan 2", _fan2State),
            ),
            const SizedBox(height: 10),

            // Bulb 1
            _buildDeviceCard(
              deviceName: "Bulb 1",
              isOn: _bulb1State,
              toggleCallback: () => _toggleDevice("Bulb 1", _bulb1State),
            ),
            const SizedBox(height: 10),

            // Bulb 2
            _buildDeviceCard(
              deviceName: "Bulb 2",
              isOn: _bulb2State,
              toggleCallback: () => _toggleDevice("Bulb 2", _bulb2State),
            ),
          ],
        ),
      ),
    );
  }

  // Helper method to build device cards
  Widget _buildDeviceCard({
    required String deviceName,
    required bool isOn,
    required VoidCallback toggleCallback,
  }) {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              deviceName,
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            Switch(
              value: isOn,
              onChanged: (value) => toggleCallback(),
              activeColor: Colors.green,
            ),
          ],
        ),
      ),
    );
  }
}
