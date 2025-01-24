import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  // Temperature value
  double _temperature = 25.0;

  // Device states
  bool _fan1State = false;
  bool _fan2State = false;
  bool _bulb1State = false;
  bool _bulb2State = false;

  // Last updated names
  String _fan1UpdatedBy = "No one";
  String _fan2UpdatedBy = "No one";
  String _bulb1UpdatedBy = "No one";
  String _bulb2UpdatedBy = "No one";

  // Simulate toggling device states
  void _toggleDevice(String deviceName, bool currentState, String updatedBy) {
    setState(() {
      switch (deviceName) {
        case "Fan 1":
          _fan1State = !currentState;
          _fan1UpdatedBy = updatedBy;
          break;
        case "Fan 2":
          _fan2State = !currentState;
          _fan2UpdatedBy = updatedBy;
          break;
        case "Bulb 1":
          _bulb1State = !currentState;
          _bulb1UpdatedBy = updatedBy;
          break;
        case "Bulb 2":
          _bulb2State = !currentState;
          _bulb2UpdatedBy = updatedBy;
          break;
      }
    });
  }

  // Log out function
  void _logout() {
    Navigator.pop(context); // Navigate back to the login page
  }

  // Navigate to Usage Details page
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
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Navigate to Usage Details Button
            ElevatedButton.icon(
              onPressed: _navigateToUsageDetails,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color.fromARGB(255, 3, 48, 86),
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8.0),
                ),
              ),
              icon: const Icon(Icons.bar_chart),
              label: Text(
                'View Usage Details',
                style: GoogleFonts.poppins(
                    fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(height: 20),

            // Temperature Display
            Card(
              elevation: 4,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Temperature',
                      style: GoogleFonts.poppins(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      '${_temperature.toStringAsFixed(1)}°C',
                      style: GoogleFonts.poppins(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.redAccent,
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
              updatedBy: _fan1UpdatedBy,
              toggleCallback: () =>
                  _toggleDevice("Fan 1", _fan1State, "User A"),
            ),
            const SizedBox(height: 10),

            // Fan 2
            _buildDeviceCard(
              deviceName: "Fan 2",
              isOn: _fan2State,
              updatedBy: _fan2UpdatedBy,
              toggleCallback: () =>
                  _toggleDevice("Fan 2", _fan2State, "User B"),
            ),
            const SizedBox(height: 10),

            // Bulb 1
            _buildDeviceCard(
              deviceName: "Bulb 1",
              isOn: _bulb1State,
              updatedBy: _bulb1UpdatedBy,
              toggleCallback: () =>
                  _toggleDevice("Bulb 1", _bulb1State, "User C"),
            ),
            const SizedBox(height: 10),

            // Bulb 2
            _buildDeviceCard(
              deviceName: "Bulb 2",
              isOn: _bulb2State,
              updatedBy: _bulb2UpdatedBy,
              toggleCallback: () =>
                  _toggleDevice("Bulb 2", _bulb2State, "User D"),
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
    required String updatedBy,
    required VoidCallback toggleCallback,
  }) {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  deviceName,
                  style: GoogleFonts.poppins(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Last updated by: $updatedBy',
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    color: Colors.grey,
                  ),
                ),
              ],
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

class UsageDetailsPage extends StatelessWidget {
  const UsageDetailsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Usage Details',
          style: GoogleFonts.poppins(),
        ),
        backgroundColor: const Color.fromARGB(255, 3, 48, 86),
      ),
      body: Center(
        child: Text(
          'Usage details will be displayed here.',
          style: GoogleFonts.poppins(fontSize: 16),
        ),
      ),
    );
  }
}
