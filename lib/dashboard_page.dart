import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:google_fonts/google_fonts.dart';
import 'login_page.dart';
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

  double _fanUsage = 0.0;
  double _light1Usage = 0.0;
  double _light2Usage = 0.0;

  String _fanTurnedBy = "Unknown";
  String _light1TurnedBy = "Unknown";
  String _light2TurnedBy = "Unknown";

  Map<String, DateTime?> _deviceStartTimes = {
    'fan1': null,
    'light1': null,
    'light2': null,
  };

  Future<void> _fetchUserData() async {
    try {
      User? currentUser = _auth.currentUser;
      if (currentUser != null) {
        _userEmail = currentUser.email ?? "Unknown Email";
        String uid = currentUser.uid;

        DatabaseEvent event = await _dbRef.child('users').once();
        if (event.snapshot.exists) {
          Map<dynamic, dynamic> users =
              event.snapshot.value as Map<dynamic, dynamic>;
          for (var key in users.keys) {
            var userData = users[key] as Map<dynamic, dynamic>;
            if (userData['userId'] == uid) {
              setState(() {
                _userName = userData['name'] ?? "Unknown User";
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

  @override
  void initState() {
    super.initState();
    _fetchUserData();
    _setupRealtimeListeners();
  }

  @override
  void dispose() {
    super.dispose();
  }

  void _setupRealtimeListeners() {
    _listenToDeviceStatus('fan1');
    _listenToDeviceStatus('light1');
    _listenToDeviceStatus('light2');

    _listenToUsage('fan1');
    _listenToUsage('light1');
    _listenToUsage('light2');

    // Listen to turnedBy updates
    _listenToTurnedBy('fan1');
    _listenToTurnedBy('light1');
    _listenToTurnedBy('light2');
  }

  void _listenToDeviceStatus(String device) {
    _dbRef.child('device/$device/status').onValue.listen((event) {
      if (event.snapshot.exists) {
        bool newState = event.snapshot.value == 1;
        setState(() {
          if (newState) {
            _deviceStartTimes[device] = DateTime.now();
          } else {
            _calculateUsage(device);
          }
          if (device == 'fan1') _fanState = newState;
          if (device == 'light1') _light1State = newState;
          if (device == 'light2') _light2State = newState;
        });
      }
    });
  }

  void _listenToUsage(String device) {
    _dbRef.child('device/$device/usage').onValue.listen((event) {
      if (event.snapshot.exists) {
        setState(() {
          double usage =
              double.tryParse(event.snapshot.value.toString()) ?? 0.0;
          if (device == 'fan1') _fanUsage = usage;
          if (device == 'light1') _light1Usage = usage;
          if (device == 'light2') _light2Usage = usage;
        });
      }
    });
  }

  void _calculateUsage(String device) {
    DateTime? startTime = _deviceStartTimes[device];
    if (startTime != null) {
      double usage = DateTime.now().difference(startTime).inMinutes.toDouble();
      _deviceStartTimes[device] = null;

      _dbRef.child('device/$device/usage').get().then((snapshot) {
        double previousUsage = snapshot.exists
            ? double.tryParse(snapshot.value.toString()) ?? 0.0
            : 0.0;
        double newUsage = previousUsage + usage;

        _dbRef.child('device/$device').update({'usage': newUsage}).then((_) {
          setState(() {
            if (device == 'fan1') _fanUsage = newUsage;
            if (device == 'light1') _light1Usage = newUsage;
            if (device == 'light2') _light2Usage = newUsage;
          });
        });
      });
    }
  }

  void _toggleDevice(String devicePath, bool currentState) async {
    int newState = currentState ? 0 : 1; // 0 for off, 1 for on
    String actionUser = _userName; // Current user's name

    try {
      await _dbRef.child('device/$devicePath').update({
        'status': newState,
        'turnedBy': actionUser, // Always update with the current user's name
      });

      // Update the corresponding turnedBy state locally
      setState(() {
        if (devicePath == 'fan1') _fanTurnedBy = actionUser;
        if (devicePath == 'light1') _light1TurnedBy = actionUser;
        if (devicePath == 'light2') _light2TurnedBy = actionUser;
      });
    } catch (e) {
      print("Error updating device state: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to update $devicePath'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _listenToTurnedBy(String device) {
    _dbRef.child('device/$device/turnedBy').onValue.listen((event) {
      if (event.snapshot.exists) {
        setState(() {
          String turnedBy = event.snapshot.value.toString();
          if (device == 'fan1') _fanTurnedBy = turnedBy;
          if (device == 'light1') _light1TurnedBy = turnedBy;
          if (device == 'light2') _light2TurnedBy = turnedBy;
        });
      }
    });
  }

  void _logout() {
    _auth.signOut().then((_) {
      Navigator.pushReplacement(
          context, MaterialPageRoute(builder: (context) => const LoginPage()));
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('IoT Dashboard', style: GoogleFonts.poppins()),
        backgroundColor: const Color.fromARGB(255, 230, 238, 245),
        actions: [
          IconButton(
              icon: const Icon(Icons.logout),
              onPressed: _logout,
              tooltip: 'Logout'),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text('Welcome, $_userName!',
                      style: GoogleFonts.poppins(
                          fontSize: 20, fontWeight: FontWeight.bold)),
                  Text('Email: $_userEmail',
                      style: GoogleFonts.poppins(
                          fontSize: 16, color: Colors.grey[700])),
                  const SizedBox(height: 20),
                  Card(
                    elevation: 4,
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text("Current Temperature:",
                              style: GoogleFonts.poppins(
                                  fontSize: 18, fontWeight: FontWeight.bold)),
                          Text(
                              _temperature != null
                                  ? "${_temperature!.toStringAsFixed(1)} °C"
                                  : "N/A",
                              style: GoogleFonts.poppins(
                                  fontSize: 18,
                                  color: Colors.blue,
                                  fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  _buildDeviceCard(
                      "Fan", _fanState, "fan1", _fanTurnedBy, _fanUsage),
                  _buildDeviceCard("Light 1", _light1State, "light1",
                      _light1TurnedBy, _light1Usage),
                  _buildDeviceCard("Light 2", _light2State, "light2",
                      _light2TurnedBy, _light2Usage),
                ],
              ),
            ),
    );
  }

  Widget _buildDeviceCard(String deviceName, bool isOn, String devicePath,
      String turnedBy, double usage) {
    return Card(
      elevation: 4,
      child: ListTile(
        title: Text(deviceName,
            style:
                GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.bold)),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Last changed by: $turnedBy",
                style:
                    GoogleFonts.poppins(fontSize: 14, color: Colors.grey[700])),
            Text("Usage: ${usage.toStringAsFixed(1)} min",
                style: GoogleFonts.poppins(
                    fontSize: 14, fontWeight: FontWeight.bold)),
          ],
        ),
        trailing: Switch(
            value: isOn,
            onChanged: (value) => _toggleDevice(devicePath, isOn),
            activeColor: Colors.green),
      ),
    );
  }
}
