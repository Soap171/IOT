import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:google_fonts/google_fonts.dart';
import 'usage_details_page.dart';
import 'dart:async';

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final DatabaseReference _dbRef = FirebaseDatabase.instance.ref();

  String _userName = "Loading...";
  String _userEmail = "Loading...";
  double? _temperature;
  bool _isLoading = true;

  bool _fanState = false;
  bool _light1State = false;
  bool _light2State = false;

  // Stream subscriptions
  late StreamSubscription<DatabaseEvent> _tempSubscription;
  late StreamSubscription<DatabaseEvent> _fanSubscription;
  late StreamSubscription<DatabaseEvent> _light1Subscription;
  late StreamSubscription<DatabaseEvent> _light2Subscription;

  @override
  void initState() {
    super.initState();
    _fetchUserData();
    _setupRealtimeListeners();
  }

  @override
  void dispose() {
    // Cancel stream subscriptions
    _tempSubscription.cancel();
    _fanSubscription.cancel();
    _light1Subscription.cancel();
    _light2Subscription.cancel();
    super.dispose();
  }

  void _setupRealtimeListeners() {
    // Listen to temperature changes
    _tempSubscription = _dbRef.child('temperature').onValue.listen((event) {
      if (event.snapshot.exists && event.snapshot.value != null) {
        setState(() {
          _temperature = double.tryParse(event.snapshot.value.toString());
        });
      }
    }, onError: (error) {
      print("Error fetching temperature: $error");
    });

    // Listen to fan state changes
    _fanSubscription = _dbRef.child('devices/fan1').onValue.listen((event) {
      if (event.snapshot.exists && event.snapshot.value != null) {
        setState(() {
          _fanState = event.snapshot.value == 1;
        });
      }
    }, onError: (error) {
      print("Error fetching fan state: $error");
    });

    // Listen to light1 state changes
    _light1Subscription =
        _dbRef.child('devices/light1').onValue.listen((event) {
      if (event.snapshot.exists && event.snapshot.value != null) {
        setState(() {
          _light1State = event.snapshot.value == 1;
        });
      }
    }, onError: (error) {
      print("Error fetching light1 state: $error");
    });

    // Listen to light2 state changes
    _light2Subscription =
        _dbRef.child('devices/light2').onValue.listen((event) {
      if (event.snapshot.exists && event.snapshot.value != null) {
        setState(() {
          _light2State = event.snapshot.value == 1;
        });
      }
    }, onError: (error) {
      print("Error fetching light2 state: $error");
    });
  }

  Future<void> _fetchUserData() async {
    try {
      User? currentUser = _auth.currentUser;

      if (currentUser != null) {
        _userEmail = currentUser.email ?? "Unknown Email";
        String uid = currentUser.uid;

        DataSnapshot snapshot = await _dbRef.child('users/$uid').get();
        if (snapshot.exists && snapshot.value != null) {
          Map<dynamic, dynamic> userData =
              snapshot.value as Map<dynamic, dynamic>;
          setState(() {
            _userName = userData['name'] ?? "Unknown User";
          });
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

  void _toggleDevice(String devicePath, bool currentState) async {
    int newState = currentState ? 0 : 1;
    try {
      await _dbRef.child('devices/$devicePath').set(newState);
      // No need to setState here as the stream listener will handle the update
    } catch (e) {
      print("Error updating device state: $e");
      // Show error snackbar
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to update $devicePath'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _logout() {
    _auth.signOut().then((_) {
      Navigator.pop(context);
    });
  }

  void _navigateToUsageDetails() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const UsageDetailsPage(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'IoT Dashboard',
          style: GoogleFonts.poppins(),
        ),
        backgroundColor: const Color.fromARGB(255, 3, 48, 86),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: _logout,
            tooltip: 'Logout',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'Welcome, $_userName!',
                    style: GoogleFonts.poppins(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    'Email: $_userEmail',
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      color: Colors.grey[700],
                    ),
                  ),
                  const SizedBox(height: 20),
                  Card(
                    elevation: 4,
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            "Current Temperature:",
                            style: GoogleFonts.poppins(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            _temperature != null
                                ? "${_temperature!.toStringAsFixed(1)} °C"
                                : "N/A",
                            style: GoogleFonts.poppins(
                              fontSize: 18,
                              color: Colors.blue,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  _buildDeviceCard("Fan", _fanState, "fan1"),
                  _buildDeviceCard("Light 1", _light1State, "light1"),
                  _buildDeviceCard("Light 2", _light2State, "light2"),
                ],
              ),
            ),
    );
  }

  Widget _buildDeviceCard(String deviceName, bool isOn, String devicePath) {
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
              onChanged: (value) => _toggleDevice(devicePath, isOn),
              activeColor: Colors.green,
            ),
          ],
        ),
      ),
    );
  }
}
