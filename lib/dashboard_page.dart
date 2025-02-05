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

  String _fanTurnedBy = "Unknown";
  String _light1TurnedBy = "Unknown";
  String _light2TurnedBy = "Unknown";

  late StreamSubscription<DatabaseEvent> _tempSubscription;
  late StreamSubscription<DatabaseEvent> _fanSubscription;
  late StreamSubscription<DatabaseEvent> _light1Subscription;
  late StreamSubscription<DatabaseEvent> _light2Subscription;
  late StreamSubscription<DatabaseEvent> _fanTurnedBySubscription;
  late StreamSubscription<DatabaseEvent> _light1TurnedBySubscription;
  late StreamSubscription<DatabaseEvent> _light2TurnedBySubscription;

  @override
  void initState() {
    super.initState();
    _fetchUserData();
    _setupRealtimeListeners();
  }

  @override
  void dispose() {
    _tempSubscription.cancel();
    _fanSubscription.cancel();
    _light1Subscription.cancel();
    _light2Subscription.cancel();
    _fanTurnedBySubscription.cancel();
    _light1TurnedBySubscription.cancel();
    _light2TurnedBySubscription.cancel();
    super.dispose();
  }

  void _setupRealtimeListeners() {
    _tempSubscription = _dbRef.child('temperature').onValue.listen((event) {
      if (event.snapshot.exists) {
        var data = event.snapshot.value as Map<dynamic, dynamic>?;
        if (data != null && data.isNotEmpty) {
          var latestKey = data.keys.last;
          var latestTemperature = double.parse(data[latestKey].toString());
          setState(() {
            _temperature = latestTemperature;
          });
        }
      }
    });

    _fanSubscription =
        _dbRef.child('device/fan1/status').onValue.listen((event) {
      if (event.snapshot.exists) {
        setState(() {
          _fanState = event.snapshot.value == 1;
        });
      }
    });

    _light1Subscription =
        _dbRef.child('device/light1/status').onValue.listen((event) {
      if (event.snapshot.exists) {
        setState(() {
          _light1State = event.snapshot.value == 1;
        });
      }
    });

    _light2Subscription =
        _dbRef.child('device/light2/status').onValue.listen((event) {
      if (event.snapshot.exists) {
        setState(() {
          _light2State = event.snapshot.value == 1;
        });
      }
    });

    _fanTurnedBySubscription =
        _dbRef.child('device/fan1/turnedBy').onValue.listen((event) {
      if (event.snapshot.exists) {
        setState(() {
          _fanTurnedBy = event.snapshot.value.toString();
        });
      }
    });

    _light1TurnedBySubscription =
        _dbRef.child('device/light1/turnedBy').onValue.listen((event) {
      if (event.snapshot.exists) {
        setState(() {
          _light1TurnedBy = event.snapshot.value.toString();
        });
      }
    });

    _light2TurnedBySubscription =
        _dbRef.child('device/light2/turnedBy').onValue.listen((event) {
      if (event.snapshot.exists) {
        setState(() {
          _light2TurnedBy = event.snapshot.value.toString();
        });
      }
    });
  }

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

  void _toggleDevice(String devicePath, bool currentState) async {
    int newState = currentState ? 0 : 1;

    try {
      await _dbRef.child('device/$devicePath').update({
        'status': newState,
        'turnedBy': newState == 1 ? _userName : "Unknown",
      });

      print(
          "Device $devicePath updated: status = $newState, turnedBy = $_userName");
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

  void _logout() {
    _auth.signOut().then((_) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const LoginPage()),
      );
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
                        fontSize: 20, fontWeight: FontWeight.bold),
                  ),
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
                  _buildDeviceCard("Fan", _fanState, "fan1", _fanTurnedBy),
                  _buildDeviceCard(
                      "Light 1", _light1State, "light1", _light1TurnedBy),
                  _buildDeviceCard(
                      "Light 2", _light2State, "light2", _light2TurnedBy),
                ],
              ),
            ),
    );
  }

  Widget _buildDeviceCard(
      String deviceName, bool isOn, String devicePath, String turnedBy) {
    return Card(
      elevation: 4,
      child: ListTile(
        title: Text(deviceName,
            style:
                GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.bold)),
        subtitle: Text("Last turned on by: $turnedBy",
            style: GoogleFonts.poppins(fontSize: 14, color: Colors.grey[700])),
        trailing: Switch(
            value: isOn,
            onChanged: (value) => _toggleDevice(devicePath, isOn),
            activeColor: Colors.green),
      ),
    );
  }
}
